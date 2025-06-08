import Cocoa

class MainWindowController: NSWindowController {

    private var hotkeyRecorderView: HotkeyRecorderView!
    private var enabledCheckbox: NSButton!
    private var openAIKeyField: NSSecureTextField!
    private var historyTableView: NSTableView!
    private var exportHistoryButton: NSButton!
    private var clearHistoryButton: NSButton!
    private var searchField: NSSearchField!
    private var totalWordsLabel: NSTextField!
    private var totalSuggestionsLabel: NSTextField!
    private var mostUsedWordLabel: NSTextField!
    
    private var historyManager: WordHistoryManager!
    private var filteredHistory: [WordHistoryEntry] = []
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.init(window: window)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Configure window
        window?.title = "WordSuggest"
        window?.center()
        window?.setFrameAutosaveName("MainWindow")

        // Initialize history manager
        historyManager = WordHistoryManager.shared

        createUI()
        setupUI()
        loadSettings()
        refreshHistoryData()

        // Set up observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(historyUpdated),
            name: .wordHistoryUpdated,
            object: nil
        )
    }

    private func createUI() {
        guard let contentView = window?.contentView else { return }

        // Create tab view
        let tabView = NSTabView()
        tabView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabView)

        // Settings tab
        let settingsTab = NSTabViewItem(identifier: "settings")
        settingsTab.label = "Settings"
        let settingsView = createSettingsView()
        settingsTab.view = settingsView
        tabView.addTabViewItem(settingsTab)

        // History tab
        let historyTab = NSTabViewItem(identifier: "history")
        historyTab.label = "History & Analytics"
        let historyView = createHistoryView()
        historyTab.view = historyView
        tabView.addTabViewItem(historyTab)

        // Layout constraints
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func createSettingsView() -> NSView {
        let view = NSView()

        // Enable checkbox
        enabledCheckbox = NSButton(checkboxWithTitle: "Enable WordSuggest", target: self, action: #selector(enabledToggled(_:)))
        enabledCheckbox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enabledCheckbox)

        // Hotkey label
        let hotkeyLabel = NSTextField(labelWithString: "Keyboard Shortcut:")
        hotkeyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hotkeyLabel)

        // Hotkey recorder
        hotkeyRecorderView = HotkeyRecorderView()
        hotkeyRecorderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hotkeyRecorderView)

        // OpenAI API key label
        let apiKeyLabel = NSTextField(labelWithString: "OpenAI API Key (Optional):")
        apiKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(apiKeyLabel)

        // OpenAI API key field
        openAIKeyField = NSSecureTextField()
        openAIKeyField.placeholderString = "Enter your OpenAI API key for enhanced suggestions"
        openAIKeyField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openAIKeyField)

        // Layout constraints
        NSLayoutConstraint.activate([
            enabledCheckbox.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            enabledCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            hotkeyLabel.topAnchor.constraint(equalTo: enabledCheckbox.bottomAnchor, constant: 20),
            hotkeyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            hotkeyRecorderView.topAnchor.constraint(equalTo: hotkeyLabel.bottomAnchor, constant: 8),
            hotkeyRecorderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hotkeyRecorderView.widthAnchor.constraint(equalToConstant: 200),
            hotkeyRecorderView.heightAnchor.constraint(equalToConstant: 30),

            apiKeyLabel.topAnchor.constraint(equalTo: hotkeyRecorderView.bottomAnchor, constant: 20),
            apiKeyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            openAIKeyField.topAnchor.constraint(equalTo: apiKeyLabel.bottomAnchor, constant: 8),
            openAIKeyField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            openAIKeyField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        return view
    }

    private func createHistoryView() -> NSView {
        let view = NSView()

        // Search field
        searchField = NSSearchField()
        searchField.placeholderString = "Search history..."
        searchField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchField)

        // Statistics labels
        totalWordsLabel = NSTextField(labelWithString: "Total Words: 0")
        totalWordsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(totalWordsLabel)

        totalSuggestionsLabel = NSTextField(labelWithString: "Total Suggestions Used: 0")
        totalSuggestionsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(totalSuggestionsLabel)

        mostUsedWordLabel = NSTextField(labelWithString: "Most Used: None")
        mostUsedWordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mostUsedWordLabel)

        // Table view in scroll view
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        view.addSubview(scrollView)

        historyTableView = NSTableView()
        historyTableView.headerView = NSTableHeaderView()

        // Create table columns
        let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DateColumn"))
        dateColumn.title = "Date"
        dateColumn.width = 120
        historyTableView.addTableColumn(dateColumn)

        let wordColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("OriginalWordColumn"))
        wordColumn.title = "Original Word"
        wordColumn.width = 150
        historyTableView.addTableColumn(wordColumn)

        let suggestionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SuggestionColumn"))
        suggestionColumn.title = "Selected Suggestion"
        suggestionColumn.width = 150
        historyTableView.addTableColumn(suggestionColumn)

        let appColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AppColumn"))
        appColumn.title = "Application"
        appColumn.width = 120
        historyTableView.addTableColumn(appColumn)

        scrollView.documentView = historyTableView

        // Buttons
        exportHistoryButton = NSButton(title: "Export CSV", target: self, action: #selector(exportHistory(_:)))
        exportHistoryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exportHistoryButton)

        clearHistoryButton = NSButton(title: "Clear History", target: self, action: #selector(clearHistory(_:)))
        clearHistoryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearHistoryButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchField.widthAnchor.constraint(equalToConstant: 300),

            exportHistoryButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            exportHistoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            clearHistoryButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            clearHistoryButton.trailingAnchor.constraint(equalTo: exportHistoryButton.leadingAnchor, constant: -10),

            totalWordsLabel.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 15),
            totalWordsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            totalSuggestionsLabel.topAnchor.constraint(equalTo: totalWordsLabel.bottomAnchor, constant: 5),
            totalSuggestionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            mostUsedWordLabel.topAnchor.constraint(equalTo: totalSuggestionsLabel.bottomAnchor, constant: 5),
            mostUsedWordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            scrollView.topAnchor.constraint(equalTo: mostUsedWordLabel.bottomAnchor, constant: 15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])

        return view
    }

    private func setupUI() {
        // Configure hotkey recorder
        hotkeyRecorderView.delegate = self
        
        // Configure table view
        historyTableView.delegate = self
        historyTableView.dataSource = self
        
        // Configure search field
        searchField.target = self
        searchField.action = #selector(searchFieldChanged(_:))
        
        // Configure buttons
        exportHistoryButton.target = self
        exportHistoryButton.action = #selector(exportHistory(_:))
        
        clearHistoryButton.target = self
        clearHistoryButton.action = #selector(clearHistory(_:))
        
        enabledCheckbox.target = self
        enabledCheckbox.action = #selector(enabledToggled(_:))
        
        // Configure OpenAI key field
        openAIKeyField.target = self
        openAIKeyField.action = #selector(openAIKeyChanged(_:))
    }
    
    private func loadSettings() {
        let settings = UserSettings.shared
        
        enabledCheckbox.state = settings.isEnabled ? .on : .off
        openAIKeyField.stringValue = settings.openAIAPIKey
        hotkeyRecorderView.setHotkey(settings.hotkey)
    }
    
    private func refreshHistoryData() {
        filteredHistory = historyManager.getAllEntries()
        updateStatistics()
        historyTableView.reloadData()
    }
    
    private func updateStatistics() {
        let stats = historyManager.getStatistics()
        
        totalWordsLabel.stringValue = "Total Words Processed: \(stats.totalWords)"
        totalSuggestionsLabel.stringValue = "Total Suggestions Used: \(stats.totalSuggestions)"
        
        if let mostUsed = stats.mostUsedWord {
            mostUsedWordLabel.stringValue = "Most Used: \(mostUsed.word) (\(mostUsed.count) times)"
        } else {
            mostUsedWordLabel.stringValue = "Most Used: None"
        }
    }
    
    @objc private func historyUpdated() {
        DispatchQueue.main.async {
            self.refreshHistoryData()
        }
    }
    
    @objc private func searchFieldChanged(_ sender: NSSearchField) {
        let searchText = sender.stringValue.lowercased()
        
        if searchText.isEmpty {
            filteredHistory = historyManager.getAllEntries()
        } else {
            filteredHistory = historyManager.getAllEntries().filter { entry in
                entry.originalWord.lowercased().contains(searchText) ||
                entry.selectedSuggestion?.lowercased().contains(searchText) == true
            }
        }
        
        historyTableView.reloadData()
    }
    
    @objc private func exportHistory(_ sender: NSButton) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "WordSuggest_History_\(DateFormatter.filenameDateFormatter.string(from: Date())).csv"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let csvData = self.historyManager.exportToCSV()
                    try csvData.write(to: url, atomically: true, encoding: .utf8)
                    
                    let alert = NSAlert()
                    alert.messageText = "Export Successful"
                    alert.informativeText = "History exported to \(url.lastPathComponent)"
                    alert.alertStyle = .informational
                    alert.runModal()
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.runModal()
                }
            }
        }
    }
    
    @objc private func clearHistory(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Clear History"
        alert.informativeText = "Are you sure you want to clear all word history? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            historyManager.clearHistory()
            refreshHistoryData()
        }
    }
    
    @objc private func enabledToggled(_ sender: NSButton) {
        UserSettings.shared.isEnabled = sender.state == .on
        
        // Notify app delegate to start/stop monitoring
        NotificationCenter.default.post(name: .enabledStateChanged, object: nil)
    }
    
    @objc private func openAIKeyChanged(_ sender: NSSecureTextField) {
        UserSettings.shared.openAIAPIKey = sender.stringValue
    }
}

