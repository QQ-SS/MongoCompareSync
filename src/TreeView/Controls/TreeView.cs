using System.Collections;
using System.Collections.Specialized;

using Microsoft.Maui.Controls;

using TreeView.Core;

namespace TreeView.Controls;

public partial class TreeView : ContentView
{
    private readonly StackLayout _root = new() { Spacing = 0 };

    public event EventHandler<DragStartingEventArgs>? NodeDragStarting;
    public event EventHandler<DragEventArgs>? NodeDragOver;
    public event EventHandler<DropEventArgs>? NodeDrop;

    public TreeView()
    {
        Content = _root;
    }

    protected virtual void OnItemsSourceSetting(IEnumerable? oldValue, IEnumerable? newValue)
    {
        if (oldValue is INotifyCollectionChanged oldItemsSource)
        {
            oldItemsSource.CollectionChanged -= OnItemsSourceChanged;
        }

        if (newValue is INotifyCollectionChanged newItemsSource)
        {
            newItemsSource.CollectionChanged += OnItemsSourceChanged;
        }
    }

    protected virtual void OnItemsSourceSet()
    {
        Render();
    }

    private protected virtual void OnItemsSourceChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        switch (e.Action)
        {
            case NotifyCollectionChangedAction.Add:
                {
                    for (int i = 0; i < e.NewItems?.Count; i++)
                    {
                        object? item = e.NewItems[i];
                        if (item != null)
                        {
                            var vNode = new TreeViewNodeView((IHasChildrenTreeViewNode)item, ItemTemplate, ArrowTheme, IconFontFamily, IconExtend, ShowNodeIcon);
                            vNode.DragStarting += NodeDragStarting;
                            vNode.DragOver += NodeDragOver;
                            vNode.Drop += NodeDrop;
                            _root.Children.Insert(e.NewStartingIndex, vNode);
                        }
                    }
                }
                break;
            case NotifyCollectionChangedAction.Remove:
                {
                    for (int i = 0; i < e.OldItems?.Count; i++)
                    {
                        object? item = e.OldItems[i];
                        _root.Children.Remove(_root.Children.FirstOrDefault(x => (x as View)?.BindingContext == item));
                    }
                }
                break;
            default:
                Render();
                break;
        }
    }

    protected virtual void OnItemTemplateChanged()
    {
        // TODO: Some optimizations
        // Eventually
        Render();
    }

    void Render()
    {
        _root.Children.Clear();

        if (ItemsSource == null)
        {
            return;
        }

        foreach (var item in ItemsSource)
        {
            if (item is IHasChildrenTreeViewNode node)
            {
                var vNode = new TreeViewNodeView(node, ItemTemplate, ArrowTheme, IconFontFamily, IconExtend, ShowNodeIcon);
                vNode.DragStarting += NodeDragStarting;
                vNode.DragOver += NodeDragOver;
                vNode.Drop += NodeDrop;
                _root.Children.Add(vNode);
            }
        }
    }

    protected virtual void OnArrowThemeChanged()
    {
        foreach (TreeViewNodeView treeViewNodeView in _root.Children.Where(x => x is TreeViewNodeView).Cast<TreeViewNodeView>())
        {
            treeViewNodeView.UpdateArrowTheme(ArrowTheme);
        }
    }
}

public class TreeViewNodeView : ContentView
{
    protected ImageButton _extendButton;
    protected StackLayout _slChildrens;
    protected IHasChildrenTreeViewNode Node { get; }
    protected DataTemplate ItemTemplate { get; }
    protected NodeArrowTheme ArrowTheme { get; }
    protected string? IconFontFamily { get; }
    protected string? IconExtend { get; }
    protected bool ShowNodeIcon { get; }

    public event EventHandler<DragStartingEventArgs>? DragStarting;
    public event EventHandler<DragEventArgs>? DragOver;
    public event EventHandler<DropEventArgs>? Drop;

    private void OnDragStarting(object? sender, DragStartingEventArgs e)
    {
        //IHasChildrenTreeViewNode? nodeFrom = (sender as DragGestureRecognizer)?.DragStartingCommandParameter as IHasChildrenTreeViewNode;
        //e.Data.Properties.Add("Node", nodeFrom);
        DragStarting?.Invoke(sender, e);
    }

    private void OnDragOver(object? sender, DragEventArgs e)
    {
        //IHasChildrenTreeViewNode? nodeTo = (sender as DropGestureRecognizer)?.DropCommandParameter as IHasChildrenTreeViewNode;
        //if (e.Data.Properties.TryGetValue("Node", out var obj))
        //{
        //    IHasChildrenTreeViewNode? nodeFrom = obj as IHasChildrenTreeViewNode;
        //    if (nodeFrom?.Name == "A" && nodeTo?.Name == "A")
        //    {
        //        e.AcceptedOperation = DataPackageOperation.None;
        //    }
        //    Console.WriteLine(nodeFrom);
        //}
        DragOver?.Invoke(sender, e);
    }

    private void OnDrop(object? sender, DropEventArgs e)
    {
        //IHasChildrenTreeViewNode? nodeTo = (sender as DropGestureRecognizer)?.DropCommandParameter as IHasChildrenTreeViewNode;
        //if (e.Data.Properties.TryGetValue("Node", out var obj))
        //{
        //    IHasChildrenTreeViewNode? nodeFrom = obj as IHasChildrenTreeViewNode;
        //    Console.WriteLine(nodeFrom);
        //    Console.WriteLine(nodeTo);
        //}
        Drop?.Invoke(sender, e);
    }

    public TreeViewNodeView(IHasChildrenTreeViewNode node, DataTemplate itemTemplate, NodeArrowTheme theme, string? iconFontFamily, string? iconExtend, bool showNodeIcon)
    {
        var sl = new StackLayout { Spacing = 0 };
        BindingContext = Node = node;
        ItemTemplate = itemTemplate;
        ArrowTheme = theme;
        IconFontFamily = iconFontFamily;
        IconExtend = iconExtend;
        ShowNodeIcon = showNodeIcon;
        Content = sl;

        _slChildrens = new StackLayout { IsVisible = node.IsExtended, Margin = new Thickness(10, 0, 0, 0), Spacing = 0 };

        _extendButton = new ImageButton
        {
            Aspect = Aspect.Center,
            Source = GetArrowSource(theme),
            HorizontalOptions = LayoutOptions.Center,
            VerticalOptions = LayoutOptions.Center,
            BackgroundColor = Colors.Transparent,
            Opacity = node.IsLeaf == true ? 0 : 1, // Using opacity instead isvisible to keep alignment
            Rotation = node.IsExtended ? 0 : -90,
            HeightRequest = 30,
            WidthRequest = 30,
            CornerRadius = 15
        };

        _extendButton.Triggers.Add(new DataTrigger(typeof(ImageButton))
        {
            Binding = new Binding(nameof(Node.IsLeaf)),
            Value = true,
            Setters = { new Setter { Property = ImageButton.OpacityProperty, Value = 0 } }
        });

        _extendButton.Triggers.Add(new DataTrigger(typeof(ImageButton))
        {
            Binding = new Binding(nameof(Node.IsLeaf)),
            Value = false,
            Setters = { new Setter { Property = ImageButton.OpacityProperty, Value = 1 } }
        });

        _extendButton.Triggers.Add(new DataTrigger(typeof(ImageButton))
        {
            Binding = new Binding(nameof(Node.IsExtended)),
            Value = true,
            EnterActions = { new GenericTriggerAction<ImageButton>((sender) => sender.RotateTo(0)) },
            ExitActions = { new GenericTriggerAction<ImageButton>((sender) => sender.RotateTo(-90)) }
        });

        _extendButton.Clicked += (s, e) =>
        {
            node.IsExtended = !node.IsExtended;
            _slChildrens.IsVisible = node.IsExtended;

            if (node.IsExtended)
            {
                _extendButton.RotateTo(0);

                if (node is ILazyLoadTreeViewNode lazyNode && lazyNode.GetChildren != null && !lazyNode.Children.Any())
                {
                    var lazyChildren = lazyNode.GetChildren(lazyNode);
                    foreach (var child in lazyChildren)
                    {
                        lazyNode.Children.Add(child);
                    }

                    if (!lazyNode.Children.Any())
                    {
                        _extendButton.Opacity = 0;
                        lazyNode.IsLeaf = true;
                    }
                }
            }
            else
            {
                _extendButton.RotateTo(-90);
            }
        };

        var content = ItemTemplate.CreateContent() as View;

        var drag = new DragGestureRecognizer
        {
            CanDrag = node.CanDrag,
            // DragStartingCommand = new Command<object>(OnDragStarting),
            DragStartingCommandParameter = node,
        };
        drag.DragStarting += OnDragStarting;

        var drop = new DropGestureRecognizer
        {
            AllowDrop = node.AllowDrop,
            // DropCommand = new Command<object>(OnDrop),
            DropCommandParameter = node,
        };
        drop.DragOver += OnDragOver;
        drop.Drop += OnDrop;

        sl.Children.Add(new StackLayout
        {
            Spacing = 0,
            Orientation = StackOrientation.Horizontal,
            Children =
            {
                _extendButton,
                new StackLayout
                {
                    Spacing = 8,
                    Orientation = StackOrientation.Horizontal,
                    Children =
                    {
                        ShowNodeIcon && !string.IsNullOrEmpty(node.Icon)
                            ? new Label { FontFamily = IconFontFamily, Text = node.Icon, VerticalOptions = LayoutOptions.Center }
                            : null,
                        content,
                    },
                    GestureRecognizers =
                    {
                        drag,
                        drop,
                    }
                }
            }
        });
        foreach (var child in node.Children)
        {
            var vNode = new TreeViewNodeView(child, ItemTemplate, theme, IconFontFamily, IconExtend, ShowNodeIcon);
            vNode.DragStarting += OnDragStarting;
            vNode.DragOver += OnDragOver;
            vNode.Drop += OnDrop;
            _slChildrens.Children.Add(vNode);
        }

        sl.Children.Add(_slChildrens);

        if (Node.Children is INotifyCollectionChanged ovservableCollection)
        {
            ovservableCollection.CollectionChanged += Children_CollectionChanged;
        }
    }

    private void Children_CollectionChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        if (e.Action == NotifyCollectionChangedAction.Add)
        {
            for (int i = 0; i < e.NewItems?.Count; i++)
            {
                object? item = e.NewItems[i];
                if (item != null)
                {
                    var vNode = new TreeViewNodeView((IHasChildrenTreeViewNode)item, ItemTemplate, ArrowTheme, IconFontFamily, IconExtend, ShowNodeIcon);
                    vNode.DragStarting += OnDragStarting;
                    vNode.DragOver += OnDragOver;
                    vNode.Drop += OnDrop;
                    _slChildrens.Children.Insert(e.NewStartingIndex, vNode);
                }
            }
        }

        else if (e.Action == NotifyCollectionChangedAction.Remove)
        {
            for (int i = 0; i < e.OldItems?.Count; i++)
            {
                object? item = e.OldItems[i];
                _slChildrens.Children.Remove(
                    _slChildrens.Children.FirstOrDefault(x => (x as View)?.BindingContext == item));
            }
        }
    }

    public void UpdateArrowTheme(NodeArrowTheme theme)
    {
        _extendButton.Source = GetArrowSource(theme);

        if (_slChildrens.Any())
        {
            foreach (var child in _slChildrens.Children)
            {
                if (child is TreeViewNodeView treeViewNodeView)
                {
                    treeViewNodeView.UpdateArrowTheme(theme);
                }
            }
        }
    }

    protected virtual ImageSource GetFontImageSource(NodeArrowTheme theme, string glyph, int size = 12)
    {
        if (theme == NodeArrowTheme.Default)
        {
            theme = Application.Current?.RequestedTheme == AppTheme.Dark
                ? NodeArrowTheme.Dark
                : NodeArrowTheme.Light;
        }

        return new FontImageSource
        {
            Glyph = glyph,
            //FontFamily = "fabmdl2.ttf#",
            FontFamily = IconFontFamily,
            Size = size,
            Color = theme == NodeArrowTheme.Light ? Color.FromArgb("#000") : Color.FromArgb("#D1D1D1")
        };
    }

    protected virtual ImageSource GetArrowSource(NodeArrowTheme theme)
    {
        if (theme == NodeArrowTheme.Default)
        {
            theme = Application.Current?.RequestedTheme == AppTheme.Dark
                ? NodeArrowTheme.Dark
                : NodeArrowTheme.Light;
        }

        return string.IsNullOrEmpty(IconFontFamily) || string.IsNullOrEmpty(IconExtend)
            ? theme == NodeArrowTheme.Dark
                ? GetImageSource("down_light.png")
                : GetImageSource("down_dark.png")
            : GetFontImageSource(theme, IconExtend);
    }

    protected ImageSource GetImageSource(string fileName)
    {
        return
            ImageSource.FromResource("TreeView.Resources.Images." + fileName, GetType().Assembly);
    }
}

public enum NodeArrowTheme
{
    Default,
    Light,
    Dark
}
