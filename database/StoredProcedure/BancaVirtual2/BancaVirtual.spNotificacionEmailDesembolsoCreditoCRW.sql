use BancaVirtual2
go
create or alter   procedure [BancaVirtual].[spNotificacionEmailDesembolsoCreditoCRW]
@_UserName                          varchar(20),
@_SessionID                         int output,
@_CodeReturn                        int output,
@_Message                           varchar(200) output,
@Request                            varchar(MAX),
@Result                             varchar(MAX) output
as


declare 
	@Credito	varchar(100), 
	@email      varchar(15),
	@nombreUsuario varchar(100),
	@datoJson	nvarchar(max),
	@CreditoHiden varchar(100),
	@plantilla INT

	SET @Credito =  JSON_VALUE(@Request, '$.credito') ;

	SET @CreditoHiden = REPLICATE('X', LEN(@Credito)/2 + 1) + SUBSTRING (@Credito, (len (@Credito) / 2 )+ 1, len (@Credito))

	Select
		@email = Email,
		@nombreUsuario = Nombre
	 FROM  BancaVirtual.Usuario
		WHERE UserName = @_UserName

	SET @datoJson = ( 
					SELECT
							Operacion = @CreditoHiden,
							Nombre = @nombreUsuario,
							Fecha = PARAMETROS.dbo.f_fecha_formato((SELECT GETDATE()),'text_de_mes_del'),
							Monto = FORMAT(cre_monto, 'C')
						FROM CREDITO..CR_CREDITOS
						WHERE cre_credito = @Credito
						FOR JSON PATH, WITHOUT_ARRAY_WRAPPER )
	
	Select @plantilla = ID FROM  bancavirtual2.bancavirtual.PlantillaNotificacionEmail WHERE Codigo = 'Credito-Web-Desembolso'


	EXEC BancaVirtual.NotificacionEmailEnviar
			@_UserName                    = @_UserName                    ,
			@_SessionID                   = @_SessionID  ,
			@_CodeReturn                  = @_CodeReturn OUTPUT,
			@_Message                     = @_Message    OUTPUT,
			@PlantillaNotificacionEmailID = @plantilla ,
			@DatoJson                     = @datoJson                     ,
			@Email						  = @email 


	RETURN @_CodeReturn 