// MARK: - HotkeyRecorderDelegate
extension MainWindowController: HotkeyRecorderDelegate {
    func hotkeyRecorder(_ recorder: HotkeyRecorderView, didChangeHotkey hotkey: Hotkey?) {
        UserSettings.shared.hotkey = hotkey
        
        // Notify app delegate to update hotkey
        NotificationCenter.default.post(name: .hotkeyChanged, object: hotkey)
    }
}

// MARK: - NSTableViewDataSource
extension MainWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredHistory.count
    }
}

// MARK: - NSTableViewDelegate
extension MainWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredHistory.count else { return nil }
        
        let entry = filteredHistory[row]
        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")
        
        if let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            switch identifier.rawValue {
            case "DateColumn":
                cellView.textField?.stringValue = DateFormatter.displayDateFormatter.string(from: entry.timestamp)
            case "OriginalWordColumn":
                cellView.textField?.stringValue = entry.originalWord
            case "SuggestionColumn":
                cellView.textField?.stringValue = entry.selectedSuggestion ?? "—"
            case "AppColumn":
                cellView.textField?.stringValue = entry.sourceApplication ?? "Unknown"
            default:
                break
            }
            return cellView
        }
        
        return nil
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let wordHistoryUpdated = Notification.Name("wordHistoryUpdated")
    static let enabledStateChanged = Notification.Name("enabledStateChanged")
    static let hotkeyChanged = Notification.Name("hotkeyChanged")
}

// MARK: - DateFormatter Extensions
extension DateFormatter {
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
