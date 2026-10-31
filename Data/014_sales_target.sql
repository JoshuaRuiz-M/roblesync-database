SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 52200, 'No existe el usuario administrador.', 1;
    IF EXISTS (SELECT 1
               FROM   sales.sales_targets)
        THROW 52201, 'La tabla de metas de ventas debe estar vacia.', 1;
    IF NOT EXISTS (SELECT 1
                   FROM   sales.salespersons)
        THROW 52202, 'No existen vendedores registrados.', 1;
    CREATE TABLE #meses (
        target_year  SMALLINT NOT NULL,
        target_month TINYINT  NOT NULL,
        PRIMARY KEY (target_year, target_month)
    );
    INSERT  INTO #meses (
        target_year,
        target_month
    )
    VALUES              (2026, 3),
                        (2026, 4),
                        (2026, 5),
                        (2026, 6),
                        (2026, 7),
                        (2026, 8),
                        (2026, 9),
                        (2026, 10);
    CREATE TABLE #metas (
        salesperson_id INT             NOT NULL,
        target_year    SMALLINT        NOT NULL,
        target_month   TINYINT         NOT NULL,
        actual_sales   DECIMAL (18, 2) NOT NULL,
        target_amount  DECIMAL (18, 2) NOT NULL,
        PRIMARY KEY (salesperson_id, target_year, target_month)
    );
    WITH VentasMensuales
    AS   (SELECT   salesperson_id,
                   YEAR(invoice_date) AS target_year,
                   MONTH(invoice_date) AS target_month,
                   SUM(total_amount) AS actual_sales
          FROM     sales.sales_invoices
          WHERE    status = 'ISSUED'
                   AND invoice_date >= '2026-03-01'
                   AND invoice_date < '2026-11-01'
          GROUP BY salesperson_id, YEAR(invoice_date), MONTH(invoice_date)),
         PromediosVendedor
    AS   (SELECT   salesperson_id,
                   CAST (SUM(actual_sales) / 8.0 AS DECIMAL (18, 2)) AS promedio_mensual
          FROM     VentasMensuales
          GROUP BY salesperson_id)
    INSERT INTO #metas (
        salesperson_id,
        target_year,
        target_month,
        actual_sales,
        target_amount
    )
    SELECT sp.salesperson_id,
           m.target_year,
           m.target_month,
           COALESCE (vm.actual_sales, 0),
           CAST (ROUND(CASE WHEN COALESCE (vm.actual_sales, 0) > 0 THEN vm.actual_sales ELSE COALESCE (pv.promedio_mensual, 10000) END * CASE WHEN m.target_month = 3 THEN 0.90 WHEN m.target_month = 4 THEN 1.05 WHEN m.target_month = 5 THEN 0.95 WHEN m.target_month = 6 THEN 1.10 WHEN m.target_month = 7 THEN 0.92 WHEN m.target_month = 8 THEN 1.08 WHEN m.target_month = 9 THEN 0.97 ELSE 1.12 END, 2) AS DECIMAL (18, 2))
    FROM   sales.salespersons AS sp
           CROSS JOIN #meses AS m
           LEFT OUTER JOIN
           VentasMensuales AS vm
           ON vm.salesperson_id = sp.salesperson_id
              AND vm.target_year = m.target_year
              AND vm.target_month = m.target_month
           LEFT OUTER JOIN
           PromediosVendedor AS pv
           ON pv.salesperson_id = sp.salesperson_id;
    IF EXISTS (SELECT 1
               FROM   #metas
               WHERE  target_amount <= 0)
        THROW 52203, 'Existen metas de ventas con importes invalidos.', 1;
    INSERT INTO sales.sales_targets (
        salesperson_id,
        target_year,
        target_month,
        target_amount,
        created_at,
        created_by
    )
    SELECT salesperson_id,
           target_year,
           target_month,
           target_amount,
           '2026-03-01',
           @admin
    FROM   #metas;
    IF (SELECT COUNT(*)
        FROM   sales.sales_targets) <> (SELECT COUNT(*)
                                        FROM   sales.salespersons) * 8
        THROW 52204, 'No se generaron todas las metas mensuales.', 1;
    IF EXISTS (SELECT   1
               FROM     sales.sales_targets
               GROUP BY salesperson_id, target_year, target_month
               HAVING   COUNT(*) > 1)
        THROW 52205, 'Existen metas duplicadas.', 1;
    COMMIT TRANSACTION;
    DROP TABLE #metas;
    DROP TABLE #meses;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    IF OBJECT_ID('tempdb..#metas') IS NOT NULL
        DROP TABLE #metas;
    IF OBJECT_ID('tempdb..#meses') IS NOT NULL
        DROP TABLE #meses;
    THROW;
END CATCH

SELECT COUNT(*) AS total_metas,
       COUNT(DISTINCT salesperson_id) AS vendedores,
       MIN(target_month) AS primer_mes,
       MAX(target_month) AS ultimo_mes,
       SUM(target_amount) AS meta_total
FROM   sales.sales_targets;

SELECT   target_year,
         target_month,
         COUNT(*) AS vendedores,
         SUM(target_amount) AS meta_mensual
FROM     sales.sales_targets
GROUP BY target_year, target_month
ORDER BY target_year, target_month;

WITH     VentasMensuales
AS       (SELECT   salesperson_id,
                   YEAR(invoice_date) AS target_year,
                   MONTH(invoice_date) AS target_month,
                   SUM(total_amount) AS total_vendido
          FROM     sales.sales_invoices
          WHERE    status = 'ISSUED'
          GROUP BY salesperson_id, YEAR(invoice_date), MONTH(invoice_date))
SELECT   st.salesperson_id,
         st.target_year,
         st.target_month,
         st.target_amount AS meta,
         COALESCE (vm.total_vendido, 0) AS ventas_reales,
         CAST (ROUND(COALESCE (vm.total_vendido, 0) * 100.0 / NULLIF (st.target_amount, 0), 2) AS DECIMAL (10, 2)) AS cumplimiento_porcentaje,
         CASE WHEN COALESCE (vm.total_vendido, 0) >= st.target_amount THEN 'CUMPLIDA' ELSE 'NO CUMPLIDA' END AS resultado
FROM     sales.sales_targets AS st
         LEFT OUTER JOIN
         VentasMensuales AS vm
         ON vm.salesperson_id = st.salesperson_id
            AND vm.target_year = st.target_year
            AND vm.target_month = st.target_month
ORDER BY st.salesperson_id, st.target_year, st.target_month;