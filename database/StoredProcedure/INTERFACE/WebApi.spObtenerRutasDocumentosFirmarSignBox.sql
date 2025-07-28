USE INTERFACE
GO
CREATE  OR ALTER procedure [WebApi].[spObtenerDocumentosFirmarSignBox]
@_UserName   varchar(20)					,
@_SessionID  int output						,
@_CodeReturn int output						,
@_Message    varchar(200) output	,
@Request     varchar(MAX)					,
@Result      varchar(MAX) output
as

		--Convertir a INT
		---Solicitud = CAST(dog_referencia AS INT),

		--SET @_Message = 'No hay documentos para Procesar' 
		--SET @_CodeReturn = 1
		--SET @Result = '{}'
		--RETURN 




	SET @Result = ( SELECT 
										ID,
										Solicitud ,										
    									Lote,
										CodigoDocumento,
    									RutaArchivo = dog_archivo
									from [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica],
									[PARAMETROS]..[RE_DOCUMENTOS_GENERADOS]
									WHERE
									dog_lote = Lote AND
									dog_referencia = Solicitud AND
									dog_reporte_codigo = CodigoDocumento AND 

									--Condiciones para obtener documentos
									SignboxEstadoFirma in ('I','R')
								
    						
					FOR JSON PATH)


SET @_CodeReturn = 1


