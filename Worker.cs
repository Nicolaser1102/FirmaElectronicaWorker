using FirmaElectronicaWorker.Models;
using FirmaElectronicaWorker.Services;

namespace FirmaElectronicaWorker
{
    public class Worker : BackgroundService
    {
        private readonly List<ServicesModel> _services;
        private readonly ILogger<Worker> _logger;

        public Worker(ILogger<Worker> logger,
            AppSettingService appSettings,
            FirmaSignBoxService firmaSignBoxService,
            FirmaOnBoardingService firmaOnBoardingService
     
            )
        {
            _logger = logger;

            _services = new List<ServicesModel>
            {
                new ServicesModel(firmaSignBoxService, "FirmaSignBox", appSettings.Service.FirmaSignBox ),
                new ServicesModel(firmaOnBoardingService, "FirmaOnBoarding", appSettings.Service.FirmaOnBoarding),
                
            };
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {

            _logger.LogInformation("Worker iniciado");

            var tasks = _services
                .Where(x => x.Settings.Enabled)
                .Select(service => Task.Run(() => RunTaskAsync(service, stoppingToken), stoppingToken))
                .ToList();

            await Task.WhenAll(tasks);

        }

        private async Task RunTaskAsync(ServicesModel model, CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await model.Service.Execute();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error técnico al procesar {name}", model.Name);
                }
                finally
                {
                    var durationMs = model.Settings.Duracion * 1000;
                    _logger.LogInformation("{message}: Esperando... {DurationBatch} segundos ", model.Name, model.Settings.Duracion);
                    Thread.Sleep(durationMs);
                }
            }
        }
    }
}
