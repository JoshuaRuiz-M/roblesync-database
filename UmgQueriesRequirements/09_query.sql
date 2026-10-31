
-- Calcular el tiempo promedio de rotación de inventario (en días) para cada categoría de productos.

DECLARE @fecha_inicio DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
DECLARE @fecha_fin DATE = CAST(GETDATE() AS DATE);

WITH categorias_productos AS (
    SELECT
        p.product_id,
        c.category_id,
        c.name AS categoria
    FROM catalog.products AS p
    INNER JOIN catalog.product_lines AS pl
        ON pl.product_line_id = p.product_line_id
    INNER JOIN catalog.categories AS c
        ON c.category_id = pl.category_id
),
movimientos AS (
    SELECT
        im.product_id,
        SUM(
            CASE
                WHEN im.movement_date < @fecha_inicio
                THEN im.total_cost
                ELSE 0
            END
        ) AS valor_inicial,
        SUM(im.total_cost) AS valor_final
    FROM inventory.inventory_movements AS im
    WHERE im.movement_date < DATEADD(DAY, 1, @fecha_fin)
    GROUP BY im.product_id
),
inventario_categoria AS (
    SELECT
        cp.category_id,
        cp.categoria,
        SUM(COALESCE(m.valor_inicial, 0)) AS inventario_inicial,
        SUM(COALESCE(m.valor_final, 0)) AS inventario_final
    FROM categorias_productos AS cp
    LEFT JOIN movimientos AS m
        ON m.product_id = cp.product_id
    GROUP BY
        cp.category_id,
        cp.categoria
),
costo_ventas_categoria AS (
    SELECT
        cp.category_id,
        SUM(sid.quantity * sid.unit_cost) AS costo_ventas
    FROM sales.sales_invoices AS si
    INNER JOIN sales.sales_invoice_details AS sid
        ON sid.sales_invoice_id = si.sales_invoice_id
    INNER JOIN categorias_productos AS cp
        ON cp.product_id = sid.product_id
    WHERE si.status = 'ISSUED'
      AND si.invoice_date >= @fecha_inicio
      AND si.invoice_date < DATEADD(DAY, 1, @fecha_fin)
    GROUP BY cp.category_id
)
SELECT
    ic.categoria,
    CAST(ic.inventario_inicial AS DECIMAL(18,2)) AS inventario_inicial_Q,
    CAST(ic.inventario_final AS DECIMAL(18,2)) AS inventario_final_Q,
    CAST(
        (ic.inventario_inicial + ic.inventario_final) / 2.0
        AS DECIMAL(18,2)
    ) AS inventario_promedio_Q,
    CAST(COALESCE(cv.costo_ventas, 0) AS DECIMAL(18,2)) AS costo_ventas_Q,
    CAST(
        CASE
            WHEN COALESCE(cv.costo_ventas, 0) = 0 THEN NULL
            ELSE
                (
                    (ic.inventario_inicial + ic.inventario_final) / 2.0
                ) * (DATEDIFF(DAY, @fecha_inicio, @fecha_fin) + 1)
                / cv.costo_ventas
        END
        AS DECIMAL(18,2)
    ) AS rotacion_promedio_dias
FROM inventario_categoria AS ic
LEFT JOIN costo_ventas_categoria AS cv
    ON cv.category_id = ic.category_id
ORDER BY
    rotacion_promedio_dias ASC,
    ic.categoria ASC;
