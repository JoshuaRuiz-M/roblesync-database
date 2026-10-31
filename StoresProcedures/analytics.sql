IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analytics'
)
BEGIN
    EXEC('CREATE SCHEMA analytics');
END;
GO


CREATE OR ALTER PROCEDURE analytics.sp_GetKardex
    @ProductId INT = NULL,
    @WarehouseId INT = NULL,
    @BatchId INT = NULL,
    @MovementType NVARCHAR(30) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @Page INT = 1,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page IS NULL OR @Page < 1
        THROW 50001, 'La página debe ser mayor que cero.', 1;

    IF @Limit IS NULL OR @Limit < 1 OR @Limit > 100
        THROW 50002, 'El límite debe estar entre 1 y 100.', 1;

    IF @StartDate IS NOT NULL
       AND @EndDate IS NOT NULL
       AND @StartDate > @EndDate
        THROW 50003, 'La fecha inicial no puede ser mayor que la fecha final.', 1;

    IF @MovementType IS NOT NULL
       AND @MovementType NOT IN (
           'PURCHASE_RECEIPT',
           'SALE_DISPATCH',
           'TRANSFER_IN',
           'TRANSFER_OUT',
           'ADJUSTMENT_IN',
           'ADJUSTMENT_OUT',
           'RETURN_IN',
           'RETURN_OUT'
       )
        THROW 50004, 'El tipo de movimiento no es válido.', 1;

    DECLARE @Offset BIGINT =
        (CAST(@Page AS BIGINT) - 1) * @Limit;

    SELECT
        im.inventory_movement_id,
        im.warehouse_id,
        w.name AS warehouse_name,
        im.product_id,
        p.name AS product_name,
        im.batch_id,
        pb.batch_number,
        im.movement_type,
        im.movement_date,
        im.quantity,
        im.unit_cost,
        im.total_cost,
        im.balance_quantity,
        im.balance_value,
        im.reference_type,
        im.reference_id,
        im.notes,
        im.created_at,
        im.created_by
    FROM inventory.inventory_movements AS im
    INNER JOIN inventory.warehouses AS w
        ON w.warehouse_id = im.warehouse_id
    INNER JOIN catalog.products AS p
        ON p.product_id = im.product_id
    LEFT JOIN inventory.product_batches AS pb
        ON pb.batch_id = im.batch_id
        AND pb.product_id = im.product_id
    WHERE
        (@ProductId IS NULL OR im.product_id = @ProductId)
        AND (@WarehouseId IS NULL OR im.warehouse_id = @WarehouseId)
        AND (@BatchId IS NULL OR im.batch_id = @BatchId)
        AND (@MovementType IS NULL OR im.movement_type = @MovementType)
        AND (@StartDate IS NULL OR im.movement_date >= @StartDate)
        AND (
            @EndDate IS NULL
            OR im.movement_date < DATEADD(DAY, 1, CAST(@EndDate AS DATETIME2))
        )
    ORDER BY
        im.movement_date ASC,
        im.inventory_movement_id ASC
    OFFSET @Offset ROWS
    FETCH NEXT @Limit ROWS ONLY;

    SELECT
        COUNT_BIG(*) AS total
    FROM inventory.inventory_movements AS im
    WHERE
        (@ProductId IS NULL OR im.product_id = @ProductId)
        AND (@WarehouseId IS NULL OR im.warehouse_id = @WarehouseId)
        AND (@BatchId IS NULL OR im.batch_id = @BatchId)
        AND (@MovementType IS NULL OR im.movement_type = @MovementType)
        AND (@StartDate IS NULL OR im.movement_date >= @StartDate)
        AND (
            @EndDate IS NULL
            OR im.movement_date < DATEADD(DAY, 1, CAST(@EndDate AS DATETIME2))
        );
END;
GO



CREATE OR ALTER PROCEDURE analytics.sp_GetKardexSummary
    @ProductId INT,
    @WarehouseId INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ProductId IS NULL OR @ProductId <= 0
        THROW 50001, 'El producto no es válido.', 1;

    IF @WarehouseId IS NULL OR @WarehouseId <= 0
        THROW 50002, 'La bodega no es válida.', 1;

    IF @StartDate IS NOT NULL
       AND @EndDate IS NOT NULL
       AND @StartDate > @EndDate
        THROW 50003, 'La fecha inicial no puede ser mayor que la fecha final.', 1;

    DECLARE @EndExclusive DATETIME2(3) = NULL;

    IF @EndDate IS NOT NULL
        SET @EndExclusive = DATEADD(
            DAY,
            1,
            CAST(@EndDate AS DATETIME2(3))
        );

    DECLARE
        @OpeningQuantity DECIMAL(18,3) = 0,
        @OpeningValue DECIMAL(19,4) = 0,
        @IncomingQuantity DECIMAL(18,3) = 0,
        @IncomingValue DECIMAL(19,4) = 0,
        @OutgoingQuantity DECIMAL(18,3) = 0,
        @OutgoingValue DECIMAL(19,4) = 0,
        @ClosingQuantity DECIMAL(18,3) = 0,
        @ClosingValue DECIMAL(19,4) = 0;

    SELECT TOP (1)
        @OpeningQuantity = balance_quantity,
        @OpeningValue = balance_value
    FROM inventory.inventory_movements
    WHERE product_id = @ProductId
      AND warehouse_id = @WarehouseId
      AND @StartDate IS NOT NULL
      AND movement_date < @StartDate
    ORDER BY
        movement_date DESC,
        inventory_movement_id DESC;

    SELECT
        @IncomingQuantity = COALESCE(
            SUM(CASE WHEN quantity > 0 THEN quantity ELSE 0 END),
            0
        ),
        @IncomingValue = COALESCE(
            SUM(CASE WHEN total_cost > 0 THEN total_cost ELSE 0 END),
            0
        ),
        @OutgoingQuantity = COALESCE(
            SUM(CASE WHEN quantity < 0 THEN -quantity ELSE 0 END),
            0
        ),
        @OutgoingValue = COALESCE(
            SUM(CASE WHEN total_cost < 0 THEN -total_cost ELSE 0 END),
            0
        )
    FROM inventory.inventory_movements
    WHERE product_id = @ProductId
      AND warehouse_id = @WarehouseId
      AND (@StartDate IS NULL OR movement_date >= @StartDate)
      AND (@EndExclusive IS NULL OR movement_date < @EndExclusive);

    SET @ClosingQuantity =
        @OpeningQuantity + @IncomingQuantity - @OutgoingQuantity;

    SET @ClosingValue =
        @OpeningValue + @IncomingValue - @OutgoingValue;

    SELECT
        @ProductId AS product_id,
        @WarehouseId AS warehouse_id,
        @OpeningQuantity AS opening_quantity,
        @OpeningValue AS opening_value,
        @IncomingQuantity AS incoming_quantity,
        @IncomingValue AS incoming_value,
        @OutgoingQuantity AS outgoing_quantity,
        @OutgoingValue AS outgoing_value,
        @ClosingQuantity AS closing_quantity,
        @ClosingValue AS closing_value;
END;
GO



CREATE OR ALTER PROCEDURE analytics.sp_GetDashboardOverview
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate IS NOT NULL
       AND @EndDate IS NOT NULL
       AND @StartDate > @EndDate
    BEGIN
        THROW 50001,
            'La fecha inicial no puede ser mayor que la fecha final.',
            1;
    END;

    DECLARE @SalesTotal DECIMAL(19,2) = 0;
    DECLARE @PurchasesTotal DECIMAL(19,2) = 0;
    DECLARE @ActiveCustomers INT = 0;
    DECLARE @LowStockProducts INT = 0;

    SELECT
        @SalesTotal = COALESCE(SUM(si.total_amount), 0)
    FROM sales.sales_invoices si
    WHERE si.status = 'ISSUED'
      AND (
          @StartDate IS NULL
          OR si.invoice_date >= @StartDate
      )
      AND (
          @EndDate IS NULL
          OR si.invoice_date < DATEADD(DAY, 1, @EndDate)
      );

    SELECT
        @PurchasesTotal = COALESCE(SUM(po.total_amount), 0)
    FROM purchasing.purchase_orders po
    WHERE po.status IN (
        'APPROVED',
        'PARTIALLY_RECEIVED',
        'RECEIVED'
    )
      AND (
          @StartDate IS NULL
          OR po.order_date >= @StartDate
      )
      AND (
          @EndDate IS NULL
          OR po.order_date < DATEADD(DAY, 1, @EndDate)
      );

    SELECT
        @ActiveCustomers = COUNT(*)
    FROM sales.customers
    WHERE is_active = 1;

    SELECT
        @LowStockProducts = COUNT(*)
    FROM catalog.products p
    OUTER APPLY (
        SELECT
            COALESCE(
                SUM(ws.quantity_on_hand - ws.quantity_reserved),
                0
            ) AS available_quantity
        FROM inventory.warehouse_stock ws
        WHERE ws.product_id = p.product_id
    ) stock
    WHERE p.is_active = 1
      AND stock.available_quantity <= p.reorder_point;

    SELECT
        @SalesTotal AS sales_total,
        @PurchasesTotal AS purchases_total,
        @ActiveCustomers AS active_customers,
        @LowStockProducts AS low_stock_products;
END;
GO



CREATE OR ALTER PROCEDURE analytics.sp_GetSalesTrend
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @EndDate = COALESCE(
        @EndDate,
        CAST(SYSUTCDATETIME() AS DATE)
    );

    SET @StartDate = COALESCE(
        @StartDate,
        DATEADD(MONTH, -11, DATEFROMPARTS(
            YEAR(@EndDate),
            MONTH(@EndDate),
            1
        ))
    );

    IF @StartDate > @EndDate
    BEGIN
        THROW 50001,
            'La fecha inicial no puede ser mayor que la fecha final.',
            1;
    END;

    DECLARE @FirstMonth DATE = DATEFROMPARTS(
        YEAR(@StartDate),
        MONTH(@StartDate),
        1
    );

    DECLARE @LastMonth DATE = DATEFROMPARTS(
        YEAR(@EndDate),
        MONTH(@EndDate),
        1
    );

    ;WITH Months AS (
        SELECT @FirstMonth AS month_start

        UNION ALL

        SELECT DATEADD(MONTH, 1, month_start)
        FROM Months
        WHERE month_start < @LastMonth
    ),
    MonthlySales AS (
        SELECT
            DATEFROMPARTS(
                YEAR(si.invoice_date),
                MONTH(si.invoice_date),
                1
            ) AS month_start,
            SUM(si.total_amount) AS total_sales,
            COUNT(*) AS invoice_count
        FROM sales.sales_invoices si
        WHERE si.status = 'ISSUED'
          AND si.invoice_date >= @StartDate
          AND si.invoice_date < DATEADD(DAY, 1, @EndDate)
        GROUP BY
            YEAR(si.invoice_date),
            MONTH(si.invoice_date)
    )
    SELECT
        YEAR(m.month_start) AS [year],
        MONTH(m.month_start) AS [month],
        CONVERT(CHAR(7), m.month_start, 120) AS period,
        CAST(
            COALESCE(ms.total_sales, 0)
            AS DECIMAL(19,2)
        ) AS total_sales,
        COALESCE(ms.invoice_count, 0) AS invoice_count
    FROM Months m
    LEFT JOIN MonthlySales ms
        ON ms.month_start = m.month_start
    ORDER BY m.month_start
    OPTION (MAXRECURSION 0);
END;
GO



CREATE OR ALTER PROCEDURE analytics.sp_GetTopSellingProducts
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @Top INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate IS NOT NULL
       AND @EndDate IS NOT NULL
       AND @StartDate > @EndDate
    BEGIN
        THROW 50001,
            'La fecha inicial no puede ser mayor que la fecha final.',
            1;
    END;

    IF @Top IS NULL OR @Top < 1 OR @Top > 100
    BEGIN
        THROW 50002,
            'El límite debe estar entre 1 y 100.',
            1;
    END;

    SELECT TOP (@Top)
        p.product_id,
        p.sku,
        p.name AS product_name,
        SUM(sid.quantity) AS quantity_sold,
        CAST(
            SUM(sid.total_amount)
            AS DECIMAL(19,2)
        ) AS total_sales,
        COUNT(DISTINCT si.sales_invoice_id) AS invoice_count,
        CAST(
            SUM(sid.subtotal - sid.discount_amount)
            / NULLIF(SUM(sid.quantity), 0)
            AS DECIMAL(18,4)
        ) AS average_unit_price
    FROM sales.sales_invoice_details sid
    INNER JOIN sales.sales_invoices si
        ON si.sales_invoice_id = sid.sales_invoice_id
    INNER JOIN catalog.products p
        ON p.product_id = sid.product_id
    WHERE si.status = 'ISSUED'
      AND (
          @StartDate IS NULL
          OR si.invoice_date >= @StartDate
      )
      AND (
          @EndDate IS NULL
          OR si.invoice_date < DATEADD(DAY, 1, @EndDate)
      )
    GROUP BY
        p.product_id,
        p.sku,
        p.name
    ORDER BY
        total_sales DESC,
        quantity_sold DESC,
        p.product_id ASC;
END;
GO



CREATE OR ALTER PROCEDURE analytics.sp_GetSalesByCategory
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate IS NOT NULL
       AND @EndDate IS NOT NULL
       AND @StartDate > @EndDate
    BEGIN
        THROW 50001,
            'La fecha inicial no puede ser mayor que la fecha final.',
            1;
    END;

    ;WITH CategorySales AS (
        SELECT
            c.category_id,
            c.name AS category_name,
            SUM(sid.total_amount) AS total_sales,
            SUM(sid.quantity) AS quantity_sold,
            COUNT(DISTINCT si.sales_invoice_id) AS invoice_count
        FROM sales.sales_invoice_details sid
        INNER JOIN sales.sales_invoices si
            ON si.sales_invoice_id = sid.sales_invoice_id
        INNER JOIN catalog.products p
            ON p.product_id = sid.product_id
        INNER JOIN catalog.product_lines pl
            ON pl.product_line_id = p.product_line_id
        INNER JOIN catalog.categories c
            ON c.category_id = pl.category_id
        WHERE si.status = 'ISSUED'
          AND (
              @StartDate IS NULL
              OR si.invoice_date >= @StartDate
          )
          AND (
              @EndDate IS NULL
              OR si.invoice_date < DATEADD(DAY, 1, @EndDate)
          )
        GROUP BY
            c.category_id,
            c.name
    )
    SELECT
        category_id,
        category_name,
        CAST(
            total_sales AS DECIMAL(19,2)
        ) AS total_sales,
        quantity_sold,
        invoice_count,
        CAST(
            CASE
                WHEN SUM(total_sales) OVER () = 0
                THEN 0
                ELSE
                    total_sales * 100.0
                    / SUM(total_sales) OVER ()
            END
            AS DECIMAL(7,2)
        ) AS percentage
    FROM CategorySales
    ORDER BY
        total_sales DESC,
        category_name ASC;
END;
GO



CREATE OR ALTER PROCEDURE analytics.sp_GetInventoryAlerts
    @ExpirationDays INT = 30,
    @Top INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @ExpirationDays IS NULL
       OR @ExpirationDays < 0
       OR @ExpirationDays > 365
    BEGIN
        THROW 50001,
            'Los días de vencimiento deben estar entre 0 y 365.',
            1;
    END;

    IF @Top IS NULL OR @Top < 1 OR @Top > 100
    BEGIN
        THROW 50002,
            'El límite debe estar entre 1 y 100.',
            1;
    END;

    DECLARE @Today DATE = CAST(SYSUTCDATETIME() AS DATE);

    ;WITH ProductStock AS (
        SELECT
            p.product_id,
            p.sku,
            p.name AS product_name,
            p.reorder_point,
            COALESCE(
                SUM(
                    ws.quantity_on_hand
                    - ws.quantity_reserved
                ),
                0
            ) AS available_quantity
        FROM catalog.products p
        LEFT JOIN inventory.warehouse_stock ws
            ON ws.product_id = p.product_id
        WHERE p.is_active = 1
        GROUP BY
            p.product_id,
            p.sku,
            p.name,
            p.reorder_point
    ),
    StockAlerts AS (
        SELECT
            CAST(
                CASE
                    WHEN available_quantity = 0
                    THEN 'OUT_OF_STOCK'
                    ELSE 'LOW_STOCK'
                END
                AS NVARCHAR(30)
            ) AS alert_type,
            CAST(
                CASE
                    WHEN available_quantity = 0
                    THEN 'HIGH'
                    ELSE 'MEDIUM'
                END
                AS NVARCHAR(10)
            ) AS priority,
            product_id,
            sku,
            product_name,
            CAST(NULL AS INT) AS warehouse_id,
            CAST(NULL AS NVARCHAR(150)) AS warehouse_name,
            CAST(NULL AS INT) AS batch_id,
            CAST(NULL AS NVARCHAR(100)) AS batch_number,
            CAST(NULL AS DATE) AS expiration_date,
            available_quantity,
            reorder_point,
            CAST(NULL AS INT) AS days_until_expiration
        FROM ProductStock
        WHERE available_quantity <= reorder_point
    ),
    ExpirationAlerts AS (
        SELECT
            CAST(
                CASE
                    WHEN pb.expiration_date < @Today
                    THEN 'EXPIRED'
                    ELSE 'EXPIRING_SOON'
                END
                AS NVARCHAR(30)
            ) AS alert_type,
            CAST(
                CASE
                    WHEN pb.expiration_date < @Today
                    THEN 'HIGH'
                    ELSE 'MEDIUM'
                END
                AS NVARCHAR(10)
            ) AS priority,
            p.product_id,
            p.sku,
            p.name AS product_name,
            w.warehouse_id,
            w.name AS warehouse_name,
            pb.batch_id,
            pb.batch_number,
            pb.expiration_date,
            bs.quantity_on_hand
                - bs.quantity_reserved AS available_quantity,
            p.reorder_point,
            DATEDIFF(
                DAY,
                @Today,
                pb.expiration_date
            ) AS days_until_expiration
        FROM inventory.batch_stock bs
        INNER JOIN inventory.product_batches pb
            ON pb.batch_id = bs.batch_id
           AND pb.product_id = bs.product_id
        INNER JOIN catalog.products p
            ON p.product_id = bs.product_id
        INNER JOIN inventory.warehouses w
            ON w.warehouse_id = bs.warehouse_id
        WHERE p.is_active = 1
          AND pb.is_active = 1
          AND pb.expiration_date IS NOT NULL
          AND pb.expiration_date
              <= DATEADD(DAY, @ExpirationDays, @Today)
          AND bs.quantity_on_hand > 0
    ),
    AllAlerts AS (
        SELECT * FROM StockAlerts
        UNION ALL
        SELECT * FROM ExpirationAlerts
    )
    SELECT TOP (@Top)
        alert_type,
        priority,
        product_id,
        sku,
        product_name,
        warehouse_id,
        warehouse_name,
        batch_id,
        batch_number,
        expiration_date,
        available_quantity,
        reorder_point,
        days_until_expiration
    FROM AllAlerts
    ORDER BY
        CASE priority
            WHEN 'HIGH' THEN 1
            ELSE 2
        END,
        CASE alert_type
            WHEN 'EXPIRED' THEN 1
            WHEN 'OUT_OF_STOCK' THEN 2
            WHEN 'EXPIRING_SOON' THEN 3
            ELSE 4
        END,
        expiration_date ASC,
        product_name ASC,
        warehouse_id ASC,
        batch_id ASC;
END;
GO


