USE INTERFACE
GO

CREATE OR ALTER PROCEDURE [WebApi].[spCambiarEstadoFirmaOnBoarding]
    @_UserName   VARCHAR(20),
    @_SessionID  INT OUTPUT,
    @_CodeReturn INT OUTPUT,
    @_Message    VARCHAR(200) OUTPUT,
    @Request     VARCHAR(MAX),
    @Result      VARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE
        @LI_SOLICITUD INT,
        @LI_LOTE INT,
        @LB_RESULT BIT,
        @LS_STATE VARCHAR(50),
		@LS_DETAIL VARCHAR (25) = NULL,
        @LS_OB_RESPUESTA_JSON VARCHAR(MAX),
        @LS_ESTADO_FIRMA CHAR(1)

    -- Extraer datos del JSON
    SELECT @LI_SOLICITUD = [value]
    FROM OPENJSON(@Request)
    WHERE [key] = 'Solicitud'

    SELECT @LI_LOTE = [value]
    FROM OPENJSON(@Request)
    WHERE [key] = 'Lote'

    SELECT @LB_RESULT = [value]
    FROM OPENJSON(@Request)
    WHERE [key] = 'Result'

    SELECT @LS_STATE = [value]
    FROM OPENJSON(@Request)
    WHERE [key] = 'State'

	SELECT @LS_DETAIL = [value]
    FROM OPENJSON(@Request)
    WHERE [key] = 'Detail'

    SELECT @LS_OB_RESPUESTA_JSON = [value]
    FROM OPENJSON(@Request)
    WHERE [key] = 'JsonRespuestaOnBoarding'

    IF (@LB_RESULT = 1)
    BEGIN
        -- Asignar estado según el valor de @LS_STATE
        SET @LS_ESTADO_FIRMA =
            CASE UPPER(@LS_STATE)
                WHEN 'OTP'        THEN 'O'
                WHEN 'CONTRATO'   THEN 'C'
                WHEN 'BIOMETRIA'  THEN 'B'
                WHEN 'CHECKID'    THEN 'K'
                WHEN 'ONESHOT'    THEN 'S'
                ELSE 'E'  -- Estado general si no coincide ninguno
            END

        UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
        SET 
            OnBoardingEstadoFirma = @LS_ESTADO_FIRMA,
            OnBoardingRespuestaJson = @LS_OB_RESPUESTA_JSON,
            OnBoardingModificaUsuario = @_UserName,
            OnBoardingModificaFecha = dbo.FechaSistema()
        WHERE 
            Solicitud = @LI_SOLICITUD AND
            Lote = @LI_LOTE

        IF @@ERROR <> 0
        BEGIN
            SET @_CodeReturn = -1
            SET @_Message = 'ERROR AL ACTUALIZAR ESTADO EN FIRMA ELECTRONICA ONBOARDING'
            RETURN
        END
    END
    ELSE
    BEGIN

	    UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
        SET 
            OnBoardingProcesandoFirma = 1
        WHERE 
            Solicitud = @LI_SOLICITUD AND
            Lote = @LI_LOTE



        UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
        SET 
            OnBoardingEstadoFirma = 'F',
			OnBoardingRespuestaDetail = @LS_DETAIL,
            OnBoardingRespuestaJson = @LS_OB_RESPUESTA_JSON,
            OnBoardingModificaUsuario = @_UserName,
            OnBoardingModificaFecha = dbo.FechaSistema()
        WHERE 
            Solicitud = @LI_SOLICITUD AND
            Lote = @LI_LOTE

			--AUMENTAR SP PARA EL CAMBIO DE ESTADO DE LA SOLICITUD DE CREDITO Y QUE APAREZCA EN LA
			--BANDEJA DE ENTRADA DE ORION



			---------

        IF @@ERROR <> 0
        BEGIN
            SET @_CodeReturn = -1
            SET @_Message = 'ERROR AL ACTUALIZAR ESTADO F EN FIRMA ELECTRONICA ONBOARDING'
            RETURN
        END
    END

	 UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
        SET 
            OnBoardingProcesandoFirma = 0
        WHERE 
            Solicitud = @LI_SOLICITUD AND
            Lote = @LI_LOTE

    SET @_CodeReturn = 1
    SET @_Message = 'Estado actualizado correctamente'
END
