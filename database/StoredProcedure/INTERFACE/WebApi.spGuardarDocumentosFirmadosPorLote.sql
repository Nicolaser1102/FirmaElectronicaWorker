USE INTERFACE
GO

CREATE OR ALTER PROCEDURE [WebApi].[spGuardarDocumentosFirmadosPorLote]
    @_UserName   VARCHAR(20),
    @_SessionID  INT     OUTPUT,
    @_CodeReturn INT     OUTPUT,
    @_Message    VARCHAR(200) OUTPUT,
    @Request     VARCHAR(MAX),
    @Result      VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @LI_SOLICITUD    INT,
        @LI_LOTE         INT,
        @LS_REQUEST_ID   VARCHAR(150);


	--LINK PARA DESCARGAR LOS DOCUMENTOS 
		DECLARE @LS_DESCARGA_DOCUMENTO VARCHAR(300);
		SET @LS_DESCARGA_DOCUMENTO = 'https://eclipsoft.dev/onboarding-back/api/retrieve-pdf?path='
		 

    -- Tabla para resultados por documento
    DECLARE @Resultados TABLE (
        CodigoDoc VARCHAR(100),
        Ruta NVARCHAR(MAX),
        Estado VARCHAR(10),
        Mensaje VARCHAR(500)
    );

    BEGIN TRY
        --------------------------------------
        -- 1) Extraer variables base desde JSON
        --------------------------------------
        SELECT 
            @LI_SOLICITUD  = TRY_CAST(JSON_VALUE(@Request, '$.solicitud') AS INT),
            @LI_LOTE       = TRY_CAST(JSON_VALUE(@Request, '$.lote') AS INT),
            @LS_REQUEST_ID = JSON_VALUE(@Request, '$.requestId');

        --------------------------------------
        -- 2) Parsear las rutas en tabla temporal
        --------------------------------------
        DECLARE @Rutas TABLE (
            Ruta NVARCHAR(MAX)
        );

        INSERT INTO @Rutas (Ruta)
        SELECT value
        FROM OPENJSON(@Request, '$.rutas');

        --------------------------------------
        -- 3) Obtener lista única de códigos documento desde tabla DocumentosFirmaElectronica para la solicitud y lote
        --------------------------------------
        DECLARE @Codigos TABLE (CodigoDoc VARCHAR(100));

        INSERT INTO @Codigos (CodigoDoc)
        SELECT DISTINCT CodigoDocumento
        FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
        WHERE Solicitud = @LI_SOLICITUD
          AND Lote = @LI_LOTE;

        --------------------------------------
        -- 4) Para cada código documento intentamos actualizar con LIKE
        --------------------------------------
        DECLARE @Codigo VARCHAR(100);
        DECLARE codigo_cursor CURSOR LOCAL FAST_FORWARD FOR 
            SELECT CodigoDoc FROM @Codigos;

        OPEN codigo_cursor;
        FETCH NEXT FROM codigo_cursor INTO @Codigo;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @RutaEncontrada NVARCHAR(MAX);

            -- Buscar la ruta que contiene el código de documento y el número de solicitud (como string)
            SELECT TOP 1 @RutaEncontrada = Ruta
            FROM @Rutas
            WHERE Ruta LIKE '%' + @Codigo + '%' 
              AND Ruta LIKE '%Sol' + CAST(@LI_SOLICITUD AS VARCHAR(20)) + '%';

            IF @RutaEncontrada IS NOT NULL
            BEGIN
                BEGIN TRY
                    UPDATE D
                    SET 
                        D.OnBoardingRutaDocumento    = @LS_DESCARGA_DOCUMENTO+@RutaEncontrada,
                        D.OnBoardingModificaUsuario = @_UserName,
                        D.OnBoardingModificaFecha   = dbo.FechaSistema()
                    FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica AS D
                    WHERE D.Solicitud = @LI_SOLICITUD
                      AND D.Lote = @LI_LOTE
                      AND D.CodigoDocumento = @Codigo;

                    IF @@ROWCOUNT = 0
                    BEGIN
                        INSERT INTO @Resultados (CodigoDoc, Ruta, Estado, Mensaje)
                        VALUES (@Codigo, @RutaEncontrada, 'NO_ENCONTRADO', 'No se encontró documento para actualizar');
                    END
                    ELSE
                    BEGIN
                        INSERT INTO @Resultados (CodigoDoc, Ruta, Estado, Mensaje)
                        VALUES (@Codigo, @RutaEncontrada, 'OK', 'Documento actualizado');
                    END
                END TRY
                BEGIN CATCH
                    INSERT INTO @Resultados (CodigoDoc, Ruta, Estado, Mensaje)
                    VALUES (@Codigo, @RutaEncontrada, 'ERROR', ERROR_MESSAGE());
                END CATCH
            END
            ELSE
            BEGIN
                -- No se encontró ruta para ese código documento
                INSERT INTO @Resultados (CodigoDoc, Ruta, Estado, Mensaje)
                VALUES (@Codigo, NULL, 'NO_RUTA', 'No se encontró ruta para el código documento');
            END

            FETCH NEXT FROM codigo_cursor INTO @Codigo;
        END

        CLOSE codigo_cursor;
        DEALLOCATE codigo_cursor;

        --------------------------------------
        -- 5) Preparar respuesta JSON resumen
        --------------------------------------
        SET @Result = (
            SELECT CodigoDoc, Ruta, Estado, Mensaje
            FROM @Resultados
            FOR JSON PATH, ROOT('Resultados')
        );

        SET @_CodeReturn = 1;
        SET @_Message = 'Proceso terminado correctamente.';

    END TRY
    BEGIN CATCH
        SET @_CodeReturn = -1;
        SET @_Message = ERROR_MESSAGE();

        SET @Result = JSON_QUERY(
            '{"error":"' + REPLACE(ERROR_MESSAGE(), '"', '\"') + '"}'
        );
    END CATCH
END;
