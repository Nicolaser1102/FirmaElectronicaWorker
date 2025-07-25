using FirmaElectronicaWorker.Dto.Request;
using FirmaElectronicaWorker.Interfaces;
using FirmaElectronicaWorker.Models;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace FirmaElectronicaWorker.Services
{
    public class FirmaSignBoxService : IBaseService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<FirmaSignBoxService> _logger;
        private readonly AppSettingService _appSettings;
        private readonly ExternalUrls _urls;

        public FirmaSignBoxService(
            ILogger<FirmaSignBoxService> logger,
            IHttpClientFactory httpClientFactory,
            AppSettingService appSettings,
            IOptions<ExternalUrls> urls)
        {
            _logger = logger;
            _httpClientFactory = httpClientFactory;
            _appSettings = appSettings;
            _urls = urls.Value;
        }

        public async Task Execute()
        {

            var documentos = await ObtenerDocumentosPendientesFirmarSignbox();
            if (!documentos.Any())
            {
                _logger.LogInformation("No hay documentos para firmar por SignBox pendientes. Finalizando ejecución.");
                return;
            }

            foreach (var doc in documentos)
            {
                _logger.LogInformation("Enviando documento {OidNotificacion} ", doc.Id);

                string res;
                try
                {
                    res = await EnviarDocumentoAFirmarSignBox(doc);
                    Console.WriteLine(res);

                }
                catch (Exception ex)
                {
                    _logger.LogWarning("Error al enviar documento a Firmar {Id} {Message}", doc.Id, ex.Message);
                    res = ex.Message;
                }

            } 
        }

        //Funciones para Execute()

            //Obtener token de API Orion y Sign Box
            //Orion API

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

        //API SignBox

        private async Task<string> ObtenerTokenSignBoxAsync()
        {


            string url = _urls.LoginUrlSignBox;

            var loginSignbox = new LoginRequestSignBox
            {
                username = _urls.LoginUserSignBox,
                password = _urls.LoginPasswordSignBox
            };

            var json = JsonSerializer.Serialize(loginSignbox);
            var content = new StringContent(json, Encoding.UTF8, "application/json");


            var response = await client.PostAsync(url, content);
            var body = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new ApplicationException($"Login fallido: {body}");
            }

            var result = JsonSerializer.Deserialize<LoginResponseSignBox>(body, new JsonSerializerOptions
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

        private async Task<List<DocumentoPendiente>> ObtenerDocumentosPendientesFirmarSignbox()
        {


            //!Aislar funcion inicio
            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            //!Aislar funcion final

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




        //Enviara a firmar por SignBox los documentos pendientes para firmar

        public async Task<string> EnviarDocumentoAFirmarSignBox(DocumentoPendiente doc)
        {
            try
            {
                string rutaArchivo = doc.RutaArchivo;
                //string rutaArchivo = @"C:\DocumentosPruebaFirmaElectronica\DocumentosFirmadosSignBox\20250625CR_CONTRATO_CREDITO01-1-3.pdf";

                if (!File.Exists(rutaArchivo))
                    return "ERROR: El archivo no existe";

                using var client = _httpClientFactory.CreateClient();

                string url = "https://eclipsoft.dev/signbox/api/sign";
                string token = await ObtenerTokenSignBoxAsync();
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                var pdfStream = new FileStream(rutaArchivo, FileMode.Open, FileAccess.Read);
                var pdfContent = new StreamContent(pdfStream);
                pdfContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");

                var content = new MultipartFormDataContent();

                string webhookId = $"sign_{Guid.NewGuid():N}";
                content.Add(pdfContent, "fileIn", Path.GetFileName(rutaArchivo));
                content.Add(new StringContent(webhookId), "webhookId");

                var imagePath = @"C:\DocumentosPruebaFirmaElectronica\25\firmaPruebaIA.png";
                if (File.Exists(imagePath))
                {
                    var imgBytes = await File.ReadAllBytesAsync(imagePath);
                    var imageBase64 = Convert.ToBase64String(imgBytes);
                    var imageContent = new StringContent(imageBase64, Encoding.UTF8, "text/plain");
                    content.Add(imageContent, "image");
                }
                else
                {
                    _logger.LogWarning("⚠️ Imagen no encontrada: {Path}", imagePath);
                }
                content.Add(new StringContent("test"), "reason");
                content.Add(new StringContent("Guayaquil, Ecuador"), "location");
                content.Add(new StringContent("1091583"), "username");
                content.Add(new StringContent("RY3qn76H"), "password");
                content.Add(new StringContent("Javier123_"), "pin");
                content.Add(new StringContent("10,10,150,59"), "position");
                content.Add(new StringContent("2"), "npage");

                string paragraphFormat = @"[{
          ""font"": [""Universal-Bold"", 6],
          ""align"": ""right"",
          ""data_format"": {
            ""timezone"": ""America/Guayaquil"",
            ""strtime"": ""%d/%m/%Y %H:%M:%S""
          },
          ""format"": [""Firmado por:"", ""$(CN)s"", ""ID: $(serialNumber)s""]
        }]";
                content.Add(new StringContent(paragraphFormat), "paragraphFormat");

                var response = await client.PostAsync(url, content);
                var result = await response.Content.ReadAsStringAsync();

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al firmar documento.");
                return $"ERROR: {ex.Message}";
            }
        }



        //Instanciando un cliente HTTP para realizar solicitudes
        private static readonly HttpClient client = new HttpClient();
    }


}
