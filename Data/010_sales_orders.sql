SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51800, 'No existe el usuario administrador.', 1;
    IF (SELECT COUNT(*)
        FROM   sales.customers) <> 150
        THROW 51801, 'Se requieren 150 clientes.', 1;
    IF EXISTS (SELECT 1
               FROM   sales.sales_orders)
       OR EXISTS (SELECT 1
                  FROM   sales.sales_order_details)
        THROW 51802, 'Las tablas de pedidos deben estar vacias.', 1;
    IF (SELECT COUNT(*)
        FROM   inventory.warehouses
        WHERE  code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC')) <> 3
        THROW 51803, 'Faltan bodegas.', 1;
    CREATE TABLE #pedidos (
        numero               INT           PRIMARY KEY,
        order_number         NVARCHAR (50),
        customer_id          INT          ,
        salesperson_id       INT          ,
        warehouse_id         INT          ,
        price_list_id        INT          ,
        order_date           DATETIME2 (3),
        status               NVARCHAR (30),
        credit_status        NVARCHAR (20),
        credit_authorized_at DATETIME2 (3) NULL,
        credit_authorized_by INT           NULL
    );
    WITH Numeros
    AS   (SELECT TOP (600) ROW_NUMBER() OVER (ORDER BY a.object_id, b.object_id) AS numero
          FROM   sys.all_objects AS a
                 CROSS JOIN sys.all_objects AS b),
         Clientes
    AS   (SELECT customer_id,
                 salesperson_id,
                 price_list_id,
                 credit_days,
                 ROW_NUMBER() OVER (ORDER BY customer_id) AS numero
          FROM   sales.customers
          WHERE  is_active = 1
                 AND is_credit_blocked = 0),
         Bodegas
    AS   (SELECT warehouse_id,
                 ROW_NUMBER() OVER (ORDER BY CASE code WHEN 'BOD-CEN' THEN 1 WHEN 'BOD-ORI' THEN 2 ELSE 3 END) AS numero
          FROM   inventory.warehouses
          WHERE  code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC'))
    INSERT INTO #pedidos (
        numero,
        order_number,
        customer_id,
        salesperson_id,
        warehouse_id,
        price_list_id,
        order_date,
        status,
        credit_status,
        credit_authorized_at,
        credit_authorized_by
    )
    SELECT n.numero,
           CONCAT('PED-SIM-', RIGHT(CONCAT('000000', n.numero), 6)),
           c.customer_id,
           c.salesperson_id,
           b.warehouse_id,
           c.price_list_id,
           DATEADD(HOUR, 8 + (n.numero % 9), DATEADD(DAY, (n.numero - 1) % 240, CAST ('2026-03-01' AS DATETIME2 (3)))),
           CASE WHEN n.numero % 20 = 0 THEN 'CANCELLED' WHEN n.numero % 20 IN (1, 2, 3) THEN 'PENDING' ELSE 'APPROVED' END,
           CASE WHEN n.numero % 20 = 0 THEN 'REJECTED' WHEN n.numero % 20 IN (1, 2, 3) THEN 'PENDING' ELSE 'APPROVED' END,
           CASE WHEN n.numero % 20 NOT IN (0, 1, 2, 3)
                     AND c.credit_days > 0 THEN DATEADD(HOUR, 8 + (n.numero % 9), DATEADD(DAY, (n.numero - 1) % 240, CAST ('2026-03-01' AS DATETIME2 (3)))) ELSE NULL END,
           CASE WHEN n.numero % 20 NOT IN (0, 1, 2, 3)
                     AND c.credit_days > 0 THEN @admin ELSE NULL END
    FROM   Numeros AS n
           INNER JOIN
           Clientes AS c
           ON c.numero = ((n.numero - 1) % 150) + 1
           INNER JOIN
           Bodegas AS b
           ON b.numero = CASE WHEN n.numero % 20 < 11 THEN 1 WHEN n.numero % 20 < 16 THEN 2 ELSE 3 END;
    IF (SELECT COUNT(*)
        FROM   #pedidos) <> 600
        THROW 51804, 'No se generaron 600 pedidos.', 1;
    CREATE TABLE #detalles (
        numero          INT            ,
        product_id      INT            ,
        quantity        DECIMAL (18, 3),
        unit_price      DECIMAL (18, 4),
        discount_amount DECIMAL (18, 2),
        subtotal        DECIMAL (18, 2),
        tax_amount      DECIMAL (18, 2),
        total_amount    DECIMAL (18, 2),
        PRIMARY KEY (numero, product_id)
    );
    INSERT INTO #detalles (
        numero,
        product_id,
        quantity,
        unit_price,
        discount_amount,
        subtotal,
        tax_amount,
        total_amount
    )
    SELECT o.numero,
           x.product_id,
           x.quantity,
           x.unit_price,
           x.discount_amount,
           x.subtotal,
           CAST (ROUND((x.subtotal - x.discount_amount) * 0.12, 2) AS DECIMAL (18, 2)),
           CAST (x.subtotal - x.discount_amount + ROUND((x.subtotal - x.discount_amount) * 0.12, 2) AS DECIMAL (18, 2))
    FROM   #pedidos AS o
           CROSS APPLY (SELECT   TOP (2 + (o.numero % 4)) ws.product_id,
                                                          CAST (CASE WHEN o.numero % 5 = 0 THEN 3 + ((o.numero + ws.product_id) % 8) ELSE 1 + ((o.numero + ws.product_id) % 4) END AS DECIMAL (18, 3)) AS quantity,
                                                          pld.unit_price,
                                                          CAST (ROUND((CASE WHEN o.numero % 5 = 0 THEN 3 + ((o.numero + ws.product_id) % 8) ELSE 1 + ((o.numero + ws.product_id) % 4) END) * pld.unit_price, 2) AS DECIMAL (18, 2)) AS subtotal,
                                                          CAST (ROUND((CASE WHEN o.numero % 5 = 0 THEN 3 + ((o.numero + ws.product_id) % 8) ELSE 1 + ((o.numero + ws.product_id) % 4) END) * pld.unit_price * CASE WHEN o.numero % 10 = 0 THEN 0.05 WHEN o.numero % 10 = 1 THEN 0.03 ELSE 0 END, 2) AS DECIMAL (18, 2)) AS discount_amount
                        FROM     inventory.warehouse_stock AS ws
                                 INNER JOIN
                                 sales.price_list_details AS pld
                                 ON pld.product_id = ws.product_id
                                    AND pld.price_list_id = o.price_list_id
                        WHERE    ws.warehouse_id = o.warehouse_id
                                 AND ws.quantity_on_hand >= 10
                                 AND EXISTS (SELECT 1
                                             FROM   inventory.batch_stock AS bs
                                                    INNER JOIN
                                                    inventory.product_batches AS pb
                                                    ON pb.batch_id = bs.batch_id
                                             WHERE  bs.warehouse_id = ws.warehouse_id
                                                    AND bs.product_id = ws.product_id
                                                    AND bs.quantity_on_hand > 0
                                                    AND pb.received_at <= o.order_date)
                        ORDER BY ABS(CAST (ws.product_id AS BIGINT) * 37 + CAST (o.numero AS BIGINT) * 17) % 997, ws.product_id) AS x;
    IF EXISTS (SELECT   1
               FROM     #pedidos AS o
                        LEFT OUTER JOIN
                        #detalles AS d
                        ON d.numero = o.numero
               GROUP BY o.numero
               HAVING   COUNT(d.product_id) < 2)
        THROW 51805, 'Algunos pedidos no tienen suficientes productos disponibles.', 1;
    IF EXISTS (SELECT 1
               FROM   #detalles
               WHERE  quantity <= 0
                      OR unit_price < 0
                      OR discount_amount > subtotal
                      OR total_amount <> subtotal - discount_amount + tax_amount)
        THROW 51806, 'Existen detalles con importes invalidos.', 1;
    INSERT INTO sales.sales_orders (
        order_number,
        customer_id,
        salesperson_id,
        warehouse_id,
        order_date,
        status,
        credit_status,
        credit_authorized_at,
        credit_authorized_by,
        subtotal,
        discount_amount,
        tax_amount,
        total_amount,
        notes,
        created_at,
        created_by
    )
    SELECT   o.order_number,
             o.customer_id,
             o.salesperson_id,
             o.warehouse_id,
             o.order_date,
             o.status,
             o.credit_status,
             o.credit_authorized_at,
             o.credit_authorized_by,
             SUM(d.subtotal),
             SUM(d.discount_amount),
             SUM(d.tax_amount),
             SUM(d.total_amount),
             N'Pedido comercial de datos sintéticos.',
             o.order_date,
             @admin
    FROM     #pedidos AS o
             INNER JOIN
             #detalles AS d
             ON d.numero = o.numero
    GROUP BY o.numero, o.order_number, o.customer_id, o.salesperson_id, o.warehouse_id, o.order_date, o.status, o.credit_status, o.credit_authorized_at, o.credit_authorized_by;
    INSERT INTO sales.sales_order_details (
        sales_order_id,
        product_id,
        quantity,
        quantity_reserved,
        unit_price,
        discount_amount,
        subtotal,
        tax_amount,
        total_amount,
        created_at,
        created_by
    )
    SELECT so.sales_order_id,
           d.product_id,
           d.quantity,
           0,
           d.unit_price,
           d.discount_amount,
           d.subtotal,
           d.tax_amount,
           d.total_amount,
           so.order_date,
           @admin
    FROM   #detalles AS d
           INNER JOIN
           #pedidos AS o
           ON o.numero = d.numero
           INNER JOIN
           sales.sales_orders AS so
           ON so.order_number = o.order_number;
    IF (SELECT COUNT(*)
        FROM   sales.sales_orders) <> 600
        THROW 51807, 'La cantidad de pedidos es incorrecta.', 1;
    IF (SELECT COUNT(*)
        FROM   sales.sales_order_details) <> (SELECT COUNT(*)
                                              FROM   #detalles)
        THROW 51808, 'Faltan detalles de pedidos.', 1;
    IF EXISTS (SELECT 1
               FROM   sales.sales_orders AS so
                      INNER JOIN
                      (SELECT   sales_order_id,
                                SUM(subtotal) AS subtotal,
                                SUM(discount_amount) AS discount_amount,
                                SUM(tax_amount) AS tax_amount,
                                SUM(total_amount) AS total_amount
                       FROM     sales.sales_order_details
                       GROUP BY sales_order_id) AS d
                      ON d.sales_order_id = so.sales_order_id
               WHERE  so.subtotal <> d.subtotal
                      OR so.discount_amount <> d.discount_amount
                      OR so.tax_amount <> d.tax_amount
                      OR so.total_amount <> d.total_amount)
        THROW 51809, 'Los totales de pedidos y detalles no coinciden.', 1;
    COMMIT TRANSACTION;
    DROP TABLE #detalles;
    DROP TABLE #pedidos;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    IF OBJECT_ID('tempdb..#detalles') IS NOT NULL
        DROP TABLE #detalles;
    IF OBJECT_ID('tempdb..#pedidos') IS NOT NULL
        DROP TABLE #pedidos;
    THROW;
END CATCH

SELECT   status,
         COUNT(*) AS pedidos,
         SUM(total_amount) AS monto_total
FROM     sales.sales_orders
GROUP BY status
ORDER BY status;

SELECT   w.code,
         w.name,
         COUNT(*) AS pedidos,
         SUM(so.total_amount) AS monto_total
FROM     sales.sales_orders AS so
         INNER JOIN
         inventory.warehouses AS w
         ON w.warehouse_id = so.warehouse_id
GROUP BY w.code, w.name
ORDER BY w.code;

SELECT   CONVERT (CHAR (7), order_date, 120) AS mes,
         COUNT(*) AS pedidos,
         SUM(total_amount) AS monto_total
FROM     sales.sales_orders
GROUP BY CONVERT (CHAR (7), order_date, 120)
ORDER BY mes;

SELECT COUNT(*) AS total_detalles,
       SUM(quantity) AS unidades_solicitadas,
       SUM(total_amount) AS monto_total
FROM   sales.sales_order_details;