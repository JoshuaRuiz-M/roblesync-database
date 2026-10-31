
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('PRODUCT_LINE_READ', 'Consultar línea de producto', 'Permite consultar las líneas de producto del sistema.', 1),
    ('PRODUCT_LINE_CREATE', 'Crear línea de producto', 'Permite registrar nuevas líneas de producto.', 1),
    ('PRODUCT_LINE_UPDATE', 'Actualizar línea de producto', 'Permite modificar las líneas de producto del sistema.', 1),
    ('PRODUCT_LINE_DELETE', 'Eliminar línea de producto', 'Permite eliminar líneas de producto del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'PRODUCT_LINE_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 32), (1, 33), (1, 34), (1, 35);


INSERT INTO navigation.menu_items (
    parent_id,
    code,
    label,
    path,
    icon,
    sort_order,
    is_active,
    created_at,
    updated_at
)
VALUES
(2, 'PRODUCT_LINES', 'Líneas de producto', '/product-lines', 'pi pi-sitemap', 3, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc

INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 10);