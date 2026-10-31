SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @admin AS INT = 1;
    DECLARE @fechaBase AS DATETIME2 (3) = '2026-10-30T08:00:00.000';
    DECLARE @i AS INT = 1;
    DECLARE @origen AS INT;
    DECLARE @destino AS INT;
    DECLARE @producto AS INT;
    DECLARE @lote AS INT;
    DECLARE @cantidad AS DECIMAL (18, 3);
    DECLARE @disponible AS DECIMAL (18, 3);
    DECLARE @costo AS DECIMAL (18, 4);
    DECLARE @estado AS NVARCHAR (20);
    DECLARE @fechaTransferencia AS DATETIME2 (3);
    DECLARE @fechaDespacho AS DATETIME2 (3);
    DECLARE @fechaRecepcion AS DATETIME2 (3);
    DECLARE @transferenciaId AS INT;
    DECLARE @saldoOrigen AS DECIMAL (18, 3);
    DECLARE @saldoDestino AS DECIMAL (18, 3);
    DECLARE @valorOrigen AS DECIMAL (19, 4);
    DECLARE @valorDestino AS DECIMAL (19, 4);
    DECLARE @valorAnterior AS DECIMAL (19, 4);
    DECLARE @saldoAnterior AS DECIMAL (18, 3);
    DECLARE @movimientoCosto AS DECIMAL (18, 4);
    DECLARE @totalCosto AS DECIMAL (19, 4);
    IF NOT EXISTS (SELECT 1
                   FROM   security.users
                   WHERE  user_id = @admin)
        THROW 52300, 'No existe el usuario administrador.', 1;
    IF EXISTS (SELECT 1
               FROM   logistics.warehouse_transfers)
       OR EXISTS (SELECT 1
                  FROM   logistics.warehouse_transfer_details)
        THROW 52301, 'Las tablas de transferencias deben estar vacias.', 1;
    IF (SELECT COUNT(*)
        FROM   inventory.warehouses
        WHERE  is_active = 1) < 3
        THROW 52302, 'Se necesitan tres bodegas activas.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock AS ws
                      OUTER APPLY (SELECT COALESCE (SUM(bs.quantity_on_hand), 0) AS total_lotes,
                                          COALESCE (SUM(bs.quantity_reserved), 0) AS total_reservado
                                   FROM   inventory.batch_stock AS bs
                                   WHERE  bs.warehouse_id = ws.warehouse_id
                                          AND bs.product_id = ws.product_id) AS lotes
               WHERE  ws.quantity_on_hand <> lotes.total_lotes
                      OR ws.quantity_reserved <> lotes.total_reservado)
        THROW 52303, 'El inventario inicial no coincide con los lotes.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock AS ws
                      OUTER APPLY (SELECT   TOP (1) im.balance_quantity,
                                                    im.balance_value
                                   FROM     inventory.inventory_movements AS im
                                   WHERE    im.warehouse_id = ws.warehouse_id
                                            AND im.product_id = ws.product_id
                                   ORDER BY im.inventory_movement_id DESC) AS ultimo
               WHERE  ultimo.balance_quantity IS NOT NULL
                      AND ultimo.balance_quantity <> ws.quantity_on_hand)
        THROW 52304, 'El inventario inicial no coincide con el ultimo movimiento.', 1;
    CREATE TABLE #bodegas (
        numero       INT PRIMARY KEY,
        warehouse_id INT NOT NULL
    );
    INSERT INTO #bodegas (
        numero,
        warehouse_id
    )
    SELECT ROW_NUMBER() OVER (ORDER BY warehouse_id),
           warehouse_id
    FROM   (SELECT   TOP (3) warehouse_id
            FROM     inventory.warehouses
            WHERE    is_active = 1
            ORDER BY warehouse_id) AS b;
    CREATE TABLE #usados (
        warehouse_id INT NOT NULL,
        batch_id     INT NOT NULL,
        PRIMARY KEY (warehouse_id, batch_id)
    );
    WHILE @i <= 60
        BEGIN
            SET @origen = (SELECT warehouse_id
                           FROM   #bodegas
                           WHERE  numero = ((@i - 1) % 3) + 1);
            SET @destino = (SELECT warehouse_id
                            FROM   #bodegas
                            WHERE  numero = (@i % 3) + 1);
            SET @estado = CASE WHEN @i <= 36 THEN 'RECEIVED' WHEN @i <= 48 THEN 'IN_TRANSIT' WHEN @i <= 54 THEN 'DRAFT' ELSE 'CANCELLED' END;
            SET @fechaTransferencia = DATEADD(MINUTE, @i, @fechaBase);
            SET @fechaDespacho = CASE WHEN @estado IN ('RECEIVED', 'IN_TRANSIT') THEN DATEADD(MINUTE, 1, @fechaTransferencia) ELSE NULL END;
            SET @fechaRecepcion = CASE WHEN @estado = 'RECEIVED' THEN DATEADD(MINUTE, 2, @fechaTransferencia) ELSE NULL END;
            SET @producto = NULL;
            SET @lote = NULL;
            SET @disponible = NULL;
            SELECT   TOP (1) @producto = bs.product_id,
                             @lote = bs.batch_id,
                             @disponible = bs.quantity_on_hand - bs.quantity_reserved
            FROM     inventory.batch_stock AS bs
                     INNER JOIN
                     inventory.product_batches AS pb
                     ON pb.batch_id = bs.batch_id
                        AND pb.product_id = bs.product_id
                     INNER JOIN
                     inventory.warehouse_stock AS ws
                     ON ws.warehouse_id = bs.warehouse_id
                        AND ws.product_id = bs.product_id
            WHERE    bs.warehouse_id = @origen
                     AND pb.is_active = 1
                     AND bs.quantity_on_hand - bs.quantity_reserved >= 2
                     AND ws.quantity_on_hand - ws.quantity_reserved >= 2
                     AND NOT EXISTS (SELECT 1
                                     FROM   #usados AS u
                                     WHERE  u.warehouse_id = bs.warehouse_id
                                            AND u.batch_id = bs.batch_id)
            ORDER BY bs.quantity_on_hand - bs.quantity_reserved DESC, bs.batch_id;
            IF @lote IS NULL
                THROW 52305, 'No hay suficientes lotes disponibles para generar las transferencias.', 1;
            SET @cantidad = CASE WHEN @disponible >= 20 THEN 5 WHEN @disponible >= 10 THEN 3 ELSE 1 END;
            INSERT  INTO #usados (
                warehouse_id,
                batch_id
            )
            VALUES               (@origen, @lote);
            SET @saldoAnterior = NULL;
            SET @valorAnterior = NULL;
            SELECT   TOP (1) @saldoAnterior = im.balance_quantity,
                             @valorAnterior = im.balance_value
            FROM     inventory.inventory_movements AS im
            WHERE    im.warehouse_id = @origen
                     AND im.product_id = @producto
            ORDER BY im.inventory_movement_id DESC;
            IF @saldoAnterior IS NULL
               OR @saldoAnterior <= 0
               OR @valorAnterior IS NULL
               OR @valorAnterior < 0
                THROW 52306, 'No existe un saldo valorizado valido en origen.', 1;
            SET @movimientoCosto = CAST (ROUND(@valorAnterior / @saldoAnterior, 4) AS DECIMAL (18, 4));
            SET @costo = @movimientoCosto;
            INSERT  INTO logistics.warehouse_transfers (
                transfer_number,
                source_warehouse_id,
                destination_warehouse_id,
                transfer_date,
                status,
                dispatched_at,
                dispatched_by,
                received_at,
                received_by,
                notes,
                created_at,
                created_by
            )
            VALUES                                     (CONCAT('TRF-SIM-', RIGHT(CONCAT('000000', @i), 6)), @origen, @destino, @fechaTransferencia, @estado, @fechaDespacho, CASE WHEN @fechaDespacho IS NOT NULL THEN @admin ELSE NULL END, @fechaRecepcion, CASE WHEN @fechaRecepcion IS NOT NULL THEN @admin ELSE NULL END, N'Transferencia de prueba entre bodegas.', @fechaTransferencia, @admin);
            SET @transferenciaId = SCOPE_IDENTITY();
            INSERT  INTO logistics.warehouse_transfer_details (
                warehouse_transfer_id,
                product_id,
                batch_id,
                quantity,
                unit_cost,
                created_at,
                created_by
            )
            VALUES                                            (@transferenciaId, @producto, @lote, @cantidad, @costo, @fechaTransferencia, @admin);
            IF @estado IN ('RECEIVED', 'IN_TRANSIT')
                BEGIN
                    UPDATE inventory.batch_stock
                    SET    quantity_on_hand = quantity_on_hand - @cantidad,
                           updated_at       = @fechaDespacho,
                           updated_by       = @admin
                    WHERE  warehouse_id = @origen
                           AND product_id = @producto
                           AND batch_id = @lote
                           AND quantity_on_hand - quantity_reserved >= @cantidad;
                    IF @@ROWCOUNT <> 1
                        THROW 52307, 'No se pudo descontar el lote de origen.', 1;
                    UPDATE inventory.warehouse_stock
                    SET    quantity_on_hand = quantity_on_hand - @cantidad,
                           updated_at       = @fechaDespacho,
                           updated_by       = @admin
                    WHERE  warehouse_id = @origen
                           AND product_id = @producto
                           AND quantity_on_hand - quantity_reserved >= @cantidad;
                    IF @@ROWCOUNT <> 1
                        THROW 52308, 'No se pudo descontar el inventario de origen.', 1;
                    SELECT @saldoOrigen = quantity_on_hand
                    FROM   inventory.warehouse_stock
                    WHERE  warehouse_id = @origen
                           AND product_id = @producto;
                    SET @totalCosto = CAST (ROUND(-@cantidad * @costo, 4) AS DECIMAL (19, 4));
                    SET @valorOrigen = CASE WHEN @saldoOrigen = 0 THEN 0 ELSE CAST (ROUND(@valorAnterior + @totalCosto, 4) AS DECIMAL (19, 4)) END;
                    IF @valorOrigen < 0
                        THROW 52309, 'El saldo valorizado de origen es negativo.', 1;
                    INSERT  INTO inventory.inventory_movements (
                        warehouse_id,
                        product_id,
                        batch_id,
                        movement_type,
                        movement_date,
                        quantity,
                        unit_cost,
                        total_cost,
                        balance_quantity,
                        balance_value,
                        reference_type,
                        reference_id,
                        notes,
                        created_at,
                        created_by
                    )
                    VALUES                                     (@origen, @producto, @lote, 'TRANSFER_OUT', @fechaDespacho, -@cantidad, @costo, @totalCosto, @saldoOrigen, @valorOrigen, 'WAREHOUSE_TRANSFER', @transferenciaId, N'Salida por transferencia.', @fechaDespacho, @admin);
                    IF @estado = 'RECEIVED'
                        BEGIN
                            IF EXISTS (SELECT 1
                                       FROM   inventory.batch_stock
                                       WHERE  warehouse_id = @destino
                                              AND batch_id = @lote)
                                BEGIN
                                    UPDATE inventory.batch_stock
                                    SET    quantity_on_hand = quantity_on_hand + @cantidad,
                                           updated_at       = @fechaRecepcion,
                                           updated_by       = @admin
                                    WHERE  warehouse_id = @destino
                                           AND product_id = @producto
                                           AND batch_id = @lote;
                                END
                            ELSE
                                BEGIN
                                    INSERT  INTO inventory.batch_stock (
                                        warehouse_id,
                                        product_id,
                                        batch_id,
                                        quantity_on_hand,
                                        quantity_reserved,
                                        updated_at,
                                        updated_by
                                    )
                                    VALUES                             (@destino, @producto, @lote, @cantidad, 0, @fechaRecepcion, @admin);
                                END
                            SET @saldoAnterior = NULL;
                            SET @valorAnterior = NULL;
                            SELECT   TOP (1) @saldoAnterior = im.balance_quantity,
                                             @valorAnterior = im.balance_value
                            FROM     inventory.inventory_movements AS im
                            WHERE    im.warehouse_id = @destino
                                     AND im.product_id = @producto
                            ORDER BY im.inventory_movement_id DESC;
                            SELECT @saldoDestino = quantity_on_hand
                            FROM   inventory.warehouse_stock
                            WHERE  warehouse_id = @destino
                                   AND product_id = @producto;
                            IF @saldoDestino IS NULL
                                THROW 52310, 'No existe el registro de inventario en destino.', 1;
                            IF @saldoAnterior IS NOT NULL
                               AND @saldoAnterior <> @saldoDestino
                                THROW 52311, 'El saldo previo de destino no coincide con el inventario.', 1;
                            SET @valorAnterior = COALESCE (@valorAnterior, 0);
                            UPDATE inventory.warehouse_stock
                            SET    quantity_on_hand = quantity_on_hand + @cantidad,
                                   updated_at       = @fechaRecepcion,
                                   updated_by       = @admin
                            WHERE  warehouse_id = @destino
                                   AND product_id = @producto;
                            IF @@ROWCOUNT <> 1
                                THROW 52312, 'No se pudo aumentar el inventario de destino.', 1;
                            SELECT @saldoDestino = quantity_on_hand
                            FROM   inventory.warehouse_stock
                            WHERE  warehouse_id = @destino
                                   AND product_id = @producto;
                            SET @totalCosto = CAST (ROUND(@cantidad * @costo, 4) AS DECIMAL (19, 4));
                            SET @valorDestino = CAST (ROUND(@valorAnterior + @totalCosto, 4) AS DECIMAL (19, 4));
                            INSERT  INTO inventory.inventory_movements (
                                warehouse_id,
                                product_id,
                                batch_id,
                                movement_type,
                                movement_date,
                                quantity,
                                unit_cost,
                                total_cost,
                                balance_quantity,
                                balance_value,
                                reference_type,
                                reference_id,
                                notes,
                                created_at,
                                created_by
                            )
                            VALUES                                     (@destino, @producto, @lote, 'TRANSFER_IN', @fechaRecepcion, @cantidad, @costo, @totalCosto, @saldoDestino, @valorDestino, 'WAREHOUSE_TRANSFER', @transferenciaId, N'Entrada por transferencia.', @fechaRecepcion, @admin);
                        END
                END
            SET @i = @i + 1;
        END
    IF (SELECT COUNT(*)
        FROM   logistics.warehouse_transfers) <> 60
        THROW 52313, 'Cantidad incorrecta de transferencias.', 1;
    IF (SELECT COUNT(*)
        FROM   logistics.warehouse_transfer_details) <> 60
        THROW 52314, 'Cantidad incorrecta de detalles.', 1;
    IF (SELECT COUNT(*)
        FROM   inventory.inventory_movements
        WHERE  reference_type = 'WAREHOUSE_TRANSFER') <> 84
        THROW 52315, 'Cantidad incorrecta de movimientos.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock AS ws
                      OUTER APPLY (SELECT COALESCE (SUM(bs.quantity_on_hand), 0) AS total_lotes,
                                          COALESCE (SUM(bs.quantity_reserved), 0) AS total_reservado
                                   FROM   inventory.batch_stock AS bs
                                   WHERE  bs.warehouse_id = ws.warehouse_id
                                          AND bs.product_id = ws.product_id) AS lotes
               WHERE  ws.quantity_on_hand <> lotes.total_lotes
                      OR ws.quantity_reserved <> lotes.total_reservado)
        THROW 52316, 'El inventario final no coincide con los lotes.', 1;
    IF EXISTS (SELECT 1
               FROM   inventory.warehouse_stock AS ws
                      OUTER APPLY (SELECT   TOP (1) im.balance_quantity
                                   FROM     inventory.inventory_movements AS im
                                   WHERE    im.warehouse_id = ws.warehouse_id
                                            AND im.product_id = ws.product_id
                                   ORDER BY im.inventory_movement_id DESC) AS ultimo
               WHERE  ultimo.balance_quantity IS NOT NULL
                      AND ultimo.balance_quantity <> ws.quantity_on_hand)
        THROW 52317, 'Los saldos finales no coinciden con los movimientos.', 1;
    COMMIT TRANSACTION;
    DROP TABLE #usados;
    DROP TABLE #bodegas;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    IF OBJECT_ID('tempdb..#usados') IS NOT NULL
        DROP TABLE #usados;
    IF OBJECT_ID('tempdb..#bodegas') IS NOT NULL
        DROP TABLE #bodegas;
    THROW;
END CATCH

SELECT   status,
         COUNT(*) AS transferencias
FROM     logistics.warehouse_transfers
GROUP BY status
ORDER BY status;

SELECT COUNT(*) AS total_transferencias
FROM   logistics.warehouse_transfers;

SELECT COUNT(*) AS total_detalles
FROM   logistics.warehouse_transfer_details;

SELECT   movement_type,
         COUNT(*) AS movimientos,
         SUM(quantity) AS cantidad_total
FROM     inventory.inventory_movements
WHERE    reference_type = 'WAREHOUSE_TRANSFER'
GROUP BY movement_type
ORDER BY movement_type;

SELECT COUNT(*) AS inconsistencias
FROM   inventory.warehouse_stock AS ws
       OUTER APPLY (SELECT COALESCE (SUM(bs.quantity_on_hand), 0) AS total_lotes,
                           COALESCE (SUM(bs.quantity_reserved), 0) AS total_reservado
                    FROM   inventory.batch_stock AS bs
                    WHERE  bs.warehouse_id = ws.warehouse_id
                           AND bs.product_id = ws.product_id) AS lotes
WHERE  ws.quantity_on_hand <> lotes.total_lotes
       OR ws.quantity_reserved <> lotes.total_reservado;