
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('PRODUCT_READ', 'Consultar producto', 'Permite consultar los productos del sistema.', 1),
    ('PRODUCT_CREATE', 'Crear producto', 'Permite registrar nuevos productos.', 1),
    ('PRODUCT_UPDATE', 'Actualizar producto', 'Permite modificar los productos del sistema.', 1),
    ('PRODUCT_DELETE', 'Eliminar producto', 'Permite eliminar productos del sistema.', 1),
    ('PRODUCT_SUPPLIER_READ', 'Consultar proveedor de producto', 'Permite consultar los proveedores de productos del sistema.', 1),
    ('PRODUCT_SUPPLIER_MANAGE', 'Gestionar proveedor de producto', 'Permite gestionar los proveedores de productos del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'PRODUCT_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 40), (1, 41), (1, 42), (1, 43), (1, 44), (1, 45);


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
(2, 'PRODUCTS', 'Productos', '/products', 'pi pi-box', 4, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 12);