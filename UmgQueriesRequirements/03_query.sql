-- Calcular la rentabilidad bruta (Monto Venta - Costo de Ventas) acumulada agrupada por categoría
-- y línea de productos en el trimestre actual.


DECLARE @inicio_trimestre DATE =
    DATEFROMPARTS(
        YEAR(GETDATE()),
        ((DATEPART(QUARTER, GETDATE()) - 1) * 3) + 1,
        1
    );

DECLARE @fin_trimestre DATE =
    DATEADD(MONTH, 3, @inicio_trimestre);

SELECT
    c.name AS categoria,
    pl.name AS linea_producto,
    SUM(sid.quantity) AS cantidad_vendida,
    CAST(SUM(sid.subtotal - sid.discount_amount) AS DECIMAL(18,2)) AS monto_venta,
    CAST(SUM(sid.quantity * sid.unit_cost) AS DECIMAL(18,2)) AS costo_ventas,
    CAST(
        SUM(
            (sid.subtotal - sid.discount_amount)
            - (sid.quantity * sid.unit_cost)
        ) AS DECIMAL(18,2)
    ) AS rentabilidad_bruta,
    CAST(
        CASE
            WHEN SUM(sid.subtotal - sid.discount_amount) = 0 THEN 0
            ELSE
                SUM(
                    (sid.subtotal - sid.discount_amount)
                    - (sid.quantity * sid.unit_cost)
                ) * 100.0
                / SUM(sid.subtotal - sid.discount_amount)
        END
        AS DECIMAL(10,2)
    ) AS margen_bruto_porcentaje
FROM sales.sales_invoices AS si
INNER JOIN sales.sales_invoice_details AS sid
    ON sid.sales_invoice_id = si.sales_invoice_id
INNER JOIN catalog.products AS p
    ON p.product_id = sid.product_id
INNER JOIN catalog.product_lines AS pl
    ON pl.product_line_id = p.product_line_id
INNER JOIN catalog.categories AS c
    ON c.category_id = pl.category_id
WHERE si.status = 'ISSUED'
  AND si.invoice_date >= @inicio_trimestre
  AND si.invoice_date < @fin_trimestre
GROUP BY
    c.category_id,
    c.name,
    pl.product_line_id,
    pl.name
ORDER BY
    rentabilidad_bruta DESC,
    c.name,
    pl.name;
