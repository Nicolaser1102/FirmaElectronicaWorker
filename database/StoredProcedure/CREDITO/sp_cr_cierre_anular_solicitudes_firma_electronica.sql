USE CREDITO
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_cr_cierre_anular_solicitudes_firma_electronica]
    @ADT_FECHA DATETIME,
    @ADT_FECHA_PRC DATETIME,
    @AS_MSJ VARCHAR(100) OUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Crear tabla temporal para almacenar registros relevantes
    IF OBJECT_ID('tempdb..#DocsAnulados') IS NOT NULL
        DROP TABLE #DocsAnulados;

    CREATE TABLE #DocsAnulados (
        Solicitud INT,
        Id INT
    );

    -- Insertar en la tabla temporal solo los registros que cumplen la condición
    INSERT INTO #DocsAnulados (Solicitud, Id)
    SELECT 
        Solicitud,
        Id
    FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
    WHERE 
        (OnBoardingEstadoFirma IS NULL OR OnBoardingEstadoFirma != 'F')
        AND CAST(SignBoxCreacionFecha AS DATE) = CAST(@ADT_FECHA_PRC AS DATE);

    -- Actualizar los documentos anulados
    UPDATE d
    SET 
        d.OnBoardingEstadoFirma = 'N',
        d.OnBoardingRutaDocumento = 'Solicitud de firma onboarding caducada'
    FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica d
    INNER JOIN #DocsAnulados t ON d.Id = t.Id;

    -- Actualizar solicitudes relacionadas
    UPDATE s
    SET 
        s.sol_estado = 'U',
        s.modifica_fecha = @ADT_FECHA
    FROM CREDITO..SL_SOLICITUD s
    INNER JOIN #DocsAnulados t ON s.sol_solicitud = t.Solicitud
    WHERE 
        s.sol_producto = 'CRWEB'
        AND s.sol_estado NOT IN ('D');

    ----------------------------------------------------------------------
    -- Envío de correos para cada solicitud anulada
    ----------------------------------------------------------------------
    DECLARE @LI_SOLICITUD INT,
            @_UserName NVARCHAR(200),
            @_SessionID NVARCHAR(200),
            @_CodeReturn INT,
            @_Message NVARCHAR(500),
            @Request NVARCHAR(MAX),
            @Result NVARCHAR(MAX),
            @LI_RET INT;

    DECLARE cur CURSOR FOR
        SELECT Solicitud
        FROM #DocsAnulados;

    OPEN cur;
    FETCH NEXT FROM cur INTO @LI_SOLICITUD;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Obtener el usuario asociado a la solicitud
        SELECT @_UserName = u.UserName
        FROM BancaVirtual2.BancaVirtual.Usuario u
        INNER JOIN CREDITO..SL_SOLICITUD s 
            ON u.ClienteId = s.sol_cliente
        WHERE s.sol_solicitud = @LI_SOLICITUD;

        -- Construir request JSON
        SET @Request = '{ "solicitud": ' + CAST(@LI_SOLICITUD AS VARCHAR(20)) + ' }';

        -- Ejecutar notificación
        EXEC @LI_RET = [BancaVirtual2].[BancaVirtual].[spNotificacionEmailAnulacionSolCreditoCRW]
            @_UserName,
            @_SessionID OUTPUT,
            @_CodeReturn OUTPUT,
            @_Message OUTPUT,
            @Request,
            @Result OUTPUT;

        -- Validar error en envío
        IF @@ERROR <> 0 OR @LI_RET <> 0
        BEGIN
            PRINT 'Error al enviar correo para la anulación de solicitud ' + CAST(@LI_SOLICITUD AS VARCHAR);
        END

        FETCH NEXT FROM cur INTO @LI_SOLICITUD;
    END

    CLOSE cur;
    DEALLOCATE cur;

    RETURN 1;
END;
GO
