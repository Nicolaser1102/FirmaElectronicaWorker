USE CREDITO 
GO
IF NOT EXISTS (SELECT * FROM SL_ESTADO_MOTIVO where esm_estado = 'D' AND esm_motivo = '1')
BEGIN 
INSERT INTO SL_ESTADO_MOTIVO (esm_estado,esm_motivo,esm_nombre,creacion_usuario,creacion_fecha)
VALUES ('D','1','NORMAL','ADMIN', dbo.FechaSistema())

END