Use BancaVirtual2
go
CREATE  or alter      procedure [BancaVirtual].[spGenerarSolicitudCRW]
@_UserName                          varchar(20),
@_SessionID                         int output,
@_CodeReturn                        int output,
@_Message                           varchar(200) output,
@Request                            varchar(MAX),
@Result                             varchar(MAX) output
as

declare
			@SolicitudID		 int,
			@OTP varchar(10),
			@hashPassword varchar(max),
			@JSON	varchar(max),
			@RET		int,
			@lote int,
			@usuarioID INT,
			@solicitud int,
			@Proceso varchar(20),
			@credito varchar(50),
			@valor money,
			@FechaSis datetime,
			@AS_CREDITO varchar(20),
			@AS_SOLICITUD_RENOVACION INT 

	select @FechaSis = GETDATE()
     
	 	  DECLARE @horaActual DATETIME = CONVERT ( DATETIME, CONVERT ( VARCHAR, @FechaSis, 114), 114)
  DECLARE @horaDesde  DATETIME = CONVERT ( DATETIME, CONVERT ( VARCHAR, '8:30', 114), 114)
  DECLARE @horaHasta  DATETIME = CONVERT ( DATETIME, CONVERT ( VARCHAR, '22:30', 114), 114)
  
	IF ( not @horaActual between @horaDesde AND @horaHasta  ) 
	BEGIN
    SET @_Message = 'Servicio fuera de horario.'
    SET @_CodeReturn = -1
	set @Result = (select mensaje = @_Message, 
							codigo = -1
							FOR JSON PATH, WITHOUT_ARRAY_WRAPPER )
    RETURN
	END

	
	IF EXISTS (SELECT 1 FROM BancaVirtual.Usuario u, BancaVirtual.UsuarioSesion s
				WHERE u.UserName = @_UserName AND 
				u.ID = s.UsuarioID AND s.ID = @_SessionID AND s.FechaCierreSesion != null)
	BEGIN
		SET @_CodeReturn = -2
		SET @_Message = 'SESIÓN NO VALIDA.'
		RETURN 	
	END  

	--VALIDAR OTP
		SET @OTP = SUBSTRING(@Request,2 , 5)
		SET @hashPassword = HASHBYTES('SHA2_256', @OTP)
		SELECT @hashPassword

	if NOT EXISTS (SELECT 1 FROM BancaVirtual.OtpUsuario
				WHERE Password = @hashPassword)

			BEGIN 
				SET @_Message = 'Código de Solicitud Incorrecto'
				SET @_CodeReturn = -1   

				update BancaVirtual.SolicitudCredito
				set IntentosOtp = IntentosOtp+1,
				UltimoMensaje = @_Message,
				ModificaFecha = GETDATE(),
				ModificaUsuario = 'ADMIN'
				where OTP = @hashPassword
				RETURN  
	END

	select @SolicitudID = ID ,
	@JSON = DatosJSON
	from BancaVirtual.SolicitudCredito
	WHERE OTP = @hashPassword

	--IF EXISTS (SELECT 1 FROM BancaVirtual.SolicitudCredito s, BancaVirtual.Usuario u 
	--			where s.ClienteId = u.clienteid
	--			and convert(date,s.Fecha) = convert(date, getdate())
	--			AND U.UserName =  @_UserName
	--			and s.Estado = 'PROCESADO')
	--	BEGIN	
	--		SET @_CodeReturn = -1
	--		SET @_Message = 'No se puede realizar mas de un crédito por dia'
	--		return
	--	END
	--ACTUALIZAR CLIENTES

	select @usuarioID =ClienteId ,
	@Proceso = OpcionCreditoWeb
	from BancaVirtual.Usuario
	where UserName = @_UserName

	--SELECT * FROM BancaVirtual.SolicitudCredito

	set @valor= JSON_VALUE(@JSON, '$.credito.montoMaximo')

	IF NOT EXISTS (SELECT 1
				FROM CREDITO..CR_LINEA_CREDITO
				WHERE lcr_cli_id = @usuarioID
				and lcr_estado = 1
				and lcr_cupo_credito >= @valor
				and lcr_vencimiento_propuesta >= PARAMETROS.dbo.fechaSistema())
		BEGIN
			SET @_Message = 'EL USUARIO NO TIENE UNA LINEA DE CREDITO ACTIVA'
			SET @_CodeReturn = -1
			RETURN
		END

		SAVE TRAN CR_SOL

EXEC @RET = BancaVirtual.spActualizarDatosClienteSolicitudCRW
	@_UserName    = @_UserName,
	@_SessionID   = @_SessionID,
	@_CodeReturn  = @_CodeReturn,
	@_Message      = @_Message,
	@Request      = @JSON,
	@Result = @Result

if @RET = -1 
	BEGIN
		ROLLBACK TRAN CR_SOL
		SET @_Message = @_Message
		SET @_CodeReturn = -1
		
		RETURN
	END
	




	if @Proceso = '/credito/nuevo'
		begin

		exec  BancaVirtual.spInsertarCreditoWebNuevo
			 @JSON,
			@usuarioID,
			 @_Message output,
			@_CodeReturn OUTPUT,
			 @solicitud output,
			 @credito output

	if @_CodeReturn = -1 
		begin
			ROLLBACK TRAN CR_SOL
			RETURN
		end
		SET @Proceso = 'N'


	
	end

	-- HASTA AQUI INGRESO DE SOLICITUD

	ELSE

		begin

			set @AS_CREDITO = (SELECT TOP(1) CRE_CREDITO
								from CREDITO..CR_CREDITOS c
										JOIN CREDITO..CR_PRODUCTOS p
											On c.cre_producto = p.pro_producto
										JOIN CREDITO..CR_TIPO_OPERACION o
											On c.cre_tipo_operacion = o.top_tipo_operacion
										JOIN CREDITO..CR_ESTADO e
											On c.cre_estado = e.est_estado 
									WHERE cre_cliente = @usuarioID 
									AND e.est_estado = 'V'
									and c.cre_producto = 'CRWEB')
									--and (cre_monto - cre_saldo) >= (cre_monto * 0.30)


		print 'INICIO RENOVACION'

		exec  BancaVirtual.spInsertarCreditoWebRenovacion
			@AS_JSON  = @JSON,
			@usuarioID	= @usuarioID,
			@AS_MSJ		= @_Message output,
			@AS_CREDITO		= @AS_CREDITO,					
			@_CodeReturn = @_CodeReturn OUTPUT,
			@AI_ID_SOLICITUD  = @solicitud output

	if @_CodeReturn = -1 
		begin
			ROLLBACK TRAN CR_SOL
			RETURN
		end
		SET @Proceso = 'R'
		SET @solicitud = @solicitud
	
	END

	-- FIN RENOVACION
	--DAR BAJA LINEA CREDITO

	UPDATE CREDITO..CR_LINEA_CREDITO
	SET lcr_estado = 0,
	modifica_usuario ='BANCAVIRTUAL',
	modifica_fecha = getdate()
	where lcr_cli_id = @usuarioID

	IF @@ERROR <>0
			BEGIN
				ROLLBACK TRAN CR_SOL
				SET @_Message = 'ERROR AL DAR DE BAJA LINEA DE CREDITO'
				SET @_CodeReturn= -1
				RETURN
			END

	--ACTUALIZAR ESTADO SOLICITUD
	UPDATE BancaVirtual.SolicitudCredito
	SET Estado = 'PROCESADO',
	ModificaFecha = GETDATE(),
	ModificaUsuario = 'ADMIN',
	IntentosOtp = IntentosOtp + 1,
	IDSolicitud = @solicitud,
	TipoOperacion = @Proceso,
	Credito = @credito
	WHERE ID = @SolicitudID

	IF @@ERROR <>0
			BEGIN
				ROLLBACK TRAN CR_SOL
				SET @_Message = 'ERROR ACTUALIZACION SOLICITUD DE CREDITO'
				SET @_CodeReturn= -1
				RETURN
			END

SET @_CodeReturn = 1	
	



