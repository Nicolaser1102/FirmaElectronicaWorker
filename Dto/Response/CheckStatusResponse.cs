using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Dto.Response
{
    public class CheckStatusResponse
    {
        public bool Result { get; set; }

        // Solo está presente cuando result == true
        public string? State { get; set; }
        public string? Route { get; set; }

        // Solo está presente cuando result == false
        public string? Detail { get; set; }
    }
}
