IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'logistics'
)
BEGIN
    EXEC('CREATE SCHEMA logistics');
END;
GO

CREATE TABLE logistics.warehouse_transfers (
    warehouse_transfer_id INT IDENTITY(1,1) NOT NULL,
    transfer_number NVARCHAR(50) NOT NULL,
    source_warehouse_id INT NOT NULL,
    destination_warehouse_id INT NOT NULL,
    transfer_date DATETIME2(3) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    dispatched_at DATETIME2(3) NULL,
    dispatched_by INT NULL,
    received_at DATETIME2(3) NULL,
    received_by INT NULL,
    notes NVARCHAR(500) NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT PK_warehouse_transfers
PRIMARY KEY (warehouse_transfer_id);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT UQ_warehouse_transfers_number
UNIQUE (transfer_number);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT FK_warehouse_transfers_source_warehouse
FOREIGN KEY (source_warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT FK_warehouse_transfers_destination_warehouse
FOREIGN KEY (destination_warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT FK_warehouse_transfers_dispatched_by
FOREIGN KEY (dispatched_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT FK_warehouse_transfers_received_by
FOREIGN KEY (received_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT FK_warehouse_transfers_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT FK_warehouse_transfers_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT CK_warehouse_transfers_different_warehouses
CHECK (
    source_warehouse_id <> destination_warehouse_id
);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT CK_warehouse_transfers_status
CHECK (
    status IN (
        'DRAFT',
        'IN_TRANSIT',
        'RECEIVED',
        'CANCELLED'
    )
);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT CK_warehouse_transfers_dates
CHECK (
    (dispatched_at IS NULL OR dispatched_at >= transfer_date)
    AND
    (
        received_at IS NULL
        OR (
            dispatched_at IS NOT NULL
            AND received_at >= dispatched_at
        )
    )
);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT CK_warehouse_transfers_status_dates
CHECK (
    status NOT IN ('IN_TRANSIT', 'RECEIVED')
    OR dispatched_at IS NOT NULL
);
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT DF_warehouse_transfers_status
DEFAULT ('DRAFT') FOR status;
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT DF_warehouse_transfers_transfer_date
DEFAULT (SYSUTCDATETIME()) FOR transfer_date;
GO

ALTER TABLE logistics.warehouse_transfers
ADD CONSTRAINT DF_warehouse_transfers_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_warehouse_transfers_status_dispatched
ON logistics.warehouse_transfers(
    status,
    dispatched_at
);
GO

CREATE NONCLUSTERED INDEX IX_warehouse_transfers_source
ON logistics.warehouse_transfers(source_warehouse_id);
GO

CREATE NONCLUSTERED INDEX IX_warehouse_transfers_destination
ON logistics.warehouse_transfers(destination_warehouse_id);
GO


CREATE TABLE logistics.warehouse_transfer_details (
    warehouse_transfer_detail_id INT IDENTITY(1,1) NOT NULL,
    warehouse_transfer_id INT NOT NULL,
    product_id INT NOT NULL,
    batch_id INT NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    unit_cost DECIMAL(18,4) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL
);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT PK_warehouse_transfer_details
PRIMARY KEY (warehouse_transfer_detail_id);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT FK_warehouse_transfer_details_transfers
FOREIGN KEY (warehouse_transfer_id)
REFERENCES logistics.warehouse_transfers(warehouse_transfer_id);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT FK_warehouse_transfer_details_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT FK_warehouse_transfer_details_batches
FOREIGN KEY (batch_id, product_id)
REFERENCES inventory.product_batches(
    batch_id,
    product_id
);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT FK_warehouse_transfer_details_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT UQ_warehouse_transfer_details_transfer_batch
UNIQUE (warehouse_transfer_id, batch_id);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT CK_warehouse_transfer_details_quantity
CHECK (quantity > 0);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT CK_warehouse_transfer_details_unit_cost
CHECK (unit_cost >= 0);
GO

ALTER TABLE logistics.warehouse_transfer_details
ADD CONSTRAINT DF_warehouse_transfer_details_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_warehouse_transfer_details_product
ON logistics.warehouse_transfer_details(product_id);
GO

CREATE NONCLUSTERED INDEX IX_warehouse_transfer_details_batch
ON logistics.warehouse_transfer_details(batch_id);
GO