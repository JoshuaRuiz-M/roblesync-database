
-- Mostrar la consulta de Kardex de un producto en un rango de fechas, detallando saldo inicial,
-- entradas, salidas y saldo final en cantidad y valor monetario.

DECLARE @product_id INT = 1;
DECLARE @warehouse_id INT = 1;
DECLARE @fecha_inicio DATE = '2026-01-01';
DECLARE @fecha_fin DATE = '2026-10-31';

WITH movimientos AS (
    SELECT
        im.inventory_movement_id,
        im.movement_date,
        im.movement_type,
        im.quantity,
        im.total_cost
    FROM inventory.inventory_movements im
    WHERE im.product_id = @product_id
      AND im.warehouse_id = @warehouse_id
      AND im.movement_date < DATEADD(DAY, 1, @fecha_fin)
),
saldo_inicial AS (
    SELECT
        COALESCE(SUM(quantity), 0) AS cantidad,
        COALESCE(SUM(total_cost), 0) AS valor
    FROM movimientos
    WHERE movement_date < @fecha_inicio
),
movimientos_periodo AS (
    SELECT
        inventory_movement_id,
        movement_date,
        movement_type,
        CASE WHEN quantity > 0 THEN quantity ELSE 0 END AS entrada_cantidad,
        CASE WHEN total_cost > 0 THEN total_cost ELSE 0 END AS entrada_valor,
        CASE WHEN quantity < 0 THEN -quantity ELSE 0 END AS salida_cantidad,
        CASE WHEN total_cost < 0 THEN -total_cost ELSE 0 END AS salida_valor
    FROM movimientos
    WHERE movement_date >= @fecha_inicio
),
kardex AS (
    SELECT
        0 AS orden,
        CAST(NULL AS INT) AS movimiento_id,
        CAST(@fecha_inicio AS DATETIME2(3)) AS fecha,
        CAST('SALDO INICIAL' AS NVARCHAR(30)) AS movimiento,
        CAST(0 AS DECIMAL(18,3)) AS entrada_cantidad,
        CAST(0 AS DECIMAL(19,4)) AS entrada_valor,
        CAST(0 AS DECIMAL(18,3)) AS salida_cantidad,
        CAST(0 AS DECIMAL(19,4)) AS salida_valor,
        si.cantidad AS saldo_cantidad,
        si.valor AS saldo_valor
    FROM saldo_inicial si

    UNION ALL

    SELECT
        1,
        mp.inventory_movement_id,
        mp.movement_date,
        CAST(mp.movement_type AS NVARCHAR(30)),
        mp.entrada_cantidad,
        mp.entrada_valor,
        mp.salida_cantidad,
        mp.salida_valor,
        si.cantidad
            + SUM(mp.entrada_cantidad - mp.salida_cantidad)
                OVER (
                    ORDER BY mp.movement_date, mp.inventory_movement_id
                    ROWS UNBOUNDED PRECEDING
                ),
        si.valor
            + SUM(mp.entrada_valor - mp.salida_valor)
                OVER (
                    ORDER BY mp.movement_date, mp.inventory_movement_id
                    ROWS UNBOUNDED PRECEDING
                )
    FROM movimientos_periodo mp
    CROSS JOIN saldo_inicial si
),
resultado AS (
    SELECT * FROM kardex

    UNION ALL

    SELECT
        2,
        NULL,
        CAST(DATEADD(DAY, 1, @fecha_fin) AS DATETIME2(3)),
        CAST('SALDO FINAL' AS NVARCHAR(30)),
        SUM(CASE WHEN orden = 1 THEN entrada_cantidad ELSE 0 END),
        SUM(CASE WHEN orden = 1 THEN entrada_valor ELSE 0 END),
        SUM(CASE WHEN orden = 1 THEN salida_cantidad ELSE 0 END),
        SUM(CASE WHEN orden = 1 THEN salida_valor ELSE 0 END),
        SUM(CASE WHEN orden = 0 THEN saldo_cantidad ELSE 0 END)
            + SUM(entrada_cantidad - salida_cantidad),
        SUM(CASE WHEN orden = 0 THEN saldo_valor ELSE 0 END)
            + SUM(entrada_valor - salida_valor)
    FROM kardex
)
SELECT
    fecha,
    movimiento,
    entrada_cantidad,
    entrada_valor,
    salida_cantidad,
    salida_valor,
    saldo_cantidad,
    saldo_valor
FROM resultado
ORDER BY orden, fecha, movimiento_id;