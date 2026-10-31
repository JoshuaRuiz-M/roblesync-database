SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    DECLARE @fechaInicio AS DATE = '2025-11-01';
    DECLARE @fechaFin AS DATE = '2026-10-30';
    DECLARE @totalOrdenes AS INT = 300;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51400, 'No existe el usuario administrador.', 1;
    IF (SELECT COUNT(*)
        FROM   catalog.products) <> 200
        THROW 51401, 'Se requieren exactamente 200 productos.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.suppliers) <> 30
        THROW 51402, 'Se requieren exactamente 30 proveedores.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.product_suppliers) <> 400
        THROW 51403, 'Se requieren 400 relaciones producto-proveedor.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.purchase_orders)
       OR EXISTS (SELECT 1
                  FROM   purchasing.purchase_order_details)
        THROW 51404, 'Las tablas de ordenes de compra deben estar vacias.', 1;
    DECLARE @proveedores TABLE (
        numero      INT PRIMARY KEY,
        supplier_id INT NOT NULL);
    INSERT INTO @proveedores (
        numero,
        supplier_id
    )
    SELECT ROW_NUMBER() OVER (ORDER BY s.supplier_id),
           s.supplier_id
    FROM   purchasing.suppliers AS s
    WHERE  s.is_active = 1
           AND EXISTS (SELECT 1
                       FROM   purchasing.product_suppliers AS ps
                       WHERE  ps.supplier_id = s.supplier_id
                              AND ps.is_active = 1);
    DECLARE @cantidadProveedores AS INT;
    SELECT @cantidadProveedores = COUNT(*)
    FROM   @proveedores;
    IF @cantidadProveedores = 0
        THROW 51405, 'No existen proveedores con productos activos.', 1;
    DECLARE @ordenes TABLE (
        numero        INT           PRIMARY KEY,
        order_number  NVARCHAR (50),
        supplier_id   INT          ,
        order_date    DATETIME2 (3),
        expected_date DATE         ,
        status        NVARCHAR (20));
    WITH Digitos
    AS   (SELECT v.n
          FROM   (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS v(n)),
         Numeros
    AS   (SELECT ROW_NUMBER() OVER (ORDER BY a.n, b.n, c.n) AS numero
          FROM   Digitos AS a
                 CROSS JOIN Digitos AS b
                 CROSS JOIN Digitos AS c)
    INSERT INTO @ordenes (
        numero,
        order_number,
        supplier_id,
        order_date,
        expected_date,
        status
    )
    SELECT n.numero,
           CONCAT('OC-SIM-', RIGHT(CONCAT('0000', n.numero), 4)),
           p.supplier_id,
           DATEADD(HOUR, 8 + (n.numero % 9), CAST (DATEADD(DAY, ((n.numero - 1) * DATEDIFF(DAY, @fechaInicio, @fechaFin)) / (@totalOrdenes - 1), @fechaInicio) AS DATETIME2 (3))),
           DATEADD(DAY, 3 + (n.numero % 8), DATEADD(DAY, ((n.numero - 1) * DATEDIFF(DAY, @fechaInicio, @fechaFin)) / (@totalOrdenes - 1), @fechaInicio)),
           CASE WHEN n.numero % 20 = 0 THEN 'CANCELLED' WHEN n.numero % 10 = 0 THEN 'DRAFT' ELSE 'APPROVED' END
    FROM   Numeros AS n
           INNER JOIN
           @proveedores AS p
           ON p.numero = ((n.numero - 1) % @cantidadProveedores) + 1
    WHERE  n.numero <= @totalOrdenes;
    IF (SELECT COUNT(*)
        FROM   @ordenes) <> 300
        THROW 51406, 'Deben generarse 300 ordenes.', 1;
    INSERT INTO purchasing.purchase_orders (
        order_number,
        supplier_id,
        order_date,
        expected_date,
        status,
        subtotal,
        tax_amount,
        total_amount,
        notes,
        created_at,
        created_by
    )
    SELECT o.order_number,
           o.supplier_id,
           o.order_date,
           o.expected_date,
           o.status,
           0,
           0,
           0,
           CASE WHEN o.status = 'CANCELLED' THEN N'Orden cancelada antes de su recepción.' WHEN o.status = 'DRAFT' THEN N'Orden pendiente de aprobación.' ELSE N'Orden aprobada para abastecimiento.' END,
           o.order_date,
           @admin
    FROM   @ordenes AS o;
    DECLARE @detalles TABLE (
        purchase_order_id INT            ,
        product_id        INT            ,
        quantity          DECIMAL (18, 3),
        unit_cost         DECIMAL (18, 4),
        discount_amount   DECIMAL (18, 2),
        subtotal          DECIMAL (18, 2),
        tax_amount        DECIMAL (18, 2),
        total_amount      DECIMAL (18, 2),
        created_at        DATETIME2 (3)  );
    INSERT INTO @detalles (
        purchase_order_id,
        product_id,
        quantity,
        unit_cost,
        discount_amount,
        subtotal,
        tax_amount,
        total_amount,
        created_at
    )
    SELECT po.purchase_order_id,
           seleccion.product_id,
           calculos.quantity,
           calculos.unit_cost,
           CAST (0 AS DECIMAL (18, 2)),
           importes.subtotal,
           importes.tax_amount,
           CAST (importes.subtotal + importes.tax_amount AS DECIMAL (18, 2)),
           po.order_date
    FROM   @ordenes AS o
           INNER JOIN
           purchasing.purchase_orders AS po
           ON po.order_number = o.order_number
           CROSS APPLY (SELECT   TOP (2 + (o.numero % 4)) p.product_id,
                                                          p.average_cost
                        FROM     purchasing.product_suppliers AS ps
                                 INNER JOIN
                                 catalog.products AS p
                                 ON p.product_id = ps.product_id
                        WHERE    ps.supplier_id = o.supplier_id
                                 AND ps.is_active = 1
                                 AND p.is_active = 1
                        ORDER BY ((p.product_id * 17 + o.numero * 13) % 997), p.product_id) AS seleccion
           CROSS APPLY (SELECT CAST (CASE WHEN seleccion.average_cost >= 40 THEN 12 + ((o.numero + seleccion.product_id) % 25) WHEN seleccion.average_cost >= 15 THEN 24 + ((o.numero + seleccion.product_id) % 45) ELSE 48 + ((o.numero + seleccion.product_id) % 90) END AS DECIMAL (18, 3)) AS quantity,
                               CAST (seleccion.average_cost AS DECIMAL (18, 4)) AS unit_cost) AS calculos
           CROSS APPLY (SELECT CAST (ROUND(calculos.quantity * calculos.unit_cost, 2) AS DECIMAL (18, 2)) AS subtotal) AS base
           CROSS APPLY (SELECT base.subtotal,
                               CAST (ROUND(base.subtotal * 0.12, 2) AS DECIMAL (18, 2)) AS tax_amount) AS importes;
    IF EXISTS (SELECT   1
               FROM     purchasing.purchase_orders AS po
                        LEFT OUTER JOIN
                        @detalles AS d
                        ON d.purchase_order_id = po.purchase_order_id
               GROUP BY po.purchase_order_id
               HAVING   COUNT(d.product_id) = 0)
        THROW 51407, 'Existen ordenes sin productos.', 1;
    IF EXISTS (SELECT 1
               FROM   @detalles AS d
                      INNER JOIN
                      purchasing.purchase_orders AS po
                      ON po.purchase_order_id = d.purchase_order_id
               WHERE  NOT EXISTS (SELECT 1
                                  FROM   purchasing.product_suppliers AS ps
                                  WHERE  ps.product_id = d.product_id
                                         AND ps.supplier_id = po.supplier_id
                                         AND ps.is_active = 1))
        THROW 51408, 'Existen productos no asociados al proveedor.', 1;
    INSERT INTO purchasing.purchase_order_details (
        purchase_order_id,
        product_id,
        quantity,
        unit_cost,
        discount_amount,
        subtotal,
        tax_amount,
        total_amount,
        created_at,
        created_by
    )
    SELECT d.purchase_order_id,
           d.product_id,
           d.quantity,
           d.unit_cost,
           d.discount_amount,
           d.subtotal,
           d.tax_amount,
           d.total_amount,
           d.created_at,
           @admin
    FROM   @detalles AS d;
    UPDATE po
    SET    po.subtotal     = totales.subtotal,
           po.tax_amount   = totales.tax_amount,
           po.total_amount = totales.total_amount
    FROM   purchasing.purchase_orders AS po
           INNER JOIN
           (SELECT   purchase_order_id,
                     CAST (SUM(subtotal) AS DECIMAL (18, 2)) AS subtotal,
                     CAST (SUM(tax_amount) AS DECIMAL (18, 2)) AS tax_amount,
                     CAST (SUM(total_amount) AS DECIMAL (18, 2)) AS total_amount
            FROM     purchasing.purchase_order_details
            GROUP BY purchase_order_id) AS totales
           ON totales.purchase_order_id = po.purchase_order_id;
    IF (SELECT COUNT(*)
        FROM   purchasing.purchase_orders) <> 300
        THROW 51409, 'La cantidad de ordenes insertadas es incorrecta.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.purchase_orders
               WHERE  total_amount <> subtotal + tax_amount
                      OR subtotal <= 0)
        THROW 51410, 'Existen totales incorrectos.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.purchase_orders AS po
                      INNER JOIN
                      (SELECT   purchase_order_id,
                                SUM(subtotal) AS subtotal,
                                SUM(tax_amount) AS tax_amount,
                                SUM(total_amount) AS total_amount
                       FROM     purchasing.purchase_order_details
                       GROUP BY purchase_order_id) AS d
                      ON d.purchase_order_id = po.purchase_order_id
               WHERE  po.subtotal <> d.subtotal
                      OR po.tax_amount <> d.tax_amount
                      OR po.total_amount <> d.total_amount)
        THROW 51411, 'Los totales de cabecera y detalle no coinciden.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT COUNT(*) AS total_ordenes,
       SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) AS aprobadas,
       SUM(CASE WHEN status = 'DRAFT' THEN 1 ELSE 0 END) AS borradores,
       SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) AS canceladas,
       SUM(subtotal) AS subtotal_general,
       SUM(tax_amount) AS impuestos_generales,
       SUM(total_amount) AS total_general
