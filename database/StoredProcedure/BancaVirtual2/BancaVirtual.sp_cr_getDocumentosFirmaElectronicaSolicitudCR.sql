USE BancaVirtual2
go 

CREATE OR ALTER PROCEDURE [BancaVirtual].[sp_cr_getDocumentosFirmaElectronicaSolicitudCR]
    @AI_SOLCITUD INT
AS
BEGIN
    SELECT 
		[Solicitud] = Solicitud,
		[CodigoDocumento] = CodigoDocumento,
		[EstadoDocumentoSignBox] = CASE WHEN SignboxEstadoFirma = 'I' THEN 'INGRESADO'
										WHEN SignboxEstadoFirma =  'F' THEN 'FIRMADO'
										ELSE 'ERROR'
										END,

		[DocumentoFirmadoSignBoxUrl] = SignBoxWeebhookPdf,
		[EstadoDocumentoOnBoarding] = CASE WHEN SignboxEstadoFirma = 'I' THEN 'INGRESADO'
										WHEN SignboxEstadoFirma =  'F' THEN 'FIRMADO'
										WHEN SignboxEstadoFirma =  'E' THEN 'ERROR'
										ELSE 'EN PROCESO'
										END,
		[DocumentosFirmadosOnBoardingUrl] = OnBoardingRutaDocumento
		
	FROM 
	[BancaVirtual].[DocumentosFirmaElectronica]
	where Solicitud  = @AI_SOLCITUD 
END