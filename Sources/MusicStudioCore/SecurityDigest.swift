import Foundation
import CryptoKit

public enum SecurityDigest {
    public static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func projectDigest(_ project: MusicProject) throws -> String {
        let data = try ProjectCodec.encode(project)
        return sha256(data)
    }
}
