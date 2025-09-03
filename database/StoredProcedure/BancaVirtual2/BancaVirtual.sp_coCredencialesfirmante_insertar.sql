USE BancaVirtual2
GO

CREATE OR ALTER PROCEDURE [BancaVirtual].[sp_coCredencialesfirmante_insertar]
	@AS_APP_USUARIO        VARCHAR(20),
    @AS_NOMBREFIRMANTE    VARCHAR(60),
    @AS_IDENTIFICACION     VARCHAR(13),
    @AS_USUARIO            VARCHAR(30),
    @AS_PASSWORD           VARCHAR(30),
    @AS_PIN                VARCHAR(10),
    @AS_CARGO              VARCHAR(25),
    @AS_IMAGENFIRMA       VARCHAR(MAX),
    @AS_UBICACION          VARCHAR(30),
    @AS_ESTADO             CHAR(1),
    @AI_ID                 INT OUTPUT,
    @AS_MSJ                VARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @AS_NOMBREFIRMANTE IS NULL OR LTRIM(RTRIM(@AS_NOMBREFIRMANTE)) = ''
    BEGIN
        SET @AS_MSJ = 'INGRESE UN NOMBRE DE FIRMANTE VÁLIDO'
        RETURN -1
    END

    IF @AS_IDENTIFICACION IS NULL OR LTRIM(RTRIM(@AS_IDENTIFICACION)) = ''
    BEGIN
        SET @AS_MSJ = 'INGRESE UNA IDENTIFICACIÓN VÁLIDA'
        RETURN -1
    END

    IF EXISTS (SELECT 1 FROM BancaVirtual.CredencialesFirmantesCoop WHERE Identificacion = @AS_IDENTIFICACION)
    BEGIN
        SET @AS_MSJ = 'YA EXISTE UN FIRMANTE CON ESA IDENTIFICACIÓN'
        RETURN -1
    END

    IF EXISTS (SELECT 1 FROM BancaVirtual.CredencialesFirmantesCoop WHERE Usuario = @AS_USUARIO)
    BEGIN
        SET @AS_MSJ = 'YA EXISTE UN FIRMANTE CON ESE USUARIO'
        RETURN -1
    END

    IF @AS_PASSWORD IS NULL OR LTRIM(RTRIM(@AS_PASSWORD)) = ''
    BEGIN
        SET @AS_MSJ = 'INGRESE UNA CONTRASEÑA VÁLIDA'
        RETURN -1
    END

    IF @AS_PIN IS NULL OR LTRIM(RTRIM(@AS_PIN)) = ''
    BEGIN
        SET @AS_MSJ = 'INGRESE UN PIN VÁLIDO'
        RETURN -1
    END

    IF @AS_ESTADO NOT IN ('A', 'I')  -- A=Activo, I=Inactivo (ejemplo)
    BEGIN
        SET @AS_MSJ = 'INGRESE UN ESTADO VÁLIDO (A=ACTIVO, I=INACTIVO)'
        RETURN -1
    END

    -- Insertar nuevo registro
    INSERT INTO BancaVirtual.CredencialesFirmantesCoop
        (NombreFirmante, Identificacion, Usuario, Password, Pin, Cargo, ImagenFirma,
         Ubicacion, Estado, CreacionUsuario, CreacionFecha)
    VALUES
        (@AS_NOMBREFIRMANTE, @AS_IDENTIFICACION, @AS_USUARIO,
         @AS_PASSWORD, @AS_PIN, @AS_CARGO, @AS_IMAGENFIRMA,
         @AS_UBICACION, @AS_ESTADO, @AS_APP_USUARIO
		 , GETDATE());

    -- Obtener el nuevo Id generado
    SET @AI_ID = SCOPE_IDENTITY();

    -- Confirmación
    IF @@ERROR <> 0
    BEGIN
        SET @AS_MSJ = 'ERROR AL INSERTAR FIRMANTE'
        RETURN -1
    END

    SET @AS_MSJ = 'FIRMANTE INSERTADO CORRECTAMENTE'
    RETURN 1
END
GO
