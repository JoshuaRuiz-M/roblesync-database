IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'inventory'
)
BEGIN
    EXEC('CREATE SCHEMA inventory');
END;
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
(NULL, 'INVENTORY', 'Inventario', NULL, 'pi pi-box', 1, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc

CREATE TABLE inventory.warehouses (
    warehouse_id INT IDENTITY(1,1) NOT NULL,
    code NVARCHAR(50) NOT NULL,
    name NVARCHAR(150) NOT NULL,
    description NVARCHAR(500) NULL,
    address NVARCHAR(300) NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE inventory.warehouses
ADD CONSTRAINT PK_warehouses
PRIMARY KEY (warehouse_id);
GO

ALTER TABLE inventory.warehouses
ADD CONSTRAINT UQ_warehouses_code
UNIQUE (code);
GO

ALTER TABLE inventory.warehouses
ADD CONSTRAINT FK_warehouses_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE inventory.warehouses
ADD CONSTRAINT FK_warehouses_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE inventory.warehouses
ADD CONSTRAINT DF_warehouses_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE inventory.warehouses
ADD CONSTRAINT DF_warehouses_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE TABLE inventory.product_batches (
    batch_id INT IDENTITY(1,1) NOT NULL,
    product_id INT NOT NULL,
    batch_number NVARCHAR(100) NOT NULL,
    manufacturing_date DATE NULL,
    expiration_date DATE NULL,
    received_at DATETIME2(3) NOT NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT PK_product_batches
PRIMARY KEY (batch_id);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT FK_product_batches_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT FK_product_batches_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT FK_product_batches_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT UQ_product_batches_product_number
UNIQUE (product_id, batch_number);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT UQ_product_batches_batch_product
UNIQUE (batch_id, product_id);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT CK_product_batches_dates
CHECK (
    manufacturing_date IS NULL
    OR expiration_date IS NULL
    OR manufacturing_date <= expiration_date
);
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT DF_product_batches_received_at
DEFAULT (SYSUTCDATETIME()) FOR received_at;
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT DF_product_batches_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE inventory.product_batches
ADD CONSTRAINT DF_product_batches_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_product_batches_expiration_date
ON inventory.product_batches(expiration_date);
GO

CREATE TABLE inventory.warehouse_stock (
    warehouse_stock_id INT IDENTITY(1,1) NOT NULL,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_on_hand DECIMAL(18,3) NOT NULL,
    quantity_reserved DECIMAL(18,3) NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT PK_warehouse_stock
PRIMARY KEY (warehouse_stock_id);
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT FK_warehouse_stock_warehouses
FOREIGN KEY (warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT FK_warehouse_stock_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT FK_warehouse_stock_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT UQ_warehouse_stock_warehouse_product
UNIQUE (warehouse_id, product_id);
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT CK_warehouse_stock_quantities
CHECK (
    quantity_on_hand >= 0
    AND quantity_reserved >= 0
    AND quantity_reserved <= quantity_on_hand
);
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT DF_warehouse_stock_quantity_on_hand
DEFAULT (0) FOR quantity_on_hand;
GO

ALTER TABLE inventory.warehouse_stock
ADD CONSTRAINT DF_warehouse_stock_quantity_reserved
DEFAULT (0) FOR quantity_reserved;
GO

CREATE NONCLUSTERED INDEX IX_warehouse_stock_product_id
ON inventory.warehouse_stock(product_id);
GO

CREATE TABLE inventory.batch_stock (
    batch_stock_id INT IDENTITY(1,1) NOT NULL,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    batch_id INT NOT NULL,
    quantity_on_hand DECIMAL(18,3) NOT NULL,
    quantity_reserved DECIMAL(18,3) NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT PK_batch_stock
PRIMARY KEY (batch_stock_id);
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT FK_batch_stock_warehouses
FOREIGN KEY (warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT FK_batch_stock_batches
FOREIGN KEY (batch_id, product_id)
REFERENCES inventory.product_batches(batch_id, product_id);
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT FK_batch_stock_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT UQ_batch_stock_warehouse_batch
UNIQUE (warehouse_id, batch_id);
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT CK_batch_stock_quantities
CHECK (
    quantity_on_hand >= 0
    AND quantity_reserved >= 0
    AND quantity_reserved <= quantity_on_hand
);
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT DF_batch_stock_quantity_on_hand
DEFAULT (0) FOR quantity_on_hand;
GO

ALTER TABLE inventory.batch_stock
ADD CONSTRAINT DF_batch_stock_quantity_reserved
DEFAULT (0) FOR quantity_reserved;
GO

CREATE NONCLUSTERED INDEX IX_batch_stock_product_warehouse
ON inventory.batch_stock(product_id, warehouse_id);
GO


CREATE TABLE inventory.inventory_movements (
    inventory_movement_id INT IDENTITY(1,1) NOT NULL,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    batch_id INT NULL,
    movement_type NVARCHAR(30) NOT NULL,
    movement_date DATETIME2(3) NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    unit_cost DECIMAL(18,4) NOT NULL,
    total_cost DECIMAL(19,4) NOT NULL,
    balance_quantity DECIMAL(18,3) NOT NULL,
    balance_value DECIMAL(19,4) NOT NULL,
    reference_type NVARCHAR(50) NULL,
    reference_id INT NULL,
    notes NVARCHAR(500) NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL
);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT PK_inventory_movements
PRIMARY KEY (inventory_movement_id);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT FK_inventory_movements_warehouses
FOREIGN KEY (warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT FK_inventory_movements_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT FK_inventory_movements_batches
FOREIGN KEY (batch_id, product_id)
REFERENCES inventory.product_batches(batch_id, product_id);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT FK_inventory_movements_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT CK_inventory_movements_type
CHECK (
    movement_type IN (
        'PURCHASE_RECEIPT',
        'SALE_DISPATCH',
        'TRANSFER_IN',
        'TRANSFER_OUT',
        'ADJUSTMENT_IN',
        'ADJUSTMENT_OUT',
        'RETURN_IN',
        'RETURN_OUT'
    )
);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT CK_inventory_movements_quantity
CHECK (
    (movement_type IN (
        'PURCHASE_RECEIPT',
        'TRANSFER_IN',
        'ADJUSTMENT_IN',
        'RETURN_IN'
    ) AND quantity > 0)
    OR
    (movement_type IN (
        'SALE_DISPATCH',
        'TRANSFER_OUT',
        'ADJUSTMENT_OUT',
        'RETURN_OUT'
    ) AND quantity < 0)
);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT CK_inventory_movements_cost
CHECK (
    unit_cost >= 0
    AND total_cost = ROUND(quantity * unit_cost, 4)
    AND balance_quantity >= 0
    AND balance_value >= 0
);
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT DF_inventory_movements_movement_date
DEFAULT (SYSUTCDATETIME()) FOR movement_date;
GO

ALTER TABLE inventory.inventory_movements
ADD CONSTRAINT DF_inventory_movements_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_inventory_movements_product_date
ON inventory.inventory_movements(
    product_id,
    movement_date,
    inventory_movement_id
);
GO

CREATE NONCLUSTERED INDEX IX_inventory_movements_warehouse_product_date
ON inventory.inventory_movements(
    warehouse_id,
    product_id,
    movement_date
);
GO