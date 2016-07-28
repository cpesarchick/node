extension Node: NodeConvertible { // Can conform to both if non-throwing implementations
    public init(node: Node, in context: Context) {
        self = node
    }

    public func makeNode() -> Node {
        return self
    }
}
