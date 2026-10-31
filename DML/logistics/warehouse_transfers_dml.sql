
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('WAREHOUSE_TRANSFERS_READ', 'Consultar transferencias de almacén', 'Permite consultar las transferencias de almacén del sistema.', 1),
    ('WAREHOUSE_TRANSFERS_CREATE', 'Crear transferencia de almacén', 'Permite registrar nuevas transferencias de almacén.', 1),
    ('WAREHOUSE_TRANSFERS_UPDATE', 'Actualizar transferencia de almacén', 'Permite modificar las transferencias de almacén del sistema.', 1),
    ('WAREHOUSE_TRANSFERS_DISPATCH', 'Despachar transferencia de almacén', 'Permite despachar transferencias de almacén.', 1),
    ('WAREHOUSE_TRANSFERS_RECEIVE', 'Recibir transferencia de almacén', 'Permite recibir transferencias de almacén.', 1),
    ('WAREHOUSE_TRANSFERS_CANCEL', 'Cancelar transferencia de almacén', 'Permite cancelar transferencias de almacén.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'WAREHOUSE_TRANSFERS_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 92), (1, 93), (1, 94), (1, 95), (1, 96), (1, 97);


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
(NULL, 'LOGISTICS', 'Logística', NULL, 'pi pi-truck', 1, 1, SYSDATETIME(), NULL)


select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES(1, 31);


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
(31, 'WAREHOUSE_TRANSFERS', 'Transferencias de Almacén', '/warehouse-transfers', 'pi pi-exchange', 1, 1, SYSDATETIME(), NULL)


select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES (1, 32);