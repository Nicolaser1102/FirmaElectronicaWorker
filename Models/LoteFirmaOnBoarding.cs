using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Models
{
    public class DocumentoPdf
    {
        [JsonPropertyName("codigoDocumento")]
        public string CodigoDocumento { get; set; }

        [JsonPropertyName("signBoxWeebhookPdf")]
        public string SignBoxWeebhookPdf { get; set; }
    }

    public class LoteFirmaOnBoarding
    {
        [JsonPropertyName("solicitud")]
        public int Solicitud { get; set; }

        [JsonPropertyName("lote")]
        public int Lote { get; set; }

        [JsonPropertyName("documentos")]
        public List<DocumentoPdf> Documentos { get; set; }
    }


}
