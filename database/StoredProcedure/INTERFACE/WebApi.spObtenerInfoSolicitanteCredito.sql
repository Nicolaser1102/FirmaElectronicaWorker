--select * from INTERFACE.WebApi.SeProcedimiento
use INTERFACE
go 

CREATE OR ALTER      procedure [WebApi].[spObtenerInfoSolicitanteCredito]
@_UserName   varchar(20)					,
@_SessionID  int output						,
@_CodeReturn int output						,
@_Message    varchar(200) output	,
@Request     varchar(MAX)					,
@Result      varchar(MAX) output
as

	DECLARE @LI_SOLICITUD int
			
     
    IF ISJSON(@Request) = 0                            
    BEGIN                                              
        SET @_Message = 'FORMATO INCORRECTO.'
        SET @_CodeReturn = -1                          
        RETURN                                         
    END                                     
	

      SELECT @LI_SOLICITUD = [value]
		  FROM OPENJSON (@Request)
		  WHERE [key] = 'Solicitud'

	IF NOT EXISTS (
					SELECT 1
					FROM CREDITO..SL_SOLICITUD
					WHERE sol_solicitud = @LI_SOLICITUD )
	BEGIN
		SET @_Message = 'SOLICITUD NO EXISTE.' 
		SET @_CodeReturn = -1
		RETURN 
	END
 
	--SET @Result = (   SELECT 
	--					Nui = cli_identificacion,
	--					GivenName = cli_nombre1,
	--					SecondName = cli_nombre2,
	--					Surname1 = cli_apellido1,
	--					Surname2 = cli_apellido2,
	--					Province = CLIENTES.dbo.f_cl_direccion_provincia(cli_id),
	--					City =  CLIENTES.dbo.f_cl_ciudad_domicilio(cli_id),
	--					Country = (SELECT pai_nombre from CLIENTES..CL_PAISES WHERE pai_pais = cli_nacionalidad),
	--					[Address] = CLIENTES.dbo.f_cl_direccion_domicilio_detalle(cli_id,'DIRECCION'),
	--					Email = ISNULL(Email,cli_email),
	--					PhoneNumber = ISNULL(TelefonoCelular,(CLIENTES.dbo.f_cl_telefono_celular(cli_id))),
 --  					Reason = 'Solicitud Firma Crédito: '+pro_nombre

	--				FROM CREDITO..SL_SOLICITUD,[BancaVirtual2].[BancaVirtual].[Usuario],CLIENTES..CL_CLIENTE ,CREDITO..CR_PRODUCTOS
	--				WHERE sol_solicitud = @LI_SOLICITUD AND
	--				pro_producto = sol_producto AND 
	--				cli_id = sol_cliente AND 
	--				ClienteId = cli_id
	
	--				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)


		SET @Result = (   SELECT 
						Nui = '0802515957',
						GivenName = 'JOHNNY',
						SecondName = 'FERNANDO',
						Surname1 = 'ESPINOZA',
						Surname2 = 'LOZA',
						Province = 'Pichincha' ,
						City =  'Quito',
						Country = 'Ecuador',
						[Address] = 'La Ofelia',
						Email = 'johnny.espinoza@greensoft.com.ec',
						PhoneNumber = '0995069393' ,
   					Reason = 'Solicitud Firma Crédito: '+pro_nombre

					FROM CREDITO..SL_SOLICITUD,[BancaVirtual2].[BancaVirtual].[Usuario],CLIENTES..CL_CLIENTE ,CREDITO..CR_PRODUCTOS
					WHERE sol_solicitud = @LI_SOLICITUD AND
					pro_producto = sol_producto AND 
					cli_id = sol_cliente AND 
					ClienteId = cli_id
	
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)



SET @_CodeReturn = 1




