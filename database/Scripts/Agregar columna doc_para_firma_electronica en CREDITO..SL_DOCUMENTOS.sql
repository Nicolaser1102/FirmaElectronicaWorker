use CREDITO 
GO 


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'SL_DOCUMENTOS'
      AND COLUMN_NAME = 'doc_para_firma_electronica'
)
BEGIN
    ALTER TABLE dbo.SL_DOCUMENTOS
    ADD doc_para_firma_electronica bit NOT NULL 
        CONSTRAINT DF_SL_DOCUMENTOS_doc_para_firma_electronica DEFAULT 0;
END


-- Agregar columna si no existe
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'SL_DOCUMENTOS'
      AND COLUMN_NAME = 'doc_coordenadas_firma_elec'
)
BEGIN
    ALTER TABLE dbo.SL_DOCUMENTOS
    ADD doc_coordenadas_firma_elec varchar(25) NULL;
END

-- Agregar columna si no existe
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'SL_DOCUMENTOS'
      AND COLUMN_NAME = 'doc_ubic_pagina_firma_elec'
)
BEGIN
    ALTER TABLE dbo.SL_DOCUMENTOS
    ADD doc_ubic_pagina_firma_elec int NULL;
END


IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'SL_DOCUMENTOS'
      AND COLUMN_NAME = 'doc_monto_minimo_impresion'
)
BEGIN
    ALTER TABLE dbo.SL_DOCUMENTOS
    ADD doc_monto_minimo_impresion MONEY NULL;
END


go

UPDATE SL_DOCUMENTOS 
set doc_datawindow = 'LICITUD_FONDOS_CRW',
 doc_monto_minimo_impresion = 5000
WHERE doc_descripcion = 'Licitud de Fondos Credito Web'

GO

--DATOS GENERICOS
UPDATE SL_DOCUMENTOS
set doc_coordenadas_firma_elec = '10,10,350,70',
doc_para_firma_electronica= 1,
doc_ubic_pagina_firma_elec = 2
WHERE doc_datawindow in ('CR_CONTRATO_CREDITO',
						   'CR_CERT_INDIVIDUAL',
						  'CR_CONDICIONES_CR',
						   'CR_SOLICITUD_CREDITO',
						  'CR_CONVENIO_USO',
						  'CR_AUTORIZACION',
						  'CR_PAGARE',
						  'LICITUD_FONDOS_CRW')


		
--SELECT * FROM SL_DOCUMENTOS