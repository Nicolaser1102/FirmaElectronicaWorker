--select * from INTERFACE.WebApi.SeProcedimiento
use INTERFACE
go 

CREATE OR ALTER      procedure [WebApi].[spObtenerRutasDocumentosPorSolicitudLote]
@_UserName   varchar(20)					,
@_SessionID  int output						,
@_CodeReturn int output						,
@_Message    varchar(200) output	,
@Request     varchar(MAX)					,
@Result      varchar(MAX) output
as

	DECLARE @clienteID INT,
			@SolicitudCredito int,
			@Lote int
			
     
    IF ISJSON(@Request) = 0                            
    BEGIN                                              
        SET @_Message = 'FORMATO INCORRECTO.'
        SET @_CodeReturn = -1                          
        RETURN                                         
    END                                     
	

    SELECT
          @SolicitudCredito	 = idSolicitud,
		  @Lote = lote
    FROM OPENJSON(@Request)                            
      WITH (                      
		 idSolicitud nvarchar(20),
		 lote nvarchar(20)
           );     

	IF NOT EXISTS (
					SELECT 1
					FROM CREDITO..SL_SOLICITUD
					WHERE sol_solicitud = @SolicitudCredito )
	BEGIN
		SET @_Message = 'SOLICITUD NO EXISTE.' 
		SET @_CodeReturn = -1
		RETURN 
	END



	SET @Result = ( SELECT 
										Solicitud = dog_referencia,
										CodigoDocumento 		 = dog_reporte_codigo,
    									Lote 		 = dog_lote,
    									RutaArchivo = dog_archivo
									from PARAMETROS..RE_DOCUMENTOS_GENERADOS
									WHERE dog_referencia = @SolicitudCredito
									and dog_lote = @Lote
								
    						
					FOR JSON PATH)
SET @_CodeReturn = 1




