import Foundation
import Cocoa

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let openAIAPIKey = "openAIAPIKey"
        static let hotkey = "hotkey"
        static let windowPosition = "windowPosition"
        static let showNotifications = "showNotifications"
        static let autoStartAtLogin = "autoStartAtLogin"
        static let suggestionDisplayDuration = "suggestionDisplayDuration"
        static let maxSuggestions = "maxSuggestions"
        static let enableAnalytics = "enableAnalytics"
    }
    
    private init() {
        // Set default values
        registerDefaults()
    }
    
    private func registerDefaults() {
        let defaults: [String: Any] = [
            Keys.isEnabled: true,
            Keys.openAIAPIKey: "",
            Keys.showNotifications: true,
            Keys.autoStartAtLogin: false,
            Keys.suggestionDisplayDuration: 5.0,
            Keys.maxSuggestions: 8,
            Keys.enableAnalytics: true
        ]
        
        userDefaults.register(defaults: defaults)
    }
    
    // MARK: - Properties
    
    var isEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.isEnabled) }
        set { 
            userDefaults.set(newValue, forKey: Keys.isEnabled)
            objectWillChange.send()
        }
    }
    
    var openAIAPIKey: String {
        get { userDefaults.string(forKey: Keys.openAIAPIKey) ?? "" }
        set { 
            userDefaults.set(newValue, forKey: Keys.openAIAPIKey)
            objectWillChange.send()
        }
    }
    
    var hotkey: Hotkey? {
        get {
            guard let data = userDefaults.data(forKey: Keys.hotkey) else {
                // Return default hotkey (Cmd+Shift+W)
                return Hotkey(keyCode: 13, modifierFlags: [.command, .shift])
            }
            return try? JSONDecoder().decode(Hotkey.self, from: data)
        }
        set {
            if let hotkey = newValue {
                let data = try? JSONEncoder().encode(hotkey)
                userDefaults.set(data, forKey: Keys.hotkey)
            } else {
                userDefaults.removeObject(forKey: Keys.hotkey)
            }
            objectWillChange.send()
        }
    }
    
    var windowPosition: NSPoint? {
        get {
            let dict = userDefaults.dictionary(forKey: Keys.windowPosition)
            guard let x = dict?["x"] as? Double,
                  let y = dict?["y"] as? Double else { return nil }
            return NSPoint(x: x, y: y)
        }
        set {
            if let point = newValue {
                let dict = ["x": point.x, "y": point.y]
                userDefaults.set(dict, forKey: Keys.windowPosition)
            } else {
                userDefaults.removeObject(forKey: Keys.windowPosition)
            }
        }
    }
    
    var showNotifications: Bool {
        get { userDefaults.bool(forKey: Keys.showNotifications) }
        set { 
            userDefaults.set(newValue, forKey: Keys.showNotifications)
            objectWillChange.send()
        }
    }
    
    var autoStartAtLogin: Bool {
        get { userDefaults.bool(forKey: Keys.autoStartAtLogin) }
        set { 
            userDefaults.set(newValue, forKey: Keys.autoStartAtLogin)
            setLoginItemEnabled(newValue)
            objectWillChange.send()
        }
    }
    
    var suggestionDisplayDuration: Double {
        get { userDefaults.double(forKey: Keys.suggestionDisplayDuration) }
        set { 
            userDefaults.set(newValue, forKey: Keys.suggestionDisplayDuration)
            objectWillChange.send()
        }
    }
    
    var maxSuggestions: Int {
        get { userDefaults.integer(forKey: Keys.maxSuggestions) }
        set { 
            userDefaults.set(newValue, forKey: Keys.maxSuggestions)
            objectWillChange.send()
        }
    }
    
    var enableAnalytics: Bool {
        get { userDefaults.bool(forKey: Keys.enableAnalytics) }
        set { 
            userDefaults.set(newValue, forKey: Keys.enableAnalytics)
            objectWillChange.send()
        }
    }
    
    // MARK: - Methods
    
    func resetToDefaults() {
        let keys = [
            Keys.isEnabled,
            Keys.openAIAPIKey,
            Keys.hotkey,
            Keys.windowPosition,
            Keys.showNotifications,
            Keys.autoStartAtLogin,
            Keys.suggestionDisplayDuration,
            Keys.maxSuggestions,
            Keys.enableAnalytics
        ]
        
        keys.forEach { userDefaults.removeObject(forKey: $0) }
        registerDefaults()
        objectWillChange.send()
    }
    
    private func setLoginItemEnabled(_ enabled: Bool) {
        _ = Bundle.main.bundleIdentifier ?? "com.wordSuggest.app"
        
        if enabled {
            // Add to login items
            let script = """
                tell application "System Events"
                    make login item at end with properties {path:"\(Bundle.main.bundlePath)", hidden:false}
                end tell
                """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
            }
        } else {
            // Remove from login items
            let script = """
                tell application "System Events"
                    delete login item "\(Bundle.main.bundlePath)"
                end tell
                """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                scriptObject.executeAndReturnError(&error)
            }
        }
    }
    
    func exportSettings() -> [String: Any] {
        return [
            "isEnabled": isEnabled,
            "showNotifications": showNotifications,
            "autoStartAtLogin": autoStartAtLogin,
            "suggestionDisplayDuration": suggestionDisplayDuration,
            "maxSuggestions": maxSuggestions,
            "enableAnalytics": enableAnalytics,
            "hotkey": hotkey?.displayString ?? "⌘⇧W"
        ]
    }
    
    func importSettings(from dictionary: [String: Any]) {
        if let enabled = dictionary["isEnabled"] as? Bool {
            isEnabled = enabled
        }
        if let notifications = dictionary["showNotifications"] as? Bool {
            showNotifications = notifications
        }
        if let autoStart = dictionary["autoStartAtLogin"] as? Bool {
            autoStartAtLogin = autoStart
        }
        if let duration = dictionary["suggestionDisplayDuration"] as? Double {
            suggestionDisplayDuration = duration
        }
        if let maxSugg = dictionary["maxSuggestions"] as? Int {
            maxSuggestions = maxSugg
        }
        if let analytics = dictionary["enableAnalytics"] as? Bool {
            enableAnalytics = analytics
        }
    }
}
