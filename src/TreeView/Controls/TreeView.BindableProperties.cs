using System.Collections;

namespace TreeView.Controls;

public partial class TreeView
{
    public static readonly BindableProperty ItemsSourceProperty = BindableProperty.Create(nameof(ItemsSource),
        typeof(IEnumerable), typeof(TreeView), null,
        propertyChanging: (b, o, n) => (b as TreeView)?.OnItemsSourceSetting(o as IEnumerable, n as IEnumerable),
        propertyChanged: (b, o, v) => (b as TreeView)?.OnItemsSourceSet());

    public IEnumerable ItemsSource
    {
        get => (IEnumerable)GetValue(ItemsSourceProperty);
        set => SetValue(ItemsSourceProperty, value);
    }

    public static readonly BindableProperty ItemTemplateProperty = BindableProperty.Create(nameof(ItemTemplate),
        typeof(DataTemplate), typeof(TreeView), new DataTemplate(typeof(DefaultTreeViewNodeView)),
        propertyChanged: (b, o, n) => (b as TreeView)?.OnItemTemplateChanged());

    public DataTemplate ItemTemplate
    {
        get => (DataTemplate)GetValue(ItemTemplateProperty);
        set => SetValue(ItemTemplateProperty, value);
    }

    public static readonly BindableProperty ArrowThemeProperty =
        BindableProperty.Create(nameof(ArrowTheme), typeof(NodeArrowTheme), typeof(TreeView),
            defaultValue: NodeArrowTheme.Default,
            propertyChanged: (bo, ov, nv) => (bo as TreeView)?.OnArrowThemeChanged());

    public NodeArrowTheme ArrowTheme
    {
        get => (NodeArrowTheme)GetValue(ArrowThemeProperty);
        set => SetValue(ArrowThemeProperty, value);
    }

    public static readonly BindableProperty IconFontFamilyProperty =
        BindableProperty.Create(nameof(IconFontFamily), typeof(string), typeof(TreeView),
            defaultValue: null,
            propertyChanged: (bo, ov, nv) => (bo as TreeView)?.OnArrowThemeChanged());

    public string? IconFontFamily
    {
        get => (string)GetValue(IconFontFamilyProperty);
        set => SetValue(IconFontFamilyProperty, value);
    }

    public static readonly BindableProperty IconExtendProperty =
        BindableProperty.Create(nameof(IconExtend), typeof(string), typeof(TreeView),
            defaultValue: null,
            propertyChanged: (bo, ov, nv) => (bo as TreeView)?.OnArrowThemeChanged());

    public string? IconExtend
    {
        get => (string)GetValue(IconExtendProperty);
        set => SetValue(IconExtendProperty, value);
    }

    public static readonly BindableProperty ShowNodeIconProperty =
        BindableProperty.Create(nameof(ShowNodeIcon), typeof(bool), typeof(TreeView),
            defaultValue: null,
            propertyChanged: (bo, ov, nv) => (bo as TreeView)?.OnItemTemplateChanged());

    public bool ShowNodeIcon
    {
        get => (bool)GetValue(ShowNodeIconProperty);
        set => SetValue(ShowNodeIconProperty, value);
    }
}