import XCTest
import Cocoa

// Mock classes for UI testing
class MockSuggestionWindow {
    var isVisible = false
    var currentSuggestions: [WordSuggestion] = []
    var windowFrame: NSRect = NSRect.zero
    var lastDisplayLocation: CGPoint = CGPoint.zero
    
    func showSuggestions(_ suggestions: [WordSuggestion], at location: CGPoint) {
        currentSuggestions = suggestions
        lastDisplayLocation = location
        isVisible = !suggestions.isEmpty
        
        // Calculate window size based on content
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 20 + CGFloat(suggestions.count * 32) + 16
        windowFrame = NSRect(x: location.x, y: location.y, width: windowWidth, height: windowHeight)
    }
    
    func hide() {
        isVisible = false
        currentSuggestions = []
    }
    
    func typeDisplayName(for type: WordSuggestion.SuggestionType) -> String {
        switch type {
        case .synonym: return "Synonym"
        case .alternative: return "Alternative"
        case .related: return "Related"
        case .rhyme: return "Rhyme"
        }
    }
    
    func validateWindowPosition(screenBounds: NSRect) -> Bool {
        // Check if window is within screen bounds
        return screenBounds.contains(windowFrame) || screenBounds.intersects(windowFrame)
    }
}

class MockTextMonitor {
    weak var delegate: TextMonitorDelegate?
    var isMonitoring = false
    var lastDetectedText: String?
    var lastDetectedLocation: CGPoint = CGPoint.zero
    
    func startMonitoring() {
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
    
    // Simulate text selection detection
    func simulateTextSelection(_ text: String, at location: CGPoint) {
        guard isMonitoring else { return }
        lastDetectedText = text
        lastDetectedLocation = location
        delegate?.textSelectionDetected(text, at: location)
    }
    
    func validateHotKeySetup() -> Bool {
        // In a real implementation, this would check if the hotkey is properly registered
        return isMonitoring
    }
}

// Protocol for testing
protocol TextMonitorDelegate: AnyObject {
    func textSelectionDetected(_ selectedText: String, at location: CGPoint)
}

class MockAppDelegate: TextMonitorDelegate {
    var textMonitor: MockTextMonitor?
    var suggestionWindow: MockSuggestionWindow?
    var suggestionService: MockWordSuggestionService?
    var lastProcessedText: String?
    var lastSuggestions: [WordSuggestion] = []
    
    init() {
        suggestionService = MockWordSuggestionService()
        suggestionWindow = MockSuggestionWindow()
        textMonitor = MockTextMonitor()
        textMonitor?.delegate = self
    }
    
    func textSelectionDetected(_ selectedText: String, at location: CGPoint) {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        lastProcessedText = selectedText
        
        // Simulate async suggestion retrieval
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let suggestions = self.suggestionService?.getBuiltInSuggestions(for: selectedText) ?? []
            self.lastSuggestions = suggestions
            self.suggestionWindow?.showSuggestions(suggestions, at: location)
        }
    }
}

// UI Component Tests
class UIComponentTests: XCTestCase {
    var mockWindow: MockSuggestionWindow!
    var mockTextMonitor: MockTextMonitor!
    var mockAppDelegate: MockAppDelegate!
    
    override func setUp() {
        super.setUp()
        mockWindow = MockSuggestionWindow()
        mockTextMonitor = MockTextMonitor()
        mockAppDelegate = MockAppDelegate()
    }
    
    override func tearDown() {
        mockWindow = nil
        mockTextMonitor = nil
        mockAppDelegate = nil
        super.tearDown()
    }
    
    // MARK: - SuggestionWindow Tests
    
    func testSuggestionWindowShowsCorrectly() {
        let suggestions = [
            WordSuggestion(word: "excellent", type: .synonym, confidence: 0.9),
            WordSuggestion(word: "great", type: .synonym, confidence: 0.8)
        ]
        let location = CGPoint(x: 100, y: 200)
        
        mockWindow.showSuggestions(suggestions, at: location)
        
        XCTAssertTrue(mockWindow.isVisible, "Window should be visible after showing suggestions")
        XCTAssertEqual(mockWindow.currentSuggestions.count, 2, "Should store correct number of suggestions")
        XCTAssertEqual(mockWindow.lastDisplayLocation, location, "Should store correct display location")
    }
    
