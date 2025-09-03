create OR ALTER    procedure [BancaVirtual].[spNotificacionEmailAnulacionSolCreditoCRW]
@_UserName                          varchar(20),
@_SessionID                         int output,
@_CodeReturn                        int output,
@_Message                           varchar(200) output,
@Request                            varchar(MAX),
@Result                             varchar(MAX) output
as


declare 
	@Solicitud	varchar(100), 
	@email      varchar(15),
	@nombreUsuario varchar(100),
	@datoJson	nvarchar(max),
	@plantilla INT

	SET @Solicitud =  JSON_VALUE(@Request, '$.solicitud') ;


	Select
		@email = Email,
		@nombreUsuario = Nombre
	 FROM  BancaVirtual.Usuario
		WHERE UserName = @_UserName

	SET @datoJson = ( 
					SELECT
							Nombre = @nombreUsuario,
							Fecha = PARAMETROS.dbo.f_fecha_formato((SELECT GETDATE()),'text_de_mes_del'),
							Monto = FORMAT(sol_monto, 'C')
						FROM CREDITO..SL_SOLICITUD
						WHERE sol_solicitud = @Solicitud
						FOR JSON PATH, WITHOUT_ARRAY_WRAPPER )
	
	Select @plantilla = ID FROM  bancavirtual2.bancavirtual.PlantillaNotificacionEmail WHERE Codigo = 'Credito-Web-Anulacion'


	EXEC BancaVirtual.NotificacionEmailEnviar
			@_UserName                    = @_UserName                    ,
			@_SessionID                   = @_SessionID  ,
			@_CodeReturn                  = @_CodeReturn OUTPUT,
			@_Message                     = @_Message    OUTPUT,
			@PlantillaNotificacionEmailID = @plantilla ,
			@DatoJson                     = @datoJson                     ,
			@Email						  = @email 


	RETURN @_CodeReturn 


