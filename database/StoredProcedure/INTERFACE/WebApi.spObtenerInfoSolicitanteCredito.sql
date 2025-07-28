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

	DECLARE @clienteID INT,
			@LI_SOLICITUD int
			
     
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


	--PRUEBAS 
	--SET @Result = ( SELECT 
	--					Nui = cli_identificacion,
	--					GivenName = cli_nombre1,
	--					SecondName = cli_nombre2,
	--					Surname1 = cli_apellido1,
	--					Surname2 = cli_apellido2,
	--					Province = CLIENTES.dbo.f_cl_direccion_provincia(cli_id),
	--					City =  CLIENTES.dbo.f_cl_ciudad_domicilio(cli_id),
	--					Country = (SELECT pai_nombre from CLIENTES..CL_PAISES WHERE pai_pais = cli_nacionalidad),
	--					[Address] = CLIENTES.dbo.f_cl_direccion_domicilio_detalle(cli_id,'DIRECCION'),
	--					Email = cli_email,
	--					PhoneNumber = ISNULL(CLIENTES.dbo.f_cl_telefono_celular(cli_id), CLIENTES.dbo.f_cl_telefono(cli_id)),
   --					Reason = 'Solicitud Firma Crédito: '+pro_nombre

	--				FROM CREDITO..SL_SOLICITUD, CLIENTES..CL_CLIENTE
	--				WHERE sol_solicitud = @LI_SOLICITUD AND
	--				cli_id = sol_cliente
	
	--				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)

	--QUEMADO LOS DATOS 
	SET @Result = ( SELECT 
						Nui = '1750017186',
						GivenName = 'ESTEBAN',
						SecondName = 'NICOLAS',
						Surname1 = 'SIMBAÑA',
						Surname2 = 'MORA',
						Province = 'PICHINCHA',
						City =  'QUITO',
						Country = 'ECUADOR',
						[Address] = 'CARAPUNGO',
						Email = 'nicomora110202@hotmail.com',
						PhoneNumber = '0989769951',
						Reason = 'Solicitud Firma Crédito: '+pro_nombre

					FROM  CREDITO..CR_PRODUCTOS
					WHERE 
					pro_producto = 'AGRIC'
	
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)


SET @_CodeReturn = 1




