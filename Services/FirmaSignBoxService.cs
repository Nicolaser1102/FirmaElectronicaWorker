using FirmaElectronicaWorker.Dto.Request;
using FirmaElectronicaWorker.Dto.Response;
using FirmaElectronicaWorker.Interfaces;
using FirmaElectronicaWorker.Models;
using FirmaElectronicaWorker.Utils;
using Microsoft.Extensions.Options;
using Microsoft.VisualBasic;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using static System.Net.Mime.MediaTypeNames;

namespace FirmaElectronicaWorker.Services
{
    public class FirmaSignBoxService : IBaseService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<FirmaSignBoxService> _logger;
        private readonly AppSettingService _appSettings;
        private readonly ExternalUrls _urls;
        private readonly PdfUtils _pdfUtils;

        public FirmaSignBoxService(
            ILogger<FirmaSignBoxService> logger,
            IHttpClientFactory httpClientFactory,
            AppSettingService appSettings,
            IOptions<ExternalUrls> urls,
            PdfUtils pdfUtils)
        {
            _logger = logger;
            _httpClientFactory = httpClientFactory;
            _appSettings = appSettings;
            _urls = urls.Value;
            _pdfUtils = pdfUtils;
        }

        public async Task Execute()
        {

            var documentos = await ObtenerDocumentosPendientesFirmarSignbox();
            if (!documentos.Any())
            {
                _logger.LogInformation("No hay documentos para firmar por SignBox pendientes. Finalizando ejecución.");
                return;
            }

            //Aqui se tiene que obtener la informacion del firmante por parte de la cooperativa 

            var infoFirmanteCoop = await ObtenerFirmanteCooperativaInfo();
            if (infoFirmanteCoop == null)
            {
                _logger.LogWarning("No se pudo obtener la información del firmante de la cooperativa. Verifique la configuración.");
                return;
            }

            foreach (var doc in documentos)
            {
                _logger.LogInformation("📄 Enviando documento {Id} a firmar...", doc.Id);

                SignBoxSignResponse respuesta = await EnviarDocumentoAFirmarSignBox(doc, infoFirmanteCoop);

                if (respuesta.Status.Contains("200"))
                {
                    _logger.LogInformation("✅ Documento {Id} firmado correctamente.", doc.Id);

                    await CambiarEstadoFirmadoSignBox(respuesta, doc.Solicitud, doc.Lote, doc.CodigoDocumento);

                }
                else
                {
                    _logger.LogWarning("❌ Documento {Id} no fue firmado. Detalle: {Detail}", doc.Id, respuesta.Detail);

                    await CambiarEstadoErrorSignBox(respuesta, doc.Solicitud, doc.Lote, doc.CodigoDocumento);



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


        //Obtener información del firmante de la cooperativa


        private async Task<InfoFirmanteCoop> ObtenerFirmanteCooperativaInfo()
        {


            //!Aislar funcion inicio
            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            //!Aislar funcion final

            var request = new GenericRequest
            {
                Action = "parametros/obtener-info-firm-coop",
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

            var result = JsonSerializer.Deserialize<GenericResponse<InfoFirmanteCoop>>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result == null)
            {
                _logger.LogWarning("Respuesta vacía del backend al obtener notificaciones.");
                return new InfoFirmanteCoop();
            }

            if (result.CodeReturn != 1)
            {
                _logger.LogWarning("Backend respondió sin éxito: {Message}", result.Message);
                return new InfoFirmanteCoop();
            }

            if (result.Result == null)
            {
                _logger.LogInformation("No hay información del firmante de la cooperativa o se encuentra en estado 'B'");
                return new InfoFirmanteCoop();
            }


            return result.Result;

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

        public async Task<SignBoxSignResponse> EnviarDocumentoAFirmarSignBox(DocumentoPendiente doc, InfoFirmanteCoop infoFirmante)
        {
            try
            {

                string url = _urls.SignDocumentUrlSignBox;

                using var client = _httpClientFactory.CreateClient();
                string token = await ObtenerTokenSignBoxAsync();
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);


                var content = new MultipartFormDataContent();


                string rutaArchivo = doc.RutaArchivo;
                if (!File.Exists(rutaArchivo))
                {
                    string errorMsg = $"El archivo no existe: {rutaArchivo}";
                    _logger.LogWarning(errorMsg);

                    return new SignBoxSignResponse
                    {
                        Result = false,
                        Status = "ERROR CON LEER ARCHIVOS DESDE EL DISCO",
                        Detail = errorMsg,
                        WebhookPdf = string.Empty,
                        WebhookTxt = string.Empty
                    };
                }
                var pdfStream = new FileStream(rutaArchivo, FileMode.Open, FileAccess.Read);
                var pdfContent = new StreamContent(pdfStream);
                pdfContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
                content.Add(pdfContent, "fileIn", Path.GetFileName(rutaArchivo));


                string webhookId = $"sign_{doc.CodigoDocumento}_{doc.Solicitud}";
                content.Add(new StringContent(webhookId), "webhookId");



                if (string.IsNullOrWhiteSpace(infoFirmante.ImagenFirma))
                {
                    _logger.LogWarning("La imagen de la firma está vacía o nula.");

                }
                // Validar que sea una cadena base64 válida (opcional pero útil)
                else
                {
                    // Intentar convertir a bytes para validar el formato base64
                    content.Add(new StringContent(infoFirmante.ImagenFirma), "image");
                }



                    var reasonFirma = $"Firma de doc: {doc.CodigoDocumento}_Sol{doc.Solicitud}_firmanteCoop";
                    content.Add(new StringContent(reasonFirma), "reason");


                    var paragraphFormat = new[]
                                    {
                        new
                        {
                            font = new object[] { "Universal-Bold", 6 },
                            align = "right",
                            data_format = new
                            {
                                timezone = "America/Guayaquil",
                                strtime = "%d/%m/%Y %H:%M:%S"
                            },
                            format = new string[]
                                            {
                                                " Firmado por:",
                                                " $(CN)s",
                                                $" C.I. {infoFirmante.Identificacion}",
                                                $" {infoFirmante.Cargo}",
                                                " ID: $(serialNumber)s"
                                            }
                        }
                    };
                    string json = JsonSerializer.Serialize(paragraphFormat);
                    string paragrapgFormatjson = JsonSerializer.Serialize(paragraphFormat);
                    content.Add(new StringContent(paragrapgFormatjson), "paragraphFormat");


                    int totalPaginas = _pdfUtils.ObtenerNumPaginasPdf(doc.RutaArchivo);
                    _logger.LogInformation($"📄 El documento tiene {totalPaginas} páginas.");

                    string ubicacionPaginaFirma = doc.UbicacionPaginaFirma.ToString();
                    // Validar que el npage solicitado esté dentro del rango
                    if (doc.UbicacionPaginaFirma > totalPaginas - 1 || doc.UbicacionPaginaFirma < 1)
                    {
                        _logger.LogWarning($"⚠️ La página de firma ({doc.UbicacionPaginaFirma}) está fuera del rango del documento ({totalPaginas} páginas)");
                        ubicacionPaginaFirma = (totalPaginas - 1).ToString();
                    }
                    content.Add(new StringContent(ubicacionPaginaFirma), "npage");


                    content.Add(new StringContent(infoFirmante.Ubicacion), "location");
                    content.Add(new StringContent(infoFirmante.Usuario), "username");
                    content.Add(new StringContent(infoFirmante.Password), "password");
                    content.Add(new StringContent(infoFirmante.Pin), "pin");
                    content.Add(new StringContent(doc.Coordenadas), "position");


                


                    var response = await client.PostAsync(url, content);
                    var result = await response.Content.ReadAsStringAsync();


                    if (!response.IsSuccessStatusCode)
                    {
                        // Intentamos deserializar como Problem+JSON
                        try
                        {
                            var apiError = JsonSerializer.Deserialize<ApiErrorResponse>(result);
                            var detalles = apiError.Violations != null
                                ? string.Join("; ", apiError.Violations.Select(v => $"{v.Field}: {v.Message}"))
                                : apiError.Message;

                            return new SignBoxSignResponse
                            {
                                Result = false,
                                Status = apiError.Status.ToString(),
                                Detail = $"Error {apiError.Status} {apiError.Title}: {detalles}",
                                WebhookTxt = string.Empty,
                                WebhookPdf = string.Empty
                            };
                        }
                        catch (JsonException)
                        {
                            // Si no pudo parsear Problem+JSON, devolvemos el body crudo
                            return new SignBoxSignResponse
                            {
                                Result = false,
                                Status = ((int)response.StatusCode).ToString(),
                                Detail = $"Error {(int)response.StatusCode}: {result}",
                                WebhookTxt = string.Empty,
                                WebhookPdf = string.Empty
                            };
                        }
                    }

                    // Si es 2xx, intentamos deserializar al DTO esperado
                    var éxito = JsonSerializer.Deserialize<SignBoxSignResponse>(result);
                    if (éxito == null)
                    {
                        return new SignBoxSignResponse
                        {
                            Result = false,
                            Status = "ERROR",
                            Detail = "No se pudo deserializar respuesta válida.",
                            WebhookTxt = string.Empty,
                            WebhookPdf = string.Empty
                        };
                    }
                    return éxito;
                }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Excepción al invocar SignBox");
                return new SignBoxSignResponse
                {
                    Result = false,
                    Status = "ERROR",
                    Detail = $"Excepción: {ex.Message}",
                    WebhookTxt = string.Empty,
                    WebhookPdf = string.Empty
                };
            }
        }

        private async Task CambiarEstadoFirmadoSignBox(SignBoxSignResponse respuestaSignBox, int solicitud, int lote, string codigoDocumento)
        {

            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            var request = new RequestGeneric
            {
                Action = "credito-web/firmado-signbox",
                Data = new
                {
                    Solicitud = solicitud,
                    Lote = lote,
                    CodigoDocumento = codigoDocumento,
                    RespuestaApiSignBox = respuestaSignBox.Status,
                    WebHookTxt = respuestaSignBox.WebhookTxt,
                    WebHookPdf = respuestaSignBox.WebhookPdf,
                    JsonRespuestaSignBox = JsonSerializer.Serialize(respuestaSignBox),


                }
            };

            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

        
            var response = await client.PostAsync(url, content);
            var body = await response.Content.ReadAsStringAsync();

            return;

    
        }


        private async Task CambiarEstadoErrorSignBox(SignBoxSignResponse respuestaSignBox, int solicitud, int lote, string codigoDocumento)
        {

            string url = _urls.GenericExecuteOrionApi;
            string tokenJwt = await ObtenerTokenJwtAsync();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokenJwt);

            var request = new RequestGeneric
            {
                Action = "credito-web/error-firma-signbox",
                Data = new
                {
                    Solicitud = solicitud,
                    Lote = lote,
                    CodigoDocumento = codigoDocumento,
                    RespuestaApiSignBox = respuestaSignBox.Status,
                    WebHookTxt = respuestaSignBox.WebhookTxt,
                    WebHookPdf = respuestaSignBox.WebhookPdf,
                    JsonRespuestaSignBox = JsonSerializer.Serialize(respuestaSignBox),


                }
            };

            var json = JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            
            var response = await client.PostAsync(url, content);
            var body = await response.Content.ReadAsStringAsync();

            
        }




        //Instanciando un cliente HTTP para realizar solicitudes
        private static readonly HttpClient client = new HttpClient();
    }


}
