
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('CATEGORY_READ', 'Consultar categoría', 'Permite consultar las categorías del sistema.', 1),
    ('CATEGORY_CREATE', 'Crear categoría', 'Permite registrar nuevas categorías.', 1),
    ('CATEGORY_UPDATE', 'Actualizar categoría', 'Permite modificar las categorías del sistema.', 1),
    ('CATEGORY_DELETE', 'Eliminar categoría', 'Permite eliminar categorías del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'CATEGORY_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 28), (1, 29), (1, 30), (1, 31);


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
(2, 'CATEGORIES', 'Categorías', '/categories', 'pi pi-th-large', 2, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc

INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 9);