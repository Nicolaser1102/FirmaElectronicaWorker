
using System.Text.Json.Serialization;


namespace FirmaElectronicaWorker.Models
{
    public class DocumentoPendiente
    {

        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("solicitud")]
        public int Solicitud { get; set; }

        [JsonPropertyName("lote")]
        public int Lote { get; set; }

        [JsonPropertyName("codigoDocumento")]
        public string CodigoDocumento { get; set; }

        [JsonPropertyName("rutaArchivo")]
        public string RutaArchivo { get; set; }

    }
}

