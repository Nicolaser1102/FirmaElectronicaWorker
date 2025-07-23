using FirmaElectronicaWorker.Interfaces;

namespace FirmaElectronicaWorker.Services
{
    public class CheckStatusFirmaService : IBaseService
    {
        private readonly ILogger<CheckStatusFirmaService> _logger;

        public CheckStatusFirmaService(ILogger<CheckStatusFirmaService> logger)
        {
            _logger = logger;
        }

        public async Task Execute()
        {
            // Simulate asynchronous work to resolve CS1998
            await Task.Delay(1);

            // Log execution for debugging purposes
            _logger.LogInformation("Execute method in CheckStatusFirmaService has been called. CHECKEANDO EL MUNDO");
        }
    }
}
