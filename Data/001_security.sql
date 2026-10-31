SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM security.users WHERE user_id = 1)
        THROW 51001, 'No existe el usuario administrador con user_id = 1.', 1;

    IF NOT EXISTS (SELECT 1 FROM security.roles WHERE role_id = 1)
        THROW 51002, 'No existe el rol administrador con role_id = 1.', 1;

    DECLARE @fecha_inicio DATETIME2(3) = '2025-10-15T09:00:00.000';

    DECLARE @hash NVARCHAR(255) =
        N'$argon2id$v=19$m=19456,p=1,t=2$CGWLrCM/4skP6UmgEbQ0Bw$d0SgIZqSolti7B0dH0pgL8VdbDnnJRQ1yUolqwuW1h0';

    DECLARE @roles TABLE (
        code NVARCHAR(100) PRIMARY KEY,
        name NVARCHAR(150) NOT NULL,
        description NVARCHAR(500) NULL
    );

    INSERT INTO @roles (code, name, description)
    VALUES
        (
            N'WAREHOUSE_MANAGER',
            N'Jefe de bodega',
            N'Recepciones de mercaderia, lotes y control de bodega.'
        ),
        (
            N'ROUTE_SALESPERSON',
            N'Vendedor rutero',
            N'Registro de pedidos y atencion de clientes por region.'
        ),
        (
            N'CREDIT_ANALYST',
            N'Analista de credito y cobros',
            N'Seguimiento de cuentas por cobrar y morosidad.'
        ),
        (
            N'PURCHASING_MANAGER',
            N'Encargado de compras',
            N'Abastecimiento y ordenes de compra.'
        ),
        (
            N'INVENTORY_AUDITOR',
            N'Auditor de inventarios',
            N'Revision de movimientos y Kardex.'
        );

    INSERT INTO security.roles (
        code,
        name,
        description,
        is_active,
        created_at,
        updated_at
    )
    SELECT
        r.code,
        r.name,
        r.description,
        1,
        @fecha_inicio,
        NULL
    FROM @roles AS r
    WHERE NOT EXISTS (
        SELECT 1
        FROM security.roles AS sr
        WHERE sr.code = r.code
    );

    DECLARE @usuarios TABLE (
        username NVARCHAR(50) PRIMARY KEY,
        email NVARCHAR(255) NOT NULL,
        first_name NVARCHAR(100) NOT NULL,
        last_name NVARCHAR(100) NOT NULL,
        role_code NVARCHAR(100) NOT NULL
    );

    INSERT INTO @usuarios (
        username,
        email,
        first_name,
        last_name,
        role_code
    )
    VALUES
        (
            N'bodega.gua',
            N'bodega.gua@distribuidora.example',
            N'Roberto',
            N'Garcia',
            N'WAREHOUSE_MANAGER'
        ),
        (
            N'bodega.chi',
            N'bodega.chi@distribuidora.example',
            N'Jose',
            N'Ramirez',
            N'WAREHOUSE_MANAGER'
        ),
        (
            N'bodega.que',
            N'bodega.que@distribuidora.example',
            N'Miguel',
            N'Perez',
            N'WAREHOUSE_MANAGER'
        ),
        (
            N'vendedor.gua01',
            N'vendedor.gua01@distribuidora.example',
            N'Daniel',
            N'Hernandez',
            N'ROUTE_SALESPERSON'
        ),
        (
            N'vendedor.gua02',
            N'vendedor.gua02@distribuidora.example',
            N'Maria',
            N'Gonzalez',
            N'ROUTE_SALESPERSON'
        ),
        (
            N'vendedor.chi01',
            N'vendedor.chi01@distribuidora.example',
            N'Kevin',
            N'Lopez',
            N'ROUTE_SALESPERSON'
        ),
        (
            N'vendedor.chi02',
            N'vendedor.chi02@distribuidora.example',
            N'Sofia',
            N'Martinez',
            N'ROUTE_SALESPERSON'
        ),
        (
            N'vendedor.que01',
            N'vendedor.que01@distribuidora.example',
            N'Fernando',
            N'Ruiz',
            N'ROUTE_SALESPERSON'
        ),
        (
            N'credito.general',
            N'credito.general@distribuidora.example',
            N'Andrea',
            N'Morales',
            N'CREDIT_ANALYST'
        ),
        (
            N'compras.general',
            N'compras.general@distribuidora.example',
            N'Luis',
            N'Castillo',
            N'PURCHASING_MANAGER'
        ),
        (
            N'auditoria.inventario',
            N'auditoria.inventario@distribuidora.example',
            N'Patricia',
            N'Lopez',
            N'INVENTORY_AUDITOR'
        );

    IF EXISTS (
        SELECT 1
        FROM @usuarios AS u
        JOIN security.users AS su
            ON su.email = u.email
            AND su.username <> u.username
    )
        THROW 51003, 'Existe un correo de prueba asociado a otro nombre de usuario.', 1;

    INSERT INTO security.users (
        username,
        email,
        password_hash,
        first_name,
        last_name,
        is_active,
        created_at,
        updated_at
    )
    SELECT
        u.username,
        u.email,
        @hash,
        u.first_name,
        u.last_name,
        1,
        @fecha_inicio,
        NULL
    FROM @usuarios AS u
    WHERE NOT EXISTS (
        SELECT 1
        FROM security.users AS su
        WHERE su.username = u.username
    );

    INSERT INTO security.user_roles (
        user_id,
        role_id,
        created_at
    )
    SELECT
        su.user_id,
        sr.role_id,
        @fecha_inicio
    FROM @usuarios AS u
    JOIN security.users AS su
        ON su.username = u.username
    JOIN security.roles AS sr
        ON sr.code = u.role_code
    WHERE NOT EXISTS (
        SELECT 1
        FROM security.user_roles AS ur
        WHERE ur.user_id = su.user_id
          AND ur.role_id = sr.role_id
    );

    IF NOT EXISTS (
        SELECT 1
        FROM security.user_roles
        WHERE user_id = 1
          AND role_id = 1
    )
    BEGIN
        INSERT INTO security.user_roles (
            user_id,
            role_id,
            created_at
        )
        VALUES (
            1,
            1,
            @fecha_inicio
        );
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

SELECT
    r.role_id,
    r.code,
    r.name,
    COUNT(ur.user_id) AS assigned_users
FROM security.roles AS r
LEFT JOIN security.user_roles AS ur
    ON ur.role_id = r.role_id
WHERE r.role_id = 1
   OR r.code IN (
        N'WAREHOUSE_MANAGER',
        N'ROUTE_SALESPERSON',
        N'CREDIT_ANALYST',
        N'PURCHASING_MANAGER',
        N'INVENTORY_AUDITOR'
    )
GROUP BY
    r.role_id,
    r.code,
    r.name
ORDER BY
    r.role_id;

SELECT
    u.user_id,
    u.username,
    u.first_name,
    u.last_name,
    r.code AS role_code,
    u.is_active
FROM security.users AS u
JOIN security.user_roles AS ur
    ON ur.user_id = u.user_id
JOIN security.roles AS r
    ON r.role_id = ur.role_id
WHERE u.user_id = 1
   OR u.username IN (
        N'bodega.gua',
        N'bodega.chi',
        N'bodega.que',
        N'vendedor.gua01',
        N'vendedor.gua02',
        N'vendedor.chi01',
        N'vendedor.chi02',
        N'vendedor.que01',
        N'credito.general',
        N'compras.general',
        N'auditoria.inventario'
    )
ORDER BY
    u.user_id,
    r.role_id;
GO