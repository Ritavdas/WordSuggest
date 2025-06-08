// Bug Fixes and Improvements for WordSuggest
// This file contains suggested improvements and fixes for the identified issues

import Foundation
import Cocoa

// MARK: - Improved Error Handling

extension WordSuggestionService {
    
    /// Enhanced error handling for network requests
    private func makeNetworkRequest(with request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                completion(.failure(NetworkError.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    /// Custom error types for better error handling
    enum NetworkError: Error, LocalizedError {
        case invalidResponse
        case httpError(Int)
        case noData
        case jsonParsingError
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response received from server"
            case .httpError(let code):
                return "HTTP error with status code: \(code)"
            case .noData:
                return "No data received from server"
            case .jsonParsingError:
                return "Failed to parse JSON response"
            }
        }
    }
}

// MARK: - Input Validation and Sanitization

extension WordSuggestionService {
    
    /// Validate and sanitize input text
    private func validateAndSanitizeInput(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty input
        guard !trimmed.isEmpty else { return nil }
        
        // Check for reasonable length (prevent abuse)
        guard trimmed.count <= 100 else { return String(trimmed.prefix(100)) }
        
        // Remove potentially harmful characters
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        let sanitized = trimmed.components(separatedBy: allowedCharacters.inverted).joined()
        
        return sanitized.isEmpty ? nil : sanitized
    }
    
    /// Enhanced getSuggestions with better input validation
    func getSuggestionsImproved(for text: String, completion: @escaping ([WordSuggestion]) -> Void) {
        // Validate and sanitize input
        guard let cleanText = validateAndSanitizeInput(text) else {
            completion([])
            return
        }
        
        // Rate limiting check (prevent API abuse)
        if !rateLimiter.canMakeRequest() {
            getBuiltInSuggestions(for: cleanText, completion: completion)
            return
        }
        
        if openAIAPIKey.isEmpty {
            getBuiltInSuggestions(for: cleanText, completion: completion)
            return
        }
        
        getOpenAISuggestions(for: cleanText, completion: completion)
    }
}

// MARK: - Rate Limiting

class RateLimiter {
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    private var requestTimes: [Date] = []
    private let queue = DispatchQueue(label: "rate.limiter", attributes: .concurrent)
    
    init(maxRequests: Int = 10, timeWindow: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.timeWindow = timeWindow
    }
    
    func canMakeRequest() -> Bool {
        return queue.sync {
            let now = Date()
            let cutoff = now.addingTimeInterval(-timeWindow)
            
            // Remove old requests
            requestTimes = requestTimes.filter { $0 > cutoff }
            
            if requestTimes.count < maxRequests {
                requestTimes.append(now)
                return true
            }
            
            return false
        }
    }
}

// MARK: - Enhanced Text Processing

extension TextMonitor {
    
    /// Improved text extraction with better error handling
    private func getSelectedTextImproved(completion: @escaping (String?, CGPoint) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var selectedText: String?
            var location = CGPoint.zero
            
            // Check accessibility permissions first
            guard AXIsProcessTrusted() else {
                DispatchQueue.main.async {
                    completion(nil, location)
                }
                return
            }
            
            // Get the currently focused application
            guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
                DispatchQueue.main.async {
                    completion(nil, location)
                }
                return
            }
            
            let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
            
            // Get focused UI element with timeout
            var focusedElement: CFTypeRef?
            let focusedResult = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
            
            if focusedResult == .success, let element = focusedElement {
                let uiElement = element as! AXUIElement
                
                // Try to get selected text with timeout
                selectedText = self.extractSelectedText(from: uiElement)
                location = self.extractElementPosition(from: uiElement)
            }
            
            // Fallback to clipboard method if needed
            if selectedText?.isEmpty ?? true {
                self.copySelectedTextImproved { clipboardText in
                    selectedText = clipboardText
                }
            }
            
            DispatchQueue.main.async {
                completion(selectedText, location)
            }
        }
    }
    
    /// Extract selected text with error handling
    private func extractSelectedText(from element: AXUIElement) -> String? {
        var selectedTextValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedTextValue)
        
        guard result == .success,
              let textValue = selectedTextValue as? String,
              !textValue.isEmpty else {
            return nil
        }
        
        return textValue
    }
    
    /// Extract element position with error handling
    private func extractElementPosition(from element: AXUIElement) -> CGPoint {
        var positionValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        
        guard result == .success,
              let position = positionValue else {
            return CGPoint.zero
        }
        
        var point = CGPoint.zero
        if AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &point) {
            return point
        }
        
        return CGPoint.zero
    }
    
    /// Improved clipboard copying with better restoration
    private func copySelectedTextImproved(completion: @escaping (String?) -> Void) {
        let pasteboard = NSPasteboard.general
        
        // Store current clipboard content with type information
        let previousContents = pasteboard.pasteboardItems?.first?.data(forType: .string)
        let previousString = pasteboard.string(forType: .string)
        
        // Clear clipboard
        pasteboard.clearContents()
        
        // Simulate Cmd+C with proper event timing
        let source = CGEventSource(stateID: .hidSystemState)
        
        let cmdCDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        cmdCDown?.flags = .maskCommand
        cmdCDown?.post(tap: .cghidEventTap)
        
        let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        cmdCUp?.post(tap: .cghidEventTap)
        
        // Wait for clipboard to update with exponential backoff
        var attempts = 0
        let maxAttempts = 5
        
        func checkClipboard() {
            attempts += 1
            let copiedText = pasteboard.string(forType: .string)
            
            if copiedText != previousString || attempts >= maxAttempts {
                // Restore previous clipboard content
                if let previous = previousString, copiedText != previous {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pasteboard.clearContents()
                        pasteboard.setString(previous, forType: .string)
                    }
                }
                completion(copiedText)
            } else {
                // Exponential backoff
                let delay = 0.05 * pow(2.0, Double(attempts - 1))
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    checkClipboard()
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            checkClipboard()
        }
    }
}

// MARK: - Enhanced Window Management

extension SuggestionWindow {
    
    /// Improved window positioning with multi-screen support
    private func calculateOptimalPosition(for location: CGPoint, windowSize: NSSize) -> NSPoint {
        // Get the screen containing the location
        let screens = NSScreen.screens
        var targetScreen = NSScreen.main
        
        for screen in screens {
            if screen.frame.contains(location) {
                targetScreen = screen
                break
            }
        }
        
        guard let screen = targetScreen else {
            return location
        }
        
        let screenFrame = screen.visibleFrame
        var windowOrigin = location
        
        // Adjust horizontal position
        if windowOrigin.x + windowSize.width > screenFrame.maxX {
            windowOrigin.x = screenFrame.maxX - windowSize.width
        }
        if windowOrigin.x < screenFrame.minX {
            windowOrigin.x = screenFrame.minX
        }
        
        // Adjust vertical position (prefer showing above the cursor)
        if windowOrigin.y - windowSize.height < screenFrame.minY {
            // Show below if not enough space above
            windowOrigin.y = location.y + 30
        } else {
            // Show above
            windowOrigin.y = windowOrigin.y - windowSize.height - 10
        }
        
        // Final bounds check
        if windowOrigin.y + windowSize.height > screenFrame.maxY {
            windowOrigin.y = screenFrame.maxY - windowSize.height
        }
        if windowOrigin.y < screenFrame.minY {
            windowOrigin.y = screenFrame.minY
        }
        
        return windowOrigin
    }
    
    /// Enhanced suggestion display with animations
    func showSuggestionsImproved(_ suggestions: [WordSuggestion], at location: CGPoint) {
        // Store current suggestions
        currentSuggestions = suggestions
        
        // Clear existing buttons
        suggestionButtons.forEach { $0.removeFromSuperview() }
        suggestionButtons.removeAll()
        
        guard !suggestions.isEmpty else {
            hideWithAnimation()
            return
        }
        
        // Create UI elements
        setupSuggestionUI(suggestions)
        
        // Calculate optimal window size and position
        let windowSize = calculateWindowSize(for: suggestions)
        let optimalPosition = calculateOptimalPosition(for: location, windowSize: windowSize)
        
        // Set window frame
        let windowFrame = NSRect(origin: optimalPosition, size: windowSize)
        self.setFrame(windowFrame, display: false)
        
        // Show with animation
        showWithAnimation()
        
        // Auto-hide with longer delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
            self?.hideWithAnimation()
        }
    }
    
    /// Calculate optimal window size based on content
    private func calculateWindowSize(for suggestions: [WordSuggestion]) -> NSSize {
        let baseWidth: CGFloat = 320
        let baseHeight: CGFloat = 28 + CGFloat(suggestions.count * 32) + 16
        
        // Adjust width based on longest suggestion
        let maxWordLength = suggestions.map { $0.word.count }.max() ?? 0
        let adjustedWidth = max(baseWidth, CGFloat(maxWordLength * 8 + 100))
        
        return NSSize(width: min(adjustedWidth, 400), height: min(baseHeight, 300))
    }
    
    /// Show window with fade-in animation
    private func showWithAnimation() {
        self.alphaValue = 0.0
        self.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }
    }
    
    /// Hide window with fade-out animation
    private func hideWithAnimation() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }) { [weak self] in
            self?.orderOut(nil)
            self?.alphaValue = 1.0
        }
    }
}

// MARK: - Performance Optimizations

extension WordSuggestionService {
    
    /// Cache for frequently requested suggestions
    private static let suggestionCache = NSCache<NSString, NSArray>()
    
    /// Get suggestions with caching
    func getCachedSuggestions(for text: String, completion: @escaping ([WordSuggestion]) -> Void) {
        let cacheKey = text.lowercased() as NSString
        
        // Check cache first
        if let cachedSuggestions = Self.suggestionCache.object(forKey: cacheKey) as? [WordSuggestion] {
            completion(cachedSuggestions)
            return
        }
        
        // Get fresh suggestions
        getSuggestionsImproved(for: text) { suggestions in
            // Cache the results
            Self.suggestionCache.setObject(suggestions as NSArray, forKey: cacheKey)
            completion(suggestions)
        }
    }
}

// MARK: - Accessibility Improvements

extension AppDelegate {
    
    /// Enhanced accessibility permission handling
    private func requestAccessibilityPermissionsImproved() {
        let trusted = AXIsProcessTrusted()
        
        if !trusted {
            // Create more informative alert
            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = """
            WordSuggest needs accessibility access to monitor text selection across all applications.
            
            This permission allows the app to:
            • Detect when you select text
            • Read the selected text for suggestions
            • Position the suggestion window correctly
            
            Your privacy is protected - text is only processed when you press Cmd+Shift+W.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Learn More")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                // Open System Preferences
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            case .alertSecondButtonReturn:
                // Show more information
                showAccessibilityHelp()
            default:
                break
            }
        }
    }
    
    /// Show detailed accessibility help
    private func showAccessibilityHelp() {
        let alert = NSAlert()
        alert.messageText = "How to Grant Accessibility Access"
        alert.informativeText = """
        1. Open System Preferences
        2. Go to Security & Privacy
        3. Click the Privacy tab
        4. Select Accessibility from the list
        5. Click the lock icon and enter your password
        6. Check the box next to WordSuggest
        7. Restart WordSuggest
        
        This permission is required for WordSuggest to function properly.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
