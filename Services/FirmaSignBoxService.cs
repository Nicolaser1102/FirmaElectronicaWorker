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

        


        //Enviara a firmar por SignBox los documentos pendientes para firmar

        private async Task<string> EnviarDocumentoAFirmarSignBox(DocumentoPendiente doc)
        {





            string res = "";

            string rutaArchivo = doc.RutaArchivo;
            var pdfStream = File.OpenRead(rutaArchivo);

            try
            {

                using var clientMultipart = _httpClientFactory.CreateClient();

                string url = _urls.SignDocumentUrlSignBox;


                string token = await ObtenerTokenSignBoxAsync();


                clientMultipart.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);




                using var content = new MultipartFormDataContent();



                
                content.Add(new StreamContent(pdfStream), "fileIn", Path.GetFileName(rutaArchivo));


                content.Add(new StringContent($"pruebaGreenSf07"), "webhookId");

                // b) Imagen de firma (Base64 en string)
                var imagePath = @"C:\DocumentosPruebaFirmaElectronica\25\firmaPruebaIA.png";
                if (System.IO.File.Exists(imagePath))
                {
                    var imgBytes = await System.IO.File.ReadAllBytesAsync(imagePath);
                    var imageBase64 = Convert.ToBase64String(imgBytes);
                    // Se envía como StringContent, no como StreamContent
                    content.Add(new StringContent(imageBase64), "image");
                }
                else
                {
                    _logger.LogWarning("⚠️ Imagen no encontrada: {Path}", imagePath);
                }


                content.Add(new StringContent("1091583"), "username");
                content.Add(new StringContent("RY3qn76H"), "password");
                content.Add(new StringContent("Javier123_"), "pin");



                content.Add(new StringContent("Firma de contrato"), "reason");

                content.Add(new StringContent("Quito"), "location");

                content.Add(new StringContent("2"), "npage");

                // d) ParagraphFormat como JSON en StringContent
                var pf = "[{ " +
                                "\"font\": [\"Universal-Bold\",6]," +
                                "\"align\": \"right\"," +
                                "\"data_format\": { \"timezone\": \"America/Guayaquil\", \"strtime\": \"%d/%m/%Y %H:%M:%S\" }," +
                                "\"format\": [" +
                                    "\"Firmado por:\"," +
                                    "\"$(CN)s\"," +
                                    "\"ID: $(serialNumber)s\"," +
                                    "\"Oficial de crédito\"" +
                                "]" +
                            "}]";
                content.Add(new StringContent(pf), "paragraphFormat");

                //content.Add(new StringContent("71,473,201,522"), "position");



                var response = await clientMultipart.PostAsync(url, content);

                var body = await response.Content.ReadAsStringAsync();
                Console.WriteLine(body);

                if (response.IsSuccessStatusCode)
                {
                    res = "OK";
                }
                else
                {
                    res = $"Error: {response.StatusCode} - {response.ReasonPhrase}";  // Error de envío
                }
            }
            catch (Exception ex)
            {
                res = $"Error al firmar documento: {ex.Message}";  // Si ocurre una excepción
            }
           finally
            {
    
                    pdfStream.Dispose(); // asegúrate de cerrarlo al final
                
            }
            return res;
        }


        //Instanciando un cliente HTTP para realizar solicitudes
        private static readonly HttpClient client = new HttpClient();
    }


}
