USE INTERFACE 
GO

CREATE  OR ALTER     PROCEDURE [WebApi].[spCambiarEstadoFirmaErrorSignBox]
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
   @LS_CODIGO_DOCUMENTO VARCHAR (20),
   @LS_SB_RESPUESTA_API VARCHAR (250),
   @LS_SB_RESPUESTA_JSON VARCHAR (MAX),
   @LI_INTENTOS_ACTUALES INT,
   @LI_MAX_INTENTOS_FIRMA INT

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


  SELECT @LS_SB_RESPUESTA_JSON = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'JsonRespuestaSignBox'


  -- Obtener el número actual de intentos
	SELECT @LI_INTENTOS_ACTUALES = SignboxIntentosFirma
	FROM [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
	WHERE CodigoDocumento = @LS_CODIGO_DOCUMENTO  
	  AND Solicitud = @LI_SOLICITUD 
	  AND Lote = @LI_LOTE;

	IF (@LI_INTENTOS_ACTUALES < @LI_MAX_INTENTOS_FIRMA)
	BEGIN
		-- Actualizar datos de intento
		UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
		SET 
			SignboxEstadoFirma = 'R',
			SignboxIntentosFirma = SignboxIntentosFirma + 1,
			SignBoxRespuestaApi = @LS_SB_RESPUESTA_API,
			SignBoxRespuestaJson = @LS_SB_RESPUESTA_JSON,
			SignBoxModificaUsuario = @_UserName,
			SignBoxModificaFecha = dbo.FechaSistema()
		WHERE 
			CodigoDocumento = @LS_CODIGO_DOCUMENTO  
			AND Solicitud = @LI_SOLICITUD 
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
			SET SignboxEstadoFirma = 'E'
			WHERE 
				CodigoDocumento = @LS_CODIGO_DOCUMENTO  
				AND Solicitud = @LI_SOLICITUD 
				AND Lote = @LI_LOTE;
		END
	END

SET @_CodeReturn = 1




