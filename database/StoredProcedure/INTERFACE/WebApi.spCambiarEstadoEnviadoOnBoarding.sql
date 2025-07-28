USE INTERFACE 
GO


CREATE  OR ALTER     PROCEDURE [WebApi].[spCambiarEstadoEnviadoOnBoarding]
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

   @LS_REQUEST_ID VARCHAR (150),
   @LS_DETAIL VARCHAR(300),
   @LS_OB_RESPUESTA_JSON VARCHAR (MAX)

  SELECT @LI_SOLICITUD = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Solicitud'

  SELECT @LI_LOTE = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Lote'

  SELECT @LS_REQUEST_ID = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'RequestId'

  SELECT @LS_DETAIL = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Detail'

  SELECT @LS_OB_RESPUESTA_JSON = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'JsonRespuestaOnBoarding'


			UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
			SET 
			OnBoardingEstadoFirma = 'E',
			OnBoardingRequestId = @LS_REQUEST_ID,
			OnBoardingRespuestaDetail = @LS_DETAIL,
			OnBoardingRespuestaJson = @LS_OB_RESPUESTA_JSON,
			OnBoardingModificaUsuario = @_UserName,
			OnBoardingModificaFecha = dbo.FechaSistema()
			

			where 
				Solicitud = @LI_SOLICITUD AND
				Lote = @LI_LOTE

			if @@ERROR <> 0
				begin
					set @_CodeReturn= -1
					set @_Message= 'ERROR AL ACTUALIZAR ESTADO E EN FIRMA ELECTRONICA ONBOARDING'
					RETURN
				end

SET @_CodeReturn = 1




