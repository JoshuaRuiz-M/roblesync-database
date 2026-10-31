
-- Obtener un reporte de sugerencia de compras listando los productos cuyo stock global sea menor
-- o igual al punto de reorden, sugiriendo la cantidad a pedir (Stock Máximo - Stock Actual) y el
-- proveedor habitual.

WITH stock_global AS (
    SELECT
        product_id,
        SUM(quantity_on_hand) AS stock_actual
    FROM inventory.warehouse_stock
    GROUP BY product_id
)
SELECT
    p.product_id,
    p.sku AS codigo_producto,
    p.name AS producto,
    COALESCE(sg.stock_actual, 0) AS stock_actual,
    p.reorder_point AS punto_reorden,
    p.maximum_stock AS stock_maximo,
    p.maximum_stock - COALESCE(sg.stock_actual, 0) AS cantidad_sugerida,
    s.business_name AS proveedor_habitual
FROM catalog.products AS p
LEFT JOIN stock_global AS sg
    ON sg.product_id = p.product_id
LEFT JOIN purchasing.product_suppliers AS ps
    ON ps.product_id = p.product_id
    AND ps.is_preferred = 1
    AND ps.is_active = 1
LEFT JOIN purchasing.suppliers AS s
    ON s.supplier_id = ps.supplier_id
    AND s.is_active = 1
WHERE p.is_active = 1
  AND COALESCE(sg.stock_actual, 0) <= p.reorder_point
  AND p.maximum_stock > COALESCE(sg.stock_actual, 0)
ORDER BY
    cantidad_sugerida DESC,
    p.name ASC;
