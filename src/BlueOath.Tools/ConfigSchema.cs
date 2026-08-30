using System.Text.Json;

internal static class ConfigSchema
{
    internal sealed class Node
    {
        public HashSet<string> Kinds { get; } = new(StringComparer.Ordinal);
        public Dictionary<string, Node> Fields { get; } = new(StringComparer.Ordinal);
        public Node? Element { get; set; }
        public bool HasNull => Kinds.Contains("null");
    }

    internal enum Kind
    {
        String,
        Integer,
        Number,
        Bool,
        Array,
        Object
    }

    internal static void Merge(Node node, JsonElement element)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Null:
            case JsonValueKind.Undefined:
                node.Kinds.Add("null");
                break;
            case JsonValueKind.String:
                node.Kinds.Add("string");
                break;
            case JsonValueKind.Number:
                node.Kinds.Add(element.TryGetInt64(out _) ? "integer" : "number");
                break;
            case JsonValueKind.True:
            case JsonValueKind.False:
                node.Kinds.Add("bool");
                break;
            case JsonValueKind.Object:
                node.Kinds.Add("object");
                foreach (var property in element.EnumerateObject())
                {
                    if (!node.Fields.TryGetValue(property.Name, out var child))
                    {
                        child = new Node();
                        node.Fields[property.Name] = child;
                    }
                    Merge(child, property.Value);
                }
                break;
            case JsonValueKind.Array:
                node.Kinds.Add("array");
                node.Element ??= new Node();
                foreach (var item in element.EnumerateArray())
                    Merge(node.Element, item);
                break;
        }
    }

    internal static string CSharpType(Node node)
    {
        var kinds = node.Kinds.Where(k => k != "null").ToHashSet(StringComparer.Ordinal);
        if (kinds.Count == 0) return "object";
        if (kinds.Count == 1)
            return kinds.Single() switch
            {
                "integer" => "long",
                "number" => "double",
                "string" => "string",
                "bool" => "bool",
                "object" => "object",
                "array" => "List<" + ElementCSharpType(node.Element) + ">",
                _ => "object"
            };
        if (kinds.SetEquals(["integer", "number"])) return "double";
        return "object";
    }

    internal static string ElementCSharpType(Node? node)
    {
        node ??= new Node();
        var baseType = CSharpType(node);
        if (node.HasNull && baseType is "long" or "double" or "bool") return baseType + "?";
        return baseType;
    }

    internal static Kind Classify(Node node)
    {
        var kinds = node.Kinds.Where(k => k != "null").ToHashSet(StringComparer.Ordinal);
        if (kinds.Count == 0) return Kind.Object;
        if (kinds.Count == 1)
            return kinds.Single() switch
            {
                "integer" => Kind.Integer,
                "number" => Kind.Number,
                "string" => Kind.String,
                "bool" => Kind.Bool,
                "array" => Kind.Array,
                "object" => Kind.Object,
                _ => Kind.Object
            };
        if (kinds.SetEquals(["integer", "number"])) return Kind.Number;
        return Kind.Object;
    }
}
