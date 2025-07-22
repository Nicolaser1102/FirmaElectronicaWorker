using FirmaElectronicaWorker.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Services
{
    public class FirmaSignBoxService : IBaseService
    {
        private readonly ILogger<FirmaSignBoxService> _logger;

        public FirmaSignBoxService(ILogger<FirmaSignBoxService> logger)
        {
            _logger = logger;
        }

        public async Task Execute()
        {
            // Simulate asynchronous work to resolve CS1998
            await Task.Delay(1);

            // Log execution for debugging purposes
            _logger.LogInformation("Execute method in FirmaSignBoxService has been called. HOLA MUNDO");
        }
    }
}
