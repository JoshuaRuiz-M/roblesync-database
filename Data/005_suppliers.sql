SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    DECLARE @fecha AS DATETIME2 (3) = '2025-10-15T09:00:00';
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51300, 'No existe el usuario administrador.', 1;
    IF (SELECT COUNT(*)
        FROM   catalog.products) <> 200
        THROW 51301, 'Se requieren exactamente 200 productos.', 1;
    IF EXISTS (SELECT 1
               FROM   purchasing.suppliers)
       OR EXISTS (SELECT 1
                  FROM   purchasing.product_suppliers)
        THROW 51302, 'Las tablas de proveedores deben estar vacias.', 1;
    DECLARE @proveedores TABLE (
        numero        INT             PRIMARY KEY,
        tax_id        NVARCHAR (20)  ,
        business_name NVARCHAR (200) ,
        address       NVARCHAR (300) ,
        credit_days   INT            ,
        credit_limit  DECIMAL (18, 2));
    INSERT  INTO @proveedores (
        numero,
        tax_id,
        business_name,
        address,
        credit_days,
        credit_limit
    )
    VALUES                    (1, 'SIM-NIT-001', N'Distribuidora Coca-Cola Guatemala', N'Ciudad de Guatemala', 30, 250000),
                              (2, 'SIM-NIT-002', N'Distribuidora Pepsi Guatemala', N'Ciudad de Guatemala', 30, 220000),
                              (3, 'SIM-NIT-003', N'Distribuidora de Bebidas Salvavidas', N'Ciudad de Guatemala', 15, 120000),
                              (4, 'SIM-NIT-004', N'Distribuidora de Bebidas Raptor', N'Ciudad de Guatemala', 30, 140000),
                              (5, 'SIM-NIT-005', N'Distribuidora de Alimentos Nestlé', N'Ciudad de Guatemala', 45, 300000),
                              (6, 'SIM-NIT-006', N'Distribuidora de Productos Malher', N'Ciudad de Guatemala', 30, 200000),
                              (7, 'SIM-NIT-007', N'Distribuidora de Productos Ducal', N'Ciudad de Guatemala', 30, 160000),
                              (8, 'SIM-NIT-008', N'Distribuidora de Alimentos La Costeña', N'Ciudad de Guatemala', 45, 180000),
                              (9, 'SIM-NIT-009', N'Distribuidora de Productos Bimbo', N'Ciudad de Guatemala', 15, 170000),
                              (10, 'SIM-NIT-010', N'Distribuidora de Productos Diana', N'Ciudad de Guatemala', 30, 150000),
                              (11, 'SIM-NIT-011', N'Distribuidora de Lácteos Dos Pinos', N'Ciudad de Guatemala', 15, 140000),
                              (12, 'SIM-NIT-012', N'Distribuidora de Higiene Colgate', N'Ciudad de Guatemala', 60, 240000),
                              (13, 'SIM-NIT-013', N'Comercializadora Metropolitana de Abarrotes', N'Zona 12, Ciudad de Guatemala', 30, 180000),
                              (14, 'SIM-NIT-014', N'Abastecedora Regional del Oriente', N'Chiquimula, Chiquimula', 15, 95000),
                              (15, 'SIM-NIT-015', N'Comercializadora Occidental de Consumo', N'Quetzaltenango, Quetzaltenango', 30, 110000),
                              (16, 'SIM-NIT-016', N'Importadora Centroamericana de Alimentos', N'Zona 4, Ciudad de Guatemala', 45, 260000),
                              (17, 'SIM-NIT-017', N'Suministros y Abarrotes del Valle', N'Villa Nueva, Guatemala', 30, 125000),
                              (18, 'SIM-NIT-018', N'Distribuciones Integrales del Altiplano', N'Totonicapán, Totonicapán', 30, 85000),
                              (19, 'SIM-NIT-019', N'Comercializadora Los Volcanes', N'Antigua Guatemala, Sacatepéquez', 15, 90000),
                              (20, 'SIM-NIT-020', N'Abastecimientos del Motagua', N'Zacapa, Zacapa', 30, 100000),
                              (21, 'SIM-NIT-021', N'Distribuidora de Consumo La Ceiba', N'Puerto Barrios, Izabal', 45, 115000),
                              (22, 'SIM-NIT-022', N'Productos de Limpieza del Sur', N'Escuintla, Escuintla', 60, 130000),
                              (23, 'SIM-NIT-023', N'Comercializadora de Víveres El Progreso', N'Guastatoya, El Progreso', 0, 0),
                              (24, 'SIM-NIT-024', N'Abastecedora de Tiendas del Norte', N'Cobán, Alta Verapaz', 0, 0),
                              (25, 'SIM-NIT-025', N'Distribuciones del Pacífico', N'Mazatenango, Suchitepéquez', 0, 0),
                              (26, 'SIM-NIT-026', N'Comercializadora Nueva Esperanza', N'Jutiapa, Jutiapa', 0, 0),
                              (27, 'SIM-NIT-027', N'Suministros Comerciales La Unión', N'Jalapa, Jalapa', 0, 0),
                              (28, 'SIM-NIT-028', N'Distribuidora de Abarrotes El Trébol', N'Zona 11, Ciudad de Guatemala', 60, 80000),
                              (29, 'SIM-NIT-029', N'Importadora de Productos de Consumo', N'Zona 9, Ciudad de Guatemala', 60, 190000),
                              (30, 'SIM-NIT-030', N'Comercializadora Mayorista del Centro', N'Mixco, Guatemala', 45, 145000);
    IF (SELECT COUNT(*)
        FROM   @proveedores) <> 30
        THROW 51303, 'Deben existir 30 proveedores.', 1;
    INSERT INTO purchasing.suppliers (
        tax_id,
        business_name,
        contact_name,
        phone,
        email,
        address,
        credit_days,
        credit_limit,
        is_active,
        created_at,
        created_by
    )
    SELECT tax_id,
           business_name,
           NULL,
           NULL,
           NULL,
           address,
           credit_days,
           credit_limit,
           1,
           @fecha,
           @admin
    FROM   @proveedores;
    DECLARE @marcas TABLE (
        brand_code         NVARCHAR (50) PRIMARY KEY,
        preferred_number   INT          ,
        alternative_number INT          );
    INSERT  INTO @marcas (
        brand_code,
        preferred_number,
        alternative_number
    )
    VALUES               ('COCA', 1, 13),
                         ('PEPSI', 2, 14),
                         ('FANTA', 1, 13),
                         ('SPRITE', 1, 13),
                         ('MIRINDA', 2, 14),
                         ('SEVENUP', 2, 14),
                         ('SALVAVIDAS', 3, 15),
                         ('RAPTOR', 4, 16),
                         ('NATURAS', 16, 17),
                         ('NESCAFE', 5, 16),
                         ('NESTLE', 5, 17),
                         ('MALHER', 6, 18),
                         ('DUCAL', 7, 19),
                         ('COSTENA', 8, 20),
                         ('BIMBO', 9, 21),
                         ('MARINELA', 9, 21),
                         ('GAMESA', 13, 22),
                         ('POZUELO', 15, 23),
                         ('DIANA', 10, 24),
                         ('TORTRIX', 10, 25),
                         ('RICA', 17, 26),
                         ('DOSPINOS', 11, 27),
                         ('COLGATE', 12, 28),
                         ('PROTEX', 12, 29),
                         ('ARIEL', 22, 30);
    IF EXISTS (SELECT 1
               FROM   catalog.products AS p
                      INNER JOIN
                      catalog.brands AS b
                      ON b.brand_id = p.brand_id
                      LEFT OUTER JOIN
                      @marcas AS m
                      ON m.brand_code = b.code
               WHERE  m.brand_code IS NULL)
        THROW 51304, 'Hay productos con marcas sin proveedor asignado.', 1;
    IF EXISTS (SELECT 1
               FROM   @marcas
               WHERE  preferred_number = alternative_number)
        THROW 51305, 'El proveedor alternativo debe ser diferente.', 1;
    IF EXISTS (SELECT 1
               FROM   @marcas AS m
                      LEFT OUTER JOIN
                      @proveedores AS p1
                      ON p1.numero = m.preferred_number
                      LEFT OUTER JOIN
                      @proveedores AS p2
                      ON p2.numero = m.alternative_number
               WHERE  p1.numero IS NULL
                      OR p2.numero IS NULL)
        THROW 51306, 'Existen proveedores no definidos.', 1;
    INSERT INTO purchasing.product_suppliers (
        product_id,
        supplier_id,
        is_preferred,
        is_active,
        created_at,
        created_by
    )
    SELECT p.product_id,
           s.supplier_id,
           1,
           1,
           @fecha,
           @admin
    FROM   catalog.products AS p
           INNER JOIN
           catalog.brands AS b
           ON b.brand_id = p.brand_id
           INNER JOIN
           @marcas AS m
           ON m.brand_code = b.code
           INNER JOIN
           @proveedores AS x
           ON x.numero = m.preferred_number
           INNER JOIN
           purchasing.suppliers AS s
           ON s.tax_id = x.tax_id;
    INSERT INTO purchasing.product_suppliers (
        product_id,
        supplier_id,
        is_preferred,
        is_active,
        created_at,
        created_by
    )
    SELECT p.product_id,
           s.supplier_id,
           0,
           1,
           @fecha,
           @admin
    FROM   catalog.products AS p
           INNER JOIN
           catalog.brands AS b
           ON b.brand_id = p.brand_id
           INNER JOIN
           @marcas AS m
           ON m.brand_code = b.code
           INNER JOIN
           @proveedores AS x
           ON x.numero = m.alternative_number
           INNER JOIN
           purchasing.suppliers AS s
           ON s.tax_id = x.tax_id;
    IF (SELECT COUNT(*)
        FROM   purchasing.suppliers) <> 30
        THROW 51307, 'La cantidad de proveedores es incorrecta.', 1;
    IF (SELECT COUNT(*)
        FROM   purchasing.product_suppliers) <> 400
        THROW 51308, 'Deben existir exactamente 400 relaciones.', 1;
    IF EXISTS (SELECT   1
               FROM     catalog.products AS p
                        LEFT OUTER JOIN
                        purchasing.product_suppliers AS ps
                        ON ps.product_id = p.product_id
               GROUP BY p.product_id
               HAVING   COUNT(ps.product_supplier_id) <> 2
                        OR SUM(CASE WHEN ps.is_preferred = 1
                                         AND ps.is_active = 1 THEN 1 ELSE 0 END) <> 1)
        THROW 51309, 'Cada producto debe tener dos proveedores y uno preferido.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT COUNT(*) AS total_proveedores,
       SUM(CASE WHEN credit_days = 0 THEN 1 ELSE 0 END) AS contado,
       SUM(CASE WHEN credit_days = 15 THEN 1 ELSE 0 END) AS credito_15,
       SUM(CASE WHEN credit_days = 30 THEN 1 ELSE 0 END) AS credito_30,
       SUM(CASE WHEN credit_days = 45 THEN 1 ELSE 0 END) AS credito_45,
       SUM(CASE WHEN credit_days = 60 THEN 1 ELSE 0 END) AS credito_60
FROM   purchasing.suppliers;

SELECT COUNT(*) AS total_relaciones,
       SUM(CASE WHEN is_preferred = 1 THEN 1 ELSE 0 END) AS preferidas,
       SUM(CASE WHEN is_preferred = 0 THEN 1 ELSE 0 END) AS alternativas,
       COUNT(DISTINCT product_id) AS productos_cubiertos
FROM   purchasing.product_suppliers;

SELECT   s.business_name,
         COUNT(ps.product_supplier_id) AS productos_asociados,
         SUM(CASE WHEN ps.is_preferred = 1 THEN 1 ELSE 0 END) AS productos_preferidos
FROM     purchasing.suppliers AS s
         LEFT OUTER JOIN
         purchasing.product_suppliers AS ps
         ON ps.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.business_name
ORDER BY productos_asociados DESC, s.business_name;