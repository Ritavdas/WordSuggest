import Cocoa
import ApplicationServices
import Carbon

protocol TextMonitorDelegate: AnyObject {
    func textSelectionDetected(_ selectedText: String, at location: CGPoint)
}

class TextMonitor {
    weak var delegate: TextMonitorDelegate?
    private var eventMonitor: Any?
    private var hotKeyEventHandler: EventHandlerUPP?
    private var hotKeyRef: EventHotKeyRef?
    
    func startMonitoring() {
        setupGlobalKeyMonitor()
        setupHotKey()
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        if hotKeyRef != nil {
            UnregisterEventHotKey(hotKeyRef!)
            hotKeyRef = nil
        }
    }
    
    private func setupGlobalKeyMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            // This monitors key events globally but we'll primarily use the hot key
        }
    }
    
    private func setupHotKey() {
        updateHotkey(UserSettings.shared.hotkey)
    }

    func updateHotkey(_ hotkey: Hotkey?) {
        // Unregister existing hotkey
        if hotKeyRef != nil {
            UnregisterEventHotKey(hotKeyRef!)
            hotKeyRef = nil
        }

        guard let hotkey = hotkey else { return }

        let hotKeySignature = FourCharCode(bitPattern: 0x574F5244) // 'WORD'
        let hotKeyID = UInt32(1)

        let keyCode = UInt32(hotkey.keyCode)
        var modifiers: UInt32 = 0

        if hotkey.modifierFlags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if hotkey.modifierFlags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if hotkey.modifierFlags.contains(.option) { modifiers |= UInt32(optionKey) }
        if hotkey.modifierFlags.contains(.control) { modifiers |= UInt32(controlKey) }

        var hotKeyEventType = EventTypeSpec()
        hotKeyEventType.eventClass = OSType(kEventClassKeyboard)
        hotKeyEventType.eventKind = OSType(kEventHotKeyPressed)

        hotKeyEventHandler = { (nextHandler, theEvent, userData) -> OSStatus in
            let monitor = Unmanaged<TextMonitor>.fromOpaque(userData!).takeUnretainedValue()
            monitor.handleHotKeyPressed()
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(),
                          hotKeyEventHandler!,
                          1,
                          &hotKeyEventType,
                          Unmanaged.passUnretained(self).toOpaque(),
                          nil)

        RegisterEventHotKey(keyCode,
                          modifiers,
                          EventHotKeyID(signature: hotKeySignature, id: hotKeyID),
                          GetApplicationEventTarget(),
                          0,
                          &hotKeyRef)
    }
    
    private func handleHotKeyPressed() {
        getSelectedText { [weak self] selectedText, location in
            if let text = selectedText, !text.isEmpty {
                self?.delegate?.textSelectionDetected(text, at: location)
            }
        }
    }
    
    private func getSelectedText(completion: @escaping (String?, CGPoint) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var selectedText: String?
            var location = CGPoint.zero
            
            // Get the currently focused application
            guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
                DispatchQueue.main.async {
                    completion(nil, location)
                }
                return
            }
            
            let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
            
            // Get focused UI element
            var focusedElement: CFTypeRef?
            let focusedResult = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
            
            if focusedResult == .success, let element = focusedElement {
                let uiElement = element as! AXUIElement
                
                // Try to get selected text
                var selectedTextValue: CFTypeRef?
                let selectedTextResult = AXUIElementCopyAttributeValue(uiElement, kAXSelectedTextAttribute as CFString, &selectedTextValue)
                
                if selectedTextResult == .success, let textValue = selectedTextValue as? String, !textValue.isEmpty {
                    selectedText = textValue
                } else {
                    // Fallback: simulate Cmd+C to get clipboard content
                    self.copySelectedText { clipboardText in
                        selectedText = clipboardText
                    }
                }
                
                // Get position of the element
                var positionValue: CFTypeRef?
                let positionResult = AXUIElementCopyAttributeValue(uiElement, kAXPositionAttribute as CFString, &positionValue)
                
                if positionResult == .success, let position = positionValue {
                    var point = CGPoint.zero
                    if AXValueGetValue(position as! AXValue, AXValueType.cgPoint, &point) {
                        location = point
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(selectedText, location)
            }
        }
    }
    
    private func copySelectedText(completion: @escaping (String?) -> Void) {
        // Store current clipboard content
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        
        // Clear clipboard
        pasteboard.clearContents()
        
        // Simulate Cmd+C
        let cmdCEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        cmdCEvent?.flags = .maskCommand
        cmdCEvent?.post(tap: .cghidEventTap)
        
        let cmdCUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        cmdCUpEvent?.post(tap: .cghidEventTap)
        
        // Wait a moment for clipboard to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let copiedText = pasteboard.string(forType: .string)
            
            // Restore previous clipboard content if we got something
            if let previous = previousContents, copiedText != previous {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                }
            }
            
            completion(copiedText)
        }
    }
}
