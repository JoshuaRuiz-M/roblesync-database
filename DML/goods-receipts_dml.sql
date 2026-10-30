INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('GOODS_RECEIPT_READ', 'Consultar recepcion de mercancías', 'Permite consultar las recepción de mercancías del sistema.', 1),
    ('GOODS_RECEIPT_CREATE', 'Crear recepción de mercancías', 'Permite registrar nuevas recepción de mercancías.', 1),
    ('GOODS_RECEIPT_UPDATE', 'Actualizar recepción de mercancías', 'Permite modificar las recepción de mercancías del sistema.', 1),
    ('GOODS_RECEIPT_CONFIRM', 'Aprobar recepción de mercancías', 'Permite aprobar las recepción de mercancías del sistema.', 1),
    ('GOODS_RECEIPT_CANCEL', 'Cancelar recepción de mercancías', 'Permite cancelar las recepción de mercancías del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'GOODS_RECEIPT_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 55), (1, 56), (1, 57), (1, 58), (1, 59);
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
(13, 'GOODS_RECEIPTS', 'Recepción de Mercancías', '/goods-receipts', 'pi pi-truck', 1, 1, SYSDATETIME(), NULL)


SELECT * FROM navigation.menu_items ORDER BY menu_item_id DESC


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 21);