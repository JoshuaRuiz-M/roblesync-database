SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 52100, 'No existe el usuario administrador.', 1;
    IF EXISTS (SELECT 1
               FROM   finance.accounts_payable)
        THROW 52101, 'La tabla de cuentas por pagar debe estar vacia.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.supplier_invoices
        WHERE  status = 'REGISTERED') <> 270
        THROW 52102, 'Se esperaban 270 facturas de proveedores registradas.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.supplier_invoices
               WHERE  status = 'REGISTERED'
                      AND (total_amount <= 0
                           OR due_date < invoice_date))
        THROW 52103, 'Existen facturas de proveedores con importes o fechas invalidas.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.supplier_invoices AS si
                      INNER JOIN
                      purchasing.purchase_orders AS po
                      ON po.purchase_order_id = si.purchase_order_id
               WHERE  si.status = 'REGISTERED'
                      AND (si.supplier_id <> po.supplier_id
                           OR si.total_amount <> po.total_amount))
        THROW 52104, 'Las facturas no coinciden con las ordenes de compra.', 1;
    INSERT INTO finance.accounts_payable (
        supplier_invoice_id,
        supplier_id,
        original_amount,
        outstanding_balance,
        due_date,
        status,
        created_at,
        created_by
    )
    SELECT si.supplier_invoice_id,
           si.supplier_id,
           si.total_amount,
           si.total_amount,
           si.due_date,
           'PENDING',
           CAST (si.invoice_date AS DATETIME2 (3)),
           @admin
    FROM   purchasing.supplier_invoices AS si
    WHERE  si.status = 'REGISTERED';
    IF (SELECT COUNT(*)
        FROM   finance.accounts_payable) <> 270
        THROW 52105, 'No se generaron las 270 cuentas por pagar.', 1;
    IF EXISTS (SELECT 1
               FROM   finance.accounts_payable
               WHERE  original_amount <= 0
                      OR outstanding_balance <> original_amount
                      OR status <> 'PENDING')
        THROW 52106, 'Existen cuentas por pagar con saldos incorrectos.', 1;
    IF EXISTS (SELECT 1
               FROM   finance.accounts_payable AS ap
                      INNER JOIN
                      purchasing.supplier_invoices AS si
                      ON si.supplier_invoice_id = ap.supplier_invoice_id
               WHERE  ap.supplier_id <> si.supplier_id
                      OR ap.original_amount <> si.total_amount
                      OR ap.due_date <> si.due_date)
        THROW 52107, 'Las cuentas por pagar no coinciden con las facturas.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT   status,
         COUNT(*) AS cantidad_cuentas,
         SUM(original_amount) AS monto_original,
         SUM(outstanding_balance) AS saldo_pendiente
FROM     finance.accounts_payable
GROUP BY status
ORDER BY status;

SELECT COUNT(*) AS total_cuentas,
       SUM(original_amount) AS total_facturado,
       SUM(outstanding_balance) AS total_pendiente
FROM   finance.accounts_payable;

SELECT   s.business_name AS proveedor,
         COUNT(*) AS facturas,
         SUM(ap.original_amount) AS monto_total,
         SUM(ap.outstanding_balance) AS saldo_pendiente
FROM     finance.accounts_payable AS ap
         INNER JOIN
         purchasing.suppliers AS s
         ON s.supplier_id = ap.supplier_id
GROUP BY s.supplier_id, s.business_name
ORDER BY monto_total DESC;

SELECT   CASE WHEN due_date < '2026-10-31' THEN 'VENCIDA' WHEN due_date = '2026-10-31' THEN 'VENCE HOY' ELSE 'POR VENCER' END AS situacion,
         COUNT(*) AS cuentas,
         SUM(outstanding_balance) AS saldo_total
FROM     finance.accounts_payable
WHERE    outstanding_balance > 0
GROUP BY CASE WHEN due_date < '2026-10-31' THEN 'VENCIDA' WHEN due_date = '2026-10-31' THEN 'VENCE HOY' ELSE 'POR VENCER' END
ORDER BY situacion;

SELECT COUNT(*) AS inconsistencias
FROM   finance.accounts_payable AS ap
       INNER JOIN
       purchasing.supplier_invoices AS si
       ON si.supplier_invoice_id = ap.supplier_invoice_id
WHERE  ap.supplier_id <> si.supplier_id
       OR ap.original_amount <> si.total_amount
       OR ap.due_date <> si.due_date
       OR ap.outstanding_balance < 0
       OR ap.outstanding_balance > ap.original_amount;