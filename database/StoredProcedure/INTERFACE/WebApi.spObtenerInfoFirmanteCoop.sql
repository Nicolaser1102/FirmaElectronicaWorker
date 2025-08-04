USE INTERFACE;
GO

CREATE OR ALTER PROCEDURE [WebApi].[spObtenerInfoFirmanteCoop]
    @_UserName     VARCHAR(20),
    @_SessionID    INT OUTPUT,
    @_CodeReturn   INT OUTPUT,
    @_Message      VARCHAR(200) OUTPUT,
    @Request       VARCHAR(MAX),
    @Result        VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener el primer firmante activo
    SET @Result = (
        SELECT TOP 1
            Id,
            NombreFirmante,
			Identificacion,
            Usuario,
            Password,
            Pin,
			Cargo,
            ImagenFirma,
            Ubicacion
        FROM BancaVirtual2.BancaVirtual.CredencialesFirmantesCoop
        WHERE Estado = 'A'
        ORDER BY Id 
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    )

    IF @Result IS NULL
    BEGIN
        SET @_Message = 'NO EXISTE NINGÚN FIRMANTE ACTIVO.'
        SET @_CodeReturn = 0
        RETURN
    END

    SET @_CodeReturn = 1
    SET @_Message = 'OK'
END
