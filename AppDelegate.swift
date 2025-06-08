import Cocoa
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var textMonitor: TextMonitor?
    var suggestionService: WordSuggestionService?
    var suggestionWindow: SuggestionWindow?
    var mainWindowController: MainWindowController?

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

        // Initialize main window
        setupMainWindow()

        // Start monitoring if enabled
        if UserSettings.shared.isEnabled {
            textMonitor?.startMonitoring()
        }

        // Set up observers
        setupNotificationObservers()

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
        menu.addItem(NSMenuItem(title: "Open WordSuggest", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About WordSuggest", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit WordSuggest", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        showMainWindow()
    }

    @objc private func showMainWindow() {
        if mainWindowController == nil {
            setupMainWindow()
        }

        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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

    private func setupMainWindow() {
        mainWindowController = MainWindowController()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enabledStateChanged),
            name: .enabledStateChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeyChanged(_:)),
            name: .hotkeyChanged,
            object: nil
        )
    }

    @objc private func enabledStateChanged() {
        if UserSettings.shared.isEnabled {
            textMonitor?.startMonitoring()
        } else {
            textMonitor?.stopMonitoring()
        }
    }

    @objc private func hotkeyChanged(_ notification: Notification) {
        // Update the hotkey in TextMonitor
        textMonitor?.updateHotkey(UserSettings.shared.hotkey)
    }
}

extension AppDelegate: TextMonitorDelegate {
    func textSelectionDetected(_ selectedText: String, at location: CGPoint) {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Get the source application
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        suggestionService?.getSuggestions(for: selectedText) { [weak self] suggestions in
            DispatchQueue.main.async {
                // Record the word lookup in history
                WordHistoryManager.shared.addEntry(
                    originalWord: selectedText,
                    suggestions: suggestions,
                    sourceApp: sourceApp
                )

                self?.suggestionWindow?.showSuggestions(suggestions, at: location)
            }
        }
    }
}
