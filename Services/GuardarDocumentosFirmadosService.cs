using FirmaElectronicaWorker.Dto.Response;
using FirmaElectronicaWorker.Interfaces;
using FirmaElectronicaWorker.Models;
using Microsoft.Extensions.Options; 
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace FirmaElectronicaWorker.Services
{
    public class GuardarDocumentosFirmadosService : IBaseService
    {

        private readonly ILogger<GuardarDocumentosFirmadosService> _logger;
        private readonly AppSettingService _appSettings;
        private readonly ExternalUrls _urls;

        public GuardarDocumentosFirmadosService(
            ILogger<GuardarDocumentosFirmadosService> logger,
            AppSettingService appSettings,
            IOptions<ExternalUrls> urls)
        {
            _logger = logger;
            _appSettings = appSettings;
            _urls = urls.Value;
        }
        public async Task Execute()
        {
            var lotes = await ObtenerLotesParaGuardarDocumentosFirmados();

            if (lotes == null || !lotes.Any())
            {
                _logger.LogInformation("No se encontraron lotes para guardar documentos firmados.");
                return;
            }

            foreach (var lote in lotes)
            {
                await GuardarDocumentosFirmadosPorLote(lote);
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

        //API  OnBoarding

        private async Task<string> ObtenerTokenOnBoardingAsync()
        {


            string url = _urls.LoginUrlOnBoarding;

            var loginOnBoarding = new LoginRequestSignBox
            {
                username = _urls.LoginUserOnBoarding,
                password = _urls.LoginPasswordOnBoarding
            };

            var json = JsonSerializer.Serialize(loginOnBoarding);
            var content = new StringContent(json, Encoding.UTF8, "application/json");


            var response = await client.PostAsync(url, content);
            var body = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new ApplicationException($"Login fallido: {body}");
            }

            var result = JsonSerializer.Deserialize<LoginResponseOnBoarding>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null || string.IsNullOrEmpty(result.Token))
            {
                throw new ApplicationException($"Error de autenticación: {"Respuesta vacía"}");
            }

            return result.Token;
        }



        private async Task<List<LoteEnviado>> ObtenerLotesParaGuardarDocumentosFirmados()
        {


            //!Aislar funcion inicio
            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            //!Aislar funcion final

            var request = new GenericRequest
            {
                Action = "credito-web/obtener-lotes-guardar-documentos",
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

            var result = JsonSerializer.Deserialize<GenericResponse<List<LoteEnviado>>>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null)
            {
                _logger.LogWarning("Respuesta vacía del backend al obtener lotes para firmar.");
                return new List<LoteEnviado>();
            }

            if (result.CodeReturn != 1)
            {
                _logger.LogWarning("Backend respondió sin éxito: {Message}", result.Message);
                return new List<LoteEnviado>();
            }

            if (result.Result == null || !result.Result.Any())
            {
                _logger.LogInformation("No hay Lotes Pendientes para guardar documentos firmados.");
                return new List<LoteEnviado>();
            }


            return result.Result;

        }

        private async Task GuardarDocumentosFirmadosPorLote(LoteEnviado lote)
        {
            // Paso 1: Obtener rutas desde la API externa
            var respuesta = await ObtenerRutasDocumentosFirmadosAsync(lote);

            if (respuesta == null || respuesta.RutasFirmadas == null || !respuesta.RutasFirmadas.Any())
            {
                _logger.LogWarning("No se recibieron rutas de documentos firmados para el lote {Lote}, solicitud {Solicitud}", lote.Lote, lote.Solicitud);
                return;
            }

            // Paso 2: Guardar en base usando SP (vía servicio de integración)
            var response = await GuardarDocumentosFirmadosEnBdAsync(lote, respuesta.RutasFirmadas);

            if (!response.Ok)
            {
                _logger.LogError("Error al guardar rutas firmadas para solicitud {Solicitud}, lote {Lote}: {Message}",
                                 lote.Solicitud, lote.Lote, response.Message);
            }
            else
            {
                _logger.LogInformation("Documentos firmados guardados correctamente para solicitud {Solicitud}, lote {Lote}.",
                    lote.Solicitud, lote.Lote);
            }
        }



        private async Task<GetDocumentsSignedResponse> ObtenerRutasDocumentosFirmadosAsync(LoteEnviado lote)
        {
            
                string baseUrl = _urls.ExtraerDocumentosFirmadosUrlOnBoarding.TrimEnd('/');
                string fullUrl = $"{baseUrl}/?requestId={lote.RequestId}";

                string token = await ObtenerTokenOnBoardingAsync();

                using var requestMessage = new HttpRequestMessage(HttpMethod.Get, fullUrl);
                requestMessage.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

                var response = await client.SendAsync(requestMessage);
                var responseBody = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Error al obtener rutas firmadas. Status: {StatusCode}. Body: {ResponseBody}",
                                      response.StatusCode, responseBody);
                    return new GetDocumentsSignedResponse { RutasFirmadas = new List<string>() };
                }

                var rutas = JsonSerializer.Deserialize<List<string>>(responseBody, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (rutas == null || !rutas.Any())
                {
                    _logger.LogWarning("Respuesta vacía o inválida al obtener rutas firmadas para el lote {Lote}", lote.Lote);
                    return new GetDocumentsSignedResponse { RutasFirmadas = new List<string>() };
                }

                return new GetDocumentsSignedResponse { RutasFirmadas = rutas };
            
            
        }

        private async Task<ResponseGeneric> GuardarDocumentosFirmadosEnBdAsync(LoteEnviado lote, List<string> rutasFirmadas)
        {
            try
            {
                // 1. Construir el objeto con los datos necesarios
                var payload = new
                {
                    solicitud = lote.Solicitud,
                    lote = lote.Lote,
                    requestId = lote.RequestId,
                    rutas = rutasFirmadas
                };

                // 2. Serializar el payload a JSON
                string jsonPayload = JsonSerializer.Serialize(payload);

                // 3. Construir el request hacia el SP genérico
                var request = new GenericRequest
                {
                    Action = "credito-web/guardar-documentos-firmados-por-lote",
                    Data = jsonPayload
                };

                string requestBody = JsonSerializer.Serialize(request);
                var content = new StringContent(requestBody, Encoding.UTF8, "application/json");

                // 4. Preparar el cliente
                string url = _urls.GenericExecuteOrionApi;
                string token = await ObtenerTokenJwtAsync();
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                // 5. Enviar el request
                var response = await client.PostAsync(url, content);
                var responseBody = await response.Content.ReadAsStringAsync();

                // 6. Manejar errores HTTP
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("Error HTTP al guardar documentos firmados: {StatusCode} - {Body}",
                                     response.StatusCode, responseBody);

                    return new ResponseGeneric
                    {
                        CodeReturn = -1,
                        Message = $"HTTP {response.StatusCode}: {response.ReasonPhrase}"
                    };
                }

                // 7. Deserializar la respuesta
                var result = JsonSerializer.Deserialize<ResponseGeneric>(responseBody, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                return result ?? new ResponseGeneric
                {
                    CodeReturn = -1,
                    Message = "Respuesta vacía del servicio"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Excepción al guardar documentos firmados");
                return new ResponseGeneric
                {
                    CodeReturn = -1,
                    Message = $"Excepción: {ex.Message}"
                };
            }
        }



        //Instanciando un cliente HTTP para realizar solicitudes
        private static readonly HttpClient client = new HttpClient();
    }
}