FROM   purchasing.purchase_orders;

SELECT COUNT(*) AS total_detalles,
       COUNT(DISTINCT purchase_order_id) AS ordenes_con_detalles,
       COUNT(DISTINCT product_id) AS productos_comprados,
       SUM(quantity) AS unidades_solicitadas
FROM   purchasing.purchase_order_details;

SELECT   CONVERT (CHAR (7), order_date, 120) AS mes,
         COUNT(*) AS ordenes,
         SUM(total_amount) AS monto_total
FROM     purchasing.purchase_orders
GROUP BY CONVERT (CHAR (7), order_date, 120)
ORDER BY mes;

SELECT   TOP (20) po.order_number,
                  s.business_name AS proveedor,
                  po.order_date,
                  po.expected_date,
                  po.status,
                  COUNT(d.purchase_order_detail_id) AS productos,
                  po.subtotal,
                  po.tax_amount,
                  po.total_amount
FROM     purchasing.purchase_orders AS po
         INNER JOIN
         purchasing.suppliers AS s
         ON s.supplier_id = po.supplier_id
         INNER JOIN
         purchasing.purchase_order_details AS d
         ON d.purchase_order_id = po.purchase_order_id
GROUP BY po.order_number, s.business_name, po.order_date, po.expected_date, po.status, po.subtotal, po.tax_amount, po.total_amount
ORDER BY po.order_date DESC;