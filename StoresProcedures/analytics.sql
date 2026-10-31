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
