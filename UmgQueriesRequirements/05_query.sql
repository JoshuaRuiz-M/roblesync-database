-- Listar el Top 10 de productos más vendidos en unidades pero que hayan generado el menor
-- margen de utilidad para la empresa.

WITH ventas_productos AS (
    SELECT
        p.product_id,
        p.name AS producto,
        SUM(sid.quantity) AS unidades_vendidas,
        SUM(sid.subtotal - sid.discount_amount) AS monto_venta,
        SUM(sid.quantity * sid.unit_cost) AS costo_ventas
    FROM sales.sales_invoice_details AS sid
    INNER JOIN sales.sales_invoices AS si
        ON si.sales_invoice_id = sid.sales_invoice_id
    INNER JOIN catalog.products AS p
        ON p.product_id = sid.product_id
    WHERE si.status = 'ISSUED'
    GROUP BY
        p.product_id,
        p.name
),
top_ventas AS (
    SELECT TOP (10)
        product_id,
        producto,
        unidades_vendidas,
        monto_venta,
        costo_ventas
    FROM ventas_productos
    ORDER BY
        unidades_vendidas DESC,
        product_id
)
SELECT
    producto,
    unidades_vendidas,
    CAST(monto_venta AS DECIMAL(18,2)) AS monto_venta,
    CAST(costo_ventas AS DECIMAL(18,2)) AS costo_ventas,
    CAST(
        monto_venta - costo_ventas
        AS DECIMAL(18,2)
    ) AS utilidad_bruta,
    CAST(
        CASE
            WHEN monto_venta = 0 THEN 0
            ELSE (monto_venta - costo_ventas) * 100.0 / monto_venta
        END
        AS DECIMAL(10,2)
    ) AS margen_utilidad_porcentaje
FROM top_ventas
ORDER BY
    margen_utilidad_porcentaje ASC,
    unidades_vendidas DESC;
