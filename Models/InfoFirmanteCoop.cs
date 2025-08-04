using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Models
{
    public class InfoFirmanteCoop
    {
        public int Id { get; set; }
        public string NombreFirmante { get; set; } = string.Empty;

        public string Identificacion { get; set; } = string.Empty;
        public string Usuario { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Pin { get; set; } = string.Empty;
        public string Cargo { get; set; } = string.Empty;
        public string ImagenFirma { get; set; } = string.Empty; // Base64
        public string Ubicacion { get; set; } = string.Empty;
    }
}
