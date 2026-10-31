
-- Listar las facturas de venta que fueron anuladas en el mes, detallando el motivo de anulación,
-- usuario que anuló y el monto de la transacción.

SELECT
    si.sales_invoice_id,
    CONCAT(si.invoice_series, '-', si.invoice_number) AS numero_factura,
    c.business_name AS cliente,
    si.invoice_date AS fecha_factura,
    si.cancelled_at AS fecha_anulacion,
    si.cancellation_reason AS motivo_anulacion,
    u.username AS usuario_anulo,
    CAST(si.total_amount AS DECIMAL(18,2)) AS monto_transaccion_Q,
    si.status AS estado_factura
FROM sales.sales_invoices AS si
INNER JOIN sales.customers AS c
    ON c.customer_id = si.customer_id
LEFT JOIN security.users AS u
    ON u.user_id = si.cancelled_by
WHERE si.status = 'CANCELLED'
  AND si.cancelled_at >= DATEFROMPARTS(
      YEAR(GETDATE()),
      MONTH(GETDATE()),
      1
  )
  AND si.cancelled_at < DATEADD(
      MONTH,
      1,
      DATEFROMPARTS(
          YEAR(GETDATE()),
          MONTH(GETDATE()),
          1
      )
  )
ORDER BY
    si.cancelled_at DESC,
    si.sales_invoice_id DESC;
