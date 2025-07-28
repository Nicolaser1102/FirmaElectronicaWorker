using FirmaElectronicaWorker.Utils;
using System.Text.Json.Serialization;


namespace FirmaElectronicaWorker.Dto.Response
{
    public class OnBoardingSignResponse
    {
        [JsonPropertyName("status")]
        [JsonConverter(typeof(StringToJsonConverter))]
        public string Status { get; set; }

        [JsonPropertyName("requestId")]
        public string ?RequestId { get; set; }

        [JsonPropertyName("url")]
        public string ?Url { get; set; }


        [JsonPropertyName("detail")]
        public string Detail { get; set; }
    }



}
