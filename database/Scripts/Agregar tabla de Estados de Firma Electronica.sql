USE BancaVirtual2
go

IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'EstadosFirmaElectronica'
      AND s.name = 'BancaVirtual'
)
BEGIN
    CREATE TABLE BancaVirtual.EstadosFirmaElectronica (
        estfe_estado_nombre CHAR(1) NOT NULL,
        estfe_descripcion   VARCHAR(50) NOT NULL,
        creacion_usuario    VARCHAR(20) NOT NULL,
        creacion_fecha      DATETIME NOT NULL,
        modifica_usuario    VARCHAR(20) NULL,
        modifica_fecha      DATETIME NULL
    );
END;
GO


INSERT INTO BancaVirtual.EstadosFirmaElectronica
    (estfe_estado_nombre, estfe_descripcion, creacion_usuario, creacion_fecha)
VALUES
    ('A', 'Activo', 'ADMIN', GETDATE()),
    ('I', 'Inactivo', 'ADMIN', GETDATE());

