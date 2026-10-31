SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    DECLARE @fecha AS DATETIME2 (3) = '2025-10-15T09:00:00';
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51200, 'No existe el usuario administrador.', 1;
    IF (SELECT COUNT(*)
        FROM   catalog.products) <> 200
        THROW 51201, 'El catalogo debe contener exactamente 200 productos.', 1;
    DECLARE @bodegas TABLE (
        code        NVARCHAR (50)  PRIMARY KEY,
        name        NVARCHAR (150),
        description NVARCHAR (500),
        address     NVARCHAR (300));
    INSERT  INTO @bodegas (
        code,
        name,
        description,
        address
    )
    VALUES                ('BOD-CEN', N'Bodega Central Guatemala', N'Centro principal de almacenamiento y distribución. Atiende la región metropolitana y coordina el abastecimiento de las bodegas regionales.', N'Zona 12, Ciudad de Guatemala, Guatemala'),
                          ('BOD-ORI', N'Bodega Regional Oriente', N'Centro regional de almacenamiento y distribución para clientes de Chiquimula, Zacapa y departamentos cercanos.', N'Zona 1, Chiquimula, Chiquimula'),
                          ('BOD-OCC', N'Bodega Regional Occidente', N'Centro regional de almacenamiento y distribución para clientes de Quetzaltenango y departamentos del occidente.', N'Zona 3, Quetzaltenango, Quetzaltenango');
    INSERT INTO inventory.warehouses (
        code,
        name,
        description,
        address,
        is_active,
        created_at,
        created_by
    )
    SELECT b.code,
           b.name,
           b.description,
           b.address,
           1,
           @fecha,
           @admin
    FROM   @bodegas AS b
    WHERE  NOT EXISTS (SELECT 1
                       FROM   inventory.warehouses AS w
                       WHERE  w.code = b.code);
    IF (SELECT COUNT(*)
        FROM   inventory.warehouses
        WHERE  code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC')) <> 3
        THROW 51202, 'No se encontraron las tres bodegas requeridas.', 1;
    INSERT INTO inventory.warehouse_stock (
        warehouse_id,
        product_id,
        quantity_on_hand,
        quantity_reserved,
        updated_at,
        updated_by
    )
    SELECT w.warehouse_id,
           p.product_id,
           CAST (0 AS DECIMAL (18, 3)),
           CAST (0 AS DECIMAL (18, 3)),
           @fecha,
           @admin
    FROM   inventory.warehouses AS w
           CROSS JOIN catalog.products AS p
    WHERE  w.code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC')
           AND NOT EXISTS (SELECT 1
                           FROM   inventory.warehouse_stock AS ws
                           WHERE  ws.warehouse_id = w.warehouse_id
                                  AND ws.product_id = p.product_id);
    IF (SELECT COUNT(*)
        FROM   inventory.warehouse_stock AS ws
               INNER JOIN
               inventory.warehouses AS w
               ON w.warehouse_id = ws.warehouse_id
        WHERE  w.code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC')) <> 600
        THROW 51203, 'Deben existir 600 registros de existencias.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT   w.warehouse_id,
         w.code,
         w.name,
         w.address,
         COUNT(ws.warehouse_stock_id) AS productos_registrados,
         SUM(ws.quantity_on_hand) AS existencias,
         SUM(ws.quantity_reserved) AS unidades_reservadas
FROM     inventory.warehouses AS w
         LEFT OUTER JOIN
         inventory.warehouse_stock AS ws
         ON ws.warehouse_id = w.warehouse_id
WHERE    w.code IN ('BOD-CEN', 'BOD-ORI', 'BOD-OCC')
GROUP BY w.warehouse_id, w.code, w.name, w.address
ORDER BY w.code;