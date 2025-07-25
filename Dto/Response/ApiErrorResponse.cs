
using System.Text.Json.Serialization;


namespace FirmaElectronicaWorker.Dto.Response
{
    public class Violation
    {
        [JsonPropertyName("field")]
        public string Field { get; set; }

        [JsonPropertyName("message")]
        public string Message { get; set; }
    }

    public class ApiErrorResponse
    {
        [JsonPropertyName("type")]
        public string Type { get; set; }

        [JsonPropertyName("title")]
        public string Title { get; set; }

        [JsonPropertyName("status")]
        public int Status { get; set; }

        [JsonPropertyName("path")]
        public string Path { get; set; }

        [JsonPropertyName("message")]
        public string Message { get; set; }

        [JsonPropertyName("violations")]
        public List<Violation> Violations { get; set; }
    }
}
