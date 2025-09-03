USE PARAMETROS 
GO 
CREATE OR ALTER PROCEDURE [dbo].[sp_wf_cr_anular_solicitud]
@AI_ID_SOLICITUD INT,
@AS_USUARIO VARCHAR(15),
@AS_XML NVARCHAR(4000),
@AS_MSJ VARCHAR(100) OUTPUT
AS
	
DECLARE @LI_SOLICITUD INT,
		@LI_RET INT,
		@LI_CLIENTE INT,
		@LS_PRODUCTO VARCHAR(20)
			
SELECT @LI_SOLICITUD = CONVERT ( INT, sol_referencia),
@LI_CLIENTE = sol_id_cliente
FROM WF_SOLICITUD
WHERE sol_id_solicitud = @AI_ID_SOLICITUD


SET @LS_PRODUCTO = (SELECT sol_producto FROM CREDITO..SL_SOLICITUD where sol_solicitud = @LI_SOLICITUD)

EXEC @LI_RET = CREDITO..sp_sl_wf_anular_solicitud
@LI_SOLICITUD, 
@AS_USUARIO, 
@AS_MSJ OUTPUT
			
IF @LI_RET = -1
	RETURN -1
		


if exists (	select 1 
			from CREDITO..SL_SOLICITUD,CREDITO..CR_PARAM_PRODUCTO,CREDITO..CR_PARAMETROS 
			WHERE sol_solicitud = @LI_SOLICITUD AND 
			ppr_producto = sol_producto AND 
				ppr_id_parametro = par_id_parametro AND 
				par_parametro = 'CREDITO_PARA_WEB' AND 
				ppr_valor_b = 1
			)
BEGIN

	EXEC @LI_RET = BancaVirtual2.BancaVirtual.sp_bv_actualizar_estado_rol_pago 
	@AI_SOLICITUD=@LI_SOLICITUD,
	@AI_CLIENTE = @LI_CLIENTE,
	@AS_ESTADO = 'A',
	@AI_APROBADO = 3,
	@AS_USUARIO = @AS_USUARIO, 
	@AS_MSJ = @AS_MSJ OUTPUT

	IF @LI_RET = -1
		RETURN -1

END 


IF @LS_PRODUCTO = 'CRWEB'
	BEGIN 

	DECLARE		@_UserName varchar(20),
				@_SessionId int = NULL,
				@_CodeReturn int,
				@_Message varchar(200),
				@Request varchar(max),
				@Result varchar(max)


				SELECT @_UserName = UserName FROM BancaVirtual2.BancaVirtual.Usuario, CREDITO..SL_SOLICITUD where ClienteId = sol_cliente
				and sol_solicitud = @LI_SOLICITUD

				SET @Request = '{ "solicitud": ' + CAST(@LI_SOLICITUD AS varchar(20)) + ' }'

	EXEC @LI_RET = [BancaVirtual2].[BancaVirtual].[spNotificacionEmailAnulacionSolCreditoCRW]
					@_UserName                          ,
					@_SessionID                        output,
					@_CodeReturn                        output,
					@_Message                            output,
					@Request                            ,
					@Result                              output

					  IF @@ERROR <> 0
						BEGIN
							PRINT 'Error al enviar correo para la anulación de solicitud ' + CAST(@LI_SOLICITUD AS VARCHAR);
						   -- RETURN -1;
						END

	END

RETURN 1


