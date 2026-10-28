IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'catalog')
BEGIN
    EXEC('CREATE SCHEMA catalog');
END;
GO

CREATE TABLE catalog.brands (
    brand_id INT IDENTITY(1,1) NOT NULL,
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

ALTER TABLE catalog.brands
ADD CONSTRAINT PK_brands
PRIMARY KEY (brand_id);
GO

ALTER TABLE catalog.brands
ADD CONSTRAINT UQ_brands_code
UNIQUE (code);
GO

ALTER TABLE catalog.brands
ADD CONSTRAINT FK_brands_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.brands
ADD CONSTRAINT FK_brands_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.brands
ADD CONSTRAINT DF_brands_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE catalog.brands
ADD CONSTRAINT DF_brands_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE TABLE catalog.categories (
    category_id INT IDENTITY(1,1) NOT NULL,
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

ALTER TABLE catalog.categories
ADD CONSTRAINT PK_categories
PRIMARY KEY (category_id);
GO

ALTER TABLE catalog.categories
ADD CONSTRAINT UQ_categories_code
UNIQUE (code);
GO

ALTER TABLE catalog.categories
ADD CONSTRAINT FK_categories_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.categories
ADD CONSTRAINT FK_categories_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.categories
ADD CONSTRAINT DF_categories_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE catalog.categories
ADD CONSTRAINT DF_categories_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE TABLE catalog.product_lines (
    product_line_id INT IDENTITY(1,1) NOT NULL,
    category_id INT NOT NULL,
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

ALTER TABLE catalog.product_lines
ADD CONSTRAINT PK_product_lines
PRIMARY KEY (product_line_id);
GO

ALTER TABLE catalog.product_lines
ADD CONSTRAINT FK_product_lines_categories
FOREIGN KEY (category_id)
REFERENCES catalog.categories(category_id);
GO

ALTER TABLE catalog.product_lines
ADD CONSTRAINT FK_product_lines_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.product_lines
ADD CONSTRAINT FK_product_lines_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.product_lines
ADD CONSTRAINT UQ_product_lines_code
UNIQUE (code);
GO

ALTER TABLE catalog.product_lines
ADD CONSTRAINT DF_product_lines_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE catalog.product_lines
ADD CONSTRAINT DF_product_lines_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_product_lines_category_id
ON catalog.product_lines(category_id);
GO

CREATE TABLE catalog.units_of_measure (
    unit_of_measure_id INT IDENTITY(1,1) NOT NULL,
    code NVARCHAR(20) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    abbreviation NVARCHAR(20) NOT NULL,
    description NVARCHAR(255) NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE catalog.units_of_measure
ADD CONSTRAINT PK_units_of_measure
PRIMARY KEY (unit_of_measure_id);
GO

ALTER TABLE catalog.units_of_measure
ADD CONSTRAINT UQ_units_of_measure_code
UNIQUE (code);
GO

ALTER TABLE catalog.units_of_measure
ADD CONSTRAINT FK_units_of_measure_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.units_of_measure
ADD CONSTRAINT FK_units_of_measure_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.units_of_measure
ADD CONSTRAINT DF_units_of_measure_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE catalog.units_of_measure
ADD CONSTRAINT DF_units_of_measure_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE TABLE catalog.products (
    product_id INT IDENTITY(1,1) NOT NULL,
    brand_id INT NOT NULL,
    product_line_id INT NOT NULL,
    unit_of_measure_id INT NOT NULL,
    sku NVARCHAR(50) NOT NULL,
    barcode NVARCHAR(50) NOT NULL,
    name NVARCHAR(200) NOT NULL,
    description NVARCHAR(1000) NULL,
    weight DECIMAL(18,3) NULL,
    average_cost DECIMAL(18,4) NOT NULL,
    list_price DECIMAL(18,4) NOT NULL,
    minimum_stock DECIMAL(18,3) NOT NULL,
    maximum_stock DECIMAL(18,3) NOT NULL,
    reorder_point DECIMAL(18,3) NOT NULL,
    tracks_expiration BIT NOT NULL,
    is_active BIT NOT NULL,
    created_at DATETIME2(3) NOT NULL,
    created_by INT NOT NULL,
    updated_at DATETIME2(3) NULL,
    updated_by INT NULL
);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT PK_products
PRIMARY KEY (product_id);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT FK_products_brands
FOREIGN KEY (brand_id)
REFERENCES catalog.brands(brand_id);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT FK_products_product_lines
FOREIGN KEY (product_line_id)
REFERENCES catalog.product_lines(product_line_id);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT FK_products_units_of_measure
FOREIGN KEY (unit_of_measure_id)
REFERENCES catalog.units_of_measure(unit_of_measure_id);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT FK_products_created_by
FOREIGN KEY (created_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT FK_products_updated_by
FOREIGN KEY (updated_by)
REFERENCES security.users(user_id);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT UQ_products_sku
UNIQUE (sku);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT UQ_products_barcode
UNIQUE (barcode);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT CK_products_weight
CHECK (weight IS NULL OR weight >= 0);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT CK_products_average_cost
CHECK (average_cost >= 0);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT CK_products_list_price
CHECK (list_price >= 0);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT CK_products_stock_levels
CHECK (
    minimum_stock >= 0
    AND maximum_stock >= minimum_stock
    AND reorder_point >= 0
    AND reorder_point <= maximum_stock
);
GO

ALTER TABLE catalog.products
ADD CONSTRAINT DF_products_average_cost
DEFAULT (0) FOR average_cost;
GO

ALTER TABLE catalog.products
ADD CONSTRAINT DF_products_minimum_stock
DEFAULT (0) FOR minimum_stock;
GO

ALTER TABLE catalog.products
ADD CONSTRAINT DF_products_maximum_stock
DEFAULT (0) FOR maximum_stock;
GO

ALTER TABLE catalog.products
ADD CONSTRAINT DF_products_reorder_point
DEFAULT (0) FOR reorder_point;
GO

ALTER TABLE catalog.products
ADD CONSTRAINT DF_products_tracks_expiration
DEFAULT (0) FOR tracks_expiration;
GO

ALTER TABLE catalog.products
ADD CONSTRAINT DF_products_is_active
DEFAULT (1) FOR is_active;
GO

ALTER TABLE catalog.products
ADD CONSTRAINT DF_products_created_at
DEFAULT (SYSUTCDATETIME()) FOR created_at;
GO

CREATE NONCLUSTERED INDEX IX_products_brand_id
ON catalog.products(brand_id);
GO

CREATE NONCLUSTERED INDEX IX_products_product_line_id
ON catalog.products(product_line_id);
GO

CREATE NONCLUSTERED INDEX IX_products_unit_of_measure_id
ON catalog.products(unit_of_measure_id);
GO