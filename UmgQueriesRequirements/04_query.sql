-- Mostrar los clientes morosos con facturas que superen los 30 días de vencimiento, incluyendo el
-- saldo adeudado y el nombre del vendedor asignado.

SELECT
    c.customer_code AS codigo_cliente,
    c.business_name AS cliente,
    CONCAT(si.invoice_series, '-', si.invoice_number) AS numero_factura,
    si.invoice_date AS fecha_factura,
    ar.due_date AS fecha_vencimiento,
    DATEDIFF(DAY, ar.due_date, CAST(GETDATE() AS DATE)) AS dias_mora,
    ar.original_amount AS monto_original,
    ar.outstanding_balance AS saldo_adeudado,
    ar.status AS estado_cuenta,
    sp.employee_code AS codigo_vendedor,
    u.username AS vendedor_asignado
FROM finance.accounts_receivable AS ar
INNER JOIN sales.sales_invoices AS si
    ON si.sales_invoice_id = ar.sales_invoice_id
INNER JOIN sales.customers AS c
    ON c.customer_id = ar.customer_id
LEFT JOIN sales.salespersons AS sp
    ON sp.salesperson_id = c.salesperson_id
LEFT JOIN security.users AS u
    ON u.user_id = sp.user_id
WHERE ar.outstanding_balance > 0
  AND ar.status IN ('PENDING', 'PARTIALLY_PAID')
  AND si.status = 'ISSUED'
  AND ar.due_date < DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
ORDER BY
    dias_mora DESC,
    ar.outstanding_balance DESC,
    c.business_name ASC;
