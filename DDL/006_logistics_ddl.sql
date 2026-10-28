IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'logistics'
)
BEGIN
    EXEC('CREATE SCHEMA logistics');
END;
GO

CREATE TABLE logistics.shipments (
    shipment_id BIGINT IDENTITY(1,1) NOT NULL,
    shipment_number NVARCHAR(50) NOT NULL,
    sales_order_id BIGINT NOT NULL,
    sales_invoice_id BIGINT NOT NULL,
    warehouse_id INT NOT NULL,
    shipment_date DATETIME2(3) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    dispatched_at DATETIME2(3) NULL,
    dispatched_by INT NULL,
    delivered_at DATETIME2(3) NULL,
    notes NVARCHAR(500) NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT PK_shipments
PRIMARY KEY (shipment_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT UQ_shipments_number
UNIQUE (shipment_number);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT UQ_shipments_sales_order
UNIQUE (sales_order_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT UQ_shipments_sales_invoice
UNIQUE (sales_invoice_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT FK_shipments_sales_orders
FOREIGN KEY (sales_order_id)
REFERENCES sales.sales_orders(sales_order_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT FK_shipments_sales_invoices
FOREIGN KEY (sales_invoice_id)
REFERENCES sales.sales_invoices(sales_invoice_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT FK_shipments_warehouses
FOREIGN KEY (warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT FK_shipments_dispatched_by
FOREIGN KEY (dispatched_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT FK_shipments_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT FK_shipments_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT CK_shipments_status
CHECK (
    status IN (
        'PENDING',
        'DISPATCHED',
        'DELIVERED',
        'CANCELLED'
    )
);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT CK_shipments_dates
CHECK (
    (dispatched_at IS NULL OR dispatched_at >= shipment_date)
    AND
    (
        delivered_at IS NULL
        OR (
            dispatched_at IS NOT NULL
            AND delivered_at >= dispatched_at
        )
    )
);
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT DF_shipments_status
DEFAULT ('PENDING') FOR status;
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT DF_shipments_shipment_date
DEFAULT (SYSUTCDATETIME()) FOR shipment_date;
GO

ALTER TABLE logistics.shipments
ADD CONSTRAINT DF_shipments_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_shipments_status_date
ON logistics.shipments(status, shipment_date);
GO

CREATE TABLE logistics.warehouse_transfers (
    warehouse_transfer_id BIGINT IDENTITY(1,1) NOT NULL,
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
    warehouse_transfer_detail_id BIGINT IDENTITY(1,1) NOT NULL,
    warehouse_transfer_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    batch_id BIGINT NOT NULL,
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