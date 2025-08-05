use CREDITO
go

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 2
WHERE doc_datawindow in ('CR_CONTRATO_CREDITO'
						  )

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,30,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 3
WHERE doc_datawindow in (
						   'CR_CERT_INDIVIDUAL'
						 )


						  UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 4
WHERE doc_datawindow in (
						  'CR_CONDICIONES_CR')



UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 5
WHERE doc_datawindow in (
						   'CR_SOLICITUD_CREDITO')


						  UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,20,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 7
WHERE doc_datawindow in (
						  'CR_CONVENIO_USO')

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,250,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 1
WHERE doc_datawindow in (
						  'CR_AUTORIZACION'
						  
						  )


UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 3
WHERE doc_datawindow in (
						  'CR_PAGARE'
						  )

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 2
WHERE doc_datawindow in (
						  'LICITUD_FONDOS_CRW')