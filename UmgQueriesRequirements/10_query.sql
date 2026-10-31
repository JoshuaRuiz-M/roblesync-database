
-- Obtener el reporte consolidado de transferencias de inventario entre bodegas que se mantengan
-- en estado "En Tránsito" sin confirmación de recepción por más de 24 horas.

WITH detalle_transferencias AS (
    SELECT
        warehouse_transfer_id,
        COUNT(*) AS total_productos,
        SUM(quantity) AS cantidad_total,
        SUM(quantity * unit_cost) AS valor_total
    FROM logistics.warehouse_transfer_details
    GROUP BY warehouse_transfer_id
)
SELECT
    wt.warehouse_transfer_id,
    wt.transfer_number AS numero_transferencia,
    wo.name AS bodega_origen,
    wd.name AS bodega_destino,
    wt.transfer_date AS fecha_transferencia,
    wt.dispatched_at AS fecha_despacho,
    DATEDIFF(HOUR, wt.dispatched_at, GETDATE()) AS horas_transcurridas,
    COALESCE(dt.total_productos, 0) AS total_productos,
    COALESCE(dt.cantidad_total, 0) AS cantidad_total_transferida,
    CAST(
        COALESCE(dt.valor_total, 0)
        AS DECIMAL(18,2)
    ) AS valor_total_Q,
    wt.status AS estado_transferencia,
    wt.notes AS observaciones
FROM logistics.warehouse_transfers AS wt
INNER JOIN inventory.warehouses AS wo
    ON wo.warehouse_id = wt.source_warehouse_id
INNER JOIN inventory.warehouses AS wd
    ON wd.warehouse_id = wt.destination_warehouse_id
LEFT JOIN detalle_transferencias AS dt
    ON dt.warehouse_transfer_id = wt.warehouse_transfer_id
WHERE wt.status = 'IN_TRANSIT'
  AND wt.received_at IS NULL
  AND wt.dispatched_at IS NOT NULL
  AND wt.dispatched_at < DATEADD(HOUR, -24, GETDATE())
ORDER BY
    wt.dispatched_at ASC,
    wt.transfer_number ASC;
