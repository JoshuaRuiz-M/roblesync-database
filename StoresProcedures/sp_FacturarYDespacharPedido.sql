
CREATE OR ALTER PROCEDURE sales.sp_FacturarYDespacharPedido
    @sales_order_id INT,
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @customer_id INT,
        @salesperson_id INT,
        @warehouse_id INT,
        @order_status NVARCHAR(30),
        @order_total DECIMAL(18,2),
        @subtotal DECIMAL(18,2),
        @discount DECIMAL(18,2),
        @tax DECIMAL(18,2),
        @credit_limit DECIMAL(18,2),
        @credit_days INT,
        @debt DECIMAL(18,2),
        @sales_invoice_id INT,
        @invoice_number NVARCHAR(50),
        @now DATETIME2(3) = SYSUTCDATETIME(),
        @lock_result INT,
        @product_id INT,
        @quantity DECIMAL(18,3),
        @reserved DECIMAL(18,3),
        @remaining DECIMAL(18,3),
        @reserved_remaining DECIMAL(18,3),
        @batch_id INT,
        @batch_quantity DECIMAL(18,3),
        @batch_reserved DECIMAL(18,3),
        @take DECIMAL(18,3),
        @release DECIMAL(18,3),
        @unit_cost DECIMAL(18,4),
        @unit_price DECIMAL(18,4),
        @line_discount DECIMAL(18,2),
        @line_subtotal DECIMAL(18,2),
        @line_tax DECIMAL(18,2),
        @line_total DECIMAL(18,2),
        @stock_quantity DECIMAL(18,3),
        @stock_reserved DECIMAL(18,3),
        @balance_quantity DECIMAL(18,3),
        @balance_value DECIMAL(19,4),
        @movement_value DECIMAL(19,4),
        @line_cost DECIMAL(19,4),
        @detail_id INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC @lock_result = sys.sp_getapplock
            @Resource = 'FACTURACION_DESPACHO_INVENTARIO',
            @LockMode = 'Exclusive',
            @LockOwner = 'Transaction',
            @LockTimeout = 15000;

        IF @lock_result < 0
            THROW 51001, 'No se pudo obtener el bloqueo de facturacion.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM security.users
            WHERE user_id = @user_id
        )
            THROW 51002, 'El usuario indicado no existe.', 1;

        SELECT
            @customer_id = customer_id,
            @salesperson_id = salesperson_id,
            @warehouse_id = warehouse_id,
            @order_status = status,
            @order_total = total_amount,
            @subtotal = subtotal,
            @discount = discount_amount,
            @tax = tax_amount
        FROM sales.sales_orders WITH (UPDLOCK, HOLDLOCK)
        WHERE sales_order_id = @sales_order_id;

        IF @customer_id IS NULL
            THROW 51003, 'El pedido de venta no existe.', 1;

        IF @order_status NOT IN ('APPROVED', 'RESERVED')
            THROW 51004, 'El pedido no esta aprobado ni reservado.', 1;

        IF EXISTS (
            SELECT 1
            FROM sales.sales_invoices
            WHERE sales_order_id = @sales_order_id
        )
            THROW 51005, 'El pedido ya tiene una factura registrada.', 1;

        SELECT
            @credit_limit = credit_limit,
            @credit_days = credit_days
        FROM sales.customers WITH (UPDLOCK, HOLDLOCK)
        WHERE customer_id = @customer_id
          AND is_active = 1
          AND is_credit_blocked = 0;

        IF @credit_limit IS NULL
            THROW 51006, 'El cliente esta inactivo o bloqueado.', 1;

        SELECT
            @debt = COALESCE(SUM(outstanding_balance), 0)
        FROM finance.accounts_receivable WITH (UPDLOCK, HOLDLOCK)
        WHERE customer_id = @customer_id
          AND status IN ('PENDING', 'PARTIALLY_PAID');

        IF @debt + @order_total > @credit_limit
            THROW 51007, 'El cliente no tiene credito disponible suficiente.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM sales.sales_order_details
            WHERE sales_order_id = @sales_order_id
        )
            THROW 51008, 'El pedido no contiene productos.', 1;

        IF EXISTS (
            SELECT 1
            FROM sales.sales_order_details AS d
            LEFT JOIN inventory.warehouse_stock AS ws WITH (UPDLOCK, HOLDLOCK)
                ON ws.product_id = d.product_id
               AND ws.warehouse_id = @warehouse_id
            WHERE d.sales_order_id = @sales_order_id
              AND (
                  ws.warehouse_stock_id IS NULL
                  OR ws.quantity_on_hand < d.quantity
                  OR ws.quantity_on_hand - ws.quantity_reserved
                     < d.quantity - d.quantity_reserved
                  OR ws.quantity_reserved < d.quantity_reserved
              )
        )
            THROW 51009, 'Stock insuficiente o reservas inconsistentes en la bodega.', 1;

        IF EXISTS (
            SELECT 1
            FROM sales.sales_order_details AS d
            OUTER APPLY (
                SELECT
                    SUM(bs.quantity_on_hand) AS stock_lotes,
                    SUM(bs.quantity_reserved) AS reservado_lotes
                FROM inventory.batch_stock AS bs WITH (UPDLOCK, HOLDLOCK)
                WHERE bs.warehouse_id = @warehouse_id
                  AND bs.product_id = d.product_id
            ) AS b
            WHERE d.sales_order_id = @sales_order_id
              AND (
                  COALESCE(b.stock_lotes, 0) < d.quantity
                  OR COALESCE(b.reservado_lotes, 0) < d.quantity_reserved
                  OR COALESCE(b.stock_lotes, 0)
                     - COALESCE(b.reservado_lotes, 0)
                     < d.quantity - d.quantity_reserved
              )
        )
            THROW 51010, 'No hay existencias suficientes distribuidas en los lotes.', 1;

        SET @invoice_number =
            CONCAT(
                'FAC-',
                REPLACE(CONVERT(NVARCHAR(36), NEWID()), '-', '')
            );

        INSERT INTO sales.sales_invoices (
            sales_order_id,
            customer_id,
            salesperson_id,
            invoice_series,
            invoice_number,
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
        VALUES (
            @sales_order_id,
            @customer_id,
            @salesperson_id,
            'FAC',
            @invoice_number,
            @now,
            DATEADD(DAY, @credit_days, CAST(@now AS DATE)),
            @subtotal,
            @discount,
            @tax,
            @order_total,
            'ISSUED',
            @now,
            @user_id
        );

        SET @sales_invoice_id = CONVERT(INT, SCOPE_IDENTITY());

        DECLARE products_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT
                d.sales_order_detail_id,
                d.product_id,
                d.quantity,
                d.quantity_reserved,
                d.unit_price,
                d.discount_amount,
                d.subtotal,
                d.tax_amount,
                d.total_amount,
                p.average_cost
            FROM sales.sales_order_details AS d
            INNER JOIN catalog.products AS p
                ON p.product_id = d.product_id
            WHERE d.sales_order_id = @sales_order_id
            ORDER BY d.product_id;

        OPEN products_cursor;

        FETCH NEXT FROM products_cursor INTO
            @detail_id,
            @product_id,
            @quantity,
            @reserved,
            @unit_price,
            @line_discount,
            @line_subtotal,
            @line_tax,
            @line_total,
            @unit_cost;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;
            SET @reserved_remaining = @reserved;
            SET @line_cost = 0;

            WHILE @remaining > 0
            BEGIN
                SET @batch_id = NULL;
                SET @batch_quantity = NULL;
                SET @batch_reserved = NULL;

                IF @reserved_remaining > 0
                BEGIN
                    SELECT TOP (1)
                        @batch_id = bs.batch_id,
                        @batch_quantity = bs.quantity_on_hand,
                        @batch_reserved = bs.quantity_reserved
                    FROM inventory.batch_stock AS bs WITH (UPDLOCK, HOLDLOCK)
                    INNER JOIN inventory.product_batches AS pb
                        ON pb.batch_id = bs.batch_id
                    WHERE bs.warehouse_id = @warehouse_id
                      AND bs.product_id = @product_id
                      AND bs.quantity_reserved > 0
                    ORDER BY
                        CASE WHEN pb.expiration_date IS NULL THEN 1 ELSE 0 END,
                        pb.expiration_date,
                        bs.batch_id;
                END
                ELSE
                BEGIN
                    SELECT TOP (1)
                        @batch_id = bs.batch_id,
                        @batch_quantity = bs.quantity_on_hand,
                        @batch_reserved = bs.quantity_reserved
                    FROM inventory.batch_stock AS bs WITH (UPDLOCK, HOLDLOCK)
                    INNER JOIN inventory.product_batches AS pb
                        ON pb.batch_id = bs.batch_id
                    WHERE bs.warehouse_id = @warehouse_id
                      AND bs.product_id = @product_id
                      AND bs.quantity_on_hand > bs.quantity_reserved
                    ORDER BY
                        CASE WHEN pb.expiration_date IS NULL THEN 1 ELSE 0 END,
                        pb.expiration_date,
                        bs.batch_id;
                END;

                IF @batch_id IS NULL
                    THROW 51011, 'No fue posible asignar los lotes para el despacho.', 1;

                IF @reserved_remaining > 0
                BEGIN
                    SET @take =
                        CASE
                            WHEN @reserved_remaining < @batch_reserved
                                THEN @reserved_remaining
                            ELSE @batch_reserved
                        END;

                    SET @release = @take;
                END
                ELSE
                BEGIN
                    SET @take =
                        CASE
                            WHEN @remaining < @batch_quantity - @batch_reserved
                                THEN @remaining
                            ELSE @batch_quantity - @batch_reserved
                        END;

                    SET @release = 0;
                END;

                IF @take > @remaining
                    SET @take = @remaining;

                IF @release > @take
                    SET @release = @take;

                UPDATE inventory.batch_stock
                SET
                    quantity_on_hand = quantity_on_hand - @take,
                    quantity_reserved = quantity_reserved - @release,
                    updated_at = @now,
                    updated_by = @user_id
                WHERE warehouse_id = @warehouse_id
                  AND product_id = @product_id
                  AND batch_id = @batch_id
                  AND quantity_on_hand >= @take
                  AND quantity_reserved >= @release;

                IF @@ROWCOUNT <> 1
                    THROW 51012, 'Error al descontar las existencias del lote.', 1;

                UPDATE inventory.warehouse_stock
                SET
                    quantity_on_hand = quantity_on_hand - @take,
                    quantity_reserved = quantity_reserved - @release,
                    updated_at = @now,
                    updated_by = @user_id
                WHERE warehouse_id = @warehouse_id
                  AND product_id = @product_id
                  AND quantity_on_hand >= @take
                  AND quantity_reserved >= @release;

                IF @@ROWCOUNT <> 1
                    THROW 51013, 'Error al actualizar el inventario de la bodega.', 1;

                SELECT
                    @balance_quantity = quantity_on_hand
                FROM inventory.warehouse_stock
                WHERE warehouse_id = @warehouse_id
                  AND product_id = @product_id;

                SET @movement_value =
                    CAST(-@take * @unit_cost AS DECIMAL(19,4));

                SELECT TOP (1)
                    @balance_value = balance_value
                FROM inventory.inventory_movements WITH (UPDLOCK, HOLDLOCK)
                WHERE warehouse_id = @warehouse_id
                  AND product_id = @product_id
                ORDER BY
                    inventory_movement_id DESC;

                IF @balance_value IS NULL
                    SET @balance_value =
                        CAST(
                            (@balance_quantity + @take) * @unit_cost
                            AS DECIMAL(19,4)
                        );

                SET @balance_value = @balance_value + @movement_value;

                IF @balance_value < 0
                    THROW 51014, 'El valor del inventario resultaria negativo.', 1;

                INSERT INTO inventory.inventory_movements (
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
                VALUES (
                    @warehouse_id,
                    @product_id,
                    @batch_id,
                    'SALE_DISPATCH',
                    @now,
                    -@take,
                    @unit_cost,
                    @movement_value,
                    @balance_quantity,
                    @balance_value,
                    'SALES_INVOICE',
                    @sales_invoice_id,
                    CONCAT('Despacho del pedido ', @sales_order_id),
                    @now,
                    @user_id
                );

                SET @line_cost = @line_cost + (@take * @unit_cost);
                SET @remaining = @remaining - @take;
                SET @reserved_remaining = @reserved_remaining - @release;
                SET @balance_value = NULL;
            END;

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
            VALUES (
                @sales_invoice_id,
                @product_id,
                @quantity,
                @unit_price,
                @unit_cost,
                @line_discount,
                @line_subtotal,
                @line_tax,
                @line_total,
                @now,
                @user_id
            );

            UPDATE sales.sales_order_details
            SET
                quantity_reserved = 0,
                updated_at = @now,
                updated_by = @user_id
            WHERE sales_order_detail_id = @detail_id;

            FETCH NEXT FROM products_cursor INTO
                @detail_id,
                @product_id,
                @quantity,
                @reserved,
                @unit_price,
                @line_discount,
                @line_subtotal,
                @line_tax,
                @line_total,
                @unit_cost;
        END;

        CLOSE products_cursor;
        DEALLOCATE products_cursor;

        INSERT INTO finance.accounts_receivable (
            sales_invoice_id,
            customer_id,
            original_amount,
            outstanding_balance,
            due_date,
            status,
            created_at,
            created_by
        )
        VALUES (
            @sales_invoice_id,
            @customer_id,
            @order_total,
            @order_total,
            DATEADD(DAY, @credit_days, CAST(@now AS DATE)),
            'PENDING',
            @now,
            @user_id
        );

        UPDATE sales.sales_orders
        SET
            status = 'COMPLETED',
            updated_at = @now,
            updated_by = @user_id
        WHERE sales_order_id = @sales_order_id
          AND status IN ('APPROVED', 'RESERVED');

        IF @@ROWCOUNT <> 1
            THROW 51015, 'No fue posible completar el pedido.', 1;

        COMMIT TRANSACTION;

        SELECT
            @sales_order_id AS sales_order_id,
            @sales_invoice_id AS sales_invoice_id,
            @invoice_number AS invoice_number,
            @order_total AS total_amount,
            'COMPLETED' AS order_status,
            'Factura y despacho registrados correctamente' AS mensaje;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'products_cursor') >= 0
            CLOSE products_cursor;

        IF CURSOR_STATUS('local', 'products_cursor') >= -1
            DEALLOCATE products_cursor;

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--Pruebas
SELECT TOP (20)
    so.sales_order_id,
    so.order_number,
    so.status,
    so.credit_status,
    so.warehouse_id,
    so.total_amount
FROM sales.sales_orders AS so
WHERE so.status IN ('APPROVED', 'RESERVED')
  AND NOT EXISTS (
      SELECT 1
      FROM sales.sales_invoices AS si
      WHERE si.sales_order_id = so.sales_order_id
  )
ORDER BY so.sales_order_id;


--Ejecución de la prueba
EXEC sales.sp_FacturarYDespacharPedido
    @sales_order_id = 1,
    @user_id = 1;


--Verificación de resultados

DECLARE @sales_order_id INT = 1;

WITH pedido AS (
    SELECT
        so.sales_order_id,
        so.order_number,
        so.status,
        so.warehouse_id,
        so.total_amount
    FROM sales.sales_orders AS so
    WHERE so.sales_order_id = @sales_order_id
),
factura AS (
    SELECT
        si.sales_invoice_id,
        si.sales_order_id,
        si.invoice_number,
        si.status,
        si.total_amount
    FROM sales.sales_invoices AS si
    WHERE si.sales_order_id = @sales_order_id
),
detalle_pedido AS (
    SELECT
        sales_order_id,
        COUNT(*) AS productos,
        SUM(quantity) AS unidades,
        SUM(quantity_reserved) AS reservas_pendientes
    FROM sales.sales_order_details
    WHERE sales_order_id = @sales_order_id
    GROUP BY sales_order_id
),
detalle_factura AS (
    SELECT
        sid.sales_invoice_id,
        COUNT(*) AS productos,
        SUM(sid.quantity) AS unidades
    FROM sales.sales_invoice_details AS sid
    INNER JOIN factura AS f
        ON f.sales_invoice_id = sid.sales_invoice_id
    GROUP BY sid.sales_invoice_id
),
kardex AS (
    SELECT
        im.reference_id AS sales_invoice_id,
        COUNT(*) AS movimientos,
        SUM(-im.quantity) AS unidades_despachadas,
        SUM(im.total_cost) AS costo_total
    FROM inventory.inventory_movements AS im
    INNER JOIN factura AS f
        ON f.sales_invoice_id = im.reference_id
    INNER JOIN pedido AS p
        ON p.warehouse_id = im.warehouse_id
    WHERE im.movement_type = 'SALE_DISPATCH'
      AND im.reference_type = 'SALES_INVOICE'
    GROUP BY im.reference_id
),
cuentas_cobrar AS (
    SELECT
        ar.sales_invoice_id,
        COUNT(*) AS registros,
        SUM(ar.original_amount) AS monto_original
    FROM finance.accounts_receivable AS ar
    INNER JOIN factura AS f
        ON f.sales_invoice_id = ar.sales_invoice_id
    GROUP BY ar.sales_invoice_id
)
SELECT
    p.sales_order_id AS pedido_id,
    p.order_number AS numero_pedido,
    p.status AS estado_pedido,
    f.sales_invoice_id AS factura_id,
    f.invoice_number AS numero_factura,
    f.status AS estado_factura,
    p.total_amount AS total_pedido_Q,
    f.total_amount AS total_factura_Q,
    COALESCE(dp.productos, 0) AS productos_pedido,
    COALESCE(df.productos, 0) AS productos_facturados,
    COALESCE(dp.unidades, 0) AS unidades_pedido,
    COALESCE(df.unidades, 0) AS unidades_facturadas,
    COALESCE(k.movimientos, 0) AS movimientos_kardex,
    COALESCE(k.unidades_despachadas, 0) AS unidades_despachadas,
    COALESCE(k.costo_total, 0) AS costo_salida_Q,
    COALESCE(cc.monto_original, 0) AS cuenta_por_cobrar_Q,

    CASE
        WHEN p.status = 'COMPLETED'
        THEN 'CORRECTO'
        ELSE 'INCORRECTO'
    END AS validacion_pedido,

    CASE
        WHEN f.sales_invoice_id IS NULL
        THEN 'SIN REGISTROS'
        WHEN f.status = 'ISSUED'
         AND f.total_amount = p.total_amount
        THEN 'CORRECTO'
        ELSE 'INCORRECTO'
    END AS validacion_factura,

    CASE
        WHEN f.sales_invoice_id IS NULL
        THEN 'SIN REGISTROS'
        WHEN dp.productos = df.productos
         AND dp.unidades = df.unidades
        THEN 'CORRECTO'
        ELSE 'INCORRECTO'
    END AS validacion_detalle,

    CASE
        WHEN f.sales_invoice_id IS NULL
        THEN 'SIN REGISTROS'
        WHEN k.movimientos > 0
         AND k.unidades_despachadas = dp.unidades
        THEN 'CORRECTO'
        ELSE 'INCORRECTO'
    END AS validacion_kardex,

    CASE
        WHEN COALESCE(dp.reservas_pendientes, 0) = 0
        THEN 'CORRECTO'
        ELSE 'INCORRECTO'
    END AS validacion_reservas,

    CASE
        WHEN f.sales_invoice_id IS NULL
        THEN 'SIN REGISTROS'
        WHEN cc.registros = 1
         AND cc.monto_original = f.total_amount
        THEN 'CORRECTO'
        ELSE 'INCORRECTO'
    END AS validacion_cuenta_cobrar

FROM pedido AS p
LEFT JOIN factura AS f
    ON f.sales_order_id = p.sales_order_id
LEFT JOIN detalle_pedido AS dp
    ON dp.sales_order_id = p.sales_order_id
LEFT JOIN detalle_factura AS df
    ON df.sales_invoice_id = f.sales_invoice_id
LEFT JOIN kardex AS k
    ON k.sales_invoice_id = f.sales_invoice_id
LEFT JOIN cuentas_cobrar AS cc
    ON cc.sales_invoice_id = f.sales_invoice_id;
