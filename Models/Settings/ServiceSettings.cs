using FirmaElectronicaWorker.Interfaces;

using System.Text.Json.Serialization;


namespace FirmaElectronicaWorker.Models.Settings
{
    public class BaseServiceSetting : IBaseServiceSetting
    {
        [JsonPropertyName("Duracion")]
        public int Duracion { get; set; }
        [JsonPropertyName("Enabled")]
        public bool Enabled { get; set; } = false;
    }


    public partial class ServiceSettings
    {

        [JsonPropertyName("FirmaSignBox")]
        public BaseServiceSetting FirmaSignBox { get; set; } = new BaseServiceSetting();

        [JsonPropertyName("FirmaOnBoarding")]
        public BaseServiceSetting FirmaOnBoarding { get; set; } = new BaseServiceSetting();

        [JsonPropertyName("GuardarDocumentosFirmados")]
        public BaseServiceSetting GuardarDocumentosFirmados { get; set; } = new BaseServiceSetting();

    }

}
