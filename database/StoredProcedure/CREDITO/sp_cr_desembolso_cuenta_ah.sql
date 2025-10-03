USE CREDITO 
GO
/*
FECHA		AUTOR	DESCRIPCION
==========	=======	======================================================
2010-06-07	GNF	DESEMBOLSO A CUENTA VIRTUAL (AH)
*/

CREATE OR ALTER PROCEDURE [dbo].[sp_cr_desembolso_cuenta_ah]
@AS_OFICINA CHAR(4),
@AS_USUARIO VARCHAR(15),
@AI_SOLICITUD INT,
@AS_CREDITO VARCHAR(20),
@AS_TIPO_DESEMBOLSO CHAR(3), 
@AS_MSJ VARCHAR(100) OUTPUT,
@AI_TRA_ID INTEGER OUTPUT,
@AS_DOCUMENTO VARCHAR(20) OUTPUT,
@AI_SEC INT
AS
DECLARE 
@LI_MIN INTEGER,
@LI_MAX INTEGER,
@LD_VALDES  MONEY,
@LI_CLIENTE INTEGER,
@LS_NOMBRE_CLIENTE VARCHAR(103),
@LS_GRUPO VARCHAR(100),
@LS_MONEDA CHAR(1), 
@LI_RET INTEGER,
@LS_CUENTA VARCHAR(16),
@LS_CUENTA_CA VARCHAR(16),
@LS_TIPO_TRANS char(3),
@LS_CONCEPTO VARCHAR(30),
@LS_CREDITO VARCHAR(30),
@LS_PRODUCTO VARCHAR(5),
@LS_DOCUMENTO VARCHAR(20),
@LS_REFERENCIA VARCHAR(20),
@LI_TRA_ID INTEGER,
@LB_POR_GRUPO BIT,
@LI_TIPO_DOCUMENTO SMALLINT,
@LB_RETENCION_PREV BIT,
@LD_FECHA_OTORGAMIENTO DATE,
@LB_CREDITO_INTEGRAN BIT,
@LI_ENTIDAD_FINANCIERA INT,
@LS_TIPO_CUENTA CHAR(1),
@LS_TIPO_TRANS_AH CHAR(3),
@LS_TIPO_TRANS_COM VARCHAR(15),
@LM_VALOR_DEBITAR MONEY,
@LM_VALOR_COMISION MONEY,
@LS_REFERENCIA_AH VARCHAR(25),
@LB_CERTIFICADO_DES BIT,
@LF_POR_CERTIFICADO_DES FLOAT,
@LM_VALOR_CERTIFICADO MONEY,
@LM_MONTO MONEY,
@LI_TRA_ID_DB INTEGER,
@LI_TRA_ID_CR INTEGER,
@LI_ID_ERROR INTEGER,
@LS_CREDITO_REN  VARCHAR(20),
@LM_VALOR_DEUDA MONEY



	
SELECT @LB_CREDITO_INTEGRAN = dbo.f_cr_obtener_parametro_b(sol_producto,'BIT_CREDITO_INTEGRAN')
FROM SL_SOLICITUD 
WHERE sol_solicitud = @AI_SOLICITUD

SET @LB_CREDITO_INTEGRAN = ISNULL(@LB_CREDITO_INTEGRAN,0)

DECLARE @DESEMBOLSO TABLE 
(
secuencial integer identity,
monto money,
cliente integer,
nombre varchar(150),
grupo varchar(150) null,
moneda char(1),
por_grupo bit not null,
cuenta varchar(16) null
)

-- PARA EL DESEMBOLSO SE DEBE CONSIDERAR EL SECUENCIAL 1, YA QUE LOS OTROS SECUENCIALES SE UTILIZARAN
-- PARA REALIZAR LOS DESEMBOLSOS POR FASES 

insert @DESEMBOLSO
(
monto,
cliente,
nombre,
grupo,
moneda,
por_grupo ,
cuenta
)
SELECT 
des_monto_liquidar,
sol_cliente, 
cli_nombre, 
null,
sol_moneda,
0,
des_referencia 
FROM SL_SOLICITUD,CL_CLIENTE, SL_MEDIO_APROB, CR_DESEMBOLSO 
WHERE 	sol_solicitud = @AI_SOLICITUD
AND sol_cliente = cli_id
AND ISNULL(sol_por_grupo,0) = 0
AND map_solicitud = sol_solicitud
AND des_solicitud = sol_solicitud
AND des_tipo_desembolso = @AS_TIPO_DESEMBOLSO
AND des_sec =  @AI_SEC  
AND @LB_CREDITO_INTEGRAN = 0

insert @DESEMBOLSO
(
monto,
cliente,
nombre,
grupo,
moneda,
por_grupo ,
cuenta
)
SELECT 
des_monto_liquidar,
sol_cliente, 
cli_nombre, 
null,
sol_moneda,
1,
des_referencia 
FROM SL_SOLICITUD,CL_CLIENTE, SL_MEDIO_APROB, CR_DESEMBOLSO 
WHERE 	sol_solicitud = @AI_SOLICITUD
AND sol_cliente = cli_id
AND sol_por_grupo = 1
AND map_solicitud = sol_solicitud
AND des_solicitud = sol_solicitud
AND des_tipo_desembolso = @AS_TIPO_DESEMBOLSO
AND des_sec =  @AI_SEC  
AND @LB_CREDITO_INTEGRAN = 0 

insert @DESEMBOLSO
(
monto,
cliente,
nombre,
grupo,
moneda ,
por_grupo ,
cuenta
)
SELECT	
igs_monto_liquidar,
igs_cliente,
cli_nombre,
grp_nombre,
sol_moneda,
1,
cg_cuenta
FROM SL_SOLICITUD,SL_INTEGRANTES_X_SOL,CL_CLIENTE,CL_GRUPO, SL_MEDIO_APROB, CR_DESEMBOLSO,
CL_CLIENTES_X_GRUPO 
WHERE 
sol_solicitud = @AI_SOLICITUD
AND sol_solicitud = map_solicitud 
AND sol_solicitud = igs_solicitud
AND sol_por_grupo = 1
AND igs_cliente = cli_id
AND igs_es_ahorrista = 0
AND sol_grupo = grp_grupo 
AND sol_solicitud = des_solicitud 
AND des_tipo_desembolso = @AS_TIPO_DESEMBOLSO
AND des_sec =  @AI_SEC  
AND @LB_CREDITO_INTEGRAN = 1 
AND grp_grupo = cg_grupo 
AND cg_cliente = igs_cliente 

IF EXISTS (SELECT 1 FROM @DESEMBOLSO WHERE cuenta IS NULL) or 
   EXISTS (SELECT 1 FROM @DESEMBOLSO WHERE len(cuenta)  = 0)	
BEGIN

	SET @AS_MSJ = 'NO EXISTE CUENTAS A LA VISTA ASIGNADAS PARA EL DESEMBOLSO'
	RETURN -1

END 

SELECT @LI_MIN = 1
SELECT @LI_MAX = secuencial FROM @DESEMBOLSO

SELECT @LI_MAX = ISNULL(@LI_MAX,0)

WHILE @LI_MIN <= @LI_MAX
BEGIN

	

	SELECT @LS_CREDITO = map_credito,
	@LS_PRODUCTO = sol_producto,
	@LB_CERTIFICADO_DES = dbo.f_cr_obtener_parametro_b(sol_producto, 'BIT_CERTIF_DES'),
	@LF_POR_CERTIFICADO_DES = dbo.f_cr_obtener_parametro_f(sol_producto, 'FLO_POR_CERTIF_DES'),
	@LM_MONTO = sol_monto
	FROM SL_MEDIO_APROB, SL_SOLICITUD
	WHERE map_solicitud = @AI_SOLICITUD
	AND map_solicitud = sol_solicitud

	SELECT @LD_VALDES = monto, 
	@LI_CLIENTE = cliente, 
	@LS_NOMBRE_CLIENTE = nombre,
	@LS_GRUPO = grupo,
	@LS_MONEDA = moneda,
	@LB_POR_GRUPO = por_grupo,
	@LS_CUENTA = cuenta 
	FROM @DESEMBOLSO 
	WHERE secuencial = @LI_MIN

	







	SET @LS_CONCEPTO = @LS_CREDITO 


	SELECT @LS_TIPO_TRANS = tds_tipo_trans_ah
	FROM CR_TIPO_DESEMBOLSO
	WHERE tds_tipo_desembolso = @AS_TIPO_DESEMBOLSO AND 
	(tds_es_ahorros = 1 OR tds_es_ahorros_cash = 1)

	SET @LI_TRA_ID  = NULL
	SET @LS_DOCUMENTO = NULL

	SET @LI_TIPO_DOCUMENTO = 1
	
	SET @LS_REFERENCIA_AH = ISNULL(@LS_DOCUMENTO, 'DESEMBOLSO CR.')
	
	EXEC @LI_RET = CUENTAS..sp_ah_insertar_transaccion
		@AS_CUENTA 	= @LS_CUENTA,
		@AS_TIPO_TRANS 	= @LS_TIPO_TRANS,
		@AS_OFICINA 	= @AS_OFICINA ,
		@AS_USUARIO	= @AS_USUARIO,
		@AM_VALOR 	= @LD_VALDES,
		@AS_REFERENCIA 	= @LS_REFERENCIA_AH,
		@AS_REFERENCIA_CTA = NULL,
		@AM_EFECTIVO 	= 0,
		@AM_CHEQUE 	= 0,
		@AS_CONCEPTO 	= @LS_CONCEPTO,
		@AS_MSJ 	= @AS_MSJ OUTPUT,
		@AI_TRA_ID 	= @LI_TRA_ID OUTPUT
		
	IF @LI_RET = -1 
		RETURN -1

	IF @@ERROR <> 0
	BEGIN
		SET @AS_MSJ = 'ERROR AL INSERTAR TRANSACCION DE DESEMBOLSO (CR)'
		RETURN -1
	END 	

	SET @LS_REFERENCIA = CONVERT(VARCHAR,@LI_TRA_ID)
	
	-- PARA CREDITOS GRUPALES SE ACTUALIZA LOS DATOS POR CADA INTEGRANTE
	-- SE ACTUALIZA UNICAMENTE SI ES EL PRIMER DESEMBOLSO
	IF @LB_POR_GRUPO = 1 AND @AI_SEC = 1 
	BEGIN

		UPDATE SL_INTEGRANTES_X_SOL
		SET igs_referencia = @LS_REFERENCIA,
		igs_documento = @LS_DOCUMENTO
		WHERE igs_solicitud = @AI_SOLICITUD
		AND igs_cliente = @LI_CLIENTE

		IF @@ERROR <> 0
		BEGIN
			SET @AS_MSJ = 'ERROR AL ACTUALIZAR NUMERO DE DOCUMENTO Y REFERENCIA'
			RETURN -1
		END 	

		SET @AI_TRA_ID = NULL
		SET @AS_DOCUMENTO = NULL

	END
	ELSE
	BEGIN
		-- PARA CREDITOS INDIVIDUALES SE RETORNA LA TRANSACCION Y EL DOCUMENTO

		SET @AI_TRA_ID = @LI_TRA_ID 
		SET @AS_DOCUMENTO = @LS_DOCUMENTO

	END
	
	------------------------------
	
	if exists (select 1 from CR_TIPO_DESEMBOLSO WHERE tds_tipo_desembolso = @AS_TIPO_DESEMBOLSO AND tds_es_ahorros_cash = 1)
	BEGIN
	
	
		SELECT @LI_ENTIDAD_FINANCIERA = cli_entidad_financiera,
		@LS_TIPO_CUENTA = cli_tipo_cuenta 
		FROM CL_CLIENTE
		WHERE cli_id = @LI_CLIENTE
	
		IF NOT EXISTS (SELECT 1 FROM CR_TIPO_DESEMBOLSO_DEBITO_CASH WHERE ddc_tipo_desembolso = @AS_TIPO_DESEMBOLSO)
		BEGIN
			SET @AS_MSJ = 'NO EXISTE PARAMETRIZADO LOS DÉBITOS PARA ESTA TRANSACCIÓN'
			RETURN -1
		END
	
		IF NOT EXISTS (	SELECT 1 
						FROM CR_TIPO_DESEMBOLSO_DEBITO_CASH 
						WHERE ddc_tipo_desembolso = @AS_TIPO_DESEMBOLSO AND 
						ddc_entidad_financiera = @LI_ENTIDAD_FINANCIERA)
						
			SET @LI_ENTIDAD_FINANCIERA = 0
			
			
		IF NOT EXISTS (	SELECT 1 
						FROM CR_TIPO_DESEMBOLSO_DEBITO_CASH 
						WHERE ddc_tipo_desembolso = @AS_TIPO_DESEMBOLSO AND 
						ddc_tipo_cuenta = @LS_TIPO_CUENTA)
						
			SET @LS_TIPO_CUENTA = '*'	
	
		
		IF NOT EXISTS (SELECT 1
						FROM CR_TIPO_DESEMBOLSO_DEBITO_CASH 
						WHERE ddc_tipo_desembolso = @AS_TIPO_DESEMBOLSO AND 
						ddc_entidad_financiera = @LI_ENTIDAD_FINANCIERA AND 
						ddc_tipo_cuenta = @LS_TIPO_CUENTA)
		BEGIN
		
			SET @AS_MSJ = 'NO EXISTE PARAMETRIZADO LOS DÉBITOS CON BANCOS Y TIPOS DE CUENTA PARA ESTA TRANSACCION'
			RETURN -1
		
		END 
		
		SELECT @LS_TIPO_TRANS_AH = ddc_tipo_trans_ah
		FROM CR_TIPO_DESEMBOLSO_DEBITO_CASH 
		WHERE ddc_tipo_desembolso = @AS_TIPO_DESEMBOLSO AND 
		ddc_entidad_financiera = @LI_ENTIDAD_FINANCIERA AND 
		ddc_tipo_cuenta = @LS_TIPO_CUENTA
		
		SET @LS_TIPO_TRANS_COM = 'AH_TTR_' + @LS_TIPO_TRANS_AH		
		
		EXEC @LI_RET = CUENTAS..sp_ct_com_calculo_valor_comision @AS_CUENTA = @LS_CUENTA, @AS_COMISION = @LS_TIPO_TRANS_COM,
		@AM_VALOR = 0, @AM_VALOR_COMISION = @LM_VALOR_COMISION OUTPUT,@AS_MSJ = @AS_MSJ OUTPUT
		
		IF @LI_RET <> 1 
			RETURN -1  
		
		SET @LM_VALOR_DEBITAR = @LD_VALDES - @LM_VALOR_COMISION
		
		SET @LS_REFERENCIA_AH = ISNULL(@LS_DOCUMENTO, 'DESEMBOLSO CR.')
		
		--AJUSTE VALOR DESCUENTO CREDIWEB RENOVACION 08/04/2025
		IF EXISTS (	SELECT 1
					FROM SL_SOLICITUD
					WHERE sol_solicitud = @AI_SOLICITUD
					AND sol_producto = 'CRWEB'
					and sol_tipo_operacion = 'T')
			BEGIN
					SELECT @LS_CREDITO_REN = ren_credito
					FROM CR_RENOVACION
					WHERE ren_solicitud_ren = @AI_SOLICITUD

					SELECT	@LM_VALOR_DEUDA  = SUM(cuo_saldo)
					FROM CR_CUOTAS 
					WHERE cuo_credito = @LS_CREDITO_REN 
					AND cuo_pagada = 0 
					AND cuo_saldo > 0 

					SET @LM_VALOR_DEBITAR = @LM_VALOR_DEBITAR - @LM_VALOR_DEUDA
			END



		EXEC @LI_RET = CUENTAS..sp_ah_insertar_transaccion
		@AS_CUENTA 	= @LS_CUENTA,
		@AS_TIPO_TRANS 	= @LS_TIPO_TRANS_AH,
		@AS_OFICINA 	= @AS_OFICINA ,
		@AS_USUARIO	= @AS_USUARIO,
		@AM_VALOR 	= @LM_VALOR_DEBITAR,
		@AS_REFERENCIA 	= @LS_REFERENCIA_AH,
		@AS_REFERENCIA_CTA = NULL,
		@AM_EFECTIVO 	= 0,
		@AM_CHEQUE 	= 0,
		@AS_CONCEPTO 	= @LS_CONCEPTO,
		@AS_MSJ 	= @AS_MSJ OUTPUT,
		@AI_TRA_ID 	= @LI_TRA_ID OUTPUT
		
		IF @LI_RET = -1 
			RETURN -1

		IF @@ERROR <> 0
		BEGIN
			SET @AS_MSJ = 'ERROR AL INSERTAR TRANSACCION DE DESEMBOLSO (DB)'
			RETURN -1
		END 	
		
	END 
	

	
	------------------------------
	IF @LB_CERTIFICADO_DES = 1 
	BEGIN

		
	
		SELECT @LM_VALOR_CERTIFICADO = ROUND(@LM_MONTO * @LF_POR_CERTIFICADO_DES / 100,2)

		

		EXEC @LI_RET = CUENTAS..sp_ah_transferencia_ordinarios_certificados
		@AS_USUARIO = @AS_USUARIO,
		@AS_OFICINA = @AS_OFICINA,
		@AS_CUENTA = @LS_CUENTA,
		@AM_VALOR = @LM_VALOR_CERTIFICADO,
		@AS_CONCEPTO = 'DESEMBOLSO CR.',
		@AS_REFERENCIA = @LS_CREDITO,
		@AB_GENERA_PENDIENTE = 0,
		@AI_TRA_ID_DB = @LI_TRA_ID_DB OUTPUT,
		@AI_TRA_ID_CR = @LI_TRA_ID_CR OUTPUT,
		@AS_MSJ = @AS_MSJ OUT,
		@AI_ID_ERROR = @LI_ID_ERROR OUTPUT

		IF @LI_RET = -1 
			RETURN -1

		IF @@ERROR <> 0
		BEGIN
			SET @AS_MSJ = 'ERROR AL INSERTAR TRANSACCION DE DESEMBOLSO (CR-CA)'
			RETURN -1
		END 	


	END 
	
	
	------------------------------
	
	
	SELECT @LD_FECHA_OTORGAMIENTO =  sol_fecha_otorgamiento FROM  SL_SOLICITUD WHERE sol_solicitud = @AI_SOLICITUD

	SET @LB_RETENCION_PREV = dbo.f_cr_obtener_parametro_b(@LS_PRODUCTO, 'BIT_ENCAJE_PREV_SOL')
	
	-- EL PROCESO SE REALIZA UNICAMENTE SI ES EL PRIMER DESEMBOLSO
	IF @LB_RETENCION_PREV = 1 AND @AI_SEC = 1 
	BEGIN
	   IF EXISTS (	SELECT 1 FROM CUENTAS..AH_RETENCIONES, CUENTAS..AH_TIPOS_RETENCION, 
					CUENTAS..AH_CUENTAS, CUENTAS..AH_TIPOS_CUENTA
					WHERE ret_cuenta = cue_cuenta
					AND ret_vigente = 1
					AND (ret_credito IS NULL OR ret_credito = '')
					AND tre_tipo_ret = ret_tipo_ret
					AND tre_es_encaje = 1
					AND cue_tipo = tip_tipo_cuenta
					AND cue_cliente = @LI_CLIENTE
					AND tip_tipo_cuenta IN ('A','C')) 
						
		BEGIN
			
			UPDATE CUENTAS..AH_RETENCIONES
			SET ret_credito = @AS_CREDITO,
			ret_fecha_venc = DATEADD(YY,30,@LD_FECHA_OTORGAMIENTO ),
			modifica_usuario = @AS_USUARIO,
			modifica_fecha = GETDATE()
			FROM CUENTAS..AH_TIPOS_RETENCION, 
			CUENTAS..AH_CUENTAS, CUENTAS..AH_TIPOS_CUENTA
			WHERE ret_cuenta = cue_cuenta
			AND ret_vigente = 1
			AND (ret_credito IS NULL OR ret_credito = '')
			AND tre_tipo_ret = ret_tipo_ret
			AND tre_es_encaje = 1
			AND cue_tipo = tip_tipo_cuenta
			AND cue_cliente = @LI_CLIENTE
			AND tip_tipo_cuenta IN ('A','C')

			IF @@ERROR <> 0
			BEGIN
				SET @AS_MSJ = 'ERROR AL ACTUALIZAR NUMERO DE CREDITO EN RETENCIONES'
				RETURN -1
			END 
		END 
	END

	-----------------------------------------------------------
	-- EL PROCESO SE REALIZA UNICAMENTE SI ES EL PRIMER DESEMBOLSO
	IF @AI_SEC = 1 
	BEGIN
		EXEC @LI_RET = sp_cr_generar_retencion_ahorros 
		@AI_SOLICITUD = @AI_SOLICITUD,
		@AS_CREDITO = @AS_CREDITO, 
		@AS_CUENTA = @LS_CUENTA, 
		@AS_OFICINA = @AS_OFICINA,
		@AS_USUARIO = @AS_USUARIO,
		@AB_CREDITO_INTEGRAN = @LB_CREDITO_INTEGRAN, 
		@AI_CLIENTE = @LI_CLIENTE,
		@AS_MSJ = @AS_MSJ OUT


		IF @LI_RET = -1 
			RETURN -1
	END

	--IF EXISTS (SELECT 1
	--			FROM SL_SOLICITUD, SL_DESCUENTOS 
	--			WHERE sol_solicitud = @AI_SOLICITUD 
	--			AND sol_solicitud = des_solicitud
	--			AND des_rubro_desc = 'AHE')--RUBRO DE DESCUENTO AHORROS ESPECIAL
		
	--BEGIN	
		
	--	EXEC @LI_RET = sp_cr_generar_ahorros_especiales
	--	@AI_SOLICITUD = @AI_SOLICITUD,
	--	@AS_CREDITO = @AS_CREDITO,
	--	@AS_CUENTA = @LS_CUENTA, 
	--	@AS_OFICINA = @AS_OFICINA,
	--	@AS_USUARIO = @AS_USUARIO,
	--	@AB_CREDITO_INTEGRAN = @LB_CREDITO_INTEGRAN, 
	--	@AI_CLIENTE = @LI_CLIENTE,
	--	@AS_MSJ = @AS_MSJ OUTPUT 
			
	--	IF @LI_RET = -1 
	--		RETURN -1
	--END
		
	--IF EXISTS (	SELECT 1
	--			FROM SL_SOLICITUD, SL_DESCUENTOS 
	--			WHERE sol_solicitud = @AI_SOLICITUD 
	--			AND sol_solicitud = des_solicitud
	--			AND des_rubro_desc = 'AHC')--RUBRO DE DESCUENTO CERTIF. APORTAC.
		
	--BEGIN
	--	EXEC @LI_RET = sp_cr_generar_ahorros_certificados
	--	@AI_SOLICITUD = @AI_SOLICITUD,
	--	@AS_CREDITO = @AS_CREDITO,
	--	@AS_CUENTA = @LS_CUENTA, 
	--	@AS_OFICINA = @AS_OFICINA,
	--	@AS_USUARIO = @AS_USUARIO,
	--	@AB_CREDITO_INTEGRAN = @LB_CREDITO_INTEGRAN, 
	--	@AI_CLIENTE = @LI_CLIENTE,
	--	@AS_MSJ = @AS_MSJ OUTPUT 
					
	--	IF @LI_RET = -1 
	--		RETURN -1
	--END
	
	
	
	SELECT @LI_MIN = @LI_MIN + 1

END 

-- EL PROCESO SE REALIZA UNICAMENTE SI ES EL PRIMER DESEMBOLSO
IF EXISTS (	SELECT 1 
			FROM SL_SOLICITUD, CR_TIPO_OPERACION
			WHERE sol_solicitud = @AI_SOLICITUD 
			AND sol_tipo_operacion = top_tipo_operacion
			AND top_es_original = 0 ) AND @AI_SEC = 1 

			
BEGIN

	DECLARE @LS_TIPO_TRAN CHAR(3),
		
			@LI_ID_TRAN_CR INT,
			@LI_ID_TRAN_CT INT
			
		
	SELECT @LS_CREDITO_REN = ren_credito
	FROM CR_RENOVACION
	WHERE ren_solicitud_ren = @AI_SOLICITUD
		
		
	EXEC @LI_RET = sp_cr_baja_retencion_ahorros 
	@AS_CREDITO = @LS_CREDITO_REN,
	@AS_CUENTA = @LS_CUENTA,
	@AS_OFICINA = @AS_OFICINA,
	@AS_USUARIO = @AS_USUARIO,
	@AS_MSJ = @AS_MSJ  OUT
	
	IF @LI_RET = -1 
	BEGIN
		SET @AS_MSJ = 'CUENTA: ' + ISNULL(@LS_CUENTA, '')+ ', ' + ISNULL(@AS_MSJ, '') + ', CREDITO: ' + CONVERT ( VARCHAR, ISNULL ( @LS_CREDITO_REN, '' ) )
		RETURN -1
	END

	SELECT @LS_TIPO_TRAN = ttr_tipo_tran
	FROM CR_TIPO_TRANSACCION
	WHERE  ttr_es_pago_nd = 1
		
	SELECT	@LM_VALOR_DEUDA  = SUM(cuo_saldo)
	FROM CR_CUOTAS 
	WHERE cuo_credito = @LS_CREDITO_REN 
	AND cuo_pagada = 0 
	AND cuo_saldo > 0 
		
	DECLARE @LS_REFERENCIA_REN  VARCHAR(25)
	SET @LS_REFERENCIA_REN = 'REN-' + @LS_CREDITO_REN
	
	EXEC @LI_RET = sp_cr_pago_credito_debito_a_cuenta
	@AS_CREDITO = @LS_CREDITO_REN,
	@AS_OFICINA = @AS_OFICINA,
	@AS_CUENTA = @LS_CUENTA,
	@AS_USUARIO = @AS_USUARIO,
	@AS_MONEDA = @LS_MONEDA,
	@AS_TIPO_TRAN = @LS_TIPO_TRAN,
	@AS_REFERENCIA = @LS_REFERENCIA_REN,
	@AM_VALOR = @LM_VALOR_DEUDA,
	@AS_MSJ = @AS_MSJ OUTPUT,
	@AI_ID_TRAN_CR = @LI_ID_TRAN_CR OUTPUT,
	@AI_ID_TRAN_CT = @LI_ID_TRAN_CT OUTPUT,
	@AB_ABONO_RECALCULO = 0,
	@AS_TIPO_PAGO  = NULL
		
	IF @LI_RET = -1 
	BEGIN
		SET @AS_MSJ = 'CUENTA: ' + ISNULL(@LS_CUENTA, '')+ ', ' + ISNULL(@AS_MSJ, '') + ', TOTAL DEUDA: ' + CONVERT ( VARCHAR, ISNULL ( @LM_VALOR_DEUDA, 0 ) )
		RETURN -1
	END
		
	EXEC sp_cr_actualizar_renovacion
	@AS_CREDITO = @AS_CREDITO ,
	@AS_CREDITO_REN = @LS_CREDITO_REN ,
	@AS_ESTADO_ACTUAL = 'A',
	@AS_ESTADO = 'P',
	@AB_PAGADO = 1,
	@AS_TIPO_DESEMBOLSO = 'AH',
	@AS_REFERENCIA = @LS_CREDITO_REN,
	@AS_USUARIO = @AS_USUARIO ,
	@AM_VALOR = @LD_VALDES,
	@AS_MSJ = @AS_MSJ OUTPUT

	IF @LI_RET <> 1 
		RETURN -1 
		
END 


RETURN 1

