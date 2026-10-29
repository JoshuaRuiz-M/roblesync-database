
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('BRAND_READ', 'Consultar marca', 'Permite consultar las marca del sistema.', 1),
    ('BRAND_CREATE', 'Crear marca', 'Permite registrar nuevas marca.', 1),
    ('BRAND_UPDATE', 'Actualizar marca', 'Permite modificar las marcas del sistema.', 1),
    ('BRAND_DELETE', 'Eliminar marca', 'Permite eliminar marcas del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'BRAND_%';

INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 24), (1, 25), (1, 26), (1, 27);
