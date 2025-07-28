using FirmaElectronicaWorker.Dto.Request;
using FirmaElectronicaWorker.Dto.Response;
using FirmaElectronicaWorker.Interfaces;
using FirmaElectronicaWorker.Models;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;


namespace FirmaElectronicaWorker.Services
{
    public class FirmaOnBoardingService : IBaseService
    {
        private readonly ILogger<FirmaOnBoardingService> _logger;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ExternalUrls _urls;

        public FirmaOnBoardingService(ILogger<FirmaOnBoardingService> logger,
                                      IHttpClientFactory httpClientFactory,
                                      IOptions<ExternalUrls> urls
            )
        {
            _logger = logger;
            _httpClientFactory = httpClientFactory;
            _urls = urls.Value;
        }

        public async Task Execute()
        {
            var lotes = await ObtenerLotesPendientesFirmarOnBoarding();
            if (!lotes.Any())
            {
                _logger.LogInformation("No hay documentos para firmar por SignBox pendientes. Finalizando ejecución.");
                return;
            }

            foreach (var lote in lotes) 
                {
                    _logger.LogInformation("📄 Enviando lote {Lote} a firmar...", lote.Lote);

                    SolicitanteCreditoInfo solicitante = await ObtenerInfoSolicitanteCredito(lote.Solicitud);

                    OnBoardingSignResponse respuesta = await EnviarDocumentoAFirmarOnBoarding(lote, solicitante);

                if (respuesta.Status.Contains("200"))
                {
                    _logger.LogInformation("✅ Lote {Lote} firmado correctamente.", lote.Lote);

                    await CambiarEstadoFirmadoOnBoarding(respuesta, lote.Solicitud, lote.Lote);

                }
                else
                {
                    _logger.LogWarning("❌  Lote: {Lote} no fue firmado.", lote.Lote);

                    //await CambiarEstadoError(respuesta, doc.Solicitud, doc.Lote, doc.CodigoDocumento);

                }


            }



        }

        //Funciones para Execute()

        //Obtener token de API Orion y OnBoarding
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


        // Obtener documentos pendientes de firma en SignBox


        private async Task<List<LoteFirmaOnBoarding>> ObtenerLotesPendientesFirmarOnBoarding()
        {


            //!Aislar funcion inicio
            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            //!Aislar funcion final

            var request = new GenericRequest
            {
                Action = "credito-web/obtener-lotes-firmar-OnBoarding",
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

            var result = JsonSerializer.Deserialize<GenericResponse<List<LoteFirmaOnBoarding>>>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null)
            {
                _logger.LogWarning("Respuesta vacía del backend al obtener lotes a firmar.");
                return new List<LoteFirmaOnBoarding>();
            }

            if (result.CodeReturn != 1)
            {
                _logger.LogWarning("Backend respondió sin éxito: {Message}", result.Message);
                return new List<LoteFirmaOnBoarding>();
            }

            if (result.Result == null )
            {
                _logger.LogInformation("No hay lotes Pendientes por firmar por OnBoarding.");
                return new List<LoteFirmaOnBoarding>();
            }



            return result.Result;

        }

        //Obtener información del cliente para parametrizar lote de documentos a firmar

        private async Task<SolicitanteCreditoInfo> ObtenerInfoSolicitanteCredito(int soliciutd)
        {


            //!Aislar funcion inicio
            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            //!Aislar funcion final

            var request = new GenericRequest
            {
                Action = "credito-web/obtener-info-solicitante-credito",
                Data  = new
                {
                    Solicitud = soliciutd
                }
            };

            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await client.PostAsync(url, content);

            var body = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new ApplicationException($"Error HTTP: {response.StatusCode} - {response.ReasonPhrase}");
            }

            var result = JsonSerializer.Deserialize<GenericResponse<SolicitanteCreditoInfo>>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null)
            {
                _logger.LogWarning("Respuesta vacía del backend al obtener lotes a firmar.");
                return new SolicitanteCreditoInfo ();
            }

            if (result.CodeReturn != 1)
            {
                _logger.LogWarning("Backend respondió sin éxito: {Message}", result.Message);
                return new SolicitanteCreditoInfo();
            }

