
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('SALES_ORDER_READ', 'Consultar órdenes de venta', 'Permite consultar las órdenes de venta del sistema.', 1),
    ('SALES_ORDER_CREATE', 'Crear orden de venta', 'Permite registrar nuevas órdenes de venta.', 1),
    ('SALES_ORDER_UPDATE', 'Actualizar orden de venta', 'Permite modificar las órdenes de venta del sistema.', 1),
    ('SALES_ORDER_SUBMIT', 'Enviar orden de venta', 'Permite enviar órdenes de venta para su procesamiento.', 1),
    ('SALES_ORDER_APPROVE', 'Aprobar orden de venta', 'Permite aprobar órdenes de venta.', 1),
    ('SALES_ORDER_RESERVE', 'Reservar orden de venta', 'Permite reservar órdenes de venta.', 1),
    ('SALES_ORDER_CANCEL', 'Cancelar orden de venta', 'Permite cancelar órdenes de venta.', 1),
    ('SALES_ORDER_CREDIT_APPROVE', 'Aprobar crédito para orden de venta', 'Permite aprobar créditos para órdenes de venta.', 1),
    ('SALES_ORDER_CREDIT_REJECT', 'Rechazar crédito para orden de venta', 'Permite rechazar créditos para órdenes de venta.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'SALES_ORDER_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 72), (1, 73), (1, 74), (1, 75), (1, 76), (1, 77), (1, 78), (1, 79), (1, 80);


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
(23, 'SALES_ORDERS', 'Órdenes de Venta', '/sales-orders', 'pi pi-shopping-cart', 1, 1, SYSDATETIME(), NULL)


select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 27);