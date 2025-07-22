using FirmaElectronicaWorker.Models.Settings;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Services
{
    public class AppSettingService
    {
        readonly IConfiguration _configuration;

        public AppSettingService(IConfiguration configuration)
        {
            _configuration = configuration;
        }


        public ServiceSettings Service
        {
            get
            {
                var serv = _configuration.GetSection("Services").Get<ServiceSettings>();
                return serv ?? throw new Exception("No se ha definido la variable: Services");
            }
        }
    }
}
