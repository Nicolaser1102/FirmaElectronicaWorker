USE BancaVirtual2;
GO

-- Crear la tabla
CREATE TABLE BancaVirtual.DocumentosFirmaElectronica
(
    ID INT NOT NULL PRIMARY KEY, -- Clave primaria
    Solicitud INT NOT NULL,
    Lote INT NOT NULL,
    CodigoDocumento VARCHAR(20) NOT NULL,
    SignBoxWeebhookTxt VARCHAR(250),
    SignBoxWeebhookPdf VARCHAR(250),
    SignBoxRespuestaApi VARCHAR(250),
    SignBoxRespuestaJson VARCHAR(MAX),
    SignboxEstadoFirma CHAR(1) NOT NULL,
    SignboxIntentosFirma INT NOT NULL DEFAULT 0,
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
    OnBoardingModificaUsuario VARCHAR(20),
    OnBoardingModificaFecha DATETIME
);
GO

-- Índice para búsquedas por OnBoardingEstadoFirma y estado de firma (útil para agregaciones y filtros masivos)
CREATE NONCLUSTERED INDEX IX_DocFirma_EstadoFirma
ON BancaVirtual.DocumentosFirmaElectronica (
    OnBoardingEstadoFirma,
    SignboxEstadoFirma,
    Solicitud,
    Lote
);
GO

-- Índice para búsquedas rápidas por CódigoDocumento + Solicitud + Lote (muy común en updates/select específicos)
CREATE NONCLUSTERED INDEX IX_DocFirma_CodigoSolicitudLote
ON BancaVirtual.DocumentosFirmaElectronica (
    CodigoDocumento,
    Solicitud,
    Lote
);
GO

-- Índice auxiliar por Solicitud + Lote (para agrupaciones frecuentes)
CREATE NONCLUSTERED INDEX IX_DocFirma_SolicitudLote
ON BancaVirtual.DocumentosFirmaElectronica (
    Solicitud,
    Lote
);
GO
