
CREATE OR ALTER   PROCEDURE [BancaVirtual].[spGenerarArchivos]
@_UserName                          varchar(20),
@_SessionID                         int output,
@_CodeReturn                        int output,
@_Message                           varchar(200) output,
@Request                            varchar(MAX),
@Result                             varchar(MAX) output

AS

DECLARE   
	
	@ret			int
	, @body			varchar(max)
	, @id			int
	, @id_max		int
	, @codigo		varchar(50)
	, @lote int
	, @solicitud int
	,@monto int

DECLARE
	  @reportes		table (id int identity(1,1), codigo varchar(50))



	 select @solicitud = (select top(1)IDSolicitud
	  from BancaVirtual.SolicitudCredito s, Usuario u
	  where s.ClienteId = u.ClienteId
	  and u.UserName = @_UserName
	  order by s.ID desc)

	  	  select @monto= sol_monto 
FROM CREDITO..SL_SOLICITUD
where  sol_solicitud= @solicitud

if @monto >= 5000 
	begin

	INSERT INTO  @reportes (codigo)
	VALUES ('CR_CONTRATO_CREDITO'),
		   ('CR_CERT_INDIVIDUAL'),
		  ('CR_CONDICIONES_CR'),
		   ('CR_SOLICITUD_CREDITO'),
		  ('CR_CONVENIO_USO'),
		  ('CR_AUTORIZACION'),
		  ('CR_PAGARE'),
		  ('LICITUD_FONDOS_CRW')

	end
else
	begin
	INSERT INTO  @reportes (codigo)
	VALUES ('CR_CONTRATO_CREDITO'),
		   ('CR_CERT_INDIVIDUAL'),
		  ('CR_CONDICIONES_CR'),
		   ('CR_SOLICITUD_CREDITO'),
		  ('CR_CONVENIO_USO'),
		  ('CR_AUTORIZACION'),
		  ('CR_PAGARE')
	end


EXEC @lote = PARAMETROS.dbo.sp_co_siguiente_secuencial @AS_CODIGO = 'BV_CREDITO_WEB'

SET	@id = 1
	
SELECT 
	 @id_max = max(id) 
FROM @reportes

WHILE @id <= @id_max
BEGIN
  SELECT @codigo = codigo 
  FROM @reportes 
  WHERE id = @id
  SET @body  = 
        '<?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
            <GenerarDocumentosGenericos xmlns="http://tempuri.org/">
              <reporte>' + @codigo + '</reporte>
              <referencia>' + CONVERT (varchar(10), @solicitud )+ '</referencia>
              <lote>' + CONVERT (varchar, @lote)+ '</lote>
              <usuario></usuario>
              <claveEnc></claveEnc>
            </GenerarDocumentosGenericos>
          </soap:Body>
        </soap:Envelope>'

 EXEC @ret = PARAMETROS.dbo.sp_co_call_webapi
    @URL     = 'http://vmservidorweb/difare/des/Orion.Credito.Documentos.WS.Difare/ServiciosCreditoDocumentos.asmx?op=GenerarDocumentosGenericos'
  , @Method  = 'POST' 
  , @Body		 = @body
  , @Headers = '{"Content-Type": "text/xml; charset=utf-8"}'
  , @Result  = @Result OUT
  , @AS_MSJ  = @_Message OUT

  IF @ret = -1
  BEGIN
    SET @_Message = 'ERROR AL GENERAR REPORTE ' + @codigo
    return -1
  END 
  
  SET @id = @id + 1
END


----Setear el resultda con la id de la solictud y el lote cuando todo esté correcto

SET @Result = (
  SELECT 
    Solicitud = @solicitud,
    Lote = @lote
  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
)

----




SET @_CodeReturn = 1	 


