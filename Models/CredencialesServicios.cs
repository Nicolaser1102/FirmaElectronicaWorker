using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Models
{
    public class LoginRequestGS
    {
        public string UserName { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class LoginResponse
    {
        public int SessionId { get; set; }
        public string? Token { get; set; }
        public string? Result { get; set; }
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

    }

}
