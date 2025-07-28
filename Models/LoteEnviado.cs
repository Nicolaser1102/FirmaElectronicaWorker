using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Models
{
    public class LoteEnviado
    {
        [JsonPropertyName("solicitud")]
        public int Solicitud { get; set; }

        [JsonPropertyName("lote")]
        public int Lote { get; set; }

        [JsonPropertyName("requestId")]
        public string RequestId { get; set; }

    }
}
