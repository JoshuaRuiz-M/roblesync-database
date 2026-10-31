
-- Consultar las ventas totales (en Quetzales) desglosadas por vendedor y comparar el cumpli-
-- miento contra la meta de ventas asignada.


DECLARE @anio INT = YEAR(GETDATE());
DECLARE @mes INT = MONTH(GETDATE());

WITH ventas_vendedor AS (
    SELECT
        si.salesperson_id,
        SUM(si.total_amount) AS ventas_totales
    FROM sales.sales_invoices AS si
    WHERE si.status = 'ISSUED'
      AND si.invoice_date >= DATEFROMPARTS(@anio, 1, 1)
      AND si.invoice_date < DATEADD(MONTH, 1, DATEFROMPARTS(@anio, @mes, 1))
    GROUP BY
        si.salesperson_id
),
metas_vendedor AS (
    SELECT
        st.salesperson_id,
        SUM(st.target_amount) AS meta_total
    FROM sales.sales_targets AS st
    WHERE st.target_year = @anio
      AND st.target_month BETWEEN 1 AND @mes
    GROUP BY
        st.salesperson_id
)
SELECT
    sp.salesperson_id,
    sp.employee_code AS codigo_vendedor,
    u.username AS vendedor,
    @anio AS anio,
    CAST(COALESCE(mv.meta_total, 0) AS DECIMAL(18,2)) AS meta_ventas_Q,
    CAST(COALESCE(vv.ventas_totales, 0) AS DECIMAL(18,2)) AS ventas_totales_Q,
    CAST(
        COALESCE(vv.ventas_totales, 0)
        - COALESCE(mv.meta_total, 0)
        AS DECIMAL(18,2)
    ) AS diferencia_Q,
    CAST(
        CASE
            WHEN COALESCE(mv.meta_total, 0) = 0 THEN NULL
            ELSE COALESCE(vv.ventas_totales, 0) * 100.0
                 / mv.meta_total
        END
        AS DECIMAL(10,2)
    ) AS porcentaje_cumplimiento,
    CASE
        WHEN COALESCE(mv.meta_total, 0) = 0 THEN 'SIN META'
        WHEN COALESCE(vv.ventas_totales, 0) >= mv.meta_total THEN 'META CUMPLIDA'
        ELSE 'META PENDIENTE'
    END AS estado_meta
FROM sales.salespersons AS sp
INNER JOIN security.users AS u
    ON u.user_id = sp.user_id
LEFT JOIN ventas_vendedor AS vv
    ON vv.salesperson_id = sp.salesperson_id
LEFT JOIN metas_vendedor AS mv
    ON mv.salesperson_id = sp.salesperson_id
ORDER BY
    porcentaje_cumplimiento DESC,
    ventas_totales_Q DESC;
