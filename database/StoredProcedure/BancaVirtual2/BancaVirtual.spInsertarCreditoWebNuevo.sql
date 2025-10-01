USE BancaVirtual2
go
CREATE  OR ALTER    procedure [BancaVirtual].[spInsertarCreditoWebNuevo]
@AS_JSON                           varchar(MAX),
@usuarioID							INT,
@AS_MSJ								VARCHAR(100) output,
@_CodeReturn						INT OUTPUT,
@AI_ID_SOLICITUD                    int output,
@AS_CREDITO							VARCHAR(50) OUTPUT
as

declare
			
			@OTP varchar(10),
			@hashPassword varchar(max),
			@RET		int,
			@lote int,
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
			@username varchar(50),
			@sesionId int,
			@entidadFinanciera int


	--INGRESAR CREDITO

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


	set @tasa = CREDITO.dbo.f_cr_obtener_tasa_producto('CRWEB')
	select @fechaOtorgamiento = GETDATE()
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

	EXEC @solicitud = CREDITO..sp_cr_insertar_solicitud
			@AI_SOLICITUD = @solicitud,
			@AI_CLIENTE = @usuarioID,
			@AS_PRODUCTO = 'CRWEB',
			@AS_ESTADO = 'I',
			@AM_MONTO = @montoMaximo,
			@AS_MONEDA = 'D',
			@ADEC_TASA = @tasa,
			@AS_TIPO_TABLA = @tipoCuota,
			@AS_FORMA_PAGO = 'M',
			@AI_PLAZO = @plazoMaximo,
			@AS_TIPO_GRACIA = 'N',
			@AI_GRACIA = 0,
			@ADT_FECHA_OTOR = @fechaOtorgamiento,
			@AS_OFICINA = '1001',
			@AS_USUARIO = 'LJORDAN',--@asesor,
			@AS_TIPO_OPERACION = 'N',
			@ADT_FECHA_1ER_PG = @ADT_FECHA_1ER_PG,
			@AI_DIAS_REAJUSTE = NULL,
			@AB_POR_GRUPO = 0,
			@AI_GRUPO = NULL,
			@AI_PRESTATARIAS = 0,
			@AS_FORMA_PAGO_INT = NULL,
			@AS_FONDO = NULL,
			@AS_SUB_FONDO = NULL,
			@AI_SCORE = NULL,
			@AS_MSJ = @AS_MSJ output

			IF @solicitud = -1 
			BEGIN 
				
				SET @AS_MSJ = @AS_MSJ + Cast(@solicitud as varchar(max))
				SET @_CodeReturn = -1
				RETURN
			END 

	
	UPDATE CREDITO..SL_SOLICITUD 
	SET sol_tipo_consumo = 'OT',
	sol_motivo_prestamo = @motivo,
	sol_asesor = 'ADMIN' 
	WHERE sol_solicitud = @solicitud


	IF @@ERROR <> 0 
	BEGIN
		
		SET @AS_MSJ = 'ERROR AL ACTUALIZAR DATOS DE LA SOLICITUD.'
		SET @_CodeReturn = -1
		RETURN
	END 	

	exec @_CodeReturn = CREDITO..sp_sl_calcular_descuentos_x_solicitud @solicitud 
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
	/*
	SELECT @id_wf_solicitud = sol_id_solicitud
	FROM PARAMETROS..WF_SOLICITUD 
	WHERE sol_referencia = @solicitud
	*/

	--EXEC PARAMETROS.dbo.sp_wf_cr_asigna_usuario_aprobacion @id_wf_solicitud, 'ADMIN', '', @AS_MSJ OUTPUT

	----
	--Insertar en el flujo
	DECLARE 
	@AI_ID_SOLICITUD_WF INT,
	@AI_ID_PROCESO INT,
	@AS_PROPIETARIO VARCHAR(15)

	SELECT @AI_ID_PROCESO =  PRO_ID_PROCESO from CREDITO..CR_PRODUCTOS, CREDITO..SL_sOLICITUD where 
	sol_producto = pro_producto 
	and sol_solicitud = @solicitud
	
	SELECT TOP 1 @AS_PROPIETARIO = ISNULL(usu_usuario,'LBAQUERIZO') FROM  PARAMETROS..SE_USUARIOS, BancaVirtual.CredencialesFirmantesCoop
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
		set sol_id_actividad_actual = 25 --SELECT * FROM WF_ACTIVIDAD where act_descripcion = 'PROCESAR DESEMBOLSO/RENOVACION'
		where sol_id_solicitud = @AI_ID_SOLICITUD_WF


	----


	EXEC @_CodeReturn = CREDITO..sp_sl_procesar_aprobacion @solicitud,'A', NULL, 'NINGUNA',@montoMaximo,'M','M',@plazoMaximo,'LBAQUERIZO', @AS_MSJ OUTPUT, NULL, NULL
    IF @_CodeReturn = -1 
	BEGIN 
		
		SET @_CodeReturn = -1
		RETURN
	END 

	EXEC @_CodeReturn = CREDITO..sp_sl_procesar_aprobacion @solicitud,'A', NULL, 'NINGUNA',@montoMaximo,'M','M',@plazoMaximo,'MNAVARRETE', @AS_MSJ OUTPUT, NULL, NULL
	IF @_CodeReturn = -1 
	BEGIN 
		
		SET @_CodeReturn = -1
		RETURN
	END 

	SELECT 'CREDITO NUEVO'

	--Cambiar estado de la solicitud a Aprobado
	EXEC CREDITO..sp_sl_solicitud_cambiar_estado @solicitud,'A', '1', 'ADMIN'

	----HASTA AQUI SE APRUEBA EL CREDITO YA DESPUÉS ES DESEMBOLSO



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
			--		SELECT @cuentaDesembolso = AH_CUENTAS.cue_cuenta     
			--FROM CUENTAS..AH_CUENTAS , CUENTAS..AH_TIPOS_CUENTA     
			--WHERE ( AH_CUENTAS.cue_tipo = AH_TIPOS_CUENTA.tip_tipo_cuenta ) 
			--and          ( ( AH_CUENTAS.cue_estado in ( 'A', 'P' ) ) 
			--and          ( AH_CUENTAS.cue_cliente = @usuarioID) 
			--and          ( AH_CUENTAS.cue_tipo = 'O' ) )  
			--END
	
			--EXEC @_CodeReturn = CREDITO..sp_cr_procesar_desembolso
			--		@AS_USUARIO = 'LJORDAN',
			--		@AS_OFICINA = '1001',
			--		@AI_SOLICITUD = @solicitud,
			--		@AS_TIPO_DESEMBOLSO = @tipoDesembolso,
			--		@AS_REFERENCIA = @cuentaDesembolso,
			--		@AS_FONDO = 'P',
			--		@AS_SUBFONDO  = NULL,
			--		@ADT_FECHA_DES = @fechaOtorgamiento,
			--		@ADT_FECHA_1ER_PG = @ADT_FECHA_1ER_PG,
			--		@ADEC_TASA = @tasa,
			--		@AB_RENOVACION  = 0,
			--		@AM_VALOR_PAGAR  = @montoMaximo,
			--		@AI_ENTIDAD_FINANCIERA  = null,
			--		@AS_TIPO_CUENTA = @tipoCuenta,
			--		@AS_NUMERO_CUENTA  = @NumeroCuenta,
			--		@AS_CREDITO  = @CREDITO OUTPUT,
			--		@AS_MSJ=  @AS_MSJ OUTPUT,
			--		@AS_XML_DESEMBOLSO = NULL
	
			--IF @_CodeReturn = -1
			--	BEGIN
			
			--		RETURN
			--	END


	
	

	-- HASTA AQUI INGRESO DE SOLICITUD


set @AI_ID_SOLICITUD = @solicitud
SET @_CodeReturn = 1	
SET @AS_CREDITO = @CREDITO


