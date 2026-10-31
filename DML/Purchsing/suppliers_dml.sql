
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('SUPPLIER_READ', 'Consultar proveedores', 'Permite consultar los proveedores del sistema.', 1),
    ('SUPPLIER_CREATE', 'Crear proveedor', 'Permite registrar nuevos proveedores.', 1),
    ('SUPPLIER_UPDATE', 'Actualizar proveedor', 'Permite modificar los proveedores del sistema.', 1),
    ('SUPPLIER_DELETE', 'Eliminar proveedor', 'Permite eliminar proveedores del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'SUPPLIER_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 24), (1, 25), (1, 26), (1, 27);
GO


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
(NULL, 'PURCHASING', 'Compras', NULL, 'pi pi-shopping-cart', 1, 1, SYSDATETIME(), NULL)
GO

INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 13);

SELECT * FROM navigation.menu_items ORDER BY menu_item_id DESC
GO

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
(13, 'SUPPLIERS', 'Proveedores', '/suppliers', 'pi pi-truck', 1, 1, SYSDATETIME(), NULL)
GO

INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 14);