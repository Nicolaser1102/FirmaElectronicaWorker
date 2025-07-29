
--select * from INTERFACE.WebApi.SeProcedimiento
use INTERFACE
go 

CREATE OR ALTER      procedure [WebApi].[spObtenerLotesParaGuardarDocumentosFirmados]
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
            DISTINCT Solicitud,
            Lote,
            RequestId = OnBoardingRequestId
        FROM BancaVirtual2.BancaVirtual.DocumentosFirmaElectronica
        WHERE OnBoardingEstadoFirma IN ('F') AND
		OnBoardingRespuestaDetail = 'Solicitud finalizada' AND 
		OnBoardingRutaDocumento IS NULL
        GROUP BY Solicitud, Lote, OnBoardingRequestId
        HAVING COUNT(*) = SUM(CASE WHEN OnBoardingEstadoFirma = 'F' THEN 1 ELSE 0 END)
    FOR JSON PATH
);


    SET @_CodeReturn = 1
    SET @_Message = 'OK'
END;






