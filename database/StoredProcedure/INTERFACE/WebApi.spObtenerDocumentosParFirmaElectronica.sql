USE INTERFACE
GO 

CREATE OR ALTER    procedure [WebApi].[spObtenerDocumentosParaFirmaElectronica]
@_UserName   varchar(20)					,
@_SessionID  int output						,
@_CodeReturn int output						,
@_Message    varchar(200) output	,
@Request     varchar(MAX)					,
@Result      varchar(MAX) output
as

		DECLARE
   @LI_SOLICITUD INT,
   @LI_LOTE INT,
   @LS_CODIGO_DOCUMENTO VARCHAR (20)


  SELECT @LI_SOLICITUD = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Solicitud'

  SELECT @LI_LOTE = [value]
  FROM OPENJSON (@Request)
  WHERE [key] = 'Lote'







	SET @Result = ( SELECT 
										
										Solicitud = CAST(dog_referencia AS INT),										
    									Lote = dog_lote,
										CodigoDocumento = dog_reporte_codigo,
    									RutaArchivo = dog_archivo
									from 
									[PARAMETROS]..[RE_DOCUMENTOS_GENERADOS]
									WHERE
									dog_lote = @LI_LOTE AND
									dog_referencia =  @LI_SOLICITUD


									AND dog_lote not IN (SELECT Lote FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica)
									
									
								
    						
					FOR JSON PATH)


SET @_CodeReturn = 1


