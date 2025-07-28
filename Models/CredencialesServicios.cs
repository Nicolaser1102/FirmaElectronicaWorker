

using System.Text.Json.Serialization;

namespace FirmaElectronicaWorker.Models
{
    public class LoginRequestGS
    {
        public string UserName { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class LoginRequestSignBox
    {
        public string username { get; set; } = string.Empty;
        public string password { get; set; } = string.Empty;
    }

    public class LoginResponse
    {
        public int SessionId { get; set; }
        public string? Token { get; set; }
        public string? Result { get; set; }
    }

    public class LoginResponseSignBox
    {
        [JsonPropertyName("id_token")]
        public string Token { get; set; }

    }

    public class LoginResponseOnBoarding
    {
        [JsonPropertyName("id_token")]
        public string Token { get; set; }

    }

    public class GenericRequest
    {
        public string Action { get; set; } = string.Empty;
        public object? Data { get; set; }


    }
    public class GenericResponse<T>
    {
        public int CodeReturn { get; set; }
        public string? Message { get; set; }
        public T? Result { get; set; }
    }


    public class ExternalUrls
    {
        public string LoginUrlOrionApi { get; set; }
        public string GenericExecuteOrionApi { get; set; }
        public string LoginUserOrionApi { get; set; }
        public string LoginPasswordOrionApi { get; set; }
        public string NameService { get; set; }
        public string HashPassword { get; set; }
        public string NamePC { get; set; }
        public string LoginAPP { get; set; }


        // SignBox URLs
        public string LoginUrlSignBox { get; set; }
        public string SignDocumentUrlSignBox { get; set; }
        public string LoginUserSignBox { get; set; }
        public string LoginPasswordSignBox { get; set; }

        // OnBoarding URLs
        public string LoginUrlOnBoarding { get; set; }
        public string SignDocumentUrlOnBoarding { get; set; }
        public string LoginUserOnBoarding { get; set; }
        public string LoginPasswordOnBoarding { get; set; }

    }



}
