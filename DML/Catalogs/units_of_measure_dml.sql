
INSERT INTO security.permissions (
    code,
    name,
    description,
    is_active
)
VALUES
    ('UNIT_OF_MEASURE_READ', 'Consultar unidad de medida', 'Permite consultar las unidades de medida del sistema.', 1),
    ('UNIT_OF_MEASURE_CREATE', 'Crear unidad de medida', 'Permite registrar nuevas unidades de medida.', 1),
    ('UNIT_OF_MEASURE_UPDATE', 'Actualizar unidad de medida', 'Permite modificar las unidades de medida del sistema.', 1),
    ('UNIT_OF_MEASURE_DELETE', 'Eliminar unidad de medida', 'Permite eliminar unidades de medida del sistema.', 1);

SELECT * FROM security.permissions
WHERE code LIKE 'UNIT_OF_MEASURE_%';


INSERT INTO security.role_permissions (
    role_id,
    permission_id
)
VALUES (1, 36), (1, 37), (1, 38), (1, 39);


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
(2, 'UNIT_OF_MEASURE', 'Unidades de Medida', '/units-of-measure', 'pi pi-ruler', 5, 1, SYSDATETIME(), NULL)
GO


select * from navigation.menu_items order by menu_item_id desc


INSERT INTO navigation.role_menu_items (role_id, menu_item_id)
VALUES
(1, 11);