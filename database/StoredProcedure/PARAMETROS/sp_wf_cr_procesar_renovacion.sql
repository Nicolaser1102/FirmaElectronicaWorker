USE PARAMETROS 
GO
CREATE   OR ALTER   PROCEDURE [sp_wf_cr_procesar_renovacion]
@AI_ID_SOLICITUD INT,
@AS_USUARIO VARCHAR(15),
@AS_XML NVARCHAR(4000),
@AS_MSJ VARCHAR(100) OUTPUT
AS
BEGIN
	DECLARE @LI_SOLICITUD INT,
			@LI_RET INT,
			@LS_TIPO_OP CHAR(1) ,@LI_ID INT,
			@LS_PRODUCTO VARCHAR(20),
			@LI_CLIENTE INT,
			@LS_TIPO_CUENTA CHAR(2)
			
	SELECT @LI_SOLICITUD = CONVERT ( INT, sol_referencia)
	FROM WF_SOLICITUD
	WHERE sol_id_solicitud = @AI_ID_SOLICITUD
	

	DECLARE	@LS_OFICINA CHAR(4),
			@LS_MONEDA CHAR(1),
			@LS_CREDITO VARCHAR(20),
			@LM_VALOR MONEY,
			@LM_EFECTIVO MONEY,
			@LM_CHEQUE MONEY,
			@LI_RENOVACION_MANUAL BIT,
			@LI_RENOVACION_AUTOMATICA BIT,
			@LS_TIPO_TRAN CHAR(3), 
			@LS_REFERENCIA VARCHAR(20), 
			@LS_CUENTA VARCHAR(20),
			@LS_CUENTA_DEB VARCHAR(20), 
			@LDT_FECHA_VALOR DATETIME,
			@LI_BANCO VARCHAR(25),
			@LI_CUENTA INTEGER,
			@LI_TRA_ID INTEGER,
			@LS_DESMBOLSO CHAR(3),
			@LM_VALOR_PAGADO MONEY
			
			
		
		
DECLARE @idoc int

EXEC sp_xml_preparedocument @idoc OUTPUT, @AS_XML
SELECT  @LS_OFICINA = OFICINA,
		@LS_MONEDA = MONEDA,
		@LS_CREDITO = CREDITO,
		@LM_VALOR = VALOR,
		@LM_EFECTIVO  = EFECTIVO,
		@LM_CHEQUE = CHEQUE,
		@LI_RENOVACION_MANUAL = RENOVACION_MANUAL,
		@LI_RENOVACION_AUTOMATICA = RENOVACION_AUTOMATICA,
		@LS_TIPO_TRAN = TIPO_TRAN, 
		@LS_REFERENCIA = REFERENCIA, 
		@LDT_FECHA_VALOR = FECHA_VALOR,
		@LI_BANCO = BANCO,
		@LI_CUENTA = CUENTA,
		@LS_CUENTA_DEB = CUENTA_DEB,
		@LS_DESMBOLSO = DESEMBOLSO
FROM   OPENXML (@idoc, N'//DATOS')
      WITH (OFICINA CHAR(4) 'OFICINA' ,
			MONEDA CHAR(1) 'MONEDA',
			CREDITO VARCHAR(20) 'CREDITO',
			VALOR MONEY 'VALOR',
			EFECTIVO MONEY 'EFECTIVO',
			CHEQUE MONEY 'CHEQUE',
			RENOVACION_MANUAL BIT 'RENOVACION_MANUAL',
			RENOVACION_AUTOMATICA BIT 'RENOVACION_AUTOMATICA',
			TIPO_TRAN CHAR(3) 'TIPO_TRAN', 
			REFERENCIA VARCHAR(20) 'REFERENCIA', 
			FECHA_VALOR DATETIME 'FECHA_VALOR',
			BANCO INT 'BANCO',
			CUENTA INT 'CUENTA', 
			CUENTA_DEB VARCHAR(16) 'CUENTA_DEB', 
			DESEMBOLSO CHAR(3) 'DESEMBOLSO') R


EXEC sp_xml_removedocument @idoc


SELECT @LS_TIPO_OP = sol_tipo_operacion ,
@LI_CLIENTE = sol_cliente
FROM CREDITO..SL_SOLICITUD
WHERE sol_solicitud = @LI_SOLICITUD

IF @LM_VALOR = 0.00 AND @LS_TIPO_OP <> 'T'
BEGIN 

	IF NOT EXISTS(SELECT 1 FROM CREDITO..CR_TIPO_TRANSACCION WHERE ttr_tipo_tran = @LS_TIPO_TRAN AND ttr_es_documento = 1)
	BEGIN
		
		SET @AS_MSJ = 'PARA PAGOS EN CERO DEBE UTILIZAR LA FORMA DE PAGO DOCUMENTO'
		RETURN -1	
	
	END 


END 

SET @LS_PRODUCTO = (SELECT sol_producto FROM CREDITO..SL_SOLICITUD where sol_solicitud = @LI_SOLICITUD)

IF @LS_PRODUCTO = 'CRWEB'
	BEGIN 

		IF NOT EXISTS (SELECT * FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica WHERE Solicitud = @LI_SOLICITUD
						)
						BEGIN 
							SET @AS_MSJ = 'NO SE PUDIERON ENVIAR LAS SOLICITUDES DE FIRMA DE ONBOARDING'
							RETURN -1
						END 

		IF EXISTS (SELECT * FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica WHERE Solicitud = @LI_SOLICITUD
						AND  OnBoardingRutaDocumento IS NULL AND OnBoardingEstadoFirma != 'F' )
						BEGIN 
							SET @AS_MSJ = 'DOCUMENTOS PENDIENTES DE FIRMA ELECTRÓNICA'
							RETURN -1
						END 
		IF @LI_CUENTA = 0 OR @LI_CUENTA IS NULL
			BEGIN 
			IF EXISTS (SELECT 1    
					FROM CUENTAS..AH_CUENTAS , CUENTAS..AH_TIPOS_CUENTA     
					WHERE ( AH_CUENTAS.cue_tipo = AH_TIPOS_CUENTA.tip_tipo_cuenta ) 
					and          ( ( AH_CUENTAS.cue_estado in ( 'A', 'P' ) ) 
					and          ( AH_CUENTAS.cue_cliente = @LI_CLIENTE) 
					and          ( AH_TIPOS_CUENTA.tip_es_ahorro_ordinario = 1 ) )  )

					BEGIN
						SELECT  @LS_CUENTA = AH_CUENTAS.cue_cuenta, @LS_TIPO_CUENTA = AH_CUENTAS.cue_tipo      
					FROM CUENTAS..AH_CUENTAS , CUENTAS..AH_TIPOS_CUENTA     
					WHERE ( AH_CUENTAS.cue_tipo = AH_TIPOS_CUENTA.tip_tipo_cuenta ) 
					and          ( ( AH_CUENTAS.cue_estado in ( 'A', 'P' ) ) 
					and          ( AH_CUENTAS.cue_cliente = @LI_CLIENTE) 
					and          ( AH_TIPOS_CUENTA.tip_es_ahorro_ordinario = 1 ) )  
					END

					ELSE

						BEGIN
								SELECT  @LS_CUENTA = AH_CUENTAS.cue_cuenta   , @LS_TIPO_CUENTA = AH_CUENTAS.cue_tipo  
						FROM CUENTAS..AH_CUENTAS , CUENTAS..AH_TIPOS_CUENTA     
						WHERE ( AH_CUENTAS.cue_tipo = AH_TIPOS_CUENTA.tip_tipo_cuenta ) 
						and          ( ( AH_CUENTAS.cue_estado in ( 'A', 'P' ) ) 
						and          ( AH_CUENTAS.cue_cliente = @LI_CLIENTE) 
						and          ( AH_CUENTAS.cue_tipo = 'O' ) )  
						END
					
				END
	
	END 

	EXEC @LI_RET =  CREDITO..sp_cr_renovacion_credito
					@AS_USUARIO	= @AS_USUARIO,
					@AS_OFICINA	= @LS_OFICINA,
					@AS_MONEDA	= @LS_MONEDA,
					@AS_CREDITO	= @LS_CREDITO,
					@AM_VALOR	= @LM_VALOR,
					@AM_EFECTIVO = @LM_EFECTIVO,
					@AM_CHEQUE	= @LM_CHEQUE,
					@AI_TRA_ID = @LI_TRA_ID OUTPUT,
					@AS_MSJ =  @AS_MSJ OUTPUT,
					@AB_RENOVACION_MANUAL = @LI_RENOVACION_MANUAL,
					@AB_RENOVACION_AUTOMATICA = @LI_RENOVACION_AUTOMATICA,
					@AS_TIPO_TRAN  = @LS_TIPO_TRAN, 
					@AS_REFERENCIA = @LS_REFERENCIA,
					@ADT_FECHA_VALOR = @LDT_FECHA_VALOR,
					@AI_BANCO_DEP  = @LI_BANCO,
					@AS_CUENTA_DEP  = @LS_CUENTA,
					@AS_TIPO_DESEMBOLSO = @LS_DESMBOLSO,
					@AS_TIPO_CUENTA_DEP = @LS_TIPO_CUENTA

					
					

	IF(@LI_RET <> 1)
		RETURN @LI_RET

		IF @LS_PRODUCTO = 'CRWEB'
	BEGIN 
	--Enviar notificación SMS del desembolso
		EXEC @LI_RET = [BancaVirtual2].[BancaVirtual].[sp_crm_notif_sms_cr_desembolso_crbv]
					@LI_ID  OUTPUT,
					@LI_SOLICITUD ,
					'ADMIN',
					@AS_MSJ	 OUTPUT

					 IF @@ERROR <> 0
		BEGIN
			PRINT 'Error al enviar SMS de encuesta de solicitud para la solicitud ' + CAST(@LI_SOLICITUD AS VARCHAR);
			--RETURN -1;
		END

	
		DECLARE		@_UserName varchar(20),
					@_SessionId int = NULL,
					@_CodeReturn int,
					@_Message varchar(200),
					@Request varchar(max),
					@Result varchar(max)


					SELECT @_UserName = UserName FROM BancaVirtual2.BancaVirtual.Usuario, CREDITO..SL_SOLICITUD where ClienteId = sol_cliente
					and sol_solicitud = @LI_SOLICITUD

					SET @Request = '{ "credito": "' + @LS_CREDITO + '" }'

		EXEC @LI_RET = [BancaVirtual2].[BancaVirtual].[spNotificacionEmailDesembolsoCreditoCRW]
						@_UserName                          ,
						@_SessionID                        output,
						@_CodeReturn                        output,
						@_Message                            output,
						@Request                            ,
						@Result                              output

						  IF @@ERROR <> 0
		BEGIN
			PRINT 'Error al enviar correo para la solicitud ' + CAST(@LI_SOLICITUD AS VARCHAR);
		   -- RETURN -1;
		END

	END


	IF EXISTS(	SELECT 1
				FROM CREDITO..CR_TIPO_TRANSACCION
				WHERE ttr_es_pago_nd = 1
				AND ttr_tipo_tran = @LS_TIPO_TRAN )
	BEGIN

	EXEC @LI_RET = CREDITO..sp_cr_debito_a_cuenta_x_renovacion
					@AS_CUENTA 	= @LS_CUENTA_DEB,
					@AS_OFICINA = @LS_OFICINA,
					@AS_USUARIO = @AS_USUARIO,
					@AS_CREDITO = @LS_CREDITO,
					@AM_VALOR 	= @LM_VALOR,
					@AM_VALOR_PAGADO = @LM_VALOR_PAGADO OUTPUT,
					@AS_REFERENCIA = @LS_REFERENCIA,
					@AS_MSJ 	= @AS_MSJ OUTPUT,
					@AI_TRA_ID	= @LI_TRA_ID OUTPUT,
					@AI_ID_TRANS_ORIGEN = NULL

	END




		
	--RETURN -1
	RETURN @LI_RET
END




