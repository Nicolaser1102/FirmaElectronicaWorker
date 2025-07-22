using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FirmaElectronicaWorker.Interfaces
{
    public interface IBaseServiceSetting
    {
        int Duracion { get; set; }
        bool Enabled { get; set; }
    }
}
