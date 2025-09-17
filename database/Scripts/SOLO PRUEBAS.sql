USE PARAMETROS
GO

declare @AI_REFERENCIA INT 

SET @AI_REFERENCIA = 25888

SELECT * FROM RE_DOCUMENTOS_GENERADOS
WHERE dog_referencia = @AI_REFERENCIA




UPDATE RE_DOCUMENTOS_GENERADOS
set dog_archivo= 'C:\DocumentosPruebaFirmaElectronica\25\2025-08\1\20250801CR_AUTORIZACION01.pdf'
WHERE dog_referencia = @AI_REFERENCIA
and dog_reporte_codigo = 'CR_AUTORIZACION'

UPDATE RE_DOCUMENTOS_GENERADOS
set dog_archivo= 'C:\DocumentosPruebaFirmaElectronica\25\2025-08\1\20250801CR_CERT_INDIVIDUAL01.PDF'
WHERE dog_referencia = @AI_REFERENCIA
and dog_reporte_codigo = 'CR_CERT_INDIVIDUAL'

UPDATE RE_DOCUMENTOS_GENERADOS
set dog_archivo= 'C:\DocumentosPruebaFirmaElectronica\25\2025-08\1\20250801CR_CONDICIONES_CR01.PDF'
WHERE dog_referencia = @AI_REFERENCIA
and dog_reporte_codigo = 'CR_CONDICIONES_CR'

UPDATE RE_DOCUMENTOS_GENERADOS
set dog_archivo= 'C:\DocumentosPruebaFirmaElectronica\25\2025-08\1\20250801CR_CONTRATO_CREDITO01.PDF'
WHERE dog_referencia = @AI_REFERENCIA
and dog_reporte_codigo = 'CR_CONTRATO_CREDITO'

UPDATE RE_DOCUMENTOS_GENERADOS
set dog_archivo= 'C:\DocumentosPruebaFirmaElectronica\25\2025-08\1\20250801CR_CONVENIO_USO01.PDF'
WHERE dog_referencia = @AI_REFERENCIA
and dog_reporte_codigo = 'CR_CONVENIO_USO'

UPDATE RE_DOCUMENTOS_GENERADOS
set dog_archivo= 'C:\DocumentosPruebaFirmaElectronica\25\2025-08\1\20250801CR_PAGARE01.PDF'
WHERE dog_referencia = @AI_REFERENCIA
and dog_reporte_codigo = 'CR_PAGARE'

UPDATE RE_DOCUMENTOS_GENERADOS
set dog_archivo= 'C:\DocumentosPruebaFirmaElectronica\25\2025-08\1\20250801CR_SOLICITUD_CREDITO01.PDF'
WHERE dog_referencia = @AI_REFERENCIA
and dog_reporte_codigo = 'CR_SOLICITUD_CREDITO'

USE BancaVirtual2
GO

declare @AI_REFERENCIA INT 

SET @AI_REFERENCIA = 25887

UPDATE BancaVirtual.DocumentosFirmaElectronica
set SignBoxWeebhookTxt = null,
SignBoxWeebhookPdf = null,
SignBoxRespuestaApi = null,
SignBoxRespuestaJson = null,
SignboxEstadoFirma = 'I',
SignboxIntentosFirma = 0,
SignBoxProcesandoFirma = 0,
OnBoardingEstadoFirma = NULL
WHERE Solicitud = @AI_REFERENCIA




SELECT * FROM CREDITO..SL_SOLICITUD
where sol_solicitud = 25887


  SELECT 
						Nui = cli_identificacion,
						GivenName = cli_nombre1,
						SecondName = cli_nombre2,
						Surname1 = cli_apellido1,
						Surname2 = cli_apellido2,
						Province = CLIENTES.dbo.f_cl_direccion_provincia(cli_id),
						City =  CLIENTES.dbo.f_cl_ciudad_domicilio(cli_id),
						Country = (SELECT pai_nombre from CLIENTES..CL_PAISES WHERE pai_pais = cli_nacionalidad),
						[Address] = CLIENTES.dbo.f_cl_direccion_domicilio_detalle(cli_id,'DIRECCION'),
						Email = ISNULL(Email,cli_email),
						PhoneNumber = ISNULL(TelefonoCelular,(CLIENTES.dbo.f_cl_telefono_celular(cli_id))),
   					Reason = 'Solicitud Firma Crédito: '+pro_nombre

					FROM CREDITO..SL_SOLICITUD,[BancaVirtual2].[BancaVirtual].[Usuario],CLIENTES..CL_CLIENTE ,CREDITO..CR_PRODUCTOS
					WHERE sol_solicitud = 25887 AND
					pro_producto = sol_producto AND 
					cli_id = sol_cliente AND 
					ClienteId = cli_id



					SELECT * FROM BancaVirtual.Usuario where UserName = 'jachson1'


					SELECT * FROM [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]