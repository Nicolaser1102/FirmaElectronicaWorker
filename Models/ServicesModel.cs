using FirmaElectronicaWorker.Interfaces;
using FirmaElectronicaWorker.Models.Settings;


namespace FirmaElectronicaWorker.Models
{
    public class ServicesModel
    {
        public string Name { get; set; }
        public IBaseService Service { get; set; }
        public BaseServiceSetting Settings { get; set; }

        public ServicesModel(IBaseService service, string name
            , BaseServiceSetting settings
            )
        {
            Service = service;
            Name = name;
            Settings = settings;
        }
    }
}
