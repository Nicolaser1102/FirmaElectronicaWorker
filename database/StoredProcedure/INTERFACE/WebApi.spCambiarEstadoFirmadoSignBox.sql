USE INTERFACE  
GO

CREATE OR ALTER PROCEDURE [WebApi].[spCambiarEstadoFirmadoSignBox]
@_UserName   VARCHAR(20),
@_SessionID  INT OUTPUT,
@_CodeReturn INT OUTPUT,
@_Message    VARCHAR(200) OUTPUT,
@Request     VARCHAR(MAX),
@Result      VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @LI_SOLICITUD INT,
        @LI_LOTE INT,
        @LS_CODIGO_DOCUMENTO VARCHAR (20),
        @LS_SB_WEBHOOK_TXT VARCHAR(250),
        @LS_SB_WEBHOOK_PDF VARCHAR(250),
        @LS_SB_RESPUESTA_API VARCHAR (250),
        @LS_SB_RESPUESTA_JSON VARCHAR (MAX)

    -- Parsear los valores desde JSON
    SELECT @LI_SOLICITUD = [value]
    FROM OPENJSON (@Request)
    WHERE [key] = 'Solicitud'

    SELECT @LI_LOTE = [value]
    FROM OPENJSON (@Request)
    WHERE [key] = 'Lote'

    SELECT @LS_CODIGO_DOCUMENTO = [value]
    FROM OPENJSON (@Request)
    WHERE [key] = 'CodigoDocumento'

    SELECT @LS_SB_RESPUESTA_API = [value]
    FROM OPENJSON (@Request)
    WHERE [key] = 'RespuestaApiSignBox'

    SELECT @LS_SB_WEBHOOK_TXT = [value]
    FROM OPENJSON (@Request)
    WHERE [key] = 'WebHookTxt'

    SELECT @LS_SB_WEBHOOK_PDF = [value]
    FROM OPENJSON (@Request)
    WHERE [key] = 'WebHookPdf'

    SELECT @LS_SB_RESPUESTA_JSON = [value]
    FROM OPENJSON (@Request)
    WHERE [key] = 'JsonRespuestaSignBox'

    -- Actualizar el documento individual
    UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
    SET 
        SignboxEstadoFirma = 'F',
        SignBoxWeebhookTxt = @LS_SB_WEBHOOK_TXT,
        SignBoxWeebhookPdf = @LS_SB_WEBHOOK_PDF,
        SignBoxRespuestaApi = @LS_SB_RESPUESTA_API,
        SignBoxRespuestaJson = @LS_SB_RESPUESTA_JSON,
        SignBoxModificaUsuario = @_UserName,
        SignBoxModificaFecha = dbo.FechaSistema(),

        OnBoardingEstadoFirma = 'I',
        OnBoardingModificaUsuario = 'ADMIN',
        OnBoardingModificaFecha = dbo.FechaSistema()
    WHERE 
        CodigoDocumento = @LS_CODIGO_DOCUMENTO AND
        Solicitud = @LI_SOLICITUD AND
        Lote = @LI_LOTE;

    IF @@ERROR <> 0
    BEGIN
        SET @_CodeReturn = -1
        SET @_Message = 'ERROR AL ACTUALIZAR ESTADO F EN FIRMA ELECTRONICA SIGNBOX'
        RETURN
    END

    -- Si aún existen documentos NO firmados del lote, se marca como en proceso
    IF EXISTS (
        SELECT 1
        FROM [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
        WHERE 
            Solicitud = @LI_SOLICITUD AND
            Lote = @LI_LOTE AND
            SignboxEstadoFirma <> 'F'
    )
    BEGIN
        UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
        SET SignBoxProcesandoFirma = 1
        WHERE Solicitud = @LI_SOLICITUD AND Lote = @LI_LOTE;
    END
    ELSE
    BEGIN
        -- Todos firmados, marcar lote como no en proceso
        UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
        SET SignBoxProcesandoFirma = 0
        WHERE Solicitud = @LI_SOLICITUD AND Lote = @LI_LOTE;
    END

    SET @_CodeReturn = 1
    SET @_Message = 'OK'
END;
