-- Registro 1
IF NOT EXISTS (
    SELECT 1
    FROM BancaVirtual.PlantillaNotificacionEmail
    WHERE Codigo = 'Credito-Web-Desembolso'
)
BEGIN
    INSERT INTO BancaVirtual.PlantillaNotificacionEmail
    (
        Codigo,
        Nombre,
        Activo,
        CredencialEmailID,
        Asunto,
        Mensaje,
        CreacionUsuario,
        CreacionFecha
    )
    VALUES
    (
        'Credito-Web-Desembolso', 
        'Credito-Web-Desembolso', 
        1, 
        1, 
        'Coop Difare:Desembolso de Crédito {Operacion}', 
        'Se ha realizado el desembolso del credito a {Nombre} el {Fecha} por un monto de {Monto}.', 
        'ADMIN', 
        GETDATE()
    );
END;

-- Registro 2
IF NOT EXISTS (
    SELECT 1
    FROM BancaVirtual.PlantillaNotificacionEmail
    WHERE Codigo = 'Credito-Web-Anulacion'
)
BEGIN
    INSERT INTO BancaVirtual.PlantillaNotificacionEmail
    (
        Codigo,
        Nombre,
        Activo,
        CredencialEmailID,
        Asunto,
        Mensaje,
        CreacionUsuario,
        CreacionFecha
    )
    VALUES
    (
        'Credito-Web-Anulacion', 
        'Credito-Web-Anulacion', 
        1, 
        1, 
        'Coop Difare:Anulación de Solicitud de Crédito', 
        'Se ha anulado la solicitud de credito a {Nombre} el {Fecha} por un monto de {Monto}', 
        'ADMIN', 
        GETDATE()
    );
END;
