USE CLIENTES;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM CRM_SERVICIOS_NOTIFICACION_SMS 
    WHERE tns_codigo = 'CR_DES_WEB'
)
BEGIN
    INSERT INTO CRM_SERVICIOS_NOTIFICACION_SMS (
        tns_codigo, 
        tns_descripcion, 
        tns_mensaje, 
        tns_es_cierre, 
        tns_procedimiento, 
        tns_hora_desde, 
        tns_hora_hasta, 
        tns_dias, 
        tns_estado, 
        creacion_usuario, 
        creacion_fecha
    )
    VALUES (
        'CR_DES_WEB',
        'Desembolso Créditos Web por Banca Virtual',
        'Cooperativa Difare informa, estimado socio su crédito: %s , ha sido procesado correctamente.',
        0,
        'BancaVirtual.sp_crm_notif_sms_cr_desembolso_crbv',
        '00:00',
        '23:59',
        1,
        'A',
        'ADMIN',
        GETDATE()
    );
END
ELSE
BEGIN
    PRINT 'Ya existe un registro con tns_codigo = CR_DES_WEB. No se insertó de nuevo.';
END


USE CLIENTES;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM CRM_SERVICIOS_NOTIFICACION_SMS 
    WHERE tns_codigo = 'CR_WEB_ES'
)
BEGIN
    INSERT INTO CRM_SERVICIOS_NOTIFICACION_SMS (
        tns_codigo, 
        tns_descripcion, 
        tns_mensaje, 
        tns_es_cierre, 
        tns_procedimiento, 
        tns_hora_desde, 
        tns_hora_hasta, 
        tns_dias, 
        tns_estado, 
        creacion_usuario, 
        creacion_fecha
    )
    VALUES (
        'CR_WEB_ES',
        'Mensaje encuesta de satisfacción del Cliente',
        'Estimado socio la Cooperativa Difare le invita a completar la encuesta de satisfacción correspondiente al proceso de su solicitud de crédito: %s. Realice la encuesta en el siguiente link: %s',
        0,
        'BancaVirtual.sp_crm_notif_sms_cr_encuesta_satisfaccion_crbv',
        '00:00',
        '23:59',
        1,
        'A',
        'ADMIN',
        GETDATE()
    );
END
ELSE
BEGIN
    PRINT 'Ya existe un registro con tns_codigo = CR_WEB_ES. No se insertó de nuevo.';
END

USE PARAMETROS;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM PARAMETROS..CI_PROCESOS 
    WHERE prc_proceso = 'CRWAS'
)
BEGIN
    INSERT INTO PARAMETROS..CI_PROCESOS (
        prc_proceso, 
        prc_orden, 
        prc_modulo, 
        prc_descripcion, 
        prc_estado, 
        prc_procedimiento, 
        prc_frecuencia, 
        creacion_usuario, 
        creacion_fecha
    )
    VALUES (
        'CRWAS',
        682,
        'CR',
        'Anular solicitudes Firma Electrónica',
        'A',
        'CREDITO..sp_cr_cierre_anular_solicitudes_firma_electr',
        'D',
        'ADMIN',
        GETDATE()
    );
END
ELSE
BEGIN
    PRINT ' Ya existe un proceso con prc_proceso = CRWAS. No se insertó de nuevo.';
END
