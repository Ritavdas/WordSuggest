import Cocoa

class SuggestionWindow: NSWindow {
    private var suggestionButtons: [NSButton] = []
    private var containerView: NSView!
    private var backgroundView: NSVisualEffectView!
    private var currentSuggestions: [WordSuggestion] = []
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    convenience init() {
        self.init(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                  styleMask: [.borderless],
                  backing: .buffered,
                  defer: false)
    }

    // Override these properties to prevent the window from becoming key or main
    override var canBecomeKey: Bool {
        return false
    }

    override var canBecomeMain: Bool {
        return false
    }

    private func setupWindow() {
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = NSWindow.Level.floating
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        
        // Create background view with blur effect
        backgroundView = NSVisualEffectView()
        backgroundView.material = .hudWindow
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 12
        backgroundView.layer?.masksToBounds = true
        
        // Create container view
        containerView = NSView()
        containerView.wantsLayer = true
        
        backgroundView.addSubview(containerView)
        self.contentView = backgroundView
        
        // Auto layout
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -8)
        ])
    }
    
    func showSuggestions(_ suggestions: [WordSuggestion], at location: CGPoint) {
        // Store current suggestions
        currentSuggestions = suggestions
        
        // Clear existing buttons
        suggestionButtons.forEach { $0.removeFromSuperview() }
        suggestionButtons.removeAll()
        
        guard !suggestions.isEmpty else {
            orderOut(nil)
            return
        }
        
        // Create title label
        let titleLabel = NSTextField(labelWithString: "Word Suggestions")
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.alignment = .center
        containerView.addSubview(titleLabel)
        
        // Create suggestion buttons
        var previousView: NSView = titleLabel
        
        for (index, suggestion) in suggestions.enumerated() {
            let button = createSuggestionButton(for: suggestion, index: index)
            suggestionButtons.append(button)
            containerView.addSubview(button)
            
            // Set up constraints
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                button.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 4),
                button.heightAnchor.constraint(equalToConstant: 28)
            ])
            
            previousView = button
        }
        
        // Set up title label constraints
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Final constraint for the last button
        if let lastButton = suggestionButtons.last {
            lastButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        }
        
        // Calculate window size based on content
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 20 + CGFloat(suggestions.count * 32) + 16 // title + buttons + padding
        
        // Position window near the text location
        var windowOrigin = location
        
        // Get screen bounds to ensure window is visible
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            // Adjust position if window would go off screen
            if windowOrigin.x + windowWidth > screenFrame.maxX {
                windowOrigin.x = screenFrame.maxX - windowWidth
            }
            if windowOrigin.x < screenFrame.minX {
                windowOrigin.x = screenFrame.minX
            }
            
            if windowOrigin.y - windowHeight < screenFrame.minY {
                windowOrigin.y = location.y + 30 // Show below instead of above
            } else {
                windowOrigin.y = windowOrigin.y - windowHeight // Show above
            }
        }
        
        // Set window frame and show
        let windowFrame = NSRect(x: windowOrigin.x, y: windowOrigin.y, width: windowWidth, height: windowHeight)
        self.setFrame(windowFrame, display: true)
        self.orderFront(nil)
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.orderOut(nil)
        }
    }
    
    private func createSuggestionButton(for suggestion: WordSuggestion, index: Int) -> NSButton {
        let button = NSButton()
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        
        // Create attributed string with word and type
        let attributedTitle = NSMutableAttributedString()
        
        // Main word
        let wordAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        attributedTitle.append(NSAttributedString(string: suggestion.word, attributes: wordAttributes))
        
        // Type indicator
        let typeString = " • \(typeDisplayName(for: suggestion.type))"
        let typeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: colorForType(suggestion.type)
        ]
        attributedTitle.append(NSAttributedString(string: typeString, attributes: typeAttributes))
        
        button.attributedTitle = attributedTitle
        button.alignment = .left
        button.contentTintColor = NSColor.controlAccentColor
        
        // Button action
        button.target = self
        button.action = #selector(suggestionButtonClicked(_:))
        button.tag = index
        
        // Hover effect
        let trackingArea = NSTrackingArea(rect: button.bounds,
                                        options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                        owner: self,
                                        userInfo: ["button": button])
        button.addTrackingArea(trackingArea)
        
        return button
    }
    
    @objc private func suggestionButtonClicked(_ sender: NSButton) {
        guard sender.tag < suggestionButtons.count,
              let suggestion = getSuggestionForButton(sender) else { return }
        
        // Copy suggestion to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(suggestion.word, forType: .string)
        
        // Visual feedback
        sender.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sender.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        // Hide window after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.orderOut(nil)
        }
        
        // Show notification
        showCopiedNotification(for: suggestion.word)
    }
    
    private func getSuggestionForButton(_ button: NSButton) -> WordSuggestion? {
        guard button.tag < currentSuggestions.count else { return nil }
        return currentSuggestions[button.tag]
    }
    
    private func typeDisplayName(for type: WordSuggestion.SuggestionType) -> String {
        switch type {
        case .synonym: return "Synonym"
        case .alternative: return "Alternative"
        case .related: return "Related"
        case .rhyme: return "Rhyme"
        }
    }
    
    private func colorForType(_ type: WordSuggestion.SuggestionType) -> NSColor {
        switch type {
        case .synonym: return NSColor.systemBlue
        case .alternative: return NSColor.systemGreen
        case .related: return NSColor.systemOrange
        case .rhyme: return NSColor.systemPurple
        }
    }
    
    private func showCopiedNotification(for word: String) {
        let notification = NSUserNotification()
        notification.title = "Word Copied"
        notification.informativeText = "'\(word)' copied to clipboard"
        notification.soundName = nil
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo,
           let button = userInfo["button"] as? NSButton {
            button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo,
           let button = userInfo["button"] as? NSButton {
            button.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
    
    override func resignKey() {
        super.resignKey()
        // Hide window when it loses focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.orderOut(nil)
        }
    }
}
