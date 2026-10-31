
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('ANALYTICS_KARDEX_READ', 'Consultar kardex', 'Permite consultar el kardex de los productos.', 1),
    ('ANALYTICS_DASHBOARD_READ', 'Consultar dashboard', 'Permite consultar el dashboard del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'ANALYTICS_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 102), (1, 103);


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
(NULL, 'ANALYTICS', 'Analíticas', NULL, 'pi pi-chart-line', 1, 1, SYSDATETIME(), NULL)

select * from navigation.menu_items order by menu_item_id desc

INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 34);


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
(34, 'ANALYTICS_KARDEX', 'Kardex', '/analytics/kardex', 'pi pi-book', 1, 1, SYSDATETIME(), NULL)


select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 35);


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
(34, 'ANALYTICS_DASHBOARD', 'Dashboard', '/analytics/dashboard', 'pi pi-chart-bar', 1, 1, SYSDATETIME(), NULL)


select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 36);