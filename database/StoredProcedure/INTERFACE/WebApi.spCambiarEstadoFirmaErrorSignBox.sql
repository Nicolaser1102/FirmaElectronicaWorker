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
   @LS_SB_RESPUESTA_JSON VARCHAR (MAX)

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


  

			UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
			SET 
			SignboxEstadoFirma = 'R',
			SignboxIntentosFirma += 1,
			SignBoxRespuestaApi = @LS_SB_RESPUESTA_API,
			SignBoxRespuestaJson = @LS_SB_RESPUESTA_JSON,
			SignBoxModificaUsuario = @_UserName,
			SignBoxModificaFecha = dbo.FechaSistema()

			where 
				CodigoDocumento = @LS_CODIGO_DOCUMENTO  AND
				Solicitud = @LI_SOLICITUD AND
				Lote = @LI_LOTE

			if @@ERROR <> 0
				begin
					set @_CodeReturn= -1
					set @_Message= 'ERROR AL ACTUALIZAR ESTADO A R'
					RETURN
				end

				--SI ES EL QUINTO INTENTO LE ACTUALIZAMOS EL ESTADO A 'E'

SET @_CodeReturn = 1




