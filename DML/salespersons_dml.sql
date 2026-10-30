
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('SALESPERSON_READ', 'Consultar vendedor', 'Permite consultar los vendedores del sistema.', 1),
    ('SALESPERSON_CREATE', 'Crear vendedor', 'Permite registrar nuevos vendedores.', 1),
    ('SALESPERSON_UPDATE', 'Actualizar vendedor', 'Permite modificar los vendedores del sistema.', 1),
    ('SALESPERSON_DELETE', 'Eliminar vendedor', 'Permite eliminar vendedores del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'SALESPERSON_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 57), (1, 58), (1, 59), (1, 60);


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
(2, 'SALESPERSONS', 'Vendedores', '/salespersons', 'pi pi-user', 1, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 8);