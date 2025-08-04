USE BancaVirtual2;
GO

-- Crear la tabla con campos de auditoría y estado
CREATE TABLE BancaVirtual.CredencialesFirmantesCoop
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    NombreFirmante VARCHAR(50) NOT NULL,
    Usuario VARCHAR(30) NOT NULL,
    Password VARCHAR(30) NOT NULL,
    Pin VARCHAR(10) NOT NULL,
    ImagenFirma VARCHAR(MAX) NOT NULL, -- Imagen en base64
    Ubicacion VARCHAR(30) NOT NULL,
    Estado CHAR(1) NOT NULL, -- 'A' = Activo, 'B' = Baja/Inactivo

    CreacionUsuario VARCHAR(20) NOT NULL,
    CreacionFecha DATETIME NOT NULL DEFAULT GETDATE(),
    ModificaUsuario VARCHAR(20) NULL,
    ModificaFecha DATETIME NULL
);
