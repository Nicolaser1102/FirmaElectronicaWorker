using FirmaElectronicaWorker.Interfaces;

namespace FirmaElectronicaWorker.Services
{
    public class FirmaOnBoardingService : IBaseService
    {
        private readonly ILogger<FirmaOnBoardingService> _logger;

        public FirmaOnBoardingService(ILogger<FirmaOnBoardingService> logger)
        {
            _logger = logger;
        }

        public async Task Execute()
        {
            // Simulate asynchronous work to resolve CS1998
            await Task.Delay(1);

            // Log execution for debugging purposes
            _logger.LogInformation("Execute method in FirmaOnBoardignService has been called. HOLA FIRMA ON BOARDING");
        }
    }
}
