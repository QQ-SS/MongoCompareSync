namespace TreeView.Core;

public interface ITreeViewNode
{
    string Name { get; set; }
    string? Icon { get; set; }
    object? Value { get; set; }
    bool IsExtended { get; set; }
    bool CanDrag { get; set; }
    bool AllowDrop { get; set; }
}
