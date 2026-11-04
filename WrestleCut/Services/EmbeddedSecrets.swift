import Foundation

/// Build-time embedded secrets.
///
/// The real NVIDIA API key is NEVER stored in this repository (the repo is
/// public). During CI, the build injects it from the `NVIDIA_API_KEY` GitHub
/// Actions secret by replacing `encodedKey` below with an XOR-obfuscated byte
/// array, so the shipped app can use the NVIDIA vision model with no key for
/// the user to enter. An empty array means "not embedded in this build".
enum EmbeddedSecrets {
    static let encodedKey: [UInt8] = []

    private static let mask: [UInt8] = Array("WrestleCut-NVIDIA".utf8)

    static var nvidiaAPIKey: String {
        guard !encodedKey.isEmpty else { return "" }
        let bytes = encodedKey.enumerated().map { i, b in b ^ mask[i % mask.count] }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
}
