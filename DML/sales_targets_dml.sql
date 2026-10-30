
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('SALESTARGET_READ', 'Consultar objetivos de ventas', 'Permite consultar los objetivos de ventas de los vendedores del sistema.', 1),
    ('SALESTARGET_CREATE', 'Crear objetivo de venta', 'Permite registrar nuevos objetivos de ventas.', 1),
    ('SALESTARGET_UPDATE', 'Actualizar objetivo de venta', 'Permite modificar los objetivos de ventas de los vendedores del sistema.', 1),
    ('SALESTARGET_DELETE', 'Eliminar objetivo de venta', 'Permite eliminar objetivos de ventas de los vendedores del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'SALESTARGET_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 65), (1, 66), (1, 67), (1, 68);


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
(2, 'SALESTARGETS', 'Objetivos de Ventas', '/sales-targets', 'pi pi-chart-bar', 1, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 8);