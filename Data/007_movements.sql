SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51500, 'No existe el usuario administrador.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.purchase_orders) <> 300
        THROW 51501, 'Se requieren las 300 ordenes de compra.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.purchase_orders
        WHERE  status = 'APPROVED') <> 270
        THROW 51502, 'Se requieren 270 ordenes aprobadas.', 1;
    IF (SELECT COUNT(*)
        FROM   inventory.warehouses
        WHERE  code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC')
               AND is_active = 1) <> 3
        THROW 51503, 'Faltan bodegas activas.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.goods_receipts)
       OR EXISTS (SELECT 1
                  FROM   purchasing.goods_receipt_details)
       OR EXISTS (SELECT 1
                  FROM   inventory.product_batches)
       OR EXISTS (SELECT 1
                  FROM   inventory.batch_stock)
       OR EXISTS (SELECT 1
                  FROM   inventory.inventory_movements)
        THROW 51504, 'Las tablas de recepciones, lotes y movimientos deben estar vacias.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock
               WHERE  quantity_on_hand <> 0
                      OR quantity_reserved <> 0)
        THROW 51505, 'El inventario inicial debe estar en cero.', 1;
    DECLARE @ordenes TABLE (
        numero            INT           PRIMARY KEY,
        purchase_order_id INT           UNIQUE,
        warehouse_id      INT          ,
        receipt_number    NVARCHAR (50),
        receipt_date      DATETIME2 (3));
    WITH OrdenesNumeradas
    AS   (SELECT po.purchase_order_id,
                 po.order_date,
                 po.expected_date,
                 ROW_NUMBER() OVER (ORDER BY po.order_date, po.purchase_order_id) AS numero
          FROM   purchasing.purchase_orders AS po
          WHERE  po.status = 'APPROVED')
    INSERT INTO @ordenes (
        numero,
        purchase_order_id,
        warehouse_id,
        receipt_number,
        receipt_date
    )
    SELECT o.numero,
           o.purchase_order_id,
           w.warehouse_id,
           CONCAT('REC-SIM-', RIGHT(CONCAT('000000', o.numero), 6)),
           DATEADD(HOUR, 9 + (o.numero % 7), CAST (CASE WHEN o.expected_date IS NOT NULL THEN o.expected_date ELSE DATEADD(DAY, 5, CAST (o.order_date AS DATE)) END AS DATETIME2 (3)))
    FROM   OrdenesNumeradas AS o
           INNER JOIN
           inventory.warehouses AS w
           ON w.code = CASE WHEN (o.numero - 1) % 20 < 11 THEN 'BOD-CEN' WHEN (o.numero - 1) % 20 < 16 THEN 'BOD-ORI' ELSE 'BOD-OCC' END;
    IF (SELECT COUNT(*)
        FROM   @ordenes) <> 270
        THROW 51506, 'No se generaron las 270 recepciones.', 1;
    INSERT INTO purchasing.goods_receipts (
        receipt_number,
        purchase_order_id,
        warehouse_id,
        receipt_date,
        status,
        notes,
        confirmed_at,
        confirmed_by,
        created_at,
        created_by
    )
    SELECT o.receipt_number,
           o.purchase_order_id,
           o.warehouse_id,
           o.receipt_date,
           'CONFIRMED',
           N'Recepción completa de mercancía correspondiente a la orden de compra.',
           o.receipt_date,
           @admin,
           o.receipt_date,
           @admin
    FROM   @ordenes AS o;
    DECLARE @lineas TABLE (
        goods_receipt_id         INT            ,
        purchase_order_id        INT            ,
        purchase_order_detail_id INT             PRIMARY KEY,
        warehouse_id             INT            ,
        product_id               INT            ,
        batch_number             NVARCHAR (100) ,
        quantity                 DECIMAL (18, 3),
        unit_cost                DECIMAL (18, 4),
        receipt_date             DATETIME2 (3)  ,
        manufacturing_date       DATE           ,
        expiration_date          DATE           );
    INSERT INTO @lineas (
        goods_receipt_id,
        purchase_order_id,
        purchase_order_detail_id,
        warehouse_id,
        product_id,
        batch_number,
        quantity,
        unit_cost,
        receipt_date,
        manufacturing_date,
        expiration_date
    )
    SELECT gr.goods_receipt_id,
           po.purchase_order_id,
           pod.purchase_order_detail_id,
           gr.warehouse_id,
           pod.product_id,
           CONCAT('LOT-SIM-', RIGHT(CONCAT('00000000', pod.purchase_order_detail_id), 8)),
           pod.quantity,
           pod.unit_cost,
           gr.receipt_date,
           CASE WHEN p.tracks_expiration = 1 THEN DATEADD(DAY, -30 - (pod.product_id % 60), CAST (gr.receipt_date AS DATE)) ELSE NULL END,
           CASE WHEN p.tracks_expiration = 1 THEN DATEADD(DAY, CASE WHEN p.product_line_id IS NULL THEN 180 WHEN pod.product_id % 5 = 0 THEN 180 WHEN pod.product_id % 5 = 1 THEN 270 WHEN pod.product_id % 5 = 2 THEN 365 WHEN pod.product_id % 5 = 3 THEN 540 ELSE 730 END, CAST (gr.receipt_date AS DATE)) ELSE NULL END
    FROM   purchasing.goods_receipts AS gr
           INNER JOIN
           purchasing.purchase_orders AS po
           ON po.purchase_order_id = gr.purchase_order_id
           INNER JOIN
           purchasing.purchase_order_details AS pod
           ON pod.purchase_order_id = po.purchase_order_id
           INNER JOIN
           catalog.products AS p
           ON p.product_id = pod.product_id
    WHERE  gr.receipt_number LIKE 'REC-SIM-%';
    IF EXISTS (SELECT   1
               FROM     purchasing.goods_receipts AS gr
                        LEFT OUTER JOIN
                        @lineas AS l
                        ON l.goods_receipt_id = gr.goods_receipt_id
               GROUP BY gr.goods_receipt_id
               HAVING   COUNT(l.purchase_order_detail_id) = 0)
        THROW 51507, 'Existen recepciones sin detalles.', 1;
    IF EXISTS (SELECT 1
               FROM   @lineas
               WHERE  quantity <= 0
                      OR unit_cost < 0)
        THROW 51508, 'Existen cantidades o costos invalidos.', 1;
    INSERT INTO inventory.product_batches (
        product_id,
        batch_number,
        manufacturing_date,
        expiration_date,
        received_at,
        is_active,
        created_at,
        created_by
    )
    SELECT l.product_id,
           l.batch_number,
           l.manufacturing_date,
           l.expiration_date,
           l.receipt_date,
           1,
           l.receipt_date,
           @admin
    FROM   @lineas AS l;
    INSERT INTO purchasing.goods_receipt_details (
        goods_receipt_id,
        purchase_order_id,
        purchase_order_detail_id,
        batch_id,
        product_id,
        quantity_received,
        unit_cost,
        created_at,
        created_by
    )
    SELECT l.goods_receipt_id,
           l.purchase_order_id,
           l.purchase_order_detail_id,
           b.batch_id,
           l.product_id,
           l.quantity,
           l.unit_cost,
           l.receipt_date,
           @admin
    FROM   @lineas AS l
           INNER JOIN
           inventory.product_batches AS b
           ON b.product_id = l.product_id
              AND b.batch_number = l.batch_number;
    INSERT INTO inventory.batch_stock (
        warehouse_id,
        product_id,
        batch_id,
        quantity_on_hand,
        quantity_reserved,
        updated_at,
        updated_by
    )
    SELECT l.warehouse_id,
           l.product_id,
           b.batch_id,
           l.quantity,
           0,
           l.receipt_date,
           @admin
    FROM   @lineas AS l
           INNER JOIN
           inventory.product_batches AS b
           ON b.product_id = l.product_id
              AND b.batch_number = l.batch_number;
    WITH Existencias
    AS   (SELECT   warehouse_id,
                   product_id,
                   SUM(quantity) AS quantity,
                   MAX(receipt_date) AS last_receipt
          FROM     @lineas
          GROUP BY warehouse_id, product_id)
    UPDATE ws
    SET    ws.quantity_on_hand = e.quantity,
           ws.updated_at       = e.last_receipt,
           ws.updated_by       = @admin
    FROM   inventory.warehouse_stock AS ws
           INNER JOIN
           Existencias AS e
           ON e.warehouse_id = ws.warehouse_id
              AND e.product_id = ws.product_id;
    IF (SELECT COUNT(*)
        FROM   (SELECT DISTINCT warehouse_id,
                                product_id
                FROM   @lineas) AS x) <> (SELECT COUNT(*)
                                          FROM   inventory.warehouse_stock
                                          WHERE  quantity_on_hand > 0)
        THROW 51509, 'No se actualizaron todas las existencias por bodega.', 1;
    WITH MovimientosBase
    AS   (SELECT l.warehouse_id,
                 l.product_id,
                 b.batch_id,
                 l.purchase_order_detail_id,
                 l.goods_receipt_id,
                 l.receipt_date,
                 l.quantity,
                 l.unit_cost,
                 CAST (ROUND(l.quantity * l.unit_cost, 4) AS DECIMAL (19, 4)) AS total_cost
          FROM   @lineas AS l
                 INNER JOIN
                 inventory.product_batches AS b
                 ON b.product_id = l.product_id
                    AND b.batch_number = l.batch_number),
         MovimientosAcumulados
    AS   (SELECT m.*,
                 CAST (SUM(m.quantity) OVER (PARTITION BY m.warehouse_id, m.product_id ORDER BY m.receipt_date, m.purchase_order_detail_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DECIMAL (18, 3)) AS balance_quantity,
                 CAST (SUM(m.total_cost) OVER (PARTITION BY m.warehouse_id, m.product_id ORDER BY m.receipt_date, m.purchase_order_detail_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DECIMAL (19, 4)) AS balance_value
          FROM   MovimientosBase AS m)
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
    SELECT m.warehouse_id,
           m.product_id,
           m.batch_id,
           'PURCHASE_RECEIPT',
           m.receipt_date,
           m.quantity,
           m.unit_cost,
           m.total_cost,
           m.balance_quantity,
           m.balance_value,
           'GOODS_RECEIPT',
           m.goods_receipt_id,
           N'Entrada de mercancía por recepción de compra.',
           m.receipt_date,
           @admin
    FROM   MovimientosAcumulados AS m;
    UPDATE po
    SET    po.status     = 'RECEIVED',
           po.updated_at = o.receipt_date,
           po.updated_by = @admin
    FROM   purchasing.purchase_orders AS po
           INNER JOIN
           @ordenes AS o
           ON o.purchase_order_id = po.purchase_order_id
    WHERE  po.status = 'APPROVED';
    IF (SELECT COUNT(*)
        FROM   purchasing.purchase_orders
        WHERE  status = 'RECEIVED') <> 270
        THROW 51510, 'No se actualizaron todas las ordenes.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.goods_receipt_details) <> (SELECT COUNT(*)
                                                     FROM   @lineas)
        THROW 51511, 'Faltan detalles de recepción.', 1;
    IF (SELECT COUNT(*)
        FROM   inventory.inventory_movements
        WHERE  movement_type = 'PURCHASE_RECEIPT') <> (SELECT COUNT(*)
                                                       FROM   @lineas)
        THROW 51512, 'Faltan movimientos de inventario.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock AS ws
                      LEFT OUTER JOIN
                      (SELECT   warehouse_id,
                                product_id,
                                SUM(quantity_on_hand) AS quantity
                       FROM     inventory.batch_stock
                       GROUP BY warehouse_id, product_id) AS bs
                      ON bs.warehouse_id = ws.warehouse_id
                         AND bs.product_id = ws.product_id
               WHERE  ws.quantity_on_hand <> COALESCE (bs.quantity, 0))
        THROW 51513, 'Las existencias por bodega y lote no coinciden.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock AS ws
                      LEFT OUTER JOIN
                      (SELECT   warehouse_id,
                                product_id,
                                SUM(quantity) AS quantity
                       FROM     inventory.inventory_movements
                       GROUP BY warehouse_id, product_id) AS im
                      ON im.warehouse_id = ws.warehouse_id
                         AND im.product_id = ws.product_id
               WHERE  ws.quantity_on_hand <> COALESCE (im.quantity, 0))
        THROW 51514, 'Las existencias y el Kardex no coinciden.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT (SELECT COUNT(*)
        FROM   purchasing.goods_receipts) AS recepciones,
       (SELECT COUNT(*)
        FROM   purchasing.goods_receipt_details) AS detalles,
       (SELECT COUNT(*)
        FROM   inventory.product_batches) AS lotes,
       (SELECT COUNT(*)
        FROM   inventory.batch_stock) AS existencias_lotes,
       (SELECT COUNT(*)
        FROM   inventory.inventory_movements) AS movimientos;

SELECT   w.code,
         w.name,
         COUNT(CASE WHEN ws.quantity_on_hand > 0 THEN 1 END) AS productos_con_existencias,
         SUM(ws.quantity_on_hand) AS unidades_disponibles
FROM     inventory.warehouses AS w
         INNER JOIN
         inventory.warehouse_stock AS ws
         ON ws.warehouse_id = w.warehouse_id
WHERE    w.code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC')
GROUP BY w.code, w.name
ORDER BY w.code;

SELECT   po.status,
         COUNT(*) AS total_ordenes
FROM     purchasing.purchase_orders AS po
GROUP BY po.status
ORDER BY po.status;

SELECT   CONVERT (CHAR (7), gr.receipt_date, 120) AS mes,
         COUNT(DISTINCT gr.goods_receipt_id) AS recepciones,
         SUM(grd.quantity_received) AS unidades_recibidas,
         CAST (SUM(grd.quantity_received * grd.unit_cost) AS DECIMAL (19, 2)) AS costo_mercancia
FROM     purchasing.goods_receipts AS gr
         INNER JOIN
         purchasing.goods_receipt_details AS grd
         ON grd.goods_receipt_id = gr.goods_receipt_id
GROUP BY CONVERT (CHAR (7), gr.receipt_date, 120)
ORDER BY mes;