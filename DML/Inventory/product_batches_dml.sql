
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('PRODUCT_BATCH_READ', 'Consultar lote de producto', 'Permite consultar las líneas de producto del sistema.', 1),
    ('PRODUCT_BATCH_CREATE', 'Crear lote de producto', 'Permite registrar nuevos lotes de producto.', 1),
    ('PRODUCT_BATCH_UPDATE', 'Actualizar lote de producto', 'Permite modificar los lotes de producto del sistema.', 1),
    ('PRODUCT_BATCH_DELETE', 'Eliminar lote de producto', 'Permite eliminar lotes de producto del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'PRODUCT_BATCH_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1,49), (1, 50), (1, 51), (1, 52);


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
(2, 'PRODUCT_BATCHES', 'Lotes de producto', '/product-batches', 'pi pi-tag', 1, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 15);