SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @fecha AS DATETIME2 (3) = '2025-10-15T09:00:00';
    DECLARE @admin AS INT = 1;
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51100, 'No existe el usuario administrador.', 1;
    IF EXISTS (SELECT 1
               FROM   catalog.products)
        THROW 51101, 'La tabla de productos debe estar vacia.', 1;
    IF (SELECT COUNT(*)
        FROM   catalog.brands) < 25
       OR (SELECT COUNT(*)
           FROM   catalog.product_lines) < 30
       OR (SELECT COUNT(*)
           FROM   catalog.units_of_measure) < 10
        THROW 51102, 'Primero debe ejecutar la parte 1 del catalogo.', 1;
    DECLARE @base TABLE (
        base_id      INT             IDENTITY (1, 1) PRIMARY KEY,
        brand_code   NVARCHAR (50)  ,
        line_code    NVARCHAR (50)  ,
        unit_code    NVARCHAR (20)  ,
        product_name NVARCHAR (160) ,
        presentation NVARCHAR (40)  ,
        weight       DECIMAL (18, 3),
        cost         DECIMAL (18, 4),
        price        DECIMAL (18, 4),
        expiration   BIT            );
    INSERT  INTO @base (
        brand_code,
        line_code,
        unit_code,
        product_name,
        presentation,
        weight,
        cost,
        price,
        expiration
    )
    VALUES             ('COCA', 'GAS', 'BOT', N'Coca-Cola Original', '355 ml', 0.355, 3.2000, 5.0000, 1),
                       ('COCA', 'GAS', 'BOT', N'Coca-Cola Original', '600 ml', 0.600, 4.6000, 7.0000, 1),
                       ('COCA', 'GAS', 'BOT', N'Coca-Cola Original', '1.5 L', 1.500, 8.9000, 13.0000, 1),
                       ('COCA', 'GAS', 'BOT', N'Coca-Cola Original', '2 L', 2.000, 10.8000, 16.0000, 1),
                       ('COCA', 'GAS', 'LAT', N'Coca-Cola Sin Azúcar', '355 ml', 0.355, 3.4000, 5.5000, 1),
                       ('PEPSI', 'GAS', 'BOT', N'Pepsi Original', '355 ml', 0.355, 3.0000, 5.0000, 1),
                       ('PEPSI', 'GAS', 'BOT', N'Pepsi Original', '600 ml', 0.600, 4.3000, 7.0000, 1),
                       ('PEPSI', 'GAS', 'BOT', N'Pepsi Original', '1.5 L', 1.500, 8.3000, 13.0000, 1),
                       ('PEPSI', 'GAS', 'BOT', N'Pepsi Original', '2 L', 2.000, 10.2000, 16.0000, 1),
                       ('FANTA', 'GAS', 'BOT', N'Fanta Naranja', '600 ml', 0.600, 4.5000, 7.0000, 1),
                       ('FANTA', 'GAS', 'BOT', N'Fanta Naranja', '2 L', 2.000, 10.5000, 16.0000, 1),
                       ('SPRITE', 'GAS', 'BOT', N'Sprite Lima-Limón', '600 ml', 0.600, 4.5000, 7.0000, 1),
                       ('SPRITE', 'GAS', 'BOT', N'Sprite Lima-Limón', '2 L', 2.000, 10.5000, 16.0000, 1),
                       ('MIRINDA', 'GAS', 'BOT', N'Mirinda Naranja', '600 ml', 0.600, 4.1000, 7.0000, 1),
                       ('MIRINDA', 'GAS', 'BOT', N'Mirinda Naranja', '2 L', 2.000, 9.9000, 15.0000, 1),
                       ('SEVENUP', 'GAS', 'BOT', N'7UP Lima-Limón', '600 ml', 0.600, 4.2000, 7.0000, 1),
                       ('SEVENUP', 'GAS', 'BOT', N'7UP Lima-Limón', '2 L', 2.000, 10.0000, 15.0000, 1),
                       ('SALVAVIDAS', 'AGU', 'BOT', N'Agua Pura Salvavidas', '600 ml', 0.600, 2.1000, 4.0000, 1),
                       ('SALVAVIDAS', 'AGU', 'BOT', N'Agua Pura Salvavidas', '1 L', 1.000, 3.0000, 5.0000, 1),
                       ('SALVAVIDAS', 'AGU', 'BOT', N'Agua Pura Salvavidas', '1.5 L', 1.500, 3.9000, 6.5000, 1),
                       ('SALVAVIDAS', 'AGU', 'BOT', N'Agua Pura Salvavidas', '5 L', 5.000, 10.5000, 16.0000, 1),
                       ('RAPTOR', 'ENE', 'LAT', N'Raptor Energética Original', '473 ml', 0.473, 5.8000, 9.0000, 1),
                       ('RAPTOR', 'ENE', 'LAT', N'Raptor Energética Original', '250 ml', 0.250, 4.0000, 7.0000, 1),
                       ('RAPTOR', 'ENE', 'LAT', N'Raptor Energética Sin Azúcar', '473 ml', 0.473, 6.0000, 10.0000, 1),
                       ('NATURAS', 'JUG', 'BRK', N'Naturas Néctar de Mango', '200 ml', 0.200, 2.2000, 4.0000, 1),
                       ('NATURAS', 'JUG', 'BRK', N'Naturas Néctar de Manzana', '200 ml', 0.200, 2.2000, 4.0000, 1),
                       ('NATURAS', 'JUG', 'BRK', N'Naturas Néctar de Durazno', '200 ml', 0.200, 2.2000, 4.0000, 1),
                       ('NATURAS', 'JUG', 'BRK', N'Naturas Néctar de Mango', '1 L', 1.000, 7.4000, 11.0000, 1),
                       ('NATURAS', 'JUG', 'BRK', N'Naturas Néctar de Manzana', '1 L', 1.000, 7.4000, 11.0000, 1),
                       ('NATURAS', 'JUG', 'BRK', N'Naturas Néctar de Durazno', '1 L', 1.000, 7.4000, 11.0000, 1),
                       ('NESCAFE', 'CAF', 'FRS', N'Nescafé Clásico', '50 g', 0.050, 16.0000, 23.0000, 1),
                       ('NESCAFE', 'CAF', 'FRS', N'Nescafé Clásico', '100 g', 0.100, 29.0000, 41.0000, 1),
                       ('NESCAFE', 'CAF', 'FRS', N'Nescafé Clásico', '200 g', 0.200, 52.0000, 73.0000, 1),
                       ('NESCAFE', 'CAF', 'PAQ', N'Nescafé Clásico Sobres', '10 unidades', 0.100, 15.0000, 23.0000, 1),
                       ('NESTLE', 'CAF', 'PAQ', N'Nestlé Cocoa para Bebida', '200 g', 0.200, 13.0000, 20.0000, 1),
                       ('MALHER', 'SOP', 'PAQ', N'Malher Consomé de Pollo', '100 g', 0.100, 5.2000, 8.0000, 1),
                       ('MALHER', 'SOP', 'PAQ', N'Malher Consomé de Pollo', '200 g', 0.200, 9.5000, 14.0000, 1),
                       ('MALHER', 'SOP', 'PAQ', N'Malher Consomé de Res', '100 g', 0.100, 5.3000, 8.0000, 1),
                       ('MALHER', 'SOP', 'PAQ', N'Malher Consomé de Res', '200 g', 0.200, 9.7000, 14.0000, 1),
                       ('MALHER', 'SOP', 'PAQ', N'Malher Sopa de Pollo', '60 g', 0.060, 2.7000, 4.5000, 1),
                       ('MALHER', 'SOP', 'PAQ', N'Malher Sopa de Res', '60 g', 0.060, 2.7000, 4.5000, 1),
                       ('MALHER', 'SAL', 'PAQ', N'Malher Sazonador Completo', '100 g', 0.100, 5.0000, 8.0000, 1),
                       ('MALHER', 'SAL', 'PAQ', N'Malher Sazonador Completo', '200 g', 0.200, 9.2000, 14.0000, 1),
                       ('MALHER', 'SAL', 'FRS', N'Malher Salsa de Tomate', '200 g', 0.200, 6.0000, 9.5000, 1),
                       ('MALHER', 'SAL', 'FRS', N'Malher Salsa de Tomate', '400 g', 0.400, 10.5000, 16.0000, 1),
                       ('MALHER', 'SAL', 'PAQ', N'Malher Pimienta Negra', '50 g', 0.050, 5.5000, 9.0000, 1),
                       ('DUCAL', 'FRI', 'LAT', N'Ducal Frijoles Negros Volteados', '227 g', 0.227, 5.5000, 8.5000, 1),
                       ('DUCAL', 'FRI', 'LAT', N'Ducal Frijoles Negros Volteados', '425 g', 0.425, 8.9000, 13.0000, 1),
                       ('DUCAL', 'FRI', 'LAT', N'Ducal Frijoles Rojos Volteados', '227 g', 0.227, 5.6000, 8.5000, 1),
                       ('DUCAL', 'FRI', 'LAT', N'Ducal Frijoles Rojos Volteados', '425 g', 0.425, 9.0000, 13.0000, 1),
                       ('DUCAL', 'FRI', 'LAT', N'Ducal Frijoles Negros Enteros', '425 g', 0.425, 8.7000, 13.0000, 1),
                       ('COSTENA', 'VEG', 'LAT', N'La Costeña Elote Dulce', '220 g', 0.220, 6.5000, 10.0000, 1),
                       ('COSTENA', 'VEG', 'LAT', N'La Costeña Elote Dulce', '400 g', 0.400, 10.2000, 15.0000, 1),
                       ('COSTENA', 'VEG', 'LAT', N'La Costeña Chícharos', '220 g', 0.220, 6.0000, 9.5000, 1),
                       ('COSTENA', 'VEG', 'LAT', N'La Costeña Vegetales Mixtos', '400 g', 0.400, 10.0000, 15.0000, 1),
                       ('COSTENA', 'VEG', 'LAT', N'La Costeña Jalapeños en Rodajas', '220 g', 0.220, 7.0000, 11.0000, 1),
                       ('COSTENA', 'FRU', 'LAT', N'La Costeña Duraznos en Almíbar', '400 g', 0.400, 13.0000, 19.0000, 1),
                       ('COSTENA', 'FRU', 'LAT', N'La Costeña Piña en Almíbar', '400 g', 0.400, 12.5000, 19.0000, 1),
                       ('COSTENA', 'ATU', 'LAT', N'La Costeña Atún en Agua', '140 g', 0.140, 10.0000, 15.0000, 1),
                       ('COSTENA', 'ATU', 'LAT', N'La Costeña Atún en Aceite', '140 g', 0.140, 10.3000, 15.5000, 1),
                       ('BIMBO', 'PANE', 'PAQ', N'Bimbo Pan Blanco', '500 g', 0.500, 13.0000, 19.0000, 1),
                       ('BIMBO', 'PANE', 'PAQ', N'Bimbo Pan Integral', '500 g', 0.500, 15.0000, 22.0000, 1),
                       ('BIMBO', 'PANE', 'PAQ', N'Bimbo Pan para Hamburguesa', '8 unidades', 0.480, 13.5000, 20.0000, 1),
                       ('BIMBO', 'PANE', 'PAQ', N'Bimbo Pan para Hot Dog', '8 unidades', 0.440, 13.0000, 19.0000, 1),
                       ('BIMBO', 'PANE', 'PAQ', N'Bimbo Pan Tostado', '200 g', 0.200, 10.0000, 16.0000, 1),
                       ('MARINELA', 'PAST', 'PAQ', N'Marinela Gansito', '50 g', 0.050, 3.3000, 5.5000, 1),
                       ('MARINELA', 'PAST', 'PAQ', N'Marinela Pingüinos', '80 g', 0.080, 5.2000, 8.0000, 1),
                       ('MARINELA', 'PAST', 'PAQ', N'Marinela Chocorroles', '80 g', 0.080, 5.0000, 8.0000, 1),
                       ('MARINELA', 'PAST', 'PAQ', N'Marinela Submarinos', '100 g', 0.100, 5.8000, 9.0000, 1),
                       ('MARINELA', 'PAST', 'PAQ', N'Marinela Barritas de Fresa', '75 g', 0.075, 4.8000, 7.5000, 1),
                       ('GAMESA', 'GAL', 'PAQ', N'Gamesa Emperador Chocolate', '91 g', 0.091, 4.5000, 7.0000, 1),
                       ('GAMESA', 'GAL', 'PAQ', N'Gamesa Emperador Vainilla', '91 g', 0.091, 4.5000, 7.0000, 1),
                       ('GAMESA', 'GAL', 'PAQ', N'Gamesa Chokis', '90 g', 0.090, 4.2000, 7.0000, 1),
                       ('GAMESA', 'GAL', 'PAQ', N'Gamesa Marías', '170 g', 0.170, 5.2000, 8.0000, 1),
                       ('GAMESA', 'GAL', 'PAQ', N'Gamesa Saladitas', '140 g', 0.140, 5.0000, 8.0000, 1),
                       ('POZUELO', 'GAL', 'PAQ', N'Pozuelo Chiky Chocolate', '100 g', 0.100, 4.8000, 7.5000, 1),
                       ('POZUELO', 'GAL', 'PAQ', N'Pozuelo Chiky Fresa', '100 g', 0.100, 4.8000, 7.5000, 1),
                       ('POZUELO', 'GAL', 'PAQ', N'Pozuelo Yipy Chocolate', '100 g', 0.100, 4.9000, 8.0000, 1),
                       ('POZUELO', 'GAL', 'PAQ', N'Pozuelo Cremas', '120 g', 0.120, 5.0000, 8.0000, 1),
                       ('POZUELO', 'GAL', 'PAQ', N'Pozuelo Soda', '200 g', 0.200, 6.0000, 9.5000, 1),
                       ('DIANA', 'CHI', 'BOL', N'Diana Nachos Queso', '45 g', 0.045, 2.5000, 4.0000, 1),
                       ('DIANA', 'CHI', 'BOL', N'Diana Nachos Queso', '100 g', 0.100, 4.8000, 7.5000, 1),
                       ('DIANA', 'CHI', 'BOL', N'Diana Jalapeños', '45 g', 0.045, 2.5000, 4.0000, 1),
                       ('DIANA', 'CHI', 'BOL', N'Diana Palitos Salados', '60 g', 0.060, 2.6000, 4.0000, 1),
                       ('DIANA', 'NUE', 'BOL', N'Diana Manías Saladas', '80 g', 0.080, 3.5000, 5.5000, 1),
                       ('DIANA', 'NUE', 'BOL', N'Diana Manías Japonesas', '80 g', 0.080, 3.8000, 6.0000, 1),
                       ('DIANA', 'PAL', 'BOL', N'Diana Palomitas de Maíz', '80 g', 0.080, 3.5000, 5.5000, 1),
                       ('TORTRIX', 'CHI', 'BOL', N'Tortrix Original', '40 g', 0.040, 2.0000, 3.5000, 1),
                       ('TORTRIX', 'CHI', 'BOL', N'Tortrix Original', '90 g', 0.090, 4.0000, 6.5000, 1),
                       ('TORTRIX', 'CHI', 'BOL', N'Tortrix Limón', '40 g', 0.040, 2.0000, 3.5000, 1),
                       ('TORTRIX', 'CHI', 'BOL', N'Tortrix Picante', '40 g', 0.040, 2.0000, 3.5000, 1),
                       ('TORTRIX', 'CHI', 'BOL', N'Tortrix Barbacoa', '90 g', 0.090, 4.2000, 7.0000, 1),
                       ('RICA', 'LEC', 'BRK', N'Rica Leche Entera', '1 L', 1.000, 9.5000, 14.0000, 1),
                       ('RICA', 'LEC', 'BRK', N'Rica Leche Descremada', '1 L', 1.000, 9.8000, 14.5000, 1),
                       ('RICA', 'LEC', 'BRK', N'Rica Leche Semidescremada', '1 L', 1.000, 9.7000, 14.5000, 1),
                       ('RICA', 'YOG', 'BOT', N'Rica Yogur Fresa', '200 ml', 0.200, 4.0000, 6.5000, 1),
                       ('RICA', 'YOG', 'BOT', N'Rica Yogur Vainilla', '200 ml', 0.200, 4.0000, 6.5000, 1),
                       ('RICA', 'CRE', 'FRS', N'Rica Crema', '200 ml', 0.200, 7.0000, 11.0000, 1),
                       ('DOSPINOS', 'LEC', 'BRK', N'Dos Pinos Leche Entera', '1 L', 1.000, 10.0000, 15.0000, 1),
                       ('DOSPINOS', 'LEC', 'BRK', N'Dos Pinos Leche Descremada', '1 L', 1.000, 10.2000, 15.5000, 1),
                       ('DOSPINOS', 'YOG', 'BOT', N'Dos Pinos Yogur Fresa', '200 ml', 0.200, 4.5000, 7.0000, 1),
                       ('DOSPINOS', 'YOG', 'BOT', N'Dos Pinos Yogur Melocotón', '200 ml', 0.200, 4.5000, 7.0000, 1),
                       ('DOSPINOS', 'CRE', 'FRS', N'Dos Pinos Crema', '200 ml', 0.200, 7.5000, 12.0000, 1),
                       ('NESTLE', 'LEC', 'BRK', N'Nestlé Leche Condensada', '397 g', 0.397, 13.0000, 19.0000, 1),
                       ('NESTLE', 'LEC', 'LAT', N'Nestlé Leche Evaporada', '360 g', 0.360, 11.5000, 17.0000, 1),
                       ('NESTLE', 'LEC', 'PAQ', N'Nestlé Leche en Polvo', '400 g', 0.400, 31.0000, 44.0000, 1),
                       ('NESTLE', 'LEC', 'PAQ', N'Nestlé Leche en Polvo', '800 g', 0.800, 57.0000, 80.0000, 1),
                       ('COLGATE', 'DEN', 'UND', N'Colgate Triple Acción', '75 ml', 0.075, 9.0000, 14.0000, 0),
                       ('COLGATE', 'DEN', 'UND', N'Colgate Triple Acción', '150 ml', 0.150, 16.0000, 24.0000, 0),
                       ('COLGATE', 'DEN', 'UND', N'Colgate Total', '75 ml', 0.075, 14.0000, 21.0000, 0),
                       ('COLGATE', 'DEN', 'UND', N'Colgate Cepillo Dental Suave', '1 unidad', 0.030, 7.0000, 11.0000, 0),
                       ('COLGATE', 'DEN', 'UND', N'Colgate Cepillo Dental Medio', '1 unidad', 0.030, 7.0000, 11.0000, 0),
                       ('COLGATE', 'DEN', 'BOT', N'Colgate Enjuague Bucal', '250 ml', 0.250, 18.0000, 27.0000, 0),
                       ('PROTEX', 'JAB', 'UND', N'Protex Jabón Original', '110 g', 0.110, 5.0000, 8.0000, 0),
                       ('PROTEX', 'JAB', 'UND', N'Protex Jabón Avena', '110 g', 0.110, 5.0000, 8.0000, 0),
                       ('PROTEX', 'JAB', 'UND', N'Protex Jabón Aloe', '110 g', 0.110, 5.0000, 8.0000, 0),
                       ('PROTEX', 'JAB', 'BOT', N'Protex Jabón Líquido', '250 ml', 0.250, 14.0000, 21.0000, 0),
                       ('ARIEL', 'DET', 'BOL', N'Ariel Detergente en Polvo', '500 g', 0.500, 11.0000, 17.0000, 0),
                       ('ARIEL', 'DET', 'BOL', N'Ariel Detergente en Polvo', '1 kg', 1.000, 20.0000, 30.0000, 0),
                       ('ARIEL', 'DET', 'BOL', N'Ariel Detergente en Polvo', '2 kg', 2.000, 37.0000, 54.0000, 0),
                       ('ARIEL', 'DET', 'BOT', N'Ariel Detergente Líquido', '900 ml', 0.900, 25.0000, 37.0000, 0),
                       ('ARIEL', 'DET', 'BOT', N'Ariel Detergente Líquido', '1.8 L', 1.800, 46.0000, 67.0000, 0),
                       ('MALHER', 'PAS', 'PAQ', N'Malher Pasta Espagueti', '200 g', 0.200, 3.5000, 6.0000, 1),
                       ('MALHER', 'PAS', 'PAQ', N'Malher Pasta Coditos', '200 g', 0.200, 3.5000, 6.0000, 1),
                       ('MALHER', 'ARR', 'BOL', N'Malher Arroz Blanco', '1 kg', 1.000, 8.0000, 12.0000, 1),
                       ('MALHER', 'ACE', 'BOT', N'Malher Aceite Vegetal', '900 ml', 0.900, 14.0000, 21.0000, 1),
                       ('COSTENA', 'SAL', 'FRS', N'La Costeña Salsa Picante', '150 ml', 0.150, 7.0000, 11.0000, 1),
                       ('COSTENA', 'SAL', 'FRS', N'La Costeña Salsa Verde', '250 g', 0.250, 9.0000, 14.0000, 1),
                       ('NESTLE', 'YOG', 'UND', N'Nestlé Yogur Natural', '125 g', 0.125, 4.0000, 6.5000, 1),
                       ('NESTLE', 'CRE', 'LAT', N'Nestlé Crema de Leche', '225 g', 0.225, 10.0000, 15.0000, 1),
                       ('PROTEX', 'CHA', 'BOT', N'Protex Champú Cuidado Diario', '400 ml', 0.400, 20.0000, 30.0000, 0),
                       ('ARIEL', 'LAV', 'BOT', N'Ariel Lavaplatos Líquido', '500 ml', 0.500, 12.0000, 19.0000, 0),
                       ('ARIEL', 'DES', 'BOT', N'Ariel Limpiador Multiusos', '900 ml', 0.900, 15.0000, 23.0000, 0),
                       ('ARIEL', 'SUA', 'BOT', N'Ariel Suavizante de Ropa', '900 ml', 0.900, 17.0000, 26.0000, 0),
                       ('DIANA', 'NUE', 'BOL', N'Diana Manías con Limón', '100 g', 0.100, 4.0000, 6.5000, 1),
                       ('DIANA', 'PAL', 'BOL', N'Diana Palomitas con Mantequilla', '100 g', 0.100, 4.0000, 6.5000, 1),
                       ('POZUELO', 'GAL', 'PAQ', N'Pozuelo Galletas de Vainilla', '150 g', 0.150, 5.0000, 8.0000, 1),
                       ('GAMESA', 'GAL', 'PAQ', N'Gamesa Galletas de Chocolate', '150 g', 0.150, 5.0000, 8.0000, 1),
                       ('BIMBO', 'PANE', 'PAQ', N'Bimbo Pan Multigrano', '500 g', 0.500, 16.0000, 24.0000, 1),
                       ('NESCAFE', 'CAF', 'FRS', N'Nescafé Descafeinado', '100 g', 0.100, 34.0000, 48.0000, 1);
    IF (SELECT COUNT(*)
        FROM   @base) < 140
        THROW 51103, 'Se requieren al menos 140 productos base.', 1;
    DECLARE @productos TABLE (
        sku               NVARCHAR (50)   PRIMARY KEY,
        barcode           NVARCHAR (50)   UNIQUE,
        brand_code        NVARCHAR (50)  ,
        line_code         NVARCHAR (50)  ,
        unit_code         NVARCHAR (20)  ,
        name              NVARCHAR (200) ,
        description       NVARCHAR (1000),
        weight            DECIMAL (18, 3),
        average_cost      DECIMAL (18, 4),
        list_price        DECIMAL (18, 4),
        minimum_stock     DECIMAL (18, 3),
        maximum_stock     DECIMAL (18, 3),
        reorder_point     DECIMAL (18, 3),
        tracks_expiration BIT            );
    INSERT INTO @productos (
        sku,
        barcode,
        brand_code,
        line_code,
        unit_code,
        name,
        description,
        weight,
        average_cost,
        list_price,
        minimum_stock,
        maximum_stock,
        reorder_point,
        tracks_expiration
    )
    SELECT CONCAT('SKU-', RIGHT(CONCAT('0000', b.base_id), 4)),
           CONCAT('SIMGT', RIGHT(CONCAT('000000000', b.base_id), 9)),
           b.brand_code,
           b.line_code,
           b.unit_code,
           CONCAT(b.product_name, N' ', b.presentation),
           CONCAT(N'Presentación individual: ', b.presentation),
           b.weight,
           b.cost,
           b.price,
           CASE WHEN b.price >= 40 THEN 15 WHEN b.price >= 15 THEN 30 ELSE 60 END,
           CASE WHEN b.price >= 40 THEN 90 WHEN b.price >= 15 THEN 180 ELSE 360 END,
           CASE WHEN b.price >= 40 THEN 30 WHEN b.price >= 15 THEN 60 ELSE 120 END,
           b.expiration
    FROM   @base AS b
    WHERE  b.base_id IN (SELECT   TOP (140) base_id
                         FROM     @base
                         ORDER BY base_id);
    INSERT INTO @productos (
        sku,
        barcode,
        brand_code,
        line_code,
        unit_code,
        name,
        description,
        weight,
        average_cost,
        list_price,
        minimum_stock,
        maximum_stock,
        reorder_point,
        tracks_expiration
    )
    SELECT CONCAT('SKU-M-', RIGHT(CONCAT('0000', s.base_id), 4)),
           CONCAT('SIMGT-M', RIGHT(CONCAT('000000000', s.base_id), 9)),
           s.brand_code,
           s.line_code,
           'CAJ',
           CONCAT(s.product_name, N' ', s.presentation, N' - Caja x12'),
           CONCAT(N'Presentación mayorista independiente de 12 unidades de ', s.presentation),
           CAST (s.weight * 12 AS DECIMAL (18, 3)),
           CAST (s.cost * 12 * 0.94 AS DECIMAL (18, 4)),
           CAST (s.price * 12 * 0.90 AS DECIMAL (18, 4)),
           CAST (8 AS DECIMAL (18, 3)),
           CAST (60 AS DECIMAL (18, 3)),
           CAST (20 AS DECIMAL (18, 3)),
           s.expiration
    FROM   (SELECT b.*,
                   ROW_NUMBER() OVER (ORDER BY CASE WHEN b.line_code IN ('GAS', 'AGU', 'JUG', 'CHI', 'GAL') THEN 0 ELSE 1 END, b.base_id) AS orden
            FROM   @base AS b
            WHERE  b.base_id IN (SELECT   TOP (140) base_id
                                 FROM     @base
                                 ORDER BY base_id)) AS s
    WHERE  s.orden <= 60;
    IF (SELECT COUNT(*)
        FROM   @productos) <> 200
        THROW 51104, 'Deben generarse exactamente 200 productos.', 1;
    IF EXISTS (SELECT 1
               FROM   @productos AS p
                      LEFT OUTER JOIN
                      catalog.brands AS b
                      ON b.code = p.brand_code
                      LEFT OUTER JOIN
                      catalog.product_lines AS l
                      ON l.code = p.line_code
                      LEFT OUTER JOIN
                      catalog.units_of_measure AS u
                      ON u.code = p.unit_code
               WHERE  b.brand_id IS NULL
                      OR l.product_line_id IS NULL
                      OR u.unit_of_measure_id IS NULL)
        THROW 51105, 'Existen referencias de catalogo no encontradas.', 1;
    INSERT INTO catalog.products (
        brand_id,
        product_line_id,
        unit_of_measure_id,
        sku,
        barcode,
        name,
        description,
        weight,
        average_cost,
        list_price,
        minimum_stock,
        maximum_stock,
        reorder_point,
        tracks_expiration,
        is_active,
        created_at,
        created_by
    )
    SELECT b.brand_id,
           l.product_line_id,
           u.unit_of_measure_id,
           p.sku,
           p.barcode,
           p.name,
           p.description,
           p.weight,
           p.average_cost,
           p.list_price,
           p.minimum_stock,
           p.maximum_stock,
           p.reorder_point,
           p.tracks_expiration,
           1,
           @fecha,
           @admin
    FROM   @productos AS p
           INNER JOIN
           catalog.brands AS b
           ON b.code = p.brand_code
           INNER JOIN
           catalog.product_lines AS l
           ON l.code = p.line_code
           INNER JOIN
           catalog.units_of_measure AS u
           ON u.code = p.unit_code;
    IF (SELECT COUNT(*)
        FROM   catalog.products) <> 200
        THROW 51106, 'La cantidad insertada de productos es incorrecta.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT COUNT(*) AS total_productos,
       SUM(CASE WHEN sku LIKE 'SKU-M-%' THEN 1 ELSE 0 END) AS mayoristas,
       SUM(CASE WHEN sku NOT LIKE 'SKU-M-%' THEN 1 ELSE 0 END) AS individuales
FROM   catalog.products;