SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51600, 'No existe el usuario administrador.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.purchase_orders
        WHERE  status = 'RECEIVED') <> 270
        THROW 51601, 'Se requieren 270 ordenes recibidas.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.goods_receipts
        WHERE  status = 'CONFIRMED') <> 270
        THROW 51602, 'Se requieren 270 recepciones confirmadas.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.supplier_invoices)
        THROW 51603, 'La tabla de facturas debe estar vacia.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.purchase_orders AS po
               WHERE  po.status = 'RECEIVED'
                      AND NOT EXISTS (SELECT 1
                                      FROM   purchasing.goods_receipts AS gr
                                      WHERE  gr.purchase_order_id = po.purchase_order_id
                                             AND gr.status = 'CONFIRMED'))
        THROW 51604, 'Hay ordenes recibidas sin recepcion confirmada.', 1;
    IF EXISTS (SELECT   1
               FROM     purchasing.purchase_orders AS po
                        INNER JOIN
                        purchasing.goods_receipts AS gr
                        ON gr.purchase_order_id = po.purchase_order_id
                           AND gr.status = 'CONFIRMED'
               WHERE    po.status = 'RECEIVED'
               GROUP BY po.purchase_order_id
               HAVING   COUNT(*) <> 1)
        THROW 51605, 'Se esperaba una recepcion por orden.', 1;
    DECLARE @facturas TABLE (
        numero            INT             PRIMARY KEY,
        purchase_order_id INT             UNIQUE,
        supplier_id       INT            ,
        invoice_number    NVARCHAR (50)  ,
        invoice_date      DATE           ,
        due_date          DATE           ,
        subtotal          DECIMAL (18, 2),
        tax_amount        DECIMAL (18, 2),
        total_amount      DECIMAL (18, 2),
        created_at        DATETIME2 (3)  );
    WITH OrdenesFacturables
    AS   (SELECT po.purchase_order_id,
                 po.supplier_id,
                 po.subtotal,
                 po.tax_amount,
                 po.total_amount,
                 gr.receipt_date,
                 s.credit_days,
                 ROW_NUMBER() OVER (ORDER BY gr.receipt_date, po.purchase_order_id) AS numero
          FROM   purchasing.purchase_orders AS po
                 INNER JOIN
                 purchasing.suppliers AS s
                 ON s.supplier_id = po.supplier_id
                 INNER JOIN
                 purchasing.goods_receipts AS gr
                 ON gr.purchase_order_id = po.purchase_order_id
                    AND gr.status = 'CONFIRMED'
          WHERE  po.status = 'RECEIVED')
    INSERT INTO @facturas (
        numero,
        purchase_order_id,
        supplier_id,
        invoice_number,
        invoice_date,
        due_date,
        subtotal,
        tax_amount,
        total_amount,
        created_at
    )
    SELECT o.numero,
           o.purchase_order_id,
           o.supplier_id,
           CONCAT('FAC-SIM-', RIGHT(CONCAT('000000', o.numero), 6)),
           CAST (o.receipt_date AS DATE),
           DATEADD(DAY, o.credit_days, CAST (o.receipt_date AS DATE)),
           o.subtotal,
           o.tax_amount,
           o.total_amount,
           o.receipt_date
    FROM   OrdenesFacturables AS o;
    IF (SELECT COUNT(*)
        FROM   @facturas) <> 270
        THROW 51606, 'Deben generarse 270 facturas.', 1;
    IF EXISTS (SELECT 1
               FROM   @facturas
               WHERE  due_date < invoice_date
                      OR subtotal < 0
                      OR tax_amount < 0
                      OR total_amount <> subtotal + tax_amount)
        THROW 51607, 'Existen fechas o importes incorrectos.', 1;
    INSERT INTO purchasing.supplier_invoices (
        supplier_id,
        purchase_order_id,
        invoice_number,
        invoice_date,
        due_date,
        subtotal,
        tax_amount,
        total_amount,
        status,
        notes,
        created_at,
        created_by
    )
    SELECT f.supplier_id,
           f.purchase_order_id,
           f.invoice_number,
           f.invoice_date,
           f.due_date,
           f.subtotal,
           f.tax_amount,
           f.total_amount,
           'REGISTERED',
           N'Factura registrada por recepción completa de mercancía.',
           f.created_at,
           @admin
    FROM   @facturas AS f;
    IF (SELECT COUNT(*)
        FROM   purchasing.supplier_invoices) <> 270
        THROW 51608, 'La cantidad de facturas es incorrecta.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.supplier_invoices AS si
                      INNER JOIN
                      purchasing.purchase_orders AS po
                      ON po.purchase_order_id = si.purchase_order_id
               WHERE  si.supplier_id <> po.supplier_id
                      OR si.subtotal <> po.subtotal
                      OR si.tax_amount <> po.tax_amount
                      OR si.total_amount <> po.total_amount)
        THROW 51609, 'Existen diferencias entre facturas y ordenes.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT COUNT(*) AS total_facturas,
       SUM(subtotal) AS subtotal_general,
       SUM(tax_amount) AS impuestos_generales,
       SUM(total_amount) AS monto_total
FROM   purchasing.supplier_invoices;

SELECT   si.status,
         COUNT(*) AS cantidad,
         SUM(si.total_amount) AS monto_total
FROM     purchasing.supplier_invoices AS si
GROUP BY si.status;

SELECT   s.credit_days,
         COUNT(*) AS facturas,
         SUM(si.total_amount) AS monto_total
FROM     purchasing.supplier_invoices AS si
         INNER JOIN
         purchasing.suppliers AS s
         ON s.supplier_id = si.supplier_id
GROUP BY s.credit_days
ORDER BY s.credit_days;

SELECT   CONVERT (CHAR (7), invoice_date, 120) AS mes,
         COUNT(*) AS facturas,
         SUM(subtotal) AS subtotal,
         SUM(tax_amount) AS impuesto,
         SUM(total_amount) AS total
FROM     purchasing.supplier_invoices
GROUP BY CONVERT (CHAR (7), invoice_date, 120)
ORDER BY mes;

SELECT   TOP (20) si.invoice_number,
                  po.order_number,
                  s.business_name AS proveedor,
                  si.invoice_date,
                  si.due_date,
                  s.credit_days,
                  si.status,
                  si.total_amount
FROM     purchasing.supplier_invoices AS si
         INNER JOIN
         purchasing.purchase_orders AS po
         ON po.purchase_order_id = si.purchase_order_id
         INNER JOIN
         purchasing.suppliers AS s
         ON s.supplier_id = si.supplier_id
ORDER BY si.invoice_date DESC, si.supplier_invoice_id DESC;