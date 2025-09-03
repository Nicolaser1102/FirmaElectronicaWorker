use BancaVirtual2
go
CREATE OR ALTER PROCEDURE [BancaVirtual].[spCoObtenerCredencialesFirmantesCoop]
AS
		SELECT Id,
				NombreFirmante,
				Identificacion,
				Usuario,
				[Password],
				Pin,
				Cargo,
				ImagenFirma,
				Ubicacion,
				Estado,
				CreacionUsuario,
				CreacionFecha,
				ModificaUsuario,
				ModificaFecha
				FROM 
				BancaVirtual2.BancaVirtual.CredencialesFirmantesCoop
