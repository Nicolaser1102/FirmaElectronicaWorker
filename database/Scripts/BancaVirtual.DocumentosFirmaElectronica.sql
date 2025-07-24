USE BancaVirtual2;
go 


CREATE TABLE BancaVirtual.DocumentosFirmaElectronica
(
    ID INT NOT NULL PRIMARY KEY, -- Int no nullable y Primary Key
    Solicitud INT NOT NULL, -- Int
    Lote INT NOT NULL, -- Int
    CodigoDocumento VARCHAR(20) NOT NULL, -- Varchar(20)
    SignBoxWeebhookTxt VARCHAR(250), -- Varchar(250)
    SignBoxWeebhookPdf VARCHAR(250), -- Varchar(250)
    SignBoxRespuestaApi VARCHAR(250), -- Varchar(250)
    SignBoxRespuestaJson VARCHAR(MAX), -- Varchar(Max)
    SignboxEstadoFirma CHAR(1) NOT NULL, -- Char(1)
    SignboxIntentosFirma INT NOT NULL DEFAULT 0, -- Int
    SignBoxCreacionUsuario VARCHAR(20) NOT NULL, -- Varchar(20)
    SignBoxCreacionFecha DATETIME NOT NULL, -- Datetime
    SignBoxModificaUsuario VARCHAR(20), -- Varchar(20)
    SignBoxModificaFecha DATETIME, -- Datetime
    OnBoardingRutaDocumento VARCHAR(250), -- Varchar(250)
    OnBoardingRequestId VARCHAR(150), -- Varchar(150)
    OnBoardingRespuestaDetail VARCHAR(300), -- Varchar(300)
    OnBoardingRespuestaJson VARCHAR(MAX), -- Varchar(Max)
    OnBoardingEstadoFirma CHAR(1), -- Char(1)
    OnBoardingIntentosFirma INT NOT NULL DEFAULT 0, -- Int
    OnBoardingModificaUsuario VARCHAR(20), -- Varchar(20)
    OnBoardingModificaFecha DATETIME -- Datetime
);