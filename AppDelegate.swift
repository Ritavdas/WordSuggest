import Cocoa
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var textMonitor: TextMonitor?
    var suggestionService: WordSuggestionService?
    var suggestionWindow: SuggestionWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set up status bar item
        setupStatusBar()
        
        // Request accessibility permissions
        requestAccessibilityPermissions()
        
        // Initialize services
        suggestionService = WordSuggestionService()
        suggestionWindow = SuggestionWindow()
        textMonitor = TextMonitor()
        textMonitor?.delegate = self
        
        // Start monitoring
        textMonitor?.startMonitoring()
        
        print("WordSuggest started successfully")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        textMonitor?.stopMonitoring()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.title = "WS"
            button.toolTip = "WordSuggest - Right click for options"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About WordSuggest", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit WordSuggest", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "WordSuggest"
        alert.informativeText = "A smart word suggestion tool.\n\nSelect text and press Cmd+Shift+W to get word suggestions."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func requestAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = "WordSuggest needs accessibility access to monitor text selection. Please grant access in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

extension AppDelegate: TextMonitorDelegate {
    func textSelectionDetected(_ selectedText: String, at location: CGPoint) {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        suggestionService?.getSuggestions(for: selectedText) { [weak self] suggestions in
            DispatchQueue.main.async {
                self?.suggestionWindow?.showSuggestions(suggestions, at: location)
            }
        }
    }
}
