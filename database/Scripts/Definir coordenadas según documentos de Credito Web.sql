use CREDITO
go

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '50,625,250,665',        --Cada coordenada forma un cuadrado en este caso es 
doc_para_firma_electronica= 1,								-- Va a formar un cuadrado desde la posicion 50 hasta 250 en x	
doc_ubic_pagina_firma_elec = 6								---Y el cuadrado va a estar ubicado en 625 con altura hasta 665 en y (40 de altura de cuadrado*200 de ancho)
WHERE doc_datawindow in ('CR_CONTRATO_CREDITO'
						  )

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,50,210,90',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 3
WHERE doc_datawindow in (
						   'CR_CERT_INDIVIDUAL'
						 )


						  UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,210,50',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 4
WHERE doc_datawindow in (
						  'CR_CONDICIONES_CR')



UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,210,50',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 5
WHERE doc_datawindow in (
						   'CR_SOLICITUD_CREDITO')


						  UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,20,210,60',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 7
WHERE doc_datawindow in (
						  'CR_CONVENIO_USO')

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '340,50,540,90',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 1
WHERE doc_datawindow in (
						  'CR_AUTORIZACION'
						  
						  )


UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,210,50',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 3
WHERE doc_datawindow in (
						  'CR_PAGARE'
						  )

UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,210,50',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 2
WHERE doc_datawindow in (
						  'LICITUD_FONDOS_CRW')


						  select * from SL_DOCUMENTOS