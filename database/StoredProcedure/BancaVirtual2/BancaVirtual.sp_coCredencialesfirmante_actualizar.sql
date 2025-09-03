USE BancaVirtual2
GO
CREATE OR ALTER PROCEDURE [BancaVirtual].[sp_coCredencialesfirmante_actualizar]
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
	@AI_ID                INT,
    @AS_MSJ               VARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;



    -- Verificar existencia
    IF NOT EXISTS (SELECT 1 FROM BancaVirtual.CredencialesFirmantesCoop WHERE Id = @AI_ID)
    BEGIN
        SET @AS_MSJ = 'EL FIRMANTE NO EXISTE'
        RETURN -1
    END

    -- Validar duplicado de usuario
    IF EXISTS (SELECT 1 FROM BancaVirtual.CredencialesFirmantesCoop 
               WHERE Usuario = @AS_USUARIO AND Id <> @AI_ID)
    BEGIN
        SET @AS_MSJ = 'YA EXISTE UN FIRMANTE CON ESE USUARIO'
        RETURN -1
    END

    -- Validar duplicado de identificación
    IF EXISTS (SELECT 1 FROM BancaVirtual.CredencialesFirmantesCoop 
               WHERE Identificacion = @AS_IDENTIFICACION AND Id <> @AI_ID)
    BEGIN
        SET @AS_MSJ = 'YA EXISTE UN FIRMANTE CON ESA IDENTIFICACIÓN'
        RETURN -1
    END

    -- Validaciones básicas
    IF (@AS_NOMBREFIRMANTE IS NULL OR LTRIM(RTRIM(@AS_NOMBREFIRMANTE)) = '')
    BEGIN
        SET @AS_MSJ = 'INGRESE UN NOMBRE DE FIRMANTE VÁLIDO'
        RETURN -1
    END

    IF (@AS_USUARIO IS NULL OR LTRIM(RTRIM(@AS_USUARIO)) = '')
    BEGIN
        SET @AS_MSJ = 'INGRESE UN USUARIO VÁLIDO'
        RETURN -1
    END

    IF (@AS_PASSWORD IS NULL OR LTRIM(RTRIM(@AS_PASSWORD)) = '')
    BEGIN
        SET @AS_MSJ = 'INGRESE UNA CONTRASEÑA VÁLIDA'
        RETURN -1
    END

    IF (@AS_PIN IS NULL OR LTRIM(RTRIM(@AS_PIN)) = '')
    BEGIN
        SET @AS_MSJ = 'INGRESE UN PIN VÁLIDO'
        RETURN -1
    END

    IF (@AS_ESTADO NOT IN ('A','I'))
    BEGIN
        SET @AS_MSJ = 'INGRESE UN ESTADO VÁLIDO (A=ACTIVO, I=INACTIVO)'
        RETURN -1
    END

    -- Actualizar
    UPDATE BancaVirtual.CredencialesFirmantesCoop
    SET NombreFirmante     = @AS_NOMBREFIRMANTE,
        Identificacion     = @AS_IDENTIFICACION,
        Usuario            = @AS_USUARIO,
        Password           = @AS_PASSWORD,
        Pin                = @AS_PIN,
        Cargo              = @AS_CARGO,
        ImagenFirma        = @AS_IMAGENFIRMA,
        Ubicacion          = @AS_UBICACION,
        Estado             = @AS_ESTADO,
        ModificaUsuario= @AS_APP_USUARIO,
        ModificaFecha  = GETDATE()
    WHERE Id = @AI_ID;

    IF @@ERROR <> 0
    BEGIN
        SET @AS_MSJ = 'ERROR AL ACTUALIZAR FIRMANTE'
        RETURN -1
    END

    SET @AS_MSJ = 'FIRMANTE ACTUALIZADO CORRECTAMENTE'
    RETURN 1
END
GO
