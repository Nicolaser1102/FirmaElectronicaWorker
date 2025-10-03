USE BancaVirtual2
go 

CREATE OR ALTER PROCEDURE [BancaVirtual].[sp_cr_getDocumentosFirmaElectronicaSolicitudCR]
    @AI_SOLICITUD INT
AS
BEGIN
SELECT 
		
		[NombreDocumento] = (SELECT ISNULL(doc_descripcion,'ERROR') from CREDITO..SL_DOCUMENTOS where 
								doc_datawindow = CodigoDocumento),
		[DocumentoFirmadoSignBoxUrl] = SignBoxWeebhookPdf,
		[DocumentosFirmadosOnBoardingUrl] = OnBoardingRutaDocumento,
		[EstadoDocumentoSignBox] = CASE WHEN OnBoardingEstadoFirma = 'I' THEN 'INGRESADO'
										WHEN OnBoardingEstadoFirma =  'F' THEN 'FIRMADO'
										ELSE OnBoardingEstadoFirma
										END
		
	FROM 
	[BancaVirtual].[DocumentosFirmaElectronica]
	where Solicitud  = @AI_SOLICITUD 
END