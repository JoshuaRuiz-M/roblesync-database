SET XACT_ABORT ON;

DECLARE @admin AS INT = 1;

DECLARE @orderId AS INT;

DECLARE @warehouseId AS INT;

DECLARE @invoiceId AS INT;

DECLARE @invoiceDate AS DATETIME2 (3);

DECLARE @productId AS INT;

DECLARE @quantity AS DECIMAL (18, 3);

DECLARE @remaining AS DECIMAL (18, 3);

DECLARE @take AS DECIMAL (18, 3);

DECLARE @batchId AS INT;

DECLARE @batchStockId AS INT;

DECLARE @batchQuantity AS DECIMAL (18, 3);

DECLARE @stockId AS INT;

DECLARE @stockQuantity AS DECIMAL (18, 3);

DECLARE @stockReserved AS DECIMAL (18, 3);

DECLARE @previousQuantity AS DECIMAL (18, 3);

DECLARE @previousValue AS DECIMAL (19, 4);

DECLARE @balanceQuantity AS DECIMAL (18, 3);

DECLARE @balanceValue AS DECIMAL (19, 4);

DECLARE @unitCost AS DECIMAL (18, 4);

DECLARE @movementCost AS DECIMAL (19, 4);

DECLARE @totalIssued AS DECIMAL (18, 3);

DECLARE @facturadas AS INT = 0;

DECLARE @omitidas AS INT = 0;

BEGIN TRY
    BEGIN TRANSACTION;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51900, 'No existe el usuario administrador.', 1;
    IF EXISTS (SELECT 1
               FROM   sales.sales_invoices
               WHERE  invoice_series = 'SIM')
        THROW 51901, 'Ya existen facturas de esta serie.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock AS ws
               WHERE  ws.quantity_reserved <> 0)
        THROW 51902, 'Existen reservas previas. Revisar antes de facturar.', 1;
    IF EXISTS (SELECT 1
               FROM   sales.sales_order_details
               WHERE  quantity_reserved <> 0)
        THROW 51903, 'Existen detalles previamente reservados.', 1;
    DECLARE pedidos CURSOR LOCAL FAST_FORWARD
        FOR SELECT   so.sales_order_id,
                     so.warehouse_id,
                     DATEADD(HOUR, 2, so.order_date)
            FROM     sales.sales_orders AS so
            WHERE    so.status = 'APPROVED'
                     AND so.credit_status = 'APPROVED'
                     AND NOT EXISTS (SELECT 1
                                     FROM   sales.sales_invoices AS si
                                     WHERE  si.sales_order_id = so.sales_order_id)
            ORDER BY so.order_date, so.sales_order_id;
    OPEN pedidos;
    FETCH NEXT FROM pedidos INTO @orderId, @warehouseId, @invoiceDate;
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF EXISTS (SELECT 1
                       FROM   sales.sales_order_details AS d
                              LEFT OUTER JOIN
                              inventory.warehouse_stock AS ws
                              ON ws.warehouse_id = @warehouseId
                                 AND ws.product_id = d.product_id
                       WHERE  d.sales_order_id = @orderId
                              AND (ws.warehouse_stock_id IS NULL
                                   OR ws.quantity_on_hand - ws.quantity_reserved < d.quantity
                                   OR (SELECT COALESCE (SUM(bs.quantity_on_hand), 0)
                                       FROM   inventory.batch_stock AS bs
                                              INNER JOIN
                                              inventory.product_batches AS pb
                                              ON pb.batch_id = bs.batch_id
                                       WHERE  bs.warehouse_id = @warehouseId
                                              AND bs.product_id = d.product_id
                                              AND pb.is_active = 1
                                              AND pb.received_at <= @invoiceDate
                                              AND (pb.expiration_date IS NULL
                                                   OR pb.expiration_date >= CAST (@invoiceDate AS DATE))) < d.quantity))
                BEGIN
                    SET @omitidas = @omitidas + 1;
                END
            ELSE
                BEGIN
                    UPDATE ws
                    SET    quantity_reserved = ws.quantity_reserved + d.quantity,
                           updated_at        = @invoiceDate,
                           updated_by        = @admin
                    FROM   inventory.warehouse_stock AS ws
                           INNER JOIN
                           sales.sales_order_details AS d
                           ON d.product_id = ws.product_id
                    WHERE  d.sales_order_id = @orderId
                           AND ws.warehouse_id = @warehouseId;
                    UPDATE sales.sales_order_details
                    SET    quantity_reserved = quantity,
                           updated_at        = @invoiceDate,
                           updated_by        = @admin
                    WHERE  sales_order_id = @orderId;
                    INSERT INTO sales.sales_invoices (
                        sales_order_id,
                        customer_id,
                        salesperson_id,
                        invoice_series,
                        invoice_number,
                        dte_uuid,
                        invoice_date,
                        due_date,
                        subtotal,
                        discount_amount,
                        tax_amount,
                        total_amount,
                        status,
                        created_at,
                        created_by
                    )
                    SELECT so.sales_order_id,
                           so.customer_id,
                           so.salesperson_id,
                           'SIM',
                           CONCAT('FAC-', RIGHT(CONCAT('000000', so.sales_order_id), 6)),
                           NULL,
                           @invoiceDate,
                           DATEADD(DAY, c.credit_days, CAST (@invoiceDate AS DATE)),
                           so.subtotal,
                           so.discount_amount,
                           so.tax_amount,
                           so.total_amount,
                           'ISSUED',
                           @invoiceDate,
                           @admin
                    FROM   sales.sales_orders AS so
                           INNER JOIN
                           sales.customers AS c
                           ON c.customer_id = so.customer_id
                    WHERE  so.sales_order_id = @orderId;
                    SET @invoiceId = CONVERT (INT, SCOPE_IDENTITY());
                    DECLARE detalles CURSOR LOCAL FAST_FORWARD
                        FOR SELECT   product_id,
                                     quantity
                            FROM     sales.sales_order_details
                            WHERE    sales_order_id = @orderId
                            ORDER BY product_id;
                    OPEN detalles;
                    FETCH NEXT FROM detalles INTO @productId, @quantity;
                    WHILE @@FETCH_STATUS = 0
                        BEGIN
                            SELECT @stockId = warehouse_stock_id,
                                   @stockQuantity = quantity_on_hand,
                                   @stockReserved = quantity_reserved
                            FROM   inventory.warehouse_stock WITH (UPDLOCK)
                            WHERE  warehouse_id = @warehouseId
                                   AND product_id = @productId;
                            SELECT   TOP (1) @previousQuantity = balance_quantity,
                                             @previousValue = balance_value
                            FROM     inventory.inventory_movements WITH (UPDLOCK)
                            WHERE    warehouse_id = @warehouseId
                                     AND product_id = @productId
                            ORDER BY inventory_movement_id DESC;
                            IF @previousQuantity IS NULL
                               OR @previousQuantity <> @stockQuantity
                               OR @stockReserved < @quantity
                               OR @stockQuantity < @quantity
                                THROW 51904, 'El inventario no coincide con el Kardex.', 1;
                            SET @unitCost = CAST (ROUND(@previousValue / @stockQuantity, 4) AS DECIMAL (18, 4));
                            INSERT INTO sales.sales_invoice_details (
                                sales_invoice_id,
                                product_id,
                                quantity,
                                unit_price,
                                unit_cost,
                                discount_amount,
                                subtotal,
                                tax_amount,
                                total_amount,
                                created_at,
                                created_by
                            )
                            SELECT @invoiceId,
                                   product_id,
                                   quantity,
                                   unit_price,
                                   @unitCost,
                                   discount_amount,
                                   subtotal,
                                   tax_amount,
                                   total_amount,
                                   @invoiceDate,
                                   @admin
                            FROM   sales.sales_order_details
                            WHERE  sales_order_id = @orderId
                                   AND product_id = @productId;
                            SET @remaining = @quantity;
                            SET @balanceQuantity = @previousQuantity;
                            SET @balanceValue = @previousValue;
                            SET @totalIssued = 0;
                            DECLARE lotes CURSOR LOCAL FAST_FORWARD
                                FOR SELECT   bs.batch_stock_id,
                                             bs.batch_id,
                                             bs.quantity_on_hand
                                    FROM     inventory.batch_stock AS bs WITH (UPDLOCK)
                                             INNER JOIN
                                             inventory.product_batches AS pb
                                             ON pb.batch_id = bs.batch_id
                                    WHERE    bs.warehouse_id = @warehouseId
                                             AND bs.product_id = @productId
                                             AND bs.quantity_on_hand > 0
                                             AND pb.is_active = 1
                                             AND pb.received_at <= @invoiceDate
                                             AND (pb.expiration_date IS NULL
                                                  OR pb.expiration_date >= CAST (@invoiceDate AS DATE))
                                    ORDER BY CASE WHEN pb.expiration_date IS NULL THEN 1 ELSE 0 END, pb.expiration_date, pb.received_at, bs.batch_id;
                            OPEN lotes;
                            FETCH NEXT FROM lotes INTO @batchStockId, @batchId, @batchQuantity;
                            WHILE @@FETCH_STATUS = 0
                                  AND @remaining > 0
                                BEGIN
                                    SET @take = CASE WHEN @batchQuantity >= @remaining THEN @remaining ELSE @batchQuantity END;
                                    SET @movementCost = CAST (ROUND(-@take * @unitCost, 4) AS DECIMAL (19, 4));
                                    SET @balanceQuantity = @balanceQuantity - @take;
                                    SET @balanceValue = CASE WHEN @balanceQuantity = 0 THEN 0 ELSE @balanceValue + @movementCost END;
                                    IF @balanceValue < 0
                                        THROW 51905, 'Saldo valorizado negativo.', 1;
                                    UPDATE inventory.batch_stock
                                    SET    quantity_on_hand = quantity_on_hand - @take,
                                           updated_at       = @invoiceDate,
                                           updated_by       = @admin
                                    WHERE  batch_stock_id = @batchStockId;
                                    INSERT  INTO inventory.inventory_movements (
                                        warehouse_id,
                                        product_id,
                                        batch_id,
                                        movement_type,
                                        movement_date,
                                        quantity,
                                        unit_cost,
                                        total_cost,
                                        balance_quantity,
                                        balance_value,
                                        reference_type,
                                        reference_id,
                                        notes,
                                        created_at,
                                        created_by
                                    )
                                    VALUES                                     (@warehouseId, @productId, @batchId, 'SALE_DISPATCH', @invoiceDate, -@take, @unitCost, @movementCost, @balanceQuantity, @balanceValue, 'SALES_INVOICE', @invoiceId, N'Salida de inventario por facturación.', @invoiceDate, @admin);
                                    SET @remaining = @remaining - @take;
                                    SET @totalIssued = @totalIssued + @take;
                                    FETCH NEXT FROM lotes INTO @batchStockId, @batchId, @batchQuantity;
                                END
                            CLOSE lotes;
                            DEALLOCATE lotes;
                            IF @remaining <> 0
                               OR @totalIssued <> @quantity
                                THROW 51906, 'No fue posible completar la salida por lotes.', 1;
                            UPDATE inventory.warehouse_stock
                            SET    quantity_on_hand  = @balanceQuantity,
                                   quantity_reserved = @stockReserved - @quantity,
                                   updated_at        = @invoiceDate,
                                   updated_by        = @admin
                            WHERE  warehouse_stock_id = @stockId;
                            UPDATE sales.sales_order_details
                            SET    quantity_reserved = 0,
                                   updated_at        = @invoiceDate,
                                   updated_by        = @admin
                            WHERE  sales_order_id = @orderId
                                   AND product_id = @productId;
                            SET @previousQuantity = NULL;
                            SET @previousValue = NULL;
                            FETCH NEXT FROM detalles INTO @productId, @quantity;
                        END
                    CLOSE detalles;
                    DEALLOCATE detalles;
                    UPDATE sales.sales_orders
                    SET    status     = 'COMPLETED',
                           updated_at = @invoiceDate,
                           updated_by = @admin
                    WHERE  sales_order_id = @orderId;
                    SET @facturadas = @facturadas + 1;
                END
            FETCH NEXT FROM pedidos INTO @orderId, @warehouseId, @invoiceDate;
        END
    CLOSE pedidos;
    DEALLOCATE pedidos;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock
               WHERE  quantity_on_hand < 0
                      OR quantity_reserved < 0
                      OR quantity_reserved > quantity_on_hand)
        THROW 51907, 'Se detectaron existencias inconsistentes.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.batch_stock
               WHERE  quantity_on_hand < 0)
        THROW 51908, 'Se detectaron lotes con existencias negativas.', 1;
    IF EXISTS (SELECT 1
               FROM   sales.sales_invoices AS si
                      INNER JOIN
                      sales.sales_orders AS so
                      ON so.sales_order_id = si.sales_order_id
               WHERE  si.invoice_series = 'SIM'
                      AND (si.subtotal <> so.subtotal
                           OR si.discount_amount <> so.discount_amount
                           OR si.tax_amount <> so.tax_amount
                           OR si.total_amount <> so.total_amount))
        THROW 51909, 'Las facturas no coinciden con sus pedidos.', 1;
    COMMIT TRANSACTION;
    SELECT @facturadas AS facturas_generadas,
           @omitidas AS pedidos_sin_stock_suficiente;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    IF CURSOR_STATUS('local', 'lotes') >= -1
        BEGIN
            IF CURSOR_STATUS('local', 'lotes') >= 0
                CLOSE lotes;
            DEALLOCATE lotes;
        END
    IF CURSOR_STATUS('local', 'detalles') >= -1
        BEGIN
            IF CURSOR_STATUS('local', 'detalles') >= 0
                CLOSE detalles;
            DEALLOCATE detalles;
        END
    IF CURSOR_STATUS('local', 'pedidos') >= -1
        BEGIN
            IF CURSOR_STATUS('local', 'pedidos') >= 0
                CLOSE pedidos;
            DEALLOCATE pedidos;
        END;
    THROW;
END CATCH

SELECT   status,
         COUNT(*) AS cantidad
FROM     sales.sales_orders
GROUP BY status
ORDER BY status;

SELECT COUNT(*) AS facturas,
       SUM(total_amount) AS ventas_facturadas
FROM   sales.sales_invoices
WHERE  status = 'ISSUED';

SELECT COUNT(*) AS movimientos_venta,
       SUM(-quantity) AS unidades_vendidas,
       SUM(-total_cost) AS costo_ventas
FROM   inventory.inventory_movements
WHERE  movement_type = 'SALE_DISPATCH'
       AND reference_type = 'SALES_INVOICE';

SELECT   w.code AS bodega,
         SUM(ws.quantity_on_hand) AS existencias,
         SUM(ws.quantity_reserved) AS reservadas
FROM     inventory.warehouse_stock AS ws
         INNER JOIN
         inventory.warehouses AS w
         ON w.warehouse_id = ws.warehouse_id
GROUP BY w.code
ORDER BY w.code;