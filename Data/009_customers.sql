SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    DECLARE @fecha AS DATETIME2 (3) = '2025-10-15T09:00:00';
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 51700, 'No existe el administrador.', 1;
    IF (SELECT COUNT(*)
        FROM   catalog.products) <> 200
        THROW 51701, 'Se requieren 200 productos.', 1;
    IF EXISTS (SELECT 1
               FROM   sales.customers)
       OR EXISTS (SELECT 1
                  FROM   sales.price_lists)
       OR EXISTS (SELECT 1
                  FROM   sales.price_list_details)
        THROW 51702, 'Las tablas comerciales deben estar vacias.', 1;
    IF EXISTS (SELECT 1
               FROM   catalog.products
               WHERE  average_cost IS NULL
                      OR average_cost <= 0)
        THROW 51703, 'Todos los productos requieren costo positivo.', 1;
    DECLARE @listas TABLE (
        code        NVARCHAR (50)  PRIMARY KEY,
        name        NVARCHAR (150),
        description NVARCHAR (500),
        multiplier  DECIMAL (8, 4));
    INSERT  INTO @listas
    VALUES ('PREC-MIN', N'Precio Minorista', N'Lista comercial para tiendas y pequeños negocios.', 1.3500),
           ('PREC-MAY', N'Precio Mayorista', N'Lista comercial para distribuidores y mayoristas.', 1.1800),
           ('PREC-CAD', N'Precio Cadenas', N'Lista comercial para cadenas comerciales.', 1.1400);
    INSERT INTO sales.price_lists (
        code,
        name,
        description,
        is_active,
        created_at,
        created_by
    )
    SELECT code,
           name,
           description,
           1,
           @fecha,
           @admin
    FROM   @listas;
    INSERT INTO sales.price_list_details (
        price_list_id,
        product_id,
        unit_price,
        created_at,
        created_by
    )
    SELECT pl.price_list_id,
           p.product_id,
           CAST (ROUND(p.average_cost * l.multiplier, 2) AS DECIMAL (18, 4)),
           @fecha,
           @admin
    FROM   sales.price_lists AS pl
           INNER JOIN
           @listas AS l
           ON l.code = pl.code
           CROSS JOIN catalog.products AS p;
    IF (SELECT COUNT(*)
        FROM   sales.price_list_details) <> 600
        THROW 51704, 'Se requieren 600 precios.', 1;
    DECLARE @usuarios TABLE (
        numero  INT PRIMARY KEY,
        user_id INT UNIQUE);
    INSERT INTO @usuarios (
        numero,
        user_id
    )
    SELECT ROW_NUMBER() OVER (ORDER BY u.user_id),
           u.user_id
    FROM   (SELECT   TOP (6) su.user_id
            FROM     security.users AS su
            ORDER BY su.user_id) AS u;
    INSERT INTO sales.salespersons (
        user_id,
        employee_code,
        phone,
        is_active,
        created_at,
        created_by
    )
    SELECT u.user_id,
           CONCAT('VEND-SIM-', RIGHT(CONCAT('000', u.numero), 3)),
           NULL,
           1,
           @fecha,
           @admin
    FROM   @usuarios AS u
    WHERE  NOT EXISTS (SELECT 1
                       FROM   sales.salespersons AS sp
                       WHERE  sp.user_id = u.user_id);
    DECLARE @vendedores TABLE (
        numero         INT PRIMARY KEY,
        salesperson_id INT UNIQUE);
    INSERT INTO @vendedores (
        numero,
        salesperson_id
    )
    SELECT ROW_NUMBER() OVER (ORDER BY sp.salesperson_id),
           sp.salesperson_id
    FROM   sales.salespersons AS sp
    WHERE  sp.is_active = 1;
    DECLARE @cantidadVendedores AS INT;
    SELECT @cantidadVendedores = COUNT(*)
    FROM   @vendedores;
    IF @cantidadVendedores = 0
        THROW 51705, 'No hay vendedores activos.', 1;
    DECLARE @clientes TABLE (
        numero         INT             PRIMARY KEY,
        customer_code  NVARCHAR (50)  ,
        tax_id         NVARCHAR (20)  ,
        business_name  NVARCHAR (200) ,
        customer_type  NVARCHAR (20)  ,
        address        NVARCHAR (300) ,
        salesperson_id INT            ,
        price_list_id  INT            ,
        credit_days    INT            ,
        credit_limit   DECIMAL (18, 2));
    WITH Digitos
    AS   (SELECT n
          FROM   (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS d(n)),
         Numeros
    AS   (SELECT ROW_NUMBER() OVER (ORDER BY a.n, b.n, c.n) AS numero
          FROM   Digitos AS a
                 CROSS JOIN Digitos AS b
                 CROSS JOIN Digitos AS c)
    INSERT INTO @clientes (
        numero,
        customer_code,
        tax_id,
        business_name,
        customer_type,
        address,
        salesperson_id,
        price_list_id,
        credit_days,
        credit_limit
    )
    SELECT n.numero,
           CONCAT('CLI-SIM-', RIGHT(CONCAT('0000', n.numero), 4)),
           CONCAT('SIM-CLI-', RIGHT(CONCAT('0000', n.numero), 4)),
           CASE WHEN n.numero <= 90 THEN CONCAT(N'Tienda y Abarrotería ', CASE n.numero % 8 WHEN 0 THEN N'La Bendición' WHEN 1 THEN N'El Progreso' WHEN 2 THEN N'San José' WHEN 3 THEN N'La Esperanza' WHEN 4 THEN N'El Buen Precio' WHEN 5 THEN N'Los Pinos' WHEN 6 THEN N'La Económica' ELSE N'El Centro' END, N' ', RIGHT(CONCAT('000', n.numero), 3)) WHEN n.numero <= 135 THEN CONCAT(N'Distribuidora Regional ', RIGHT(CONCAT('000', n.numero), 3)) ELSE CONCAT(N'Cadena Comercial Regional ', RIGHT(CONCAT('000', n.numero), 3)) END,
           CASE WHEN n.numero <= 90 THEN 'RETAIL' WHEN n.numero <= 135 THEN 'WHOLESALE' ELSE 'CHAIN' END,
           CASE WHEN n.numero % 20 < 11 THEN N'Ciudad de Guatemala, Guatemala' WHEN n.numero % 20 < 16 THEN N'Chiquimula, Chiquimula, Guatemala' ELSE N'Quetzaltenango, Quetzaltenango, Guatemala' END,
           v.salesperson_id,
           pl.price_list_id,
           CASE WHEN n.numero <= 90 THEN CASE WHEN n.numero % 5 = 0 THEN 15 ELSE 0 END WHEN n.numero <= 135 THEN CASE WHEN n.numero % 3 = 0 THEN 60 WHEN n.numero % 3 = 1 THEN 30 ELSE 15 END ELSE CASE WHEN n.numero % 2 = 0 THEN 60 ELSE 30 END END,
           CASE WHEN n.numero <= 90 THEN CASE WHEN n.numero % 5 = 0 THEN 5000 ELSE 0 END WHEN n.numero <= 135 THEN 25000 + ((n.numero % 5) * 10000) ELSE 100000 + ((n.numero % 5) * 25000) END
    FROM   Numeros AS n
           INNER JOIN
           @vendedores AS v
           ON v.numero = ((n.numero - 1) % @cantidadVendedores) + 1
           INNER JOIN
           sales.price_lists AS pl
           ON pl.code = CASE WHEN n.numero <= 90 THEN 'PREC-MIN' WHEN n.numero <= 135 THEN 'PREC-MAY' ELSE 'PREC-CAD' END
    WHERE  n.numero <= 150;
    IF (SELECT COUNT(*)
        FROM   @clientes) <> 150
        THROW 51706, 'Deben generarse 150 clientes.', 1;
    INSERT INTO sales.customers (
        customer_code,
        tax_id,
        business_name,
        customer_type,
        contact_name,
        phone,
        email,
        address,
        salesperson_id,
        price_list_id,
        credit_days,
        credit_limit,
        is_credit_blocked,
        is_active,
        created_at,
        created_by
    )
    SELECT c.customer_code,
           c.tax_id,
           c.business_name,
           c.customer_type,
           NULL,
           NULL,
           NULL,
           c.address,
           c.salesperson_id,
           c.price_list_id,
           c.credit_days,
           c.credit_limit,
           0,
           1,
           @fecha,
           @admin
    FROM   @clientes AS c;
    IF (SELECT COUNT(*)
        FROM   sales.customers) <> 150
        THROW 51707, 'La cantidad de clientes es incorrecta.', 1;
    IF EXISTS (SELECT   1
               FROM     sales.customers AS c
                        LEFT OUTER JOIN
                        sales.price_list_details AS pld
                        ON pld.price_list_id = c.price_list_id
               GROUP BY c.customer_id
               HAVING   COUNT(pld.price_list_detail_id) <> 200)
        THROW 51708, 'Existen clientes con listas de precios incompletas.', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH

SELECT   customer_type,
         COUNT(*) AS total_clientes,
         SUM(credit_limit) AS credito_autorizado
FROM     sales.customers
GROUP BY customer_type
ORDER BY customer_type;

SELECT   pl.code,
         pl.name,
         COUNT(pld.price_list_detail_id) AS productos
FROM     sales.price_lists AS pl
         INNER JOIN
         sales.price_list_details AS pld
         ON pld.price_list_id = pl.price_list_id
GROUP BY pl.code, pl.name
ORDER BY pl.code;

SELECT   sp.salesperson_id,
         sp.employee_code,
         COUNT(c.customer_id) AS clientes_asignados
FROM     sales.salespersons AS sp
         LEFT OUTER JOIN
         sales.customers AS c
         ON c.salesperson_id = sp.salesperson_id
GROUP BY sp.salesperson_id, sp.employee_code
ORDER BY sp.salesperson_id;