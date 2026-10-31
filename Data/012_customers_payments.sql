SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    DECLARE @fechaCorte AS DATETIME2 (3) = '2026-10-31T23:59:59.997';
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 52000, 'No existe el usuario administrador.', 1;
    IF EXISTS (SELECT 1
               FROM   finance.accounts_receivable)
       OR EXISTS (SELECT 1
                  FROM   finance.customer_payments)
        THROW 52001, 'Las tablas financieras deben estar vacias.', 1;
    IF (SELECT COUNT(*)
        FROM   sales.sales_invoices
        WHERE  status = 'ISSUED') <> 417
        THROW 52002, 'Se esperaban 417 facturas emitidas.', 1;
    CREATE TABLE #facturas (
        numero           INT             PRIMARY KEY,
        sales_invoice_id INT             NOT NULL,
        customer_id      INT             NOT NULL,
        invoice_date     DATETIME2 (3)   NOT NULL,
        due_date         DATE            NOT NULL,
        total_amount     DECIMAL (18, 2) NOT NULL,
        tipo_pago        NVARCHAR (20)   NOT NULL
    );
    WITH FacturasNumeradas
    AS   (SELECT ROW_NUMBER() OVER (ORDER BY invoice_date, sales_invoice_id) AS numero,
                 sales_invoice_id,
                 customer_id,
                 invoice_date,
                 due_date,
                 total_amount
          FROM   sales.sales_invoices
          WHERE  status = 'ISSUED')
    INSERT INTO #facturas (
        numero,
        sales_invoice_id,
        customer_id,
        invoice_date,
        due_date,
        total_amount,
        tipo_pago
    )
    SELECT numero,
           sales_invoice_id,
           customer_id,
           invoice_date,
           due_date,
           total_amount,
           CASE WHEN numero % 20 < 12 THEN 'PAID' WHEN numero % 20 < 17 THEN 'PARTIALLY_PAID' ELSE 'PENDING' END
    FROM   FacturasNumeradas;
    IF EXISTS (SELECT 1
               FROM   #facturas
               WHERE  total_amount <= 0
                      OR invoice_date > @fechaCorte)
        THROW 52003, 'Existen facturas con fechas o importes invalidos.', 1;
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
    SELECT sales_invoice_id,
           customer_id,
           total_amount,
           total_amount,
           due_date,
           'PENDING',
           invoice_date,
           @admin
    FROM   #facturas;
    CREATE TABLE #pagos (
        numero                INT             NOT NULL,
        numero_abono          INT             NOT NULL,
        account_receivable_id INT             NOT NULL,
        payment_number        NVARCHAR (50)   NOT NULL,
        payment_date          DATETIME2 (3)   NOT NULL,
        amount                DECIMAL (18, 2) NOT NULL,
        payment_method        NVARCHAR (20)   NOT NULL,
        reference_number      NVARCHAR (100)  NULL,
        PRIMARY KEY (numero, numero_abono)
    );
    INSERT INTO #pagos (
        numero,
        numero_abono,
        account_receivable_id,
        payment_number,
        payment_date,
        amount,
        payment_method,
        reference_number
    )
    SELECT f.numero,
           1,
           ar.account_receivable_id,
           CONCAT('PAG-SIM-', RIGHT(CONCAT('000000', f.numero), 6), '-01'),
           fechas.payment_date,
           CASE WHEN f.tipo_pago = 'PAID' THEN CASE WHEN f.numero % 3 = 0 THEN CAST (ROUND(f.total_amount * 0.50, 2) AS DECIMAL (18, 2)) ELSE f.total_amount END ELSE CAST (ROUND(f.total_amount * 0.35, 2) AS DECIMAL (18, 2)) END,
           CASE f.numero % 4 WHEN 0 THEN 'CASH' WHEN 1 THEN 'TRANSFER' WHEN 2 THEN 'CARD' ELSE 'CHECK' END,
           CONCAT('REF-SIM-', RIGHT(CONCAT('000000', f.numero), 6), '-01')
    FROM   #facturas AS f
           INNER JOIN
           finance.accounts_receivable AS ar
           ON ar.sales_invoice_id = f.sales_invoice_id
           CROSS APPLY (SELECT DATEADD(DAY, CASE f.numero % 4 WHEN 0 THEN 0 WHEN 1 THEN 2 WHEN 2 THEN 5 ELSE 10 END, f.invoice_date) AS payment_date) AS fechas
    WHERE  f.tipo_pago IN ('PAID', 'PARTIALLY_PAID')
           AND fechas.payment_date <= @fechaCorte;
    INSERT INTO #pagos (
        numero,
        numero_abono,
        account_receivable_id,
        payment_number,
        payment_date,
        amount,
        payment_method,
        reference_number
    )
    SELECT f.numero,
           2,
           ar.account_receivable_id,
           CONCAT('PAG-SIM-', RIGHT(CONCAT('000000', f.numero), 6), '-02'),
           fechas.payment_date,
           CAST (f.total_amount - p.amount AS DECIMAL (18, 2)),
           CASE f.numero % 4 WHEN 0 THEN 'TRANSFER' WHEN 1 THEN 'CARD' WHEN 2 THEN 'CASH' ELSE 'CHECK' END,
           CONCAT('REF-SIM-', RIGHT(CONCAT('000000', f.numero), 6), '-02')
    FROM   #facturas AS f
           INNER JOIN
           finance.accounts_receivable AS ar
           ON ar.sales_invoice_id = f.sales_invoice_id
           INNER JOIN
           #pagos AS p
           ON p.numero = f.numero
              AND p.numero_abono = 1
           CROSS APPLY (SELECT DATEADD(DAY, 15 + (f.numero % 10), f.invoice_date) AS payment_date) AS fechas
    WHERE  f.tipo_pago = 'PAID'
           AND f.numero % 3 = 0
           AND fechas.payment_date <= @fechaCorte
           AND fechas.payment_date >= p.payment_date;
    IF EXISTS (SELECT 1
               FROM   #pagos
               WHERE  amount <= 0)
        THROW 52004, 'Existen pagos con importes invalidos.', 1;
    IF EXISTS (SELECT 1
               FROM   #pagos AS p
                      INNER JOIN
                      finance.accounts_receivable AS ar
                      ON ar.account_receivable_id = p.account_receivable_id
                      INNER JOIN
                      sales.sales_invoices AS si
                      ON si.sales_invoice_id = ar.sales_invoice_id
               WHERE  p.payment_date < si.invoice_date
                      OR p.payment_date > @fechaCorte)
        THROW 52005, 'Existen pagos fuera del periodo permitido.', 1;
    IF EXISTS (SELECT   1
               FROM     #pagos AS p
                        INNER JOIN
                        finance.accounts_receivable AS ar
                        ON ar.account_receivable_id = p.account_receivable_id
               GROUP BY p.account_receivable_id, ar.original_amount
               HAVING   SUM(p.amount) > ar.original_amount)
        THROW 52006, 'Los pagos superan el importe de alguna factura.', 1;
    INSERT INTO finance.customer_payments (
        account_receivable_id,
        payment_number,
        payment_date,
        amount,
        payment_method,
        reference_number,
        notes,
        created_at,
        created_by
    )
    SELECT account_receivable_id,
           payment_number,
           payment_date,
           amount,
           payment_method,
           reference_number,
           N'Pago de cliente de datos sintéticos.',
           payment_date,
           @admin
    FROM   #pagos;
    WITH Totales
    AS   (SELECT   ar.account_receivable_id,
                   ar.original_amount,
                   COALESCE (SUM(cp.amount), 0) AS total_pagado,
                   MAX(cp.payment_date) AS ultima_fecha_pago
          FROM     finance.accounts_receivable AS ar
                   LEFT OUTER JOIN
                   finance.customer_payments AS cp
                   ON cp.account_receivable_id = ar.account_receivable_id
          GROUP BY ar.account_receivable_id, ar.original_amount)
    UPDATE ar
    SET    outstanding_balance = t.original_amount - t.total_pagado,
           status              = CASE WHEN t.total_pagado = 0 THEN 'PENDING' WHEN t.total_pagado = t.original_amount THEN 'PAID' ELSE 'PARTIALLY_PAID' END,
           updated_at          = COALESCE (t.ultima_fecha_pago, ar.created_at),
           updated_by          = @admin
    FROM   finance.accounts_receivable AS ar
           INNER JOIN
           Totales AS t
           ON t.account_receivable_id = ar.account_receivable_id;
    IF EXISTS (SELECT 1
               FROM   finance.accounts_receivable
               WHERE  outstanding_balance < 0
                      OR outstanding_balance > original_amount
                      OR (status = 'PAID'
                          AND outstanding_balance <> 0)
                      OR (status = 'PENDING'
                          AND outstanding_balance <> original_amount)
                      OR (status = 'PARTIALLY_PAID'
                          AND (outstanding_balance <= 0
                               OR outstanding_balance >= original_amount)))
        THROW 52007, 'Existen cuentas por cobrar inconsistentes.', 1;
    IF (SELECT COUNT(*)
        FROM   finance.accounts_receivable) <> 417
        THROW 52008, 'La cantidad de cuentas por cobrar es incorrecta.', 1;
    IF EXISTS (SELECT 1
               FROM   finance.accounts_receivable AS ar
                      INNER JOIN
                      sales.sales_invoices AS si
                      ON si.sales_invoice_id = ar.sales_invoice_id
               WHERE  ar.customer_id <> si.customer_id
                      OR ar.original_amount <> si.total_amount
                      OR ar.due_date <> si.due_date)
        THROW 52009, 'Las cuentas por cobrar no coinciden con las facturas.', 1;
    IF EXISTS (SELECT 1
               FROM   finance.accounts_receivable AS ar
                      LEFT OUTER JOIN
                      (SELECT   account_receivable_id,
                                SUM(amount) AS total_pagado
                       FROM     finance.customer_payments
                       GROUP BY account_receivable_id) AS p
                      ON p.account_receivable_id = ar.account_receivable_id
               WHERE  ar.outstanding_balance <> ar.original_amount - COALESCE (p.total_pagado, 0))
        THROW 52010, 'Los saldos no coinciden con los pagos registrados.', 1;
    COMMIT TRANSACTION;
    DROP TABLE #pagos;
    DROP TABLE #facturas;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    IF OBJECT_ID('tempdb..#pagos') IS NOT NULL
        DROP TABLE #pagos;
    IF OBJECT_ID('tempdb..#facturas') IS NOT NULL
        DROP TABLE #facturas;
    THROW;
END CATCH

SELECT   status,
         COUNT(*) AS cuentas,
         SUM(original_amount) AS monto_original,
         SUM(outstanding_balance) AS saldo_pendiente
FROM     finance.accounts_receivable
GROUP BY status
ORDER BY status;

SELECT   payment_method,
         COUNT(*) AS cantidad_pagos,
         SUM(amount) AS total_cobrado
FROM     finance.customer_payments
GROUP BY payment_method
ORDER BY payment_method;

SELECT COUNT(*) AS total_cuentas,
       SUM(original_amount) AS total_facturado,
       SUM(original_amount - outstanding_balance) AS total_cobrado,
       SUM(outstanding_balance) AS total_pendiente
FROM   finance.accounts_receivable;

SELECT COUNT(*) AS pagos_futuros
FROM   finance.customer_payments
WHERE  payment_date > '2026-10-31T23:59:59.997';

SELECT COUNT(*) AS cuentas_inconsistentes
FROM   finance.accounts_receivable AS ar
       LEFT OUTER JOIN
       (SELECT   account_receivable_id,
                 SUM(amount) AS total_pagado
        FROM     finance.customer_payments
        GROUP BY account_receivable_id) AS p
       ON p.account_receivable_id = ar.account_receivable_id
WHERE  ar.outstanding_balance <> ar.original_amount - COALESCE (p.total_pagado, 0);