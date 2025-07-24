using FirmaElectronicaWorker.Interfaces;
using FirmaElectronicaWorker.Models;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace FirmaElectronicaWorker.Services
{
    public class FirmaSignBoxService : IBaseService
    {
        private readonly ILogger<FirmaSignBoxService> _logger;
        private readonly AppSettingService _appSettings;
        private readonly ExternalUrls _urls;

        public FirmaSignBoxService(
            ILogger<FirmaSignBoxService> logger,
            AppSettingService appSettings,
            IOptions<ExternalUrls> urls)
        {
            _logger = logger;
            _appSettings = appSettings;
            _urls = urls.Value;
        }

        public async Task Execute()
        {

            var documentos = await GetDocumentosPendientesFirmarSignbox();
            if (!documentos.Any())
            {
                _logger.LogInformation("No hay documentos para firmar por SignBox pendientes. Finalizando ejecución.");
                return;
            }

            foreach (var doc in documentos)
            {
                Console.WriteLine($"DocumentoPendiente - Id: {doc.Id}, Solicitud: {doc.Solicitud}, Lote: {doc.Lote}, CodigoDocumento: {doc.CodigoDocumento}, RutaArchivo: {doc.RutaArchivo}");
            }
        }

        //Funciones para Execute()

        //Obtener token de API Orion

        private async Task<string> ObtenerTokenJwtAsync()
        {
            string url = _urls.LoginUrlOrionApi;

            var login = new LoginRequestGS
            {
                UserName = _urls.LoginUserOrionApi,
                Password = _urls.LoginPasswordOrionApi
            };

            var json = JsonSerializer.Serialize(login);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await client.PostAsync(url, content);
            var body = await response.Content.ReadAsStringAsync();


            if (!response.IsSuccessStatusCode)
            {
                throw new ApplicationException($"Login fallido: {body}");
            }

            var result = JsonSerializer.Deserialize<LoginResponse>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null || string.IsNullOrEmpty(result.Token))
            {
                throw new ApplicationException($"Error de autenticación: {"Respuesta vacía"}");
            }

            return result.Token;
        }

        // Obtener documentos pendientes de firma en SignBox

        private async Task<List<DocumentoPendiente>> GetDocumentosPendientesFirmarSignbox()
        {

            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            var request = new GenericRequest
            {
                Action = "credito-web/obtener-docs-firmar-SignBox",
                Data = ""
            };

            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await client.PostAsync(url, content);
            var body = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new ApplicationException($"Error HTTP: {response.StatusCode} - {response.ReasonPhrase}");
            }

            var result = JsonSerializer.Deserialize<GenericResponse<List<DocumentoPendiente>>>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null)
            {
                _logger.LogWarning("Respuesta vacía del backend al obtener notificaciones.");
                return new List<DocumentoPendiente>();
            }

            if (result.CodeReturn != 1)
            {
                _logger.LogWarning("Backend respondió sin éxito: {Message}", result.Message);
                return new List<DocumentoPendiente>();
            }

            if (result.Result == null || !result.Result.Any())
            {
                _logger.LogInformation("No hay Documentos Pendientes por firmar por SignBox.");
                return new List<DocumentoPendiente>();
            }


            return result.Result;

        }


        //Instanciando un cliente HTTP para realizar solicitudes
        private static readonly HttpClient client = new HttpClient();
    }


}
