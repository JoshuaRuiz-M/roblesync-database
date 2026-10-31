INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('PRICE_LIST_READ', 'Consultar listas de precios', 'Permite consultar las listas de precios del sistema.', 1),
    ('PRICE_LIST_CREATE', 'Crear lista de precios', 'Permite registrar nuevas listas de precios.', 1),
    ('PRICE_LIST_UPDATE', 'Actualizar lista de precios', 'Permite modificar las listas de precios del sistema.', 1),
    ('PRICE_LIST_DELETE', 'Eliminar lista de precios', 'Permite eliminar las listas de precios del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'PRICE_LIST_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 68), (1, 69), (1, 70), (1, 71);


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
(23, 'PRICE_LISTS', 'Listas de Precios', '/price-lists', 'pi pi-tag', 1, 1, SYSDATETIME(), NULL)


SELECT * FROM navigation.menu_items ORDER BY menu_item_id DESC


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 24);


