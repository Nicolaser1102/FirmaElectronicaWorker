
using PdfSharpCore.Pdf.IO;

namespace FirmaElectronicaWorker.Utils
{
    public class PdfUtils
    {
        public int ObtenerNumPaginasPdf(string rutaArchivo)
        {
            using var stream = File.OpenRead(rutaArchivo);
            using var pdf = PdfReader.Open(stream, PdfDocumentOpenMode.ReadOnly);
            return pdf.PageCount;
        }
    }
}