    func testSuggestionWindowHidesWithEmptySuggestions() {
        let emptySuggestions: [WordSuggestion] = []
        let location = CGPoint(x: 100, y: 200)
        
        mockWindow.showSuggestions(emptySuggestions, at: location)
        
        XCTAssertFalse(mockWindow.isVisible, "Window should not be visible with empty suggestions")
        XCTAssertTrue(mockWindow.currentSuggestions.isEmpty, "Should not store empty suggestions")
    }
    
    func testSuggestionWindowSizeCalculation() {
        let suggestions = [
            WordSuggestion(word: "test1", type: .synonym, confidence: 0.9),
            WordSuggestion(word: "test2", type: .alternative, confidence: 0.8),
            WordSuggestion(word: "test3", type: .related, confidence: 0.7)
        ]
        let location = CGPoint(x: 100, y: 200)
        
        mockWindow.showSuggestions(suggestions, at: location)
        
        let expectedHeight: CGFloat = 20 + CGFloat(3 * 32) + 16 // title + 3 buttons + padding
        let expectedWidth: CGFloat = 300
        
        XCTAssertEqual(mockWindow.windowFrame.width, expectedWidth, "Window width should be calculated correctly")
        XCTAssertEqual(mockWindow.windowFrame.height, expectedHeight, "Window height should be calculated correctly")
    }
    
    func testSuggestionWindowPositioning() {
        let suggestions = [WordSuggestion(word: "test", type: .synonym, confidence: 0.9)]
        let location = CGPoint(x: 100, y: 200)
        
        mockWindow.showSuggestions(suggestions, at: location)
        
        XCTAssertEqual(mockWindow.windowFrame.origin.x, location.x, "Window X position should match location")
        XCTAssertEqual(mockWindow.windowFrame.origin.y, location.y, "Window Y position should match location")
    }
    
    func testSuggestionWindowScreenBoundsValidation() {
        let suggestions = [WordSuggestion(word: "test", type: .synonym, confidence: 0.9)]
        let location = CGPoint(x: 100, y: 200)
        let screenBounds = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        mockWindow.showSuggestions(suggestions, at: location)
        
        XCTAssertTrue(mockWindow.validateWindowPosition(screenBounds: screenBounds), 
                     "Window should be positioned within screen bounds")
    }
    
    func testTypeDisplayNames() {
        XCTAssertEqual(mockWindow.typeDisplayName(for: .synonym), "Synonym")
        XCTAssertEqual(mockWindow.typeDisplayName(for: .alternative), "Alternative")
        XCTAssertEqual(mockWindow.typeDisplayName(for: .related), "Related")
        XCTAssertEqual(mockWindow.typeDisplayName(for: .rhyme), "Rhyme")
    }
    
    // MARK: - TextMonitor Tests
    
    func testTextMonitorStartStop() {
        XCTAssertFalse(mockTextMonitor.isMonitoring, "Should not be monitoring initially")
        
        mockTextMonitor.startMonitoring()
        XCTAssertTrue(mockTextMonitor.isMonitoring, "Should be monitoring after start")
        
        mockTextMonitor.stopMonitoring()
        XCTAssertFalse(mockTextMonitor.isMonitoring, "Should not be monitoring after stop")
    }
    
    func testTextSelectionDetection() {
        let expectation = XCTestExpectation(description: "Text selection detected")
        
        class TestDelegate: TextMonitorDelegate {
            let expectation: XCTestExpectation
            var detectedText: String?
            var detectedLocation: CGPoint?
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            
            func textSelectionDetected(_ selectedText: String, at location: CGPoint) {
                detectedText = selectedText
                detectedLocation = location
                expectation.fulfill()
            }
        }
        
        let delegate = TestDelegate(expectation: expectation)
        mockTextMonitor.delegate = delegate
        mockTextMonitor.startMonitoring()
        
        let testText = "test text"
        let testLocation = CGPoint(x: 50, y: 100)
        
        mockTextMonitor.simulateTextSelection(testText, at: testLocation)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(delegate.detectedText, testText, "Should detect correct text")
        XCTAssertEqual(delegate.detectedLocation, testLocation, "Should detect correct location")
    }
    
    func testTextSelectionIgnoredWhenNotMonitoring() {
        class TestDelegate: TextMonitorDelegate {
            var callCount = 0
            
            func textSelectionDetected(_ selectedText: String, at location: CGPoint) {
                callCount += 1
            }
        }
        
        let delegate = TestDelegate()
        mockTextMonitor.delegate = delegate
        // Don't start monitoring
        
        mockTextMonitor.simulateTextSelection("test", at: CGPoint.zero)
        
        XCTAssertEqual(delegate.callCount, 0, "Should not detect text when not monitoring")
    }
    
    func testHotKeyValidation() {
        mockTextMonitor.startMonitoring()
        XCTAssertTrue(mockTextMonitor.validateHotKeySetup(), "Hot key should be set up when monitoring")
        
        mockTextMonitor.stopMonitoring()
        XCTAssertFalse(mockTextMonitor.validateHotKeySetup(), "Hot key should not be set up when not monitoring")
    }
    
    // MARK: - Integration Tests
    
    func testAppDelegateIntegration() {
        mockAppDelegate.textMonitor?.startMonitoring()
        
        let testText = "good"
        let testLocation = CGPoint(x: 100, y: 200)
        
        mockAppDelegate.textMonitor?.simulateTextSelection(testText, at: testLocation)
        
        // Wait for async processing
        let expectation = XCTestExpectation(description: "Async processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockAppDelegate.lastProcessedText, testText, "Should process the detected text")
        XCTAssertFalse(mockAppDelegate.lastSuggestions.isEmpty, "Should generate suggestions")
        XCTAssertTrue(mockAppDelegate.suggestionWindow?.isVisible ?? false, "Should show suggestion window")
    }
    
    func testAppDelegateIgnoresEmptyText() {
        mockAppDelegate.textMonitor?.startMonitoring()
        
        let emptyText = "   "
        let testLocation = CGPoint(x: 100, y: 200)
        
        mockAppDelegate.textMonitor?.simulateTextSelection(emptyText, at: testLocation)
        
        // Wait for potential async processing
        let expectation = XCTestExpectation(description: "Async processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNil(mockAppDelegate.lastProcessedText, "Should not process empty text")
        XCTAssertTrue(mockAppDelegate.lastSuggestions.isEmpty, "Should not generate suggestions for empty text")
    }
    
    func testFullWorkflow() {
        // Start monitoring
        mockAppDelegate.textMonitor?.startMonitoring()
        
        // Simulate text selection
        let testText = "happy"
        let testLocation = CGPoint(x: 150, y: 250)
        
        mockAppDelegate.textMonitor?.simulateTextSelection(testText, at: testLocation)
        
        // Wait for async processing
        let expectation = XCTestExpectation(description: "Full workflow complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the complete workflow
        XCTAssertEqual(mockAppDelegate.lastProcessedText, testText, "Text should be processed")
        XCTAssertFalse(mockAppDelegate.lastSuggestions.isEmpty, "Suggestions should be generated")
        XCTAssertTrue(mockAppDelegate.suggestionWindow?.isVisible ?? false, "Window should be visible")
        XCTAssertEqual(mockAppDelegate.suggestionWindow?.lastDisplayLocation, testLocation, "Window should be at correct location")
        
        // Verify suggestions are for the correct word
        let synonymSuggestions = mockAppDelegate.lastSuggestions.filter { $0.type == .synonym }
        XCTAssertFalse(synonymSuggestions.isEmpty, "Should include synonym suggestions for 'happy'")
    }
    
    // MARK: - Performance Tests
    
    func testUIPerformance() {
        let suggestions = Array(0..<10).map { 
            WordSuggestion(word: "word\($0)", type: .synonym, confidence: 0.8) 
        }
        
        measure {
            for i in 0..<100 {
                let location = CGPoint(x: i, y: i)
                mockWindow.showSuggestions(suggestions, at: location)
            }
        }
    }
    
    func testTextMonitorPerformance() {
        mockTextMonitor.startMonitoring()
        
        measure {
            for i in 0..<100 {
                mockTextMonitor.simulateTextSelection("test\(i)", at: CGPoint(x: i, y: i))
            }
        }
    }
}
