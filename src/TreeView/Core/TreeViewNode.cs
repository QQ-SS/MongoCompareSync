using System.Collections.ObjectModel;
using System.Runtime.CompilerServices;

namespace TreeView.Core;

public class TreeViewNode : BindableObject, ILazyLoadTreeViewNode
{
    private bool? _isLeaf;
    private string _name = string.Empty;
    private object? _value;
    private string? _icon;
    private bool _isExtended;
    private bool _canDrag;
    private bool _allowDrop;

    public TreeViewNode()
    {
    }

    public TreeViewNode(string name, object? value = null, string? icon = null, bool isExtended = false,
        bool canDrag = true, bool allowDrop = true, IList<IHasChildrenTreeViewNode>? children = null)
    {
        Name = name;
        Value = value;
        Icon = icon;
        IsExtended = isExtended;
        CanDrag = canDrag;
        AllowDrop = allowDrop;

        if (children != null)
        {
            Children = children;
        }
    }

    public virtual string Name { get => _name; set => SetProperty(ref _name, value); }
    public virtual object? Value { get => _value; set => SetProperty(ref this._value, value); }
    public virtual string? Icon { get => _icon; set => SetProperty(ref _icon, value); }
    public virtual bool IsExtended { get => _isExtended; set => SetProperty(ref _isExtended, value); }
    public virtual bool CanDrag { get => _canDrag; set => SetProperty(ref _canDrag, value); }
    public virtual bool AllowDrop { get => _allowDrop; set => SetProperty(ref _allowDrop, value); }

    public virtual IList<IHasChildrenTreeViewNode> Children { get; set; } =
        new ObservableCollection<IHasChildrenTreeViewNode>();

    public virtual Func<ITreeViewNode, IEnumerable<IHasChildrenTreeViewNode>>? GetChildren { get; set; }

    public virtual bool? IsLeaf
    {
        get => _isLeaf ?? !Children.Any() && GetChildren == null;
        set => SetProperty(ref _isLeaf, value);
    }

    protected virtual void SetProperty<T>(ref T field, T value, Action<T>? doAfter = null,
        [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value))
        {
            return;
        }

        field = value;
        OnPropertyChanged(propertyName);
        doAfter?.Invoke(value);
    }
}
