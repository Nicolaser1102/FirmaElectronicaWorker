using FirmaElectronicaWorker.Interfaces;
using FirmaElectronicaWorker.Models.Settings;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
