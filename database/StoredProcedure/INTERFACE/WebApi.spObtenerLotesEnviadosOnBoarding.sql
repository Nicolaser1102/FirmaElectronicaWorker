
--select * from INTERFACE.WebApi.SeProcedimiento
use INTERFACE
go 

CREATE OR ALTER      procedure [WebApi].[spObtenerLotesEnviadosOnBoarding]
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
    SELECT *
    FROM (
        SELECT 
            DISTINCT Solicitud,
            Lote,
            RequestId = OnBoardingRequestId
        FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
        WHERE OnBoardingEstadoFirma IN ('E', 'O', 'C', 'B', 'K', 'S')
        GROUP BY Solicitud, Lote, OnBoardingRequestId
        HAVING COUNT(*) = SUM(CASE WHEN OnBoardingEstadoFirma = 'E' THEN 1 ELSE 0 END)

        UNION

        SELECT 
            DISTINCT Solicitud,
            Lote,
            RequestId = OnBoardingRequestId
        FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
        WHERE OnBoardingEstadoFirma IN ('O', 'C', 'B', 'K', 'S')
    ) AS ResultadoFinal
    FOR JSON PATH
);


    SET @_CodeReturn = 1
    SET @_Message = 'OK'
END;






