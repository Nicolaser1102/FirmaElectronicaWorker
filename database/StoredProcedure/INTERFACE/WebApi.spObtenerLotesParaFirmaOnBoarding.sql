USE INTERFACE
GO

CREATE OR ALTER PROCEDURE [WebApi].[spObtenerLotesParaFirmaOnBoarding]
@_UserName   VARCHAR(20),
@_SessionID  INT OUTPUT,
@_CodeReturn INT OUTPUT,
@_Message    VARCHAR(200) OUTPUT,
@Request     VARCHAR(MAX),
@Result      VARCHAR(MAX) OUTPUT
AS
BEGIN 
    SET NOCOUNT ON;

    SET @Result = (
        SELECT 
            df.Solicitud,
            df.Lote,
            (
                SELECT 
                    d.CodigoDocumento,
                    d.SignBoxWeebhookPdf
                FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica d
                WHERE 
                    d.Solicitud = df.Solicitud AND 
                    d.Lote = df.Lote AND
                    d.OnBoardingEstadoFirma IN ('I', 'R') AND
                    d.SignboxEstadoFirma = 'F'
                FOR JSON PATH
            ) AS Documentos
        FROM (
            SELECT Solicitud, Lote
            FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
            WHERE 
                OnBoardingEstadoFirma IN ('I', 'R')
                AND (SignBoxProcesandoFirma IS NULL OR SignBoxProcesandoFirma = 0)
            GROUP BY Solicitud, Lote
            HAVING 
                COUNT(*) = SUM(CASE WHEN SignboxEstadoFirma = 'F' THEN 1 ELSE 0 END)
                AND COUNT(*) = SUM(CASE WHEN SignBoxWeebhookPdf IS NOT NULL AND LTRIM(RTRIM(SignBoxWeebhookPdf)) <> '' THEN 1 ELSE 0 END)
        ) df
        FOR JSON PATH
    );

    SET @_CodeReturn = 1;
    SET @_Message = 'OK';
END;
