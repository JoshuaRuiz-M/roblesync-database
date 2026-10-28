IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'finance'
)
BEGIN
    EXEC('CREATE SCHEMA finance');
END;
GO


CREATE TABLE finance.accounts_receivable (
    account_receivable_id BIGINT IDENTITY(1,1) NOT NULL,
    sales_invoice_id BIGINT NOT NULL,
    customer_id INT NOT NULL,
    original_amount DECIMAL(18,2) NOT NULL,
    outstanding_balance DECIMAL(18,2) NOT NULL,
    due_date DATE NOT NULL,
    status NVARCHAR(20) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT PK_accounts_receivable
PRIMARY KEY (account_receivable_id);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT UQ_accounts_receivable_sales_invoice
UNIQUE (sales_invoice_id);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT FK_accounts_receivable_sales_invoices
FOREIGN KEY (sales_invoice_id)
REFERENCES sales.sales_invoices(sales_invoice_id);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT FK_accounts_receivable_customers
FOREIGN KEY (customer_id)
REFERENCES sales.customers(customer_id);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT FK_accounts_receivable_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT FK_accounts_receivable_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT CK_accounts_receivable_amounts
CHECK (
    original_amount >= 0
    AND outstanding_balance >= 0
    AND outstanding_balance <= original_amount
);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT CK_accounts_receivable_status
CHECK (
    status IN (
        'PENDING',
        'PARTIALLY_PAID',
        'PAID',
        'CANCELLED'
    )
);
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT DF_accounts_receivable_status
DEFAULT ('PENDING') FOR status;
GO

ALTER TABLE finance.accounts_receivable
ADD CONSTRAINT DF_accounts_receivable_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_accounts_receivable_customer_status
ON finance.accounts_receivable(
    customer_id,
    status
);
GO

CREATE NONCLUSTERED INDEX IX_accounts_receivable_due_date
ON finance.accounts_receivable(
    due_date,
    outstanding_balance
);
GO

CREATE TABLE finance.customer_payments (
    customer_payment_id BIGINT IDENTITY(1,1) NOT NULL,
    account_receivable_id BIGINT NOT NULL,
    payment_number NVARCHAR(50) NOT NULL,
    payment_date DATETIME2(3) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    payment_method NVARCHAR(20) NOT NULL,
    reference_number NVARCHAR(100) NULL,
    notes NVARCHAR(500) NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL
);
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT PK_customer_payments
PRIMARY KEY (customer_payment_id);
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT UQ_customer_payments_number
UNIQUE (payment_number);
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT FK_customer_payments_accounts_receivable
FOREIGN KEY (account_receivable_id)
REFERENCES finance.accounts_receivable(account_receivable_id);
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT FK_customer_payments_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT CK_customer_payments_amount
CHECK (amount > 0);
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT CK_customer_payments_method
CHECK (
    payment_method IN (
        'CASH',
        'TRANSFER',
        'CARD',
        'CHECK'
    )
);
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT DF_customer_payments_payment_date
DEFAULT (SYSUTCDATETIME()) FOR payment_date;
GO

ALTER TABLE finance.customer_payments
ADD CONSTRAINT DF_customer_payments_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_customer_payments_account_receivable
ON finance.customer_payments(account_receivable_id);
GO

CREATE NONCLUSTERED INDEX IX_customer_payments_payment_date
ON finance.customer_payments(payment_date);
GO


CREATE TABLE finance.accounts_payable (
    account_payable_id BIGINT IDENTITY(1,1) NOT NULL,
    supplier_invoice_id BIGINT NOT NULL,
    supplier_id INT NOT NULL,
    original_amount DECIMAL(18,2) NOT NULL,
    outstanding_balance DECIMAL(18,2) NOT NULL,
    due_date DATE NOT NULL,
    status NVARCHAR(20) NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT PK_accounts_payable
PRIMARY KEY (account_payable_id);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT UQ_accounts_payable_supplier_invoice
UNIQUE (supplier_invoice_id);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT FK_accounts_payable_supplier_invoices
FOREIGN KEY (supplier_invoice_id)
REFERENCES purchasing.supplier_invoices(supplier_invoice_id);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT FK_accounts_payable_suppliers
FOREIGN KEY (supplier_id)
REFERENCES purchasing.suppliers(supplier_id);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT FK_accounts_payable_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT FK_accounts_payable_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT CK_accounts_payable_amounts
CHECK (
    original_amount >= 0
    AND outstanding_balance >= 0
    AND outstanding_balance <= original_amount
);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT CK_accounts_payable_status
CHECK (
    status IN (
        'PENDING',
        'PARTIALLY_PAID',
        'PAID',
        'CANCELLED'
    )
);
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT DF_accounts_payable_status
DEFAULT ('PENDING') FOR status;
GO

ALTER TABLE finance.accounts_payable
ADD CONSTRAINT DF_accounts_payable_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_accounts_payable_supplier_status
ON finance.accounts_payable(
    supplier_id,
    status
);
GO

CREATE NONCLUSTERED INDEX IX_accounts_payable_due_date
ON finance.accounts_payable(
    due_date,
    outstanding_balance
);
GO