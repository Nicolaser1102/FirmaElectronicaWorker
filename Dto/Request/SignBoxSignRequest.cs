

using System.Text.Json.Serialization;

namespace FirmaElectronicaWorker.Dto.Request
{
    public class SignBoxSignRequest
    {
        [JsonPropertyName("fileIn")]
        public string FileIn { get; set; }  // Documento (ruta o contenido Base64)

        [JsonPropertyName("webhookId")]
        public string WebhookId { get; set; }

        [JsonPropertyName("image")]
        public string? Image { get; set; }  // Base64 (opcional)

        [JsonPropertyName("username")]
        public string Username { get; set; }

        [JsonPropertyName("password")]
        public string Password { get; set; }

        [JsonPropertyName("pin")]
        public string Pin { get; set; }

        [JsonPropertyName("reason")]
        public string? Reason { get; set; }

        [JsonPropertyName("location")]
        public string? Location { get; set; }

        [JsonPropertyName("position")]
        public string? Position { get; set; }  // "x1,y1,x2,y2"

        [JsonPropertyName("npage")]
        public int? Npage { get; set; }

        [JsonPropertyName("paragraphFormat")]
        public string? ParagraphFormat { get; set; }  // JSON o string según spec
    }
}
