
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('INVENTORY_MOVEMENT_READ', 'Consultar movimiento de inventario', 'Permite consultar los movimientos de inventario del sistema.', 1),
    ('INVENTORY_MOVEMENT_CREATE', 'Crear movimiento de inventario', 'Permite registrar nuevos movimientos de inventario.', 1),
    ('INVENTORY_MOVEMENT_UPDATE', 'Actualizar movimiento de inventario', 'Permite modificar los movimientos de inventario del sistema.', 1),
    ('INVENTORY_MOVEMENT_DELETE', 'Eliminar movimiento de inventario', 'Permite eliminar movimientos de inventario del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'INVENTORY_MOVEMENT_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 53), (1, 54), (1, 55), (1, 56);


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
(2, 'INVENTORY_MOVEMENTS', 'Movimientos de inventario', '/inventory-movements', 'pi pi-arrow-right-arrow-left', 1, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc

INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 10);