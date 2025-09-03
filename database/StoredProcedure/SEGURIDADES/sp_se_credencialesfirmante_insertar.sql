USE SEGURIDADES
GO
CREATE OR ALTER PROCEDURE sp_se_credencialesfirmante_insertar
    @AS_APP_USUARIO        VARCHAR(20),
    @AS_NOMBREFIRMANTE   VARCHAR(60),
    @AS_IDENTIFICACION    VARCHAR(13),
    @AS_USUARIO           VARCHAR(30),
    @AS_PASSWORD          VARCHAR(30),
    @AS_PIN               VARCHAR(10),
    @AS_CARGO             VARCHAR(25),
    @AS_IMAGENFIRMA      VARCHAR(MAX),
    @AS_UBICACION         VARCHAR(30),
    @AS_ESTADO            CHAR(1),
	@AI_ID                INT OUTPUT,
    @AS_MSJ               VARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @li_ret int

	EXEC @li_ret =  [BancaVirtual2].[BancaVirtual].[sp_coCredencialesfirmante_Insertar]
    @AS_APP_USUARIO = @AS_APP_USUARIO,       
    @AS_NOMBREFIRMANTE = @AS_NOMBREFIRMANTE,  
    @AS_IDENTIFICACION =  @AS_IDENTIFICACION,   
    @AS_USUARIO= @AS_USUARIO  ,      
    @AS_PASSWORD =@AS_PASSWORD,       
    @AS_PIN  =  @AS_PIN   ,        
    @AS_CARGO  = @AS_CARGO     ,    
    @AS_IMAGENFIRMA= @AS_IMAGENFIRMA ,     
    @AS_UBICACION= @AS_UBICACION  ,      
    @AS_ESTADO = @AS_ESTADO   ,      
	@AI_ID  =  @AI_ID OUTPUT   ,         
    @AS_MSJ =  @AS_MSJ           OUTPUT

	if @li_ret != 1
	begin 
		return -1
	end


	RETURN 1

END
GO
