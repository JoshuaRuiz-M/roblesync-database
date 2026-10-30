
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('CUSTOMER_READ', 'Consultar cliente', 'Permite consultar los clientes del sistema.', 1),
    ('CUSTOMER_CREATE', 'Crear cliente', 'Permite registrar nuevos clientes.', 1),
    ('CUSTOMER_UPDATE', 'Actualizar cliente', 'Permite modificar los clientes del sistema.', 1),
    ('CUSTOMER_DELETE', 'Eliminar cliente', 'Permite eliminar clientes del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'CUSTOMER_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 61), (1, 62), (1, 63), (1, 60);


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
(2, 'CUSTOMERS', 'Clientes', '/customers', 'pi pi-user', 1, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 8);