
using CommandLine;
using FirmaElectronicaWorker.Models;
using FirmaElectronicaWorker.Services;


namespace FirmaElectronicaWorker;
public class Program
{

    static void Main(string[] args)
    {
        IHost host = Host.CreateDefaultBuilder(args)
            .UseWindowsService()
            .ConfigureAppConfiguration((hostingContext, config) =>
            {
                config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
            })
            .ConfigureServices(services =>
            {
                services.AddHostedService<Worker>();
                services.AddHttpClient();
                ConfigureServices(services, args);
            })
            .Build();

        host.Run();
    }


    private static void ConfigureServices(IServiceCollection services, string[] args)
    {

        services.AddSingleton<Worker>();
        services.AddSingleton<AppSettingService>();
        services.AddSingleton<FirmaSignBoxService>();
        services.AddSingleton<FirmaOnBoardingService>();
        services.AddSingleton<GuardarDocumentosFirmadosService>();

        var configuration = new ConfigurationBuilder()
               .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
               .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
               .Build();
        services.Configure<ExternalUrls>(configuration.GetSection("ServiciosExternos"));



        var result = Parser.Default.ParseArguments<Models.Options>(args);
        if (result.Tag == ParserResultType.Parsed)
        {
            var parsedResult = (Parsed<Models.Options>)result;
            services.AddSingleton(parsedResult.Value);
        }
        else
        {
            Environment.Exit(0);
        }

    }

}