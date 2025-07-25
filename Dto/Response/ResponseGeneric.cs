

namespace FirmaElectronicaWorker.Dto.Response;

public class ResponseGeneric
{
    public int CodeReturn { get; set; } = -1;
    public string Message { get; set; } = "";
    public object? Result { get; set; }
    public bool Ok => CodeReturn == 1;
    public override string ToString()
    {
        return $"{CodeReturn},{Message},{(Result == null ? "": Result)}";
    }
}
