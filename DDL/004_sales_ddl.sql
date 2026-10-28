IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'sales'
)
BEGIN
    EXEC('CREATE SCHEMA sales');
END;
GO

CREATE TABLE sales.price_lists (
    price_list_id INT IDENTITY(1,1) NOT NULL,
    code NVARCHAR(50) NOT NULL,
    name NVARCHAR(150) NOT NULL,
    description NVARCHAR(500) NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE sales.price_lists
ADD CONSTRAINT PK_price_lists
PRIMARY KEY (price_list_id);
GO

ALTER TABLE sales.price_lists
ADD CONSTRAINT UQ_price_lists_code
UNIQUE (code);
GO

ALTER TABLE sales.price_lists
ADD CONSTRAINT FK_price_lists_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.price_lists
ADD CONSTRAINT FK_price_lists_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.price_lists
ADD CONSTRAINT DF_price_lists_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE sales.price_lists
ADD CONSTRAINT DF_price_lists_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE TABLE sales.price_list_details (
    price_list_detail_id INT IDENTITY(1,1) NOT NULL,
    price_list_id INT NOT NULL,
    product_id INT NOT NULL,
    unit_price DECIMAL(18,4) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT PK_price_list_details
PRIMARY KEY (price_list_detail_id);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT FK_price_list_details_price_lists
FOREIGN KEY (price_list_id)
REFERENCES sales.price_lists(price_list_id);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT FK_price_list_details_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT FK_price_list_details_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT FK_price_list_details_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT UQ_price_list_details_list_product
UNIQUE (price_list_id, product_id);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT CK_price_list_details_unit_price
CHECK (unit_price >= 0);
GO

ALTER TABLE sales.price_list_details
ADD CONSTRAINT DF_price_list_details_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_price_list_details_product_id
ON sales.price_list_details(product_id);
GO


CREATE TABLE sales.salespersons (
    salesperson_id INT IDENTITY(1,1) NOT NULL,
    user_id INT NOT NULL,
    employee_code NVARCHAR(30) NOT NULL,
    phone NVARCHAR(30) NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT PK_salespersons
PRIMARY KEY (salesperson_id);
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT FK_salespersons_users
FOREIGN KEY (user_id)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT FK_salespersons_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT FK_salespersons_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT UQ_salespersons_user_id
UNIQUE (user_id);
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT UQ_salespersons_employee_code
UNIQUE (employee_code);
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT DF_salespersons_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE sales.salespersons
ADD CONSTRAINT DF_salespersons_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO


CREATE TABLE sales.customers (
    customer_id INT IDENTITY(1,1) NOT NULL,
    customer_code NVARCHAR(50) NOT NULL,
    tax_id NVARCHAR(20) NOT NULL,
    business_name NVARCHAR(200) NOT NULL,
    customer_type NVARCHAR(20) NOT NULL,
    contact_name NVARCHAR(150) NULL,
    phone NVARCHAR(30) NULL,
    email NVARCHAR(255) NULL,
    address NVARCHAR(300) NULL,
    salesperson_id INT NOT NULL,
    price_list_id INT NOT NULL,
    credit_days INT NOT NULL,
    credit_limit DECIMAL(18,2) NOT NULL,
    is_credit_blocked BIT NOT NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT PK_customers
PRIMARY KEY (customer_id);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT UQ_customers_code
UNIQUE (customer_code);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT FK_customers_salespersons
FOREIGN KEY (salesperson_id)
REFERENCES sales.salespersons(salesperson_id);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT FK_customers_price_lists
FOREIGN KEY (price_list_id)
REFERENCES sales.price_lists(price_list_id);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT FK_customers_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT FK_customers_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT CK_customers_type
CHECK (
    customer_type IN (
        'WHOLESALE',
        'RETAIL',
        'CHAIN'
    )
);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT CK_customers_credit_days
CHECK (credit_days IN (0, 15, 30, 60));
GO

ALTER TABLE sales.customers
ADD CONSTRAINT CK_customers_credit_limit
CHECK (credit_limit >= 0);
GO

ALTER TABLE sales.customers
ADD CONSTRAINT DF_customers_credit_days
DEFAULT (0) FOR credit_days;
GO

ALTER TABLE sales.customers
ADD CONSTRAINT DF_customers_credit_limit
DEFAULT (0) FOR credit_limit;
GO

ALTER TABLE sales.customers
ADD CONSTRAINT DF_customers_is_credit_blocked
DEFAULT (0) FOR is_credit_blocked;
GO

ALTER TABLE sales.customers
ADD CONSTRAINT DF_customers_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE sales.customers
ADD CONSTRAINT DF_customers_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_customers_salesperson_id
ON sales.customers(salesperson_id);
GO

CREATE NONCLUSTERED INDEX IX_customers_price_list_id
ON sales.customers(price_list_id);
GO


CREATE TABLE sales.sales_orders (
    sales_order_id BIGINT IDENTITY(1,1) NOT NULL,
    order_number NVARCHAR(50) NOT NULL,
    customer_id INT NOT NULL,
    salesperson_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    order_date DATETIME2(3) NOT NULL,
    status NVARCHAR(30) NOT NULL,
    credit_status NVARCHAR(20) NOT NULL,
    credit_authorized_at DATETIME2(3) NULL,
    credit_authorized_by INT NULL,
    subtotal DECIMAL(18,2) NOT NULL,
    discount_amount DECIMAL(18,2) NOT NULL,
    tax_amount DECIMAL(18,2) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    notes NVARCHAR(500) NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT PK_sales_orders
PRIMARY KEY (sales_order_id);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT UQ_sales_orders_number
UNIQUE (order_number);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT FK_sales_orders_customers
FOREIGN KEY (customer_id)
REFERENCES sales.customers(customer_id);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT FK_sales_orders_salespersons
FOREIGN KEY (salesperson_id)
REFERENCES sales.salespersons(salesperson_id);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT FK_sales_orders_warehouses
FOREIGN KEY (warehouse_id)
REFERENCES inventory.warehouses(warehouse_id);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT FK_sales_orders_credit_authorized_by
FOREIGN KEY (credit_authorized_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT FK_sales_orders_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT FK_sales_orders_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT CK_sales_orders_status
CHECK (
    status IN (
        'DRAFT',
        'PENDING',
        'APPROVED',
        'RESERVED',
        'COMPLETED',
        'CANCELLED'
    )
);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT CK_sales_orders_credit_status
CHECK (
    credit_status IN (
        'PENDING',
        'APPROVED',
        'REJECTED'
    )
);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT CK_sales_orders_amounts
CHECK (
    subtotal >= 0
    AND discount_amount >= 0
    AND discount_amount <= subtotal
    AND tax_amount >= 0
    AND total_amount = subtotal - discount_amount + tax_amount
);
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_status
DEFAULT ('DRAFT') FOR status;
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_credit_status
DEFAULT ('PENDING') FOR credit_status;
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_order_date
DEFAULT (SYSUTCDATETIME()) FOR order_date;
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_subtotal
DEFAULT (0) FOR subtotal;
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_discount_amount
DEFAULT (0) FOR discount_amount;
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_tax_amount
DEFAULT (0) FOR tax_amount;
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_total_amount
DEFAULT (0) FOR total_amount;
GO

ALTER TABLE sales.sales_orders
ADD CONSTRAINT DF_sales_orders_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_sales_orders_customer_date
ON sales.sales_orders(customer_id, order_date);
GO

CREATE NONCLUSTERED INDEX IX_sales_orders_salesperson_date
ON sales.sales_orders(salesperson_id, order_date);
GO

CREATE NONCLUSTERED INDEX IX_sales_orders_status
ON sales.sales_orders(status);
GO


CREATE TABLE sales.sales_order_details (
    sales_order_detail_id BIGINT IDENTITY(1,1) NOT NULL,
    sales_order_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    quantity_reserved DECIMAL(18,3) NOT NULL,
    unit_price DECIMAL(18,4) NOT NULL,
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

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT PK_sales_order_details
PRIMARY KEY (sales_order_detail_id);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT FK_sales_order_details_orders
FOREIGN KEY (sales_order_id)
REFERENCES sales.sales_orders(sales_order_id);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT FK_sales_order_details_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT FK_sales_order_details_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT FK_sales_order_details_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT UQ_sales_order_details_order_product
UNIQUE (sales_order_id, product_id);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT CK_sales_order_details_quantities
CHECK (
    quantity > 0
    AND quantity_reserved >= 0
    AND quantity_reserved <= quantity
);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT CK_sales_order_details_amounts
CHECK (
    unit_price >= 0
    AND discount_amount >= 0
    AND subtotal >= 0
    AND discount_amount <= subtotal
    AND tax_amount >= 0
    AND total_amount = subtotal - discount_amount + tax_amount
);
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT DF_sales_order_details_quantity_reserved
DEFAULT (0) FOR quantity_reserved;
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT DF_sales_order_details_discount_amount
DEFAULT (0) FOR discount_amount;
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT DF_sales_order_details_subtotal
DEFAULT (0) FOR subtotal;
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT DF_sales_order_details_tax_amount
DEFAULT (0) FOR tax_amount;
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT DF_sales_order_details_total_amount
DEFAULT (0) FOR total_amount;
GO

ALTER TABLE sales.sales_order_details
ADD CONSTRAINT DF_sales_order_details_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_sales_order_details_product_id
ON sales.sales_order_details(product_id);
GO


CREATE TABLE sales.sales_invoices (
    sales_invoice_id BIGINT IDENTITY(1,1) NOT NULL,
    sales_order_id BIGINT NOT NULL,
    customer_id INT NOT NULL,
    salesperson_id INT NOT NULL,
    invoice_series NVARCHAR(50) NOT NULL,
    invoice_number NVARCHAR(50) NOT NULL,
    dte_uuid NVARCHAR(100) NULL,
    invoice_date DATETIME2(3) NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(18,2) NOT NULL,
    discount_amount DECIMAL(18,2) NOT NULL,
    tax_amount DECIMAL(18,2) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    cancellation_reason NVARCHAR(500) NULL,
    cancelled_at DATETIME2(3) NULL,
    cancelled_by INT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT PK_sales_invoices
PRIMARY KEY (sales_invoice_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT UQ_sales_invoices_order
UNIQUE (sales_order_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT UQ_sales_invoices_series_number
UNIQUE (invoice_series, invoice_number);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT FK_sales_invoices_orders
FOREIGN KEY (sales_order_id)
REFERENCES sales.sales_orders(sales_order_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT FK_sales_invoices_customers
FOREIGN KEY (customer_id)
REFERENCES sales.customers(customer_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT FK_sales_invoices_salespersons
FOREIGN KEY (salesperson_id)
REFERENCES sales.salespersons(salesperson_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT FK_sales_invoices_cancelled_by
FOREIGN KEY (cancelled_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT FK_sales_invoices_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT FK_sales_invoices_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT CK_sales_invoices_status
CHECK (
    status IN (
        'ISSUED',
        'CANCELLED'
    )
);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT CK_sales_invoices_amounts
CHECK (
    subtotal >= 0
    AND discount_amount >= 0
    AND discount_amount <= subtotal
    AND tax_amount >= 0
    AND total_amount = subtotal - discount_amount + tax_amount
);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT CK_sales_invoices_cancellation
CHECK (
    status <> 'CANCELLED'
    OR (
        cancellation_reason IS NOT NULL
        AND cancelled_at IS NOT NULL
        AND cancelled_by IS NOT NULL
    )
);
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT DF_sales_invoices_status
DEFAULT ('ISSUED') FOR status;
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT DF_sales_invoices_invoice_date
DEFAULT (SYSUTCDATETIME()) FOR invoice_date;
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT DF_sales_invoices_subtotal
DEFAULT (0) FOR subtotal;
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT DF_sales_invoices_discount_amount
DEFAULT (0) FOR discount_amount;
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT DF_sales_invoices_tax_amount
DEFAULT (0) FOR tax_amount;
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT DF_sales_invoices_total_amount
DEFAULT (0) FOR total_amount;
GO

ALTER TABLE sales.sales_invoices
ADD CONSTRAINT DF_sales_invoices_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_sales_invoices_dte_uuid
ON sales.sales_invoices(dte_uuid)
WHERE dte_uuid IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_sales_invoices_invoice_date_status
ON sales.sales_invoices(invoice_date, status);
GO

CREATE NONCLUSTERED INDEX IX_sales_invoices_customer_due_date
ON sales.sales_invoices(customer_id, due_date);
GO

CREATE TABLE sales.sales_invoice_details (
    sales_invoice_detail_id BIGINT IDENTITY(1,1) NOT NULL,
    sales_invoice_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    unit_price DECIMAL(18,4) NOT NULL,
    unit_cost DECIMAL(18,4) NOT NULL,
    discount_amount DECIMAL(18,2) NOT NULL,
    subtotal DECIMAL(18,2) NOT NULL,
    tax_amount DECIMAL(18,2) NOT NULL,
    total_amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL
);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT PK_sales_invoice_details
PRIMARY KEY (sales_invoice_detail_id);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT FK_sales_invoice_details_invoices
FOREIGN KEY (sales_invoice_id)
REFERENCES sales.sales_invoices(sales_invoice_id);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT FK_sales_invoice_details_products
FOREIGN KEY (product_id)
REFERENCES catalog.products(product_id);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT FK_sales_invoice_details_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT UQ_sales_invoice_details_invoice_product
UNIQUE (sales_invoice_id, product_id);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT CK_sales_invoice_details_quantity
CHECK (quantity > 0);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT CK_sales_invoice_details_amounts
CHECK (
    unit_price >= 0
    AND unit_cost >= 0
    AND discount_amount >= 0
    AND subtotal >= 0
    AND discount_amount <= subtotal
    AND tax_amount >= 0
    AND total_amount = subtotal - discount_amount + tax_amount
);
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT DF_sales_invoice_details_discount_amount
DEFAULT (0) FOR discount_amount;
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT DF_sales_invoice_details_subtotal
DEFAULT (0) FOR subtotal;
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT DF_sales_invoice_details_tax_amount
DEFAULT (0) FOR tax_amount;
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT DF_sales_invoice_details_total_amount
DEFAULT (0) FOR total_amount;
GO

ALTER TABLE sales.sales_invoice_details
ADD CONSTRAINT DF_sales_invoice_details_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_sales_invoice_details_product_id
ON sales.sales_invoice_details(product_id);
GO


CREATE TABLE sales.sales_targets (
    sales_target_id INT IDENTITY(1,1) NOT NULL,
    salesperson_id INT NOT NULL,
    target_year SMALLINT NOT NULL,
    target_month TINYINT NOT NULL,
    target_amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT PK_sales_targets
PRIMARY KEY (sales_target_id);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT FK_sales_targets_salespersons
FOREIGN KEY (salesperson_id)
REFERENCES sales.salespersons(salesperson_id);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT FK_sales_targets_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT FK_sales_targets_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT UQ_sales_targets_salesperson_period
UNIQUE (
    salesperson_id,
    target_year,
    target_month
);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT CK_sales_targets_year
CHECK (target_year BETWEEN 2000 AND 2100);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT CK_sales_targets_month
CHECK (target_month BETWEEN 1 AND 12);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT CK_sales_targets_amount
CHECK (target_amount >= 0);
GO

ALTER TABLE sales.sales_targets
ADD CONSTRAINT DF_sales_targets_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO