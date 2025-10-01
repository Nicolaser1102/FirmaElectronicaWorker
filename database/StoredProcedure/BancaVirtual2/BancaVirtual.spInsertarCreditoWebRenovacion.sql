USE BancaVirtual2
go
CREATE   OR ALTER   procedure [BancaVirtual].[spInsertarCreditoWebRenovacion]
@AS_JSON                           varchar(MAX),
@usuarioID							INT,
@AS_CREDITO							VARCHAR(50),
@AS_MSJ								VARCHAR(100) output,
@_CodeReturn						INT OUTPUT,
@AI_ID_SOLICITUD                    int output
as


declare
			@SolicitudID		 int,
			@OTP varchar(10),
			@hashPassword varchar(max),
			@JSON	varchar(max),
			@RET		int,
			@montoMaximo money,
			@plazoMaximo int,
			@cuenta varchar(16),
			@cuotaAproximada money,
			@solicitud int,
			@asesor VARCHAR(15),
			@tasa	money, 
			@tipoCuota char(10),
			@descuentos money,
			@fechaOtorgamiento datetime,
			@ADT_FECHA_1ER_PG datetime,
			@id_wf_solicitud INT,
			@CREDITO varchar(20),
			@Proceso varchar(20),
			@motivo varchar(3),
			@destino varchar(3),
			@tipoDesembolso  varchar(10) = 'ACB',
			@nombreBanco varchar(50),
			@tipoCuenta varchar(1),
			@cuentaDesembolso varchar(16),
			@NumeroCuenta varchar(16),
			@entidadFinanciera int,
			@LI_TRA_ID INT,
			@AI_SOLICITUD_RENOVACION INT 


		 	SELECT
          @montoMaximo = montoMaximo,
		  @plazoMaximo = plazoMaximo,
		  @cuenta = cuenta,
		  @tipoCuota = tipoCuota,
		  @cuotaAproximada = cuotaAproximada,
		  @motivo = motivoCredito,
		  @destino = destinoCredito,
		  @nombreBanco = banco,
		  @tipoCuenta = tipoCuenta,
		  @NumeroCuenta = numeroCuenta
    FROM OPENJSON(@AS_JSON)                            
      WITH (                      
		 montoMaximo money '$.credito.montoMaximo',
		 plazoMaximo int '$.credito.plazoMaximo',
		 cuenta varchar(16) '$.credito.cuenta',
		 tipoCuota char(1) '$.credito.tipoCuota',
		 cuotaAproximada money '$.credito.cuotaAproximada',
		 motivoCredito varchar(3) '$.credito.motivoCredito',
		 destinoCredito varchar(3) '$.credito.destinoCredito',
		 banco varchar(50) '$.referenciaBancaria.banco',
		 tipoCuenta varchar(1) '$.referenciaBancaria.tipoCuenta',
		 numeroCuenta varchar(16) '$.referenciaBancaria.numeroCuenta');


		 SELECT 'RENOVACION'


	set @tasa = CREDITO.dbo.f_cr_obtener_tasa_producto('CRWEB')
	select @fechaOtorgamiento =PARAMETROS.dbo.FechaSistema()  --GETDATE()
	select @plazoMaximo = @plazoMaximo * 30

		if @tipoCuota = 'C' 
	BEGIN
		SET @tipoCuota = 'FRANCESA'
		SET @tipoCuota ='2'
	END
	ELSE
	BEGIN
		SET @tipoCuota = 'ALEMANA'
		SET @tipoCuota ='5'
	END

	-- CALCULO FECHA 1ER CUOTA
	EXEC CREDITO..sp_cr_calcular_fecha_1er_pago_mensual_simulacion
			@AS_PRODUCTO = 'CRWEB',
			@AM_MONTO = @montoMaximo,
			@ADEC_TASA = @tasa,
			@AS_TIPO_TABLA = @tipoCuota,
			@AI_PLAZO = @plazoMaximo,
			@ADT_FECHA_OTOR = @fechaOtorgamiento,
			@AS_FORMA_PAGO = 'M',
			@ADT_FECHA_1ER_PAGO = @ADT_FECHA_1ER_PG OUTPUT




	EXEC @solicitud = CREDITO..sp_cr_renovacion_ingreso
			@AS_CREDITO = @AS_CREDITO,
			@AI_SOLICITUD = @solicitud,
			@AS_TIPO_RENOVACION = 'T',
			@AM_MONTO = @montoMaximo,
			@ADEC_TASA = @tasa,
			@AS_FORMA_PAGO = 'M',
			@AI_PLAZO = @plazoMaximo,
			@AS_TIPO_GRACIA = 'N',
			@AI_GRACIA = 0,
			@ADT_FECHA_OTOR = @fechaOtorgamiento,
			@AS_OFICINA = '1001',
			@AS_USUARIO = 'ADMIN',--@asesor,
			@AS_MSJ = @AS_MSJ output,
			@ADT_FECHA_1ER_PG = @ADT_FECHA_1ER_PG,
			@AS_PRODUCTO = 'CRWEB',
			@AS_TIPO_TABLA = @tipoCuota,
			@AS_FORMA_PAGO_INT = 'M'
			

			IF @solicitud = -1 
			BEGIN 
			
				SET @AS_MSJ = @AS_MSJ + Cast(@solicitud as varchar(max))
				SET @_CodeReturn = -1
				RETURN
			END 

	
	UPDATE CREDITO..SL_SOLICITUD 
	SET sol_tipo_consumo = 'OT',
	sol_motivo_prestamo = @motivo,
	sol_asesor = 'ADMIN' ,
	sol_fondo = 'P'
	WHERE sol_solicitud = @solicitud

	IF @@ERROR <> 0 
	BEGIN
		SET @AS_MSJ = 'ERROR AL ACTUALIZAR DATOS DE LA SOLICITUD.'
		SET @_CodeReturn = -1
		RETURN
	END 	
	
	exec  @_CodeReturn = CREDITO..sp_sl_calcular_descuentos_x_solicitud @solicitud 
	IF @_CodeReturn = -1 
	BEGIN 
		
		SET @AS_MSJ = 'ERROR AL CALCULAR DESCUENTOS POR SOLICITUD.'
		SET @_CodeReturn = -1
		RETURN
	END 
	exec @_CodeReturn = CREDITO..sp_sl_calcular_monto_financiado @solicitud,NULL,@AS_MSJ OUTPUT
	
	IF @_CodeReturn = -1 
	BEGIN 
		SET @AS_MSJ = 'ERROR AL CALCULAR MONTO FINANCIADO'
		SET @_CodeReturn = -1
		RETURN
	END 	

	EXEC @_CodeReturn = CREDITO..sp_sl_wf_genera_comite_aprobacion @solicitud, 'ADMIN', @AS_MSJ OUTPUT
		IF @_CodeReturn = -1 
	BEGIN 
		
		SET @_CodeReturn = -1
		RETURN
	END 


		----
	--Insertar en el flujo
	DECLARE 
	@AI_ID_SOLICITUD_WF INT,
	@AI_ID_PROCESO INT,
	@AS_PROPIETARIO VARCHAR(15)

	SELECT @AI_ID_PROCESO =  PRO_ID_PROCESO from CREDITO..CR_PRODUCTOS, CREDITO..SL_sOLICITUD where 
	sol_producto = pro_producto 
	and sol_solicitud = @solicitud
	
	SELECT TOP 1 @AS_PROPIETARIO = ISNULL(usu_usuario,'LJORDAN') FROM  PARAMETROS..SE_USUARIOS, BancaVirtual.CredencialesFirmantesCoop
	WHERE usu_id = Identificacion
	and Estado = 'A'
	
	


	EXEC @_CodeReturn = PARAMETROS..sp_wf_solicitud_insertar
    @AI_ID_SOLICITUD = @AI_ID_SOLICITUD_WF OUTPUT,
    @AI_ID_PROCESO   = @AI_ID_PROCESO,
    @AI_ID_CLIENTE   = @usuarioID,
    @AS_OFICINA      = '1001',
    @AS_REFERENCIA   = @solicitud,
    @AS_PROPIETARIO  = 'LJORDAN',
    @AS_USUARIO      = 'LJORDAN',
    @AS_MSJ          = @AS_MSJ OUTPUT;

    IF @_CodeReturn = -1 
	BEGIN 
		SET @_CodeReturn = -1
		RETURN
	END 


		UPDATE PARAMETROS..WF_SOLICITUD
		set sol_id_actividad_actual = 61 --SELECT * FROM WF_ACTIVIDAD where act_descripcion = 'PAGO RENOVACION CREDITO'
		where sol_id_solicitud = @AI_ID_SOLICITUD_WF


	------fin insertar flujo


	
	EXEC CREDITO..sp_sl_procesar_aprobacion @solicitud,'A', NULL, 'NINGUNA',@montoMaximo,'M','M',@plazoMaximo,'LBAQUERIZO', @AS_MSJ OUTPUT, NULL, NULL
    IF @_CodeReturn = -1 
	BEGIN 
		
		SET @_CodeReturn = -1
		RETURN
	END 

   EXEC CREDITO..sp_sl_procesar_aprobacion @solicitud,'A', NULL, 'NINGUNA',@montoMaximo,'M','M',@plazoMaximo,'MNAVARRETE', @AS_MSJ OUTPUT, NULL, NULL
	 IF @_CodeReturn = -1 
	BEGIN 
		
		SET @_CodeReturn = -1
		RETURN
	END 

	EXEC CREDITO..sp_sl_procesar_aprobacion @solicitud,'A', NULL, 'NINGUNA',@montoMaximo,'M','M',@plazoMaximo,'KAGUIRRE', @AS_MSJ OUTPUT, NULL, NULL
	 IF @_CodeReturn = -1 
	BEGIN 
		
		SET @_CodeReturn = -1
		RETURN
	END 


	UPDATE CREDITO..SL_SOLICITUD 
	set sol_estado = 'S'
	WHERE sol_solicitud = @solicitud 


	SET @AI_ID_SOLICITUD = @solicitud




	EXEC CREDITO..sp_sl_solicitud_cambiar_estado @solicitud,'A', '1', 'ADMIN'
	
	--select @entidadFinanciera = cli_entidad_financiera
	--from CLIENTES..CL_CLIENTE
	--where cli_id = @usuarioID

	--if @entidadFinanciera = 4
	--BEGIN
	--	SET @tipoDesembolso = 'ACB'
	--END

	-- if @entidadFinanciera = 14
	--BEGIN
	--	SET @tipoDesembolso = 'ACI'
	--END

	-- if @entidadFinanciera = 17
	--BEGIN
	--	SET @tipoDesembolso = 'ACP'
	--END
	
	--if @entidadFinanciera = 18
	--BEGIN 
	--	SET @tipoDesembolso = 'ACB'
	--END

	--IF EXISTS (SELECT 1    
	--FROM CUENTAS..AH_CUENTAS , CUENTAS..AH_TIPOS_CUENTA     
	--WHERE ( AH_CUENTAS.cue_tipo = AH_TIPOS_CUENTA.tip_tipo_cuenta ) 
	--and          ( ( AH_CUENTAS.cue_estado in ( 'A', 'P' ) ) 
	--and          ( AH_CUENTAS.cue_cliente = @usuarioID) 
	--and          ( AH_TIPOS_CUENTA.tip_es_ahorro_ordinario = 1 ) )  )

	--BEGIN
	--	SELECT  @cuentaDesembolso = AH_CUENTAS.cue_cuenta     
	--FROM CUENTAS..AH_CUENTAS , CUENTAS..AH_TIPOS_CUENTA     
	--WHERE ( AH_CUENTAS.cue_tipo = AH_TIPOS_CUENTA.tip_tipo_cuenta ) 
	--and          ( ( AH_CUENTAS.cue_estado in ( 'A', 'P' ) ) 
	--and          ( AH_CUENTAS.cue_cliente = @usuarioID) 
	--and          ( AH_TIPOS_CUENTA.tip_es_ahorro_ordinario = 1 ) )  
	--END

	--ELSE

	--BEGIN
	--		SELECT  @cuentaDesembolso = AH_CUENTAS.cue_cuenta     
	--FROM CUENTAS..AH_CUENTAS , CUENTAS..AH_TIPOS_CUENTA     
	--WHERE ( AH_CUENTAS.cue_tipo = AH_TIPOS_CUENTA.tip_tipo_cuenta ) 
	--and ( ( AH_CUENTAS.cue_estado in ( 'A', 'P' ) ) 
	--and          ( AH_CUENTAS.cue_cliente = @usuarioID) 
	--and          ( AH_CUENTAS.cue_tipo = 'O' ) )  
	--END


	/*EXEC @_CodeReturn =  CREDITO..sp_cr_renovacion_credito
					@AS_USUARIO	= 'ADMIN',
					@AS_OFICINA	= '1001',
					@AS_MONEDA	= 'D',
					@AS_CREDITO	= @AS_CREDITO,
					@AM_VALOR	= @montoMaximo, 
					@AM_EFECTIVO = 0,
					@AM_CHEQUE	= 0,
					@AI_TRA_ID = @LI_TRA_ID OUTPUT,
					@AS_MSJ =  @AS_MSJ OUTPUT,
					@AB_RENOVACION_MANUAL = 1,
					@AB_RENOVACION_AUTOMATICA = 0,
					@AS_TIPO_TRAN  = 'REN', 
					@AS_REFERENCIA = @cuentaDesembolso,
					@ADT_FECHA_VALOR = @fechaOtorgamiento,
					@AI_BANCO_DEP  = NULL,
					@AI_CUENTA_DEP  = NULL,
					@AS_TIPO_DESEMBOLSO = @tipoDesembolso */

		/*Procesar desembolso*/
		--EXEC @_CodeReturn =  CREDITO..sp_cr_procesar_desembolso
		--		@AS_USUARIO = 'ADMIN',
		--		@AS_OFICINA = '1001',
		--		@AI_SOLICITUD = @solicitud,
		--		@AS_TIPO_DESEMBOLSO = @tipoDesembolso,
		--		@AS_REFERENCIA = @cuentaDesembolso,
		--		@AS_FONDO = 'P',
		--		@AS_SUBFONDO  = NULL,
		--		@ADT_FECHA_DES = @fechaOtorgamiento ,
		--		@ADT_FECHA_1ER_PG = @ADT_FECHA_1ER_PG ,
		--		@ADEC_TASA  = @tasa,
		--		@AB_RENOVACION  = 1,
		--		@AM_VALOR_PAGAR  = @montoMaximo,
		--		@AI_ENTIDAD_FINANCIERA  = @entidadFinanciera,
		--		@AS_TIPO_CUENTA = 'A',
		--		@AS_NUMERO_CUENTA = @cuentaDesembolso,
		--		@AS_CREDITO  = @AS_CREDITO OUTPUT,
		--		@AS_MSJ  = @AS_MSJ OUTPUT,
		--		@AS_XML_DESEMBOLSO  = NULL
	

	--SET @AS_MSJ = 'ERROR'
	--SET @_CodeReturn = -1
 
	
	--IF @_CodeReturn = -1
	--	BEGIN
	--	RETURN
	--	END

		

SET @_CodeReturn = 1






