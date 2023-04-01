namespace MongoCompareSync;
using System.Globalization;

using Resources.Localization;

public partial class MainPage : ContentPage
{

    public MainPage()
    {
        InitializeComponent();
        LanguagePicker.Items.Add("zh-CN");
        LanguagePicker.Items.Add("en-US");
        LanguagePicker.SelectedIndex = 0;
        LocalizationResourceManager = LocalizationResourceManager.Instance;
        BindingContext = this;
    }

    public LocalizationResourceManager LocalizationResourceManager { get; }

    private void LanguageChanged(object sender, EventArgs e)
    {
        LocalizationResourceManager.Instance.SetCulture(new CultureInfo(LanguagePicker.Items[LanguagePicker.SelectedIndex]));
    }

}

