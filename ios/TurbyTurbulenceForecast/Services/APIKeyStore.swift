import Foundation

enum APIKeyStore {
    private static let aeroDataBoxKeyName = "aeroDataBoxAPIKey"

    static var aeroDataBoxKey: String {
        get {
            let userKey = UserDefaults.standard.string(forKey: aeroDataBoxKeyName) ?? ""
            if !userKey.isEmpty { return userKey }
            let configKey = Config.EXPO_PUBLIC_AERODATABOX_API_KEY
            if !configKey.isEmpty { return configKey }
            return ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: aeroDataBoxKeyName)
        }
    }

    static var hasAeroDataBoxKey: Bool {
        !aeroDataBoxKey.isEmpty
    }

    static var isUsingConfigKey: Bool {
        let userKey = UserDefaults.standard.string(forKey: aeroDataBoxKeyName) ?? ""
        return userKey.isEmpty && !Config.EXPO_PUBLIC_AERODATABOX_API_KEY.isEmpty
    }
}
