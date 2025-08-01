USE INTERFACE
GO

CREATE OR ALTER PROCEDURE [WebApi].[spInsertarRegistrosFirmaElectronica]
    @_UserName     VARCHAR(20),
    @_SessionID    INT OUTPUT,
    @_CodeReturn   INT OUTPUT,
    @_Message      VARCHAR(200) OUTPUT,
    @Request       VARCHAR(MAX),
    @Result        VARCHAR(MAX) OUTPUT
AS
BEGIN
    BEGIN TRY
        DECLARE @clienteID INT,
                @SolicitudCredito INT,
                @Lote INT;

        -- Validar que el JSON tenga formato correcto
        IF ISJSON(@Request) = 0
        BEGIN
            SET @_Message = 'FORMATO INCORRECTO.'
            SET @_CodeReturn = -1
            RETURN
        END

        -- Extraer una muestra para validaciones iniciales
        SELECT
            @SolicitudCredito = Solicitud,
            @Lote = Lote
        FROM OPENJSON(@Request, '$.Documentos')
        WITH (
            Solicitud INT,
            Lote INT
        );

        -- Validación: Solicitud debe existir
        IF NOT EXISTS (
            SELECT 1
            FROM CREDITO..SL_SOLICITUD
            WHERE sol_solicitud = @SolicitudCredito
        )
        BEGIN
            SET @_Message = 'SOLICITUD NO EXISTE.'
            SET @_CodeReturn = -1
            RETURN
        END

        -- Validación: Verificar si ya existen registros
        IF EXISTS (
            SELECT 1
            FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
            WHERE Solicitud = @SolicitudCredito
              AND Lote = @Lote
        )
        BEGIN
            SET @_Message = 'DOCUMENTOS YA GENERADOS Y ENVIADOS A FIRMAR. FAVOR GENERAR OTRA SOLICITUD.'
            SET @_CodeReturn = -1
            RETURN
        END

        -- Insertar documentos
        INSERT INTO BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica (
            Solicitud, Lote, CodigoDocumento, SignboxEstadoFirma, SignBoxCreacionUsuario, SignBoxCreacionFecha
        )
        SELECT 
            Solicitud,
            Lote,
            CodigoDocumento,
            'I',
            @_UserName,
            dbo.FechaSistema()
        FROM OPENJSON(@Request, '$.Documentos')
        WITH (
            Solicitud INT,
            Lote INT,
            CodigoDocumento NVARCHAR(100)
        );

        SET @_CodeReturn = 1
        SET @_Message = 'DOCUMENTOS INSERTADOS CORRECTAMENTE.'
    END TRY
    BEGIN CATCH
        SET @_CodeReturn = ERROR_NUMBER()
        SET @_Message = 'ERROR EN PROCEDIMIENTO: ' + ERROR_MESSAGE()
    END CATCH
END