            if (result.Result == null)
            {
                _logger.LogInformation("No hay lotes Pendientes por firmar por OnBoarding.");
                return new SolicitanteCreditoInfo();
            }

            _logger.LogInformation("JSON recibido del backend: {Json}", body);


            return result.Result;
        }


        //Enviara a firmar por SignBox los documentos pendientes para firmar

        public async Task<OnBoardingSignResponse> EnviarDocumentoAFirmarOnBoarding(
                                                    LoteFirmaOnBoarding lote,
                                                    SolicitanteCreditoInfo solicitante)
        {
            try
            {
                using var client = _httpClientFactory.CreateClient();
                using var content = new MultipartFormDataContent();

                foreach (var doc in lote.Documentos)
                {
                    var urlPdf = doc.SignBoxWeebhookPdf;

                    using var httpClient = new HttpClient();
                    var pdfBytes = await httpClient.GetByteArrayAsync(urlPdf);

                    if (pdfBytes == null || pdfBytes.Length == 0)
                    {
                        string errorMsg = $"No se pudo descargar el archivo PDF desde: {urlPdf}";
                        _logger.LogWarning(errorMsg);
                        return new OnBoardingSignResponse
                        {
                            Status = "ERROR",
                            Detail = errorMsg,
                        };
                    }

                    var fileName = $"{doc.CodigoDocumento}_Sol{lote.Solicitud}_{solicitante.Nui}.pdf";
                    var byteArrayContent = new ByteArrayContent(pdfBytes);
                    byteArrayContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");

                    // 👇 Este nombre de campo ("archivos") depende de cómo la API espera los archivos
                    content.Add(byteArrayContent, "file", fileName);
                }

                content.Add(new StringContent(solicitante.Nui),"nui");
                content.Add(new StringContent(solicitante.GivenName), "givenName");
                content.Add(new StringContent(solicitante.SecondName), "secondName");
                content.Add(new StringContent(solicitante.Surname1), "surname1");
                content.Add(new StringContent(solicitante.Surname2), "surname2");
                content.Add(new StringContent(solicitante.Province), "province");
                content.Add(new StringContent(solicitante.City), "city");
                content.Add(new StringContent(solicitante.Country), "country");
                content.Add(new StringContent(solicitante.Address), "address");
                content.Add(new StringContent(solicitante.Email), "email");
                content.Add(new StringContent(solicitante.PhoneNumber), "phoneNumber");
                content.Add(new StringContent(solicitante.Reason), "reason");

                string url = _urls.SignDocumentUrlOnBoarding;
                string token = await ObtenerTokenOnBoardingAsync();
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);


                // Aquí haces el POST a la API de OnBoarding
                var response = await client.PostAsync(url, content);
                var responseBody = await response.Content.ReadAsStringAsync();

                var result = JsonSerializer.Deserialize<OnBoardingSignResponse>(responseBody, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                _logger.LogInformation("✅ Se envió la firma OnBoarding: {Status} - {Body}", result?.Status, responseBody);

                return new OnBoardingSignResponse
                {
                    Status = result?.Status ?? "OK",
                    Detail = result?.Detail ?? "Respuesta sin detalle",
                    Url = result?.Url,
                    RequestId = result?.RequestId
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Excepción al enviar documentos a OnBoarding");
                return new OnBoardingSignResponse
                {
                    Status = "ERROR",
                    Detail = $"Excepción: {ex.Message}"
                };
            }
        }


        private async Task CambiarEstadoFirmadoOnBoarding(OnBoardingSignResponse respuestaOnBoarding, int solicitud, int lote)
        {

            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            var request = new RequestGeneric
            {
                Action = "credito-web/enviado-onboarding",
                Data = new
                {
                    Solicitud = solicitud,
                    Lote = lote,
                    RequestId = respuestaOnBoarding.RequestId,
                    Detail = respuestaOnBoarding.Detail,
                    JsonRespuestaOnBoarding = JsonSerializer.Serialize(respuestaOnBoarding)


                }
            };

            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");


            var response = await client.PostAsync(url, content);
            var body = await response.Content.ReadAsStringAsync();

            return;


        }





        private static readonly HttpClient client = new HttpClient();
    }
}
