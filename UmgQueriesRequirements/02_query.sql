
-- Obtener la lista de productos próximos a vencer en los siguientes 30 días, indicando número de
-- lote, cantidad en existencia y bodega donde se ubican.

SELECT
    p.product_id,
    p.name AS producto,
    pb.batch_number AS numero_lote,
    pb.expiration_date AS fecha_vencimiento,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), pb.expiration_date) AS dias_para_vencer,
    bs.quantity_on_hand AS cantidad_existencia,
    w.code AS codigo_bodega,
    w.name AS bodega
FROM inventory.product_batches AS pb
INNER JOIN catalog.products AS p
    ON p.product_id = pb.product_id
INNER JOIN inventory.batch_stock AS bs
    ON bs.batch_id = pb.batch_id
    AND bs.product_id = pb.product_id
INNER JOIN inventory.warehouses AS w
    ON w.warehouse_id = bs.warehouse_id
WHERE pb.expiration_date >= CAST(GETDATE() AS DATE)
  AND pb.expiration_date <= DATEADD(DAY, 30, CAST(GETDATE() AS DATE))
  AND bs.quantity_on_hand > 0
  AND pb.is_active = 1
ORDER BY
    pb.expiration_date ASC,
    p.name ASC,
    w.name ASC;
