--select * from INTERFACE.WebApi.SeProcedimiento
use INTERFACE
go 

CREATE OR ALTER      procedure [WebApi].[spObtenerLotesParaFirmaOnBoarding]
@_UserName   varchar(20)					,
@_SessionID  int output						,
@_CodeReturn int output						,
@_Message    varchar(200) output	,
@Request     varchar(MAX)					,
@Result      varchar(MAX) output
as

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
            SELECT DISTINCT Solicitud, Lote
            FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
            WHERE 
                OnBoardingEstadoFirma IN ('I', 'R')
            GROUP BY Solicitud, Lote
            HAVING COUNT(*) = SUM(CASE WHEN SignboxEstadoFirma = 'F' THEN 1 ELSE 0 END)
        ) df
        FOR JSON PATH
    );

    SET @_CodeReturn = 1
    SET @_Message = 'OK'
END;






