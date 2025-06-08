import Cocoa
import Carbon

protocol HotkeyRecorderDelegate: AnyObject {
    func hotkeyRecorder(_ recorder: HotkeyRecorderView, didChangeHotkey hotkey: Hotkey?)
}

struct Hotkey: Equatable {
    let keyCode: UInt16
    let modifierFlags: NSEvent.ModifierFlags
    
    var displayString: String {
        var parts: [String] = []
        
        if modifierFlags.contains(.control) { parts.append("⌃") }
        if modifierFlags.contains(.option) { parts.append("⌥") }
        if modifierFlags.contains(.shift) { parts.append("⇧") }
        if modifierFlags.contains(.command) { parts.append("⌘") }
        
        if let keyString = keyCodeToString(keyCode) {
            parts.append(keyString)
        }
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
            39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "⇥", 49: "Space", 50: "`", 51: "⌫", 53: "⎋", 65: ".", 67: "*", 69: "+",
            71: "⌧", 75: "/", 76: "↩", 78: "-", 81: "=", 82: "0", 83: "1", 84: "2", 85: "3",
            86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9", 96: "F5", 97: "F6", 98: "F7",
            99: "F3", 100: "F8", 101: "F9", 103: "F11", 109: "F10", 111: "F12",
            105: "F13", 107: "F14", 113: "F15", 114: "Help", 115: "Home", 116: "⇞", 117: "⌦",
            118: "F4", 119: "End", 120: "F2", 121: "⇟", 122: "F1", 123: "←", 124: "→",
            125: "↓", 126: "↑"
        ]
        
        return keyMap[keyCode]
    }
}

// MARK: - Codable Implementation
extension Hotkey: Codable {
    enum CodingKeys: String, CodingKey {
        case keyCode
        case modifierFlags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(UInt16.self, forKey: .keyCode)
        let rawValue = try container.decode(UInt.self, forKey: .modifierFlags)
        modifierFlags = NSEvent.ModifierFlags(rawValue: rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifierFlags.rawValue, forKey: .modifierFlags)
    }
}

class HotkeyRecorderView: NSView {
    weak var delegate: HotkeyRecorderDelegate?
    
    private var currentHotkey: Hotkey?
    private var isRecording = false
    private var eventMonitor: Any?
    
    private let borderLayer = CALayer()
    private let textLayer = CATextLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        
        // Configure border layer
        borderLayer.borderWidth = 2.0
        borderLayer.cornerRadius = 8.0
        borderLayer.borderColor = NSColor.controlAccentColor.cgColor
        layer?.addSublayer(borderLayer)
        
        // Configure text layer
        textLayer.fontSize = 14.0
        textLayer.alignmentMode = .center
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        textLayer.foregroundColor = NSColor.labelColor.cgColor
        layer?.addSublayer(textLayer)
        
        updateDisplay()
    }
    
    override func layout() {
        super.layout()
        
        borderLayer.frame = bounds
        textLayer.frame = bounds
    }
    
    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            startRecording()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if isRecording {
            recordHotkey(event)
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        updateDisplay()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        stopRecording()
        updateDisplay()
        return super.resignFirstResponder()
    }
    
    func setHotkey(_ hotkey: Hotkey?) {
        currentHotkey = hotkey
        updateDisplay()
    }
    
    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        
        // Monitor for escape key to cancel recording
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.stopRecording()
                return nil
            }
            return event
        }
        
        updateDisplay()
    }
    
    private func stopRecording() {
        isRecording = false
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        updateDisplay()
    }
    
    private func recordHotkey(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])
        
        // Require at least one modifier key
        guard !modifiers.isEmpty else {
            NSSound.beep()
            return
        }
        
        let hotkey = Hotkey(keyCode: event.keyCode, modifierFlags: modifiers)
        currentHotkey = hotkey
        
        stopRecording()
        delegate?.hotkeyRecorder(self, didChangeHotkey: hotkey)
    }
    
    private func updateDisplay() {
        let text: String
        let textColor: NSColor
        let borderColor: NSColor
        
        if isRecording {
            text = "Press hotkey combination..."
            textColor = .secondaryLabelColor
            borderColor = .controlAccentColor
        } else if let hotkey = currentHotkey {
            text = hotkey.displayString
            textColor = .labelColor
            borderColor = .separatorColor
        } else {
            text = "Click to set hotkey"
            textColor = .secondaryLabelColor
            borderColor = .separatorColor
        }
        
        textLayer.string = text
        textLayer.foregroundColor = textColor.cgColor
        borderLayer.borderColor = borderColor.cgColor
        
        needsDisplay = true
    }
}
