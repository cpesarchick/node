
extension Dictionary {
    func mapValues<T>(_ mapper: @noescape (value: Value) throws -> T)
        rethrows -> Dictionary<Key, T> {
        var mapped: [Key: T] = [:]
        try forEach { key, value in
            mapped[key] = try mapper(value: value)
        }
        return mapped
    }
}

// MARK: Transforming

extension Node {
    public func extract<T, InputType: NodeInitializable>(
        _ keyType: PathIndex...,
        transform: (InputType) throws -> T)
        throws -> T {
            let node = self[keyType] ?? .null
            let input = try InputType(node: node)
            return try transform(input)
    }

    public func extract<T, InputType: NodeInitializable>(
        _ keyType: PathIndex...,
        transform: (InputType?) throws -> T)
        throws -> T {
            let value = try self[keyType].flatMap { try InputType(node: $0) }
            return try transform(value)
    }
}

// MARK: Non-Optional

extension Node {
    public func extract<T : NodeInitializable>(
        _ keyType: PathIndex...)
        throws -> T {
            let node = self[keyType] ?? .null
            return try T(node: node)
    }

    public func extract<T : NodeInitializable>(
        _ keyType: PathIndex...)
        throws -> [T] {
            let node = self[keyType] ?? .null
            return try [T](node: node)
    }

    public func extract<T : NodeInitializable>(
        _ keyType: PathIndex...)
        throws -> [[T]] {
            guard let arrayOfArrays = self[keyType]?.arrayOfArrays else {
                throw NodeError.unableToConvert(node: .null, expected: "\([[T]].self)")
            }
            return try arrayOfArrays.map { innerArray
                in try innerArray.map { node in try T(node: node) }
            }
    }

    public func extract<T : NodeInitializable>(
        _ keyType: PathIndex...)
        throws -> [String : T] {
            guard let object = self[keyType]?.nodeObject else {
                throw NodeError.unableToConvert(node: .null, expected: "\([String: T].self)")
            }

            return try object.mapValues { return try T(node: $0) }
    }

    public func extract<T : NodeInitializable>(
        _ keyType: PathIndex...)
        throws -> [String : [T]] {
            guard let object = self[keyType]?.nodeObject else {
                throw NodeError.unableToConvert(node: .null, expected: "\([String: [T]].self)")
            }
            return try object.mapValues { return try [T](node: $0) }
    }

    public func extract<T : NodeInitializable>(
        _ keyType: PathIndex...)
        throws -> Set<T> {
            let node = self[keyType] ?? .null
            let array = try [T](node: node)
            return Set(array)
    }
}

// MARK: Optional Extractions

extension Node {

    public func extract<T : NodeConvertible>(
        _ keyType: PathIndex...)
        throws -> T? {
            return try self[keyType].flatMap { try T(node: $0) }
    }

    public func extract<T : NodeConvertible>(
        _ keyType: PathIndex...)
        throws -> [T]? {
            return try self[keyType].flatMap { try [T](node: $0) }
    }

    public func extract<T : NodeConvertible>(
        _ keyType: PathIndex...)
        throws -> [[T]]? {
            return try self[keyType]?
                .arrayOfArrays
                .map { innerArray
                    in try innerArray.map { node in try T(node: node) }
                }
    }

    public func extract<T : NodeConvertible>(
        _ keyType: PathIndex...)
        throws -> [String : T]? {
            return try self[keyType]?
                .nodeObject?
                .mapValues { return try T(node: $0) }
    }

    public func extract<T : NodeConvertible>(
        _ keyType: PathIndex...)
        throws -> [String : [T]]? {
            return try self[keyType]?
                .nodeObject?
                .mapValues { return try [T](node: $0) }
    }

    public func extract<T : NodeConvertible>(
        _ keyType: PathIndex...)
        throws -> Set<T>? {
            return try self[keyType]
                .flatMap { try [T](node: $0) }
                .flatMap { Set($0) }
    }
}

extension Node {
    internal var arrayOfArrays: [[Node]] {
        let array = self.nodeArray ?? [self]
        let possibleArrayOfArrays = array.flatMap { $0.nodeArray }
        let isAlreadyAnArrayOfArrays = possibleArrayOfArrays.count == array.count
        let arrayOfArrays: [[Node]] = isAlreadyAnArrayOfArrays ? possibleArrayOfArrays : [array]
        return arrayOfArrays
    }
}
