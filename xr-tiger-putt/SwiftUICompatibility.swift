import Foundation

#if !canImport(SwiftUI)
/// Minimal `ObservableObject` and `Published` shims to allow non-Apple platforms
/// to compile the core session model for testing.
public protocol ObservableObject: AnyObject {}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public var projectedValue: Published<Value> { self }
}
#endif

#if !canImport(simd)
/// Lightweight stand-in for `SIMD3` when `simd` is unavailable.
public struct SIMD3<Scalar: FloatingPoint & Codable>: Codable, Equatable {
    public var x: Scalar
    public var y: Scalar
    public var z: Scalar

    public init(_ x: Scalar, _ y: Scalar, _ z: Scalar) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Scalar.self)
        let y = try container.decode(Scalar.self)
        let z = try container.decode(Scalar.self)
        self.init(x, y, z)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
        try container.encode(z)
    }
}

/// Basic distance utility mirroring `simd_distance` for Float vectors.
public func simd_distance(_ lhs: SIMD3<Float>, _ rhs: SIMD3<Float>) -> Float {
    let dx = lhs.x - rhs.x
    let dy = lhs.y - rhs.y
    let dz = lhs.z - rhs.z
    return (dx * dx + dy * dy + dz * dz).squareRoot()
}
#endif
