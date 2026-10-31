
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('PURCHASE_ORDER_READ', 'Consultar ordenes de compra', 'Permite consultar las ordenes de compra del sistema.', 1),
    ('PURCHASE_ORDER_CREATE', 'Crear orden de compra', 'Permite registrar nuevas ordenes de compra.', 1),
    ('PURCHASE_ORDER_UPDATE', 'Actualizar orden de compra', 'Permite modificar las ordenes de compra del sistema.', 1),
    ('PURCHASE_ORDER_APPROVE', 'Aprobar orden de compra', 'Permite aprobar las ordenes de compra del sistema.', 1),
    ('PURCHASE_ORDER_CANCEL', 'Cancelar orden de compra', 'Permite cancelar las ordenes de compra del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'PURCHASE_ORDER_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 50), (1, 51), (1, 52), (1, 53), (1, 54);
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
(13, 'PURCHASE_ORDERS', 'Ordenes de Compra', '/purchase-orders', 'pi pi-shopping-cart', 1, 1, SYSDATETIME(), NULL)


SELECT * FROM navigation.menu_items ORDER BY menu_item_id DESC


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 20);