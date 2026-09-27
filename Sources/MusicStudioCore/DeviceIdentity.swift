import Foundation

public struct DeviceIdentity: Codable, Equatable, Sendable {
    public let id: UUID
    public let platform: String
    public let createdAt: Date

    public init(id: UUID = UUID(), platform: String, createdAt: Date = Date()) {
        self.id=id; self.platform=platform; self.createdAt=createdAt
    }
}

public enum SecurityPolicy {
    public static let maxClockSkewSeconds: TimeInterval = 300
    public static let requireAuthenticatedTransport = true
    public static let requireRevisionValidation = true
}
