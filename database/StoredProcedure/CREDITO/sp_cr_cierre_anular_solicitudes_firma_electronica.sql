USE CREDITO 
GO
CREATE  OR ALTER  PROCEDURE dbo.sp_cr_cierre_anular_solicitudes_firma_electr
    @ADT_FECHA DATETIME,
    @ADT_FECHA_PRC DATETIME,
    @AS_MSJ VARCHAR(100) OUT
AS
BEGIN
    -- SET NOCOUNT ON;

    ----------------------------------------------------------------------
    -- Crear tabla temporal para almacenar registros relevantes
    ----------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#DocsAnulados') IS NOT NULL
        DROP TABLE #DocsAnulados;

    CREATE TABLE #DocsAnulados (
        Solicitud INT,
        Id INT
    );

    ----------------------------------------------------------------------
    -- Insertar en la tabla temporal solo los registros que cumplen la condición
    ----------------------------------------------------------------------
    INSERT INTO #DocsAnulados (Solicitud, Id)
    SELECT 
        Solicitud,
        Id
    FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
    WHERE 
        (OnBoardingEstadoFirma IS NULL OR OnBoardingEstadoFirma != 'F')
        AND SignBoxCreacionFecha = @ADT_FECHA;

    ----------------------------------------------------------------------
    -- Actualizar los documentos anulados
    ----------------------------------------------------------------------
    UPDATE d
    SET 
        d.OnBoardingEstadoFirma = 'N',
        d.OnBoardingRutaDocumento = 'Solicitud de firma onboarding caducada'
    FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica d
    INNER JOIN #DocsAnulados t ON d.Id = t.Id;

    ----------------------------------------------------------------------
    -- Cambiar estado de las solicitudes y anularlas
    ----------------------------------------------------------------------
    DECLARE @LI_SOLICITUD INT,
            @AS_PROPIETARIO INT = 1,  -- Ajusta según necesidad
            @LI_RET INT;

    DECLARE cur1 CURSOR FOR
        SELECT Solicitud
        FROM #DocsAnulados;

    OPEN cur1;
    FETCH NEXT FROM cur1 INTO @LI_SOLICITUD;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Cambiar estado de la solicitud
        

        -- Anular solicitud vía flujo de trabajo
        EXEC @LI_RET = CREDITO..sp_sl_wf_anular_solicitud
            @LI_SOLICITUD, 
            'ADMIN', 
            @AS_MSJ OUTPUT;

		UPDATE PARAMETROS..WF_SOLICITUD
		set sol_id_actividad_actual = 17,
		sol_estado = 'B'
		where sol_referencia = @LI_SOLICITUD

        -- Opcional: manejo de error
        IF @@ERROR <> 0 OR @LI_RET <> 1
        BEGIN
            PRINT 'Error al anular solicitud vía WF: ' + CAST(@LI_SOLICITUD AS VARCHAR);
        END

        FETCH NEXT FROM cur1 INTO @LI_SOLICITUD;
    END

    CLOSE cur1;
    DEALLOCATE cur1;

    ----------------------------------------------------------------------
    -- Envío de correos para cada solicitud anulada
    ----------------------------------------------------------------------
    DECLARE @_UserName NVARCHAR(200),
            @_SessionID NVARCHAR(200),
            @_CodeReturn INT,
            @_Message NVARCHAR(500),
            @Request NVARCHAR(MAX),
            @Result NVARCHAR(MAX);

    DECLARE cur2 CURSOR FOR
        SELECT Solicitud
        FROM #DocsAnulados;

    OPEN cur2;
    FETCH NEXT FROM cur2 INTO @LI_SOLICITUD;

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

        FETCH NEXT FROM cur2 INTO @LI_SOLICITUD;
    END

    CLOSE cur2;
    DEALLOCATE cur2;

    ----------------------------------------------------------------------
    -- Finalización
    ----------------------------------------------------------------------
    SET @AS_MSJ = 'Proceso finalizado correctamente';
    RETURN 1;
END;


