INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('SALES_INVOICE_READ', 'Consultar facturas de venta', 'Permite consultar las facturas de venta del sistema.', 1),
    ('SALES_INVOICE_CREATE', 'Crear factura de venta', 'Permite registrar nuevas facturas de venta.', 1),
    ('SALES_INVOICE_CANCEL', 'Cancelar factura de venta', 'Permite cancelar facturas de venta.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'SALES_INVOICE_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 89), (1, 90), (1, 91);


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
(23, 'SALES_INVOICES', 'Facturas de Venta', '/sales-invoices', 'pi pi-receipt', 3, 1, SYSDATETIME(), NULL)


SELECT * FROM navigation.menu_items ORDER BY menu_item_id DESC


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 30);