
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @fecha DATETIME2(3) = '2025-10-15T09:00:00';
    DECLARE @admin INT = 1;

    IF NOT EXISTS (
        SELECT 1
        FROM security.users
        WHERE user_id = @admin
    )
        THROW 51010, 'No existe el usuario administrador.', 1;

    IF EXISTS (
        SELECT 1 FROM catalog.brands
    ) OR EXISTS (
        SELECT 1 FROM catalog.categories
    ) OR EXISTS (
        SELECT 1 FROM catalog.product_lines
    ) OR EXISTS (
        SELECT 1 FROM catalog.units_of_measure
    )
        THROW 51011, 'Los catalogos deben estar vacios antes de ejecutar este script.', 1;

    INSERT INTO catalog.brands (
        code, name, description,
        is_active, created_at, created_by
    )
    VALUES
    ('COCA', N'Coca-Cola', N'Bebidas gaseosas', 1, @fecha, @admin),
    ('PEPSI', N'Pepsi', N'Bebidas gaseosas', 1, @fecha, @admin),
    ('FANTA', N'Fanta', N'Bebidas gaseosas', 1, @fecha, @admin),
    ('SPRITE', N'Sprite', N'Bebidas gaseosas', 1, @fecha, @admin),
    ('MIRINDA', N'Mirinda', N'Bebidas gaseosas', 1, @fecha, @admin),
    ('SEVENUP', N'7UP', N'Bebidas gaseosas', 1, @fecha, @admin),
    ('SALVAVIDAS', N'Agua Pura Salvavidas', N'Agua embotellada', 1, @fecha, @admin),
    ('RAPTOR', N'Raptor', N'Bebidas energéticas', 1, @fecha, @admin),
    ('MALHER', N'Malher', N'Condimentos y alimentos', 1, @fecha, @admin),
    ('NATURAS', N'Naturas', N'Jugos y néctares', 1, @fecha, @admin),
    ('DUCAL', N'Ducal', N'Frijoles preparados', 1, @fecha, @admin),
    ('COSTENA', N'La Costeña', N'Conservas y enlatados', 1, @fecha, @admin),
    ('BIMBO', N'Bimbo', N'Pan empacado', 1, @fecha, @admin),
    ('MARINELA', N'Marinela', N'Pastelitos empacados', 1, @fecha, @admin),
    ('GAMESA', N'Gamesa', N'Galletas', 1, @fecha, @admin),
    ('POZUELO', N'Pozuelo', N'Galletas', 1, @fecha, @admin),
    ('DIANA', N'Diana', N'Boquitas y snacks', 1, @fecha, @admin),
    ('TORTRIX', N'Tortrix', N'Boquitas de maíz', 1, @fecha, @admin),
    ('RICA', N'Rica', N'Productos lácteos', 1, @fecha, @admin),
    ('DOSPINOS', N'Dos Pinos', N'Productos lácteos', 1, @fecha, @admin),
    ('NESTLE', N'Nestlé', N'Alimentos y lácteos', 1, @fecha, @admin),
    ('NESCAFE', N'Nescafé', N'Café soluble', 1, @fecha, @admin),
    ('COLGATE', N'Colgate', N'Higiene dental', 1, @fecha, @admin),
    ('PROTEX', N'Protex', N'Jabones de tocador', 1, @fecha, @admin),
    ('ARIEL', N'Ariel', N'Detergentes', 1, @fecha, @admin);

    INSERT INTO catalog.categories (
        code, name, description,
        is_active, created_at, created_by
    )
    VALUES
    ('BEB', N'Bebidas', N'Bebidas para consumo', 1, @fecha, @admin),
    ('ALI', N'Alimentos básicos', N'Alimentos y condimentos', 1, @fecha, @admin),
    ('CON', N'Conservas y enlatados', N'Alimentos conservados', 1, @fecha, @admin),
    ('PAN', N'Panadería y galletas', N'Pan y productos horneados', 1, @fecha, @admin),
    ('BOT', N'Boquitas y snacks', N'Productos para refrigerio', 1, @fecha, @admin),
    ('LAC', N'Lácteos', N'Leche y derivados', 1, @fecha, @admin),
    ('HIG', N'Higiene personal', N'Cuidado personal', 1, @fecha, @admin),
    ('LIM', N'Limpieza del hogar', N'Productos de limpieza', 1, @fecha, @admin);

    DECLARE @lineas TABLE (
        category_code NVARCHAR(50),
        code NVARCHAR(50),
        name NVARCHAR(150)
    );

    INSERT INTO @lineas VALUES
    ('BEB', 'GAS', N'Gaseosas'),
    ('BEB', 'AGU', N'Agua embotellada'),
    ('BEB', 'JUG', N'Jugos y néctares'),
    ('BEB', 'ENE', N'Bebidas energéticas'),
    ('BEB', 'CAF', N'Café'),
    ('ALI', 'SOP', N'Sopas y consomés'),
    ('ALI', 'PAS', N'Pastas'),
    ('ALI', 'ARR', N'Arroz'),
    ('ALI', 'FRI', N'Frijoles preparados'),
    ('ALI', 'ACE', N'Aceites'),
    ('ALI', 'SAL', N'Salsas y condimentos'),
    ('CON', 'VEG', N'Vegetales en conserva'),
    ('CON', 'ATU', N'Atún y pescado'),
    ('CON', 'FRU', N'Frutas en conserva'),
    ('PAN', 'PANE', N'Pan empacado'),
    ('PAN', 'GAL', N'Galletas'),
    ('PAN', 'PAST', N'Pastelitos'),
    ('BOT', 'CHI', N'Churros y frituras'),
    ('BOT', 'NUE', N'Manías y nueces'),
    ('BOT', 'PAL', N'Palomitas'),
    ('LAC', 'LEC', N'Leche'),
    ('LAC', 'YOG', N'Yogur'),
    ('LAC', 'CRE', N'Crema y derivados'),
    ('HIG', 'DEN', N'Cuidado dental'),
    ('HIG', 'JAB', N'Jabones'),
    ('HIG', 'CHA', N'Champú'),
    ('LIM', 'DET', N'Detergentes'),
    ('LIM', 'LAV', N'Lavaplatos'),
    ('LIM', 'DES', N'Desinfectantes'),
    ('LIM', 'SUA', N'Suavizantes');

    INSERT INTO catalog.product_lines (
        category_id,
        code,
        name,
        description,
        is_active,
        created_at,
        created_by
    )
    SELECT
        c.category_id,
        l.code,
        l.name,
        N'Línea de productos de distribución',
        1,
        @fecha,
        @admin
    FROM @lineas AS l
    INNER JOIN catalog.categories AS c
        ON c.code = l.category_code;

    INSERT INTO catalog.units_of_measure (
        code, name, abbreviation, description,
        is_active, created_at, created_by
    )
    VALUES
    ('UND', N'Unidad', 'und', N'Producto individual', 1, @fecha, @admin),
    ('BOT', N'Botella', 'bot', N'Producto embotellado', 1, @fecha, @admin),
    ('LAT', N'Lata', 'lat', N'Producto enlatado', 1, @fecha, @admin),
    ('BOL', N'Bolsa', 'bol', N'Producto embolsado', 1, @fecha, @admin),
    ('PAQ', N'Paquete', 'paq', N'Producto empacado', 1, @fecha, @admin),
    ('CAJ', N'Caja', 'caj', N'Presentación mayorista', 1, @fecha, @admin),
    ('SIX', N'Six pack', 'six', N'Conjunto de seis unidades', 1, @fecha, @admin),
    ('SAC', N'Saco', 'sac', N'Presentación en saco', 1, @fecha, @admin),
    ('FRS', N'Frasco', 'frs', N'Producto en frasco', 1, @fecha, @admin),
    ('BRK', N'Envase tipo brik', 'brk', N'Envase de cartón', 1, @fecha, @admin);

    IF (SELECT COUNT(*) FROM catalog.brands) <> 25
        THROW 51012, 'Cantidad de marcas incorrecta.', 1;

    IF (SELECT COUNT(*) FROM catalog.categories) <> 8
        THROW 51013, 'Cantidad de categorias incorrecta.', 1;

    IF (SELECT COUNT(*) FROM catalog.product_lines) <> 30
        THROW 51014, 'Cantidad de lineas incorrecta.', 1;

    IF (SELECT COUNT(*) FROM catalog.units_of_measure) <> 10
        THROW 51015, 'Cantidad de unidades incorrecta.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

SELECT 'Marcas' AS entidad, COUNT(*) AS total
FROM catalog.brands
UNION ALL
SELECT 'Categorías', COUNT(*)
FROM catalog.categories
UNION ALL
SELECT 'Líneas de producto', COUNT(*)
FROM catalog.product_lines
UNION ALL
SELECT 'Unidades de medida', COUNT(*)
FROM catalog.units_of_measure;
GO
