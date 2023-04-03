namespace TreeView.Core;

public interface ILazyLoadTreeViewNode : IHasChildrenTreeViewNode
{
    Func<ITreeViewNode, IEnumerable<IHasChildrenTreeViewNode>>? GetChildren { get; }
}
