namespace MongoCompareSync.Resources.Localization;

using System.ComponentModel;
using System.Globalization;

public class LocalizationResourceManager : INotifyPropertyChanged
{
    private LocalizationResourceManager()
    {
        Resource.Culture = CultureInfo.CurrentCulture;
    }

    public static LocalizationResourceManager Instance { get; } = new();

    public object this[string resourceKey] =>
        Resource.ResourceManager.GetObject(resourceKey, Resource.Culture) ?? Array.Empty<byte>();

    public event PropertyChangedEventHandler? PropertyChanged;

    public void SetCulture(CultureInfo culture)
    {
        Resource.Culture = culture;
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(null));
    }
}