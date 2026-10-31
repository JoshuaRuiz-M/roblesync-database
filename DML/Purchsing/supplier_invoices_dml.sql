
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('SUPPLIER_INVOICE_READ', 'Consultar facturas de proveedores', 'Permite consultar las facturas de los proveedores del sistema.', 1),
    ('SUPPLIER_INVOICE_CREATE', 'Crear factura de proveedor', 'Permite registrar nuevas facturas de proveedores.', 1),
    ('SUPPLIER_INVOICE_UPDATE', 'Actualizar factura de proveedor', 'Permite modificar las facturas de proveedores del sistema.', 1),
    ('SUPPLIER_INVOICE_DELETE', 'Eliminar factura de proveedor', 'Permite eliminar facturas de proveedores del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'SUPPLIER_INVOICE_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 64), (1, 65), (1, 66), (1, 67);



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
(13, 'SUPPLIERS_INVOICES', 'Facturas de Proveedores', '/suppliers-invoices', 'pi pi-file-invoice', 1, 1, SYSDATETIME(), NULL);

SELECT * FROM navigation.menu_items ORDER BY menu_item_id DESC;

INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 22);