use parametros 
go

CREATE OR ALTER PROCEDURE sp_wf_cr_anular_renovacion
@AI_ID_SOLICITUD INT,
@AS_USUARIO VARCHAR(15),
@AS_XML NVARCHAR(4000),
@AS_MSJ VARCHAR(100) OUTPUT
AS
	DECLARE @LI_SOLICITUD INT,
			@LI_RET INT ,
			@LS_PRODUCTO VARCHAR(20)
			
SELECT @LI_SOLICITUD = CONVERT ( INT, sol_referencia)
FROM WF_SOLICITUD
WHERE sol_id_solicitud = @AI_ID_SOLICITUD

SET @LS_PRODUCTO = (SELECT sol_producto FROM CREDITO..SL_SOLICITUD where sol_solicitud = @LI_SOLICITUD)


EXEC @LI_RET = CREDITO..sp_cr_wf_anulacion_renovacion
		@LI_SOLICITUD, 
		@AS_USUARIO, 
		@AS_MSJ OUTPUT



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
		
RETURN @LI_RET


