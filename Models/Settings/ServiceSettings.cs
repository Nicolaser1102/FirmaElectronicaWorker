using FirmaElectronicaWorker.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

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


    }

}
