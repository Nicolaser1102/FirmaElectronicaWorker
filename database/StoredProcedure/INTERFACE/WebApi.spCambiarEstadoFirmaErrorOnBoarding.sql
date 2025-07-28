USE INTERFACE 
GO

CREATE  OR ALTER     PROCEDURE [WebApi].[spCambiarEstadoFirmaErrorOnBoarding]
@_UserName   VARCHAR(20)                              ,
@_SessionID  INT OUTPUT                                      ,
@_CodeReturn INT OUTPUT                                      ,
@_Message    VARCHAR(200) OUTPUT               ,
@Request     VARCHAR(MAX)                             ,
@Result      VARCHAR(MAX) OUTPUT
as
DECLARE
   @LI_SOLICITUD INT,
   @LI_LOTE INT,

   @LS_RESP_DETAIL VARCHAR (300),
   @LS_OB_RESPUESTA_JSON VARCHAR (MAX),

   @LI_INTENTOS_ACTUALES INT,
   @LI_MAX_INTENTOS_FIRMA INT = 5

  SELECT @LI_SOLICITUD = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Solicitud'

  SELECT @LI_LOTE = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Lote'

  SELECT @LS_RESP_DETAIL = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Detail'

  SELECT @LS_OB_RESPUESTA_JSON = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'JsonRespuestaOnBoarding'


  -- Obtener el número actual de intentos
	SELECT TOP 1 @LI_INTENTOS_ACTUALES =  OnBoardingIntentosFirma
	FROM [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
	WHERE
	   Solicitud = @LI_SOLICITUD 
	  AND Lote = @LI_LOTE;


	IF (@LI_INTENTOS_ACTUALES < @LI_MAX_INTENTOS_FIRMA)
	BEGIN
		-- Actualizar datos de intento
		UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
		SET 
			OnBoardingEstadoFirma = 'R',
			OnBoardingIntentosFirma = OnBoardingIntentosFirma + 1,
			OnBoardingRespuestaDetail = @LS_RESP_DETAIL,
			OnBoardingRespuestaJson = @LS_OB_RESPUESTA_JSON,
			OnBoardingModificaUsuario = @_UserName,
			OnBoardingModificaFecha = dbo.FechaSistema()
		WHERE  
			Solicitud = @LI_SOLICITUD 
			AND Lote = @LI_LOTE;

		-- Verificar errores en la actualización
		IF @@ERROR <> 0
		BEGIN
			SET @_CodeReturn = -1;
			SET @_Message = 'ERROR AL ACTUALIZAR ESTADO A R';
			RETURN;
		END

		-- Verificar si con esta actualización se llegó al límite de intentos
		IF (@LI_INTENTOS_ACTUALES + 1 = @LI_MAX_INTENTOS_FIRMA)
		BEGIN
			UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
			SET OnBoardingEstadoFirma = 'N'
			WHERE 
				Solicitud = @LI_SOLICITUD 
				AND Lote = @LI_LOTE;
		END
	END

SET @_CodeReturn = 1




