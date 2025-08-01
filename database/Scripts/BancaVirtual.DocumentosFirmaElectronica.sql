USE BancaVirtual2;
GO

-- Crear la tabla con ID autoincremental
CREATE TABLE BancaVirtual.DocumentosFirmaElectronica
(
    ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY, -- Clave primaria autoincremental
    Solicitud INT NOT NULL,
    Lote INT NOT NULL,
    CodigoDocumento VARCHAR(20) NOT NULL,
    SignBoxWeebhookTxt VARCHAR(250),
    SignBoxWeebhookPdf VARCHAR(250),
    SignBoxRespuestaApi VARCHAR(250),
    SignBoxRespuestaJson VARCHAR(MAX),
    SignboxEstadoFirma CHAR(1) NOT NULL,
    SignboxIntentosFirma INT NOT NULL DEFAULT 0,
	SignBoxProcesandoFirma BIT NOT NULL DEFAULT 0,
    SignBoxCreacionUsuario VARCHAR(20) NOT NULL,
    SignBoxCreacionFecha DATETIME NOT NULL,
    SignBoxModificaUsuario VARCHAR(20),
    SignBoxModificaFecha DATETIME,
    OnBoardingRutaDocumento VARCHAR(250),
    OnBoardingRequestId VARCHAR(150),
    OnBoardingRespuestaDetail VARCHAR(300),
    OnBoardingRespuestaJson VARCHAR(MAX),
    OnBoardingEstadoFirma CHAR(1),
    OnBoardingIntentosFirma INT NOT NULL DEFAULT 0,
	OnBoardingProcesandoFirma BIT NOT NULL DEFAULT 0,
    OnBoardingModificaUsuario VARCHAR(20),
    OnBoardingModificaFecha DATETIME
);
GO

-- Índice para búsquedas por OnBoardingEstadoFirma y estado de firma
CREATE NONCLUSTERED INDEX IX_DocFirma_EstadoFirma
ON BancaVirtual.DocumentosFirmaElectronica (
    OnBoardingEstadoFirma,
    SignboxEstadoFirma,
    Solicitud,
    Lote
);
GO

-- Índice para búsquedas rápidas por CódigoDocumento + Solicitud + Lote
CREATE NONCLUSTERED INDEX IX_DocFirma_CodigoSolicitudLote
ON BancaVirtual.DocumentosFirmaElectronica (
    CodigoDocumento,
    Solicitud,
    Lote
);
GO

-- Índice auxiliar por Solicitud + Lote
CREATE NONCLUSTERED INDEX IX_DocFirma_SolicitudLote
ON BancaVirtual.DocumentosFirmaElectronica (
    Solicitud,
    Lote
);
GO
