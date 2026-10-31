IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'purchasing'
)
BEGIN
    EXEC('CREATE SCHEMA purchasing');
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
(NULL, 'PURCHASING', 'Compras', NULL, 'pi pi-shopping-cart',4, 1, SYSDATETIME(), NULL)
GO

select * from navigation.menu_items order by menu_item_id desc

CREATE TABLE purchasing.suppliers (
    supplier_id INT IDENTITY(1,1) NOT NULL,
    tax_id NVARCHAR(20) NOT NULL,
    business_name NVARCHAR(200) NOT NULL,
    contact_name NVARCHAR(150) NULL,
    phone NVARCHAR(30) NULL,
    email NVARCHAR(255) NULL,
    address NVARCHAR(300) NULL,
    credit_days INT NOT NULL,
    credit_limit DECIMAL(18,2) NOT NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT PK_suppliers
PRIMARY KEY (supplier_id);
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT UQ_suppliers_tax_id
UNIQUE (tax_id);
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT FK_suppliers_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT FK_suppliers_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT CK_suppliers_credit_days
CHECK (credit_days >= 0);
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT CK_suppliers_credit_limit
CHECK (credit_limit >= 0);
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT DF_suppliers_credit_days
DEFAULT (0) FOR credit_days;
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT DF_suppliers_credit_limit
DEFAULT (0) FOR credit_limit;
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT DF_suppliers_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE purchasing.suppliers
ADD CONSTRAINT DF_suppliers_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO


CREATE TABLE purchasing.product_suppliers (
    product_supplier_id INT IDENTITY(1,1) NOT NULL,
    product_id INT NOT NULL,
    supplier_id INT NOT NULL,
    is_preferred BIT NOT NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT PK_product_suppliers
PRIMARY KEY (product_supplier_id);
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT FK_product_suppliers_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT FK_product_suppliers_suppliers
FOREIGN KEY (supplier_id)
REFERENCES purchasing.suppliers(supplier_id);
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT FK_product_suppliers_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT FK_product_suppliers_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT UQ_product_suppliers_product_supplier
UNIQUE (product_id, supplier_id);
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT DF_product_suppliers_is_preferred
DEFAULT (0) FOR is_preferred;
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT DF_product_suppliers_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE purchasing.product_suppliers
ADD CONSTRAINT DF_product_suppliers_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_product_suppliers_preferred
ON purchasing.product_suppliers(product_id)
WHERE is_preferred = 1 AND is_active = 1;
GO

CREATE NONCLUSTERED INDEX IX_product_suppliers_supplier_id
ON purchasing.product_suppliers(supplier_id);
GO

CREATE TABLE purchasing.purchase_orders (
    purchase_order_id INT IDENTITY(1,1) NOT NULL,
    order_number NVARCHAR(50) NOT NULL,
    supplier_id INT NOT NULL,
    order_date DATETIME2(3) NOT NULL,
    expected_date DATE NULL,
    status NVARCHAR(20) NOT NULL,
    subtotal DECIMAL(18,2) NOT NULL,
    tax_amount DECIMAL(18,2) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    notes NVARCHAR(500) NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT PK_purchase_orders
PRIMARY KEY (purchase_order_id);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT UQ_purchase_orders_order_number
UNIQUE (order_number);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT FK_purchase_orders_suppliers
FOREIGN KEY (supplier_id)
REFERENCES purchasing.suppliers(supplier_id);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT FK_purchase_orders_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT FK_purchase_orders_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT CK_purchase_orders_status
CHECK (
    status IN (
        'DRAFT',
        'APPROVED',
        'PARTIALLY_RECEIVED',
        'RECEIVED',
        'CANCELLED'
    )
);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT CK_purchase_orders_amounts
CHECK (
    subtotal >= 0
    AND tax_amount >= 0
    AND total_amount = subtotal + tax_amount
);
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT DF_purchase_orders_status
DEFAULT ('DRAFT') FOR status;
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT DF_purchase_orders_order_date
DEFAULT (SYSUTCDATETIME()) FOR order_date;
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT DF_purchase_orders_subtotal
DEFAULT (0) FOR subtotal;
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT DF_purchase_orders_tax_amount
DEFAULT (0) FOR tax_amount;
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT DF_purchase_orders_total_amount
DEFAULT (0) FOR total_amount;
GO

ALTER TABLE purchasing.purchase_orders
ADD CONSTRAINT DF_purchase_orders_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_purchase_orders_supplier_date
ON purchasing.purchase_orders(supplier_id, order_date);
GO

CREATE TABLE purchasing.purchase_order_details (
    purchase_order_detail_id INT IDENTITY(1,1) NOT NULL,
    purchase_order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    unit_cost DECIMAL(18,4) NOT NULL,
    discount_amount DECIMAL(18,2) NOT NULL,
    subtotal DECIMAL(18,2) NOT NULL,
    tax_amount DECIMAL(18,2) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT PK_purchase_order_details
PRIMARY KEY (purchase_order_detail_id);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT FK_purchase_order_details_orders
FOREIGN KEY (purchase_order_id)
REFERENCES purchasing.purchase_orders(purchase_order_id);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT FK_purchase_order_details_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT FK_purchase_order_details_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT FK_purchase_order_details_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT UQ_purchase_order_details_order_product
UNIQUE (purchase_order_id, product_id);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT UQ_purchase_order_details_id_order
UNIQUE (purchase_order_detail_id, purchase_order_id);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT CK_purchase_order_details_quantity
CHECK (quantity > 0);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT CK_purchase_order_details_amounts
CHECK (
    unit_cost >= 0
    AND discount_amount >= 0
    AND subtotal >= 0
    AND tax_amount >= 0
    AND total_amount = subtotal + tax_amount
);
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT DF_purchase_order_details_discount
DEFAULT (0) FOR discount_amount;
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT DF_purchase_order_details_subtotal
DEFAULT (0) FOR subtotal;
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT DF_purchase_order_details_tax
DEFAULT (0) FOR tax_amount;
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT DF_purchase_order_details_total
DEFAULT (0) FOR total_amount;
GO

ALTER TABLE purchasing.purchase_order_details
ADD CONSTRAINT DF_purchase_order_details_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_purchase_order_details_product_id
ON purchasing.purchase_order_details(product_id);
GO

CREATE TABLE purchasing.goods_receipts (
    goods_receipt_id INT IDENTITY(1,1) NOT NULL,
    receipt_number NVARCHAR(50) NOT NULL,
    purchase_order_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    receipt_date DATETIME2(3) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    notes NVARCHAR(500) NULL,
    confirmed_at DATETIME2(3) NULL,
    confirmed_by INT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT PK_goods_receipts
PRIMARY KEY (goods_receipt_id);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT UQ_goods_receipts_number
UNIQUE (receipt_number);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT UQ_goods_receipts_id_order
UNIQUE (goods_receipt_id, purchase_order_id);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT FK_goods_receipts_purchase_orders
FOREIGN KEY (purchase_order_id)
REFERENCES purchasing.purchase_orders(purchase_order_id);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT FK_goods_receipts_warehouses
FOREIGN KEY (warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT FK_goods_receipts_confirmed_by
FOREIGN KEY (confirmed_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT FK_goods_receipts_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT FK_goods_receipts_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT CK_goods_receipts_status
CHECK (
    status IN (
        'DRAFT',
        'CONFIRMED',
        'CANCELLED'
    )
);
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT DF_goods_receipts_status
DEFAULT ('DRAFT') FOR status;
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT DF_goods_receipts_receipt_date
DEFAULT (SYSUTCDATETIME()) FOR receipt_date;
GO

ALTER TABLE purchasing.goods_receipts
ADD CONSTRAINT DF_goods_receipts_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_goods_receipts_purchase_order_id
ON purchasing.goods_receipts(purchase_order_id);
GO

CREATE NONCLUSTERED INDEX IX_goods_receipts_warehouse_date
ON purchasing.goods_receipts(warehouse_id, receipt_date);
GO

CREATE TABLE purchasing.goods_receipt_details (
    goods_receipt_detail_id INT IDENTITY(1,1) NOT NULL,
    goods_receipt_id INT NOT NULL,
    purchase_order_id INT NOT NULL,
    purchase_order_detail_id INT NOT NULL,
    batch_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_received DECIMAL(18,3) NOT NULL,
    unit_cost DECIMAL(18,4) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL
);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT PK_goods_receipt_details
PRIMARY KEY (goods_receipt_detail_id);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT FK_goods_receipt_details_receipts
FOREIGN KEY (goods_receipt_id, purchase_order_id)
REFERENCES purchasing.goods_receipts(
    goods_receipt_id,
    purchase_order_id
);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT FK_goods_receipt_details_order_details
FOREIGN KEY (purchase_order_detail_id, purchase_order_id)
REFERENCES purchasing.purchase_order_details(
    purchase_order_detail_id,
    purchase_order_id
);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT FK_goods_receipt_details_batches
FOREIGN KEY (batch_id, product_id)
REFERENCES inventory.product_batches(
    batch_id,
    product_id
);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT FK_goods_receipt_details_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT UQ_goods_receipt_details_receipt_order_batch
UNIQUE (
    goods_receipt_id,
    purchase_order_detail_id,
    batch_id
);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT CK_goods_receipt_details_quantity
CHECK (quantity_received > 0);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT CK_goods_receipt_details_unit_cost
CHECK (unit_cost >= 0);
GO

ALTER TABLE purchasing.goods_receipt_details
ADD CONSTRAINT DF_goods_receipt_details_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_goods_receipt_details_order_detail
ON purchasing.goods_receipt_details(purchase_order_detail_id);
GO

CREATE NONCLUSTERED INDEX IX_goods_receipt_details_batch_id
ON purchasing.goods_receipt_details(batch_id);
GO

CREATE TABLE purchasing.supplier_invoices (
    supplier_invoice_id INT IDENTITY(1,1) NOT NULL,
    supplier_id INT NOT NULL,
    purchase_order_id INT NOT NULL,
    invoice_number NVARCHAR(50) NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(18,2) NOT NULL,
    tax_amount DECIMAL(18,2) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    notes NVARCHAR(500) NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT PK_supplier_invoices
PRIMARY KEY (supplier_invoice_id);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT UQ_supplier_invoices_supplier_number
UNIQUE (supplier_id, invoice_number);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT FK_supplier_invoices_suppliers
FOREIGN KEY (supplier_id)
REFERENCES purchasing.suppliers(supplier_id);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT FK_supplier_invoices_purchase_orders
FOREIGN KEY (purchase_order_id)
REFERENCES purchasing.purchase_orders(purchase_order_id);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT FK_supplier_invoices_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT FK_supplier_invoices_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT CK_supplier_invoices_dates
CHECK (due_date >= invoice_date);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT CK_supplier_invoices_amounts
CHECK (
    subtotal >= 0
    AND tax_amount >= 0
    AND total_amount = subtotal + tax_amount
);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT CK_supplier_invoices_status
CHECK (
    status IN (
        'REGISTERED',
        'CANCELLED'
    )
);
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT DF_supplier_invoices_status
DEFAULT ('REGISTERED') FOR status;
GO

ALTER TABLE purchasing.supplier_invoices
ADD CONSTRAINT DF_supplier_invoices_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_supplier_invoices_purchase_order_id
ON purchasing.supplier_invoices(purchase_order_id);
GO

CREATE NONCLUSTERED INDEX IX_supplier_invoices_due_date
ON purchasing.supplier_invoices(due_date);
GO