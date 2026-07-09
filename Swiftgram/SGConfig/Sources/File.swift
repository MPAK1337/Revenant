import Foundation

public struct SGConfig: Codable {
    public var apiUrl: String = "https://api.swiftgram.app"
    public var webappUrl: String = "https://my.swiftgram.app"
    public var botUsername: String = "SwiftgramBot"
    public var publicKey: String?
    public var iaps: [String] = []
}

public let SG_CONFIG: SGConfig = SGConfig()
public let SG_API_WEBAPP_URL_PARSED = URL(string: SG_CONFIG.webappUrl)!
