
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('WAREHOUSE_READ', 'Consultar almacén', 'Permite consultar los almacenes del sistema.', 1),
    ('WAREHOUSE_CREATE', 'Crear almacén', 'Permite registrar nuevos almacenes.', 1),
    ('WAREHOUSE_UPDATE', 'Actualizar almacén', 'Permite modificar los almacenes del sistema.', 1),
    ('WAREHOUSE_DELETE', 'Eliminar almacén', 'Permite eliminar almacenes del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'WAREHOUSE_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 45), (1, 46), (1, 47), (1, 48);


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
(2, 'WAREHOUSES', 'Almacenes', '/warehouses', 'pi pi-warehouse', 2, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES(13, 11), (1, 11);