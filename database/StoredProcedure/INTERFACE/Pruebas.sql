select OnBoardingRespuestaJson ,OnBoardingIntentosFirma,* from [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]

--delete  from [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]


UPDATE [BancaVirtual2].[BancaVirtual].[DocumentosFirmaElectronica]
set SignBoxWeebhookPdf = 'https://eclipsoft.dev/signbox/api/file/sign_CR_SOLICITUD_CREDITO_25885',
SignBoxWeebhookTxt = 'https://eclipsoft.dev/signbox/api/log/sign_CR_SOLICITUD_CREDITO_25885'
WHERE ID = 27 


SELECT * FROM PARAMETROS..RE_DOCUMENTOS_gENERADOS


UPDATE PARAMETROS..RE_DOCUMENTOS_gENERADOS 
set dog_archivo  = 'C:\DocumentosPruebaFirmaElectronica\25\PRUEBA_.pdf'
WHERE 
dog_id = 26617