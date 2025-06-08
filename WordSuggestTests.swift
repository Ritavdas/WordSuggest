import XCTest
import Foundation

// Mock classes for testing
class MockWordSuggestionService {
    private let builtInSynonyms: [String: [String]] = [
        "good": ["excellent", "great", "wonderful", "fantastic", "superb"],
        "bad": ["terrible", "awful", "horrible", "poor", "dreadful"],
        "big": ["large", "huge", "enormous", "massive", "gigantic"],
        "small": ["tiny", "little", "minute", "petite", "compact"],
        "fast": ["quick", "rapid", "swift", "speedy", "hasty"],
        "slow": ["gradual", "leisurely", "sluggish", "unhurried", "deliberate"],
        "happy": ["joyful", "cheerful", "delighted", "elated", "content"],
        "sad": ["sorrowful", "melancholy", "dejected", "gloomy", "mournful"]
    ]
    
    func getBuiltInSuggestions(for text: String) -> [WordSuggestion] {
        var suggestions: [WordSuggestion] = []
        let lowercaseText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for exact matches
        if let synonyms = builtInSynonyms[lowercaseText] {
            suggestions = synonyms.prefix(5).map { 
                WordSuggestion(word: $0, type: .synonym, confidence: 0.8) 
            }
        }
        
        // Look for partial matches
        if suggestions.isEmpty {
            for (key, synonyms) in builtInSynonyms {
                if key.contains(lowercaseText) || lowercaseText.contains(key) {
                    suggestions = synonyms.prefix(3).map { 
                        WordSuggestion(word: $0, type: .related, confidence: 0.6) 
                    }
                    break
                }
            }
        }
        
        // Add general alternatives if needed
        if suggestions.count < 3 {
            let generalAlternatives = ["alternative", "option", "choice", "variant", "substitute"]
            for alt in generalAlternatives.prefix(5 - suggestions.count) {
                suggestions.append(WordSuggestion(word: alt, type: .alternative, confidence: 0.4))
            }
        }
        
        return suggestions
    }
    
    func validateOpenAIResponse(_ jsonString: String) -> [WordSuggestion]? {
        guard let jsonData = jsonString.data(using: .utf8),
              let suggestions = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            return nil
        }
        
        return suggestions.compactMap { dict -> WordSuggestion? in
            guard let word = dict["word"] as? String,
                  let typeString = dict["type"] as? String,
                  let confidence = dict["confidence"] as? Double else {
                return nil
            }
            
            let type: WordSuggestion.SuggestionType
            switch typeString {
            case "synonym": type = .synonym
            case "alternative": type = .alternative
            case "related": type = .related
            default: type = .alternative
            }
            
            return WordSuggestion(word: word, type: type, confidence: confidence)
        }
    }
}

// Test cases
class WordSuggestTests: XCTestCase {
    var mockService: MockWordSuggestionService!
    
    override func setUp() {
        super.setUp()
        mockService = MockWordSuggestionService()
    }
    
    override func tearDown() {
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - WordSuggestion Model Tests
    
    func testWordSuggestionCreation() {
        let suggestion = WordSuggestion(word: "excellent", type: .synonym, confidence: 0.9)
        
        XCTAssertEqual(suggestion.word, "excellent")
        XCTAssertEqual(suggestion.type, .synonym)
        XCTAssertEqual(suggestion.confidence, 0.9)
    }
    
    func testSuggestionTypes() {
        let synonym = WordSuggestion(word: "great", type: .synonym, confidence: 0.8)
        let alternative = WordSuggestion(word: "option", type: .alternative, confidence: 0.7)
        let related = WordSuggestion(word: "similar", type: .related, confidence: 0.6)
        let rhyme = WordSuggestion(word: "mood", type: .rhyme, confidence: 0.5)
        
        XCTAssertEqual(synonym.type, .synonym)
        XCTAssertEqual(alternative.type, .alternative)
        XCTAssertEqual(related.type, .related)
        XCTAssertEqual(rhyme.type, .rhyme)
    }
    
    // MARK: - Built-in Suggestion Tests
    
    func testBuiltInSuggestionsForKnownWord() {
        let suggestions = mockService.getBuiltInSuggestions(for: "good")
        
        XCTAssertFalse(suggestions.isEmpty, "Should return suggestions for known word")
        XCTAssertLessThanOrEqual(suggestions.count, 5, "Should not return more than 5 suggestions")
        
        // Check that all suggestions are synonyms with correct confidence
        for suggestion in suggestions {
            XCTAssertEqual(suggestion.type, .synonym)
            XCTAssertEqual(suggestion.confidence, 0.8)
            XCTAssertTrue(["excellent", "great", "wonderful", "fantastic", "superb"].contains(suggestion.word))
        }
    }
    
    func testBuiltInSuggestionsForUnknownWord() {
        let suggestions = mockService.getBuiltInSuggestions(for: "unknownword")
        
        XCTAssertFalse(suggestions.isEmpty, "Should return fallback suggestions for unknown word")
        XCTAssertGreaterThanOrEqual(suggestions.count, 3, "Should return at least 3 fallback suggestions")
        
        // Check that fallback suggestions are alternatives
        let alternativeSuggestions = suggestions.filter { $0.type == .alternative }
        XCTAssertFalse(alternativeSuggestions.isEmpty, "Should include alternative suggestions")
    }
    
    func testBuiltInSuggestionsWithWhitespace() {
        let suggestions = mockService.getBuiltInSuggestions(for: "  good  ")
        
        XCTAssertFalse(suggestions.isEmpty, "Should handle whitespace correctly")
        XCTAssertEqual(suggestions.first?.type, .synonym)
    }
    
    func testBuiltInSuggestionsWithCaseInsensitivity() {
        let lowercaseSuggestions = mockService.getBuiltInSuggestions(for: "good")
        let uppercaseSuggestions = mockService.getBuiltInSuggestions(for: "GOOD")
        let mixedCaseSuggestions = mockService.getBuiltInSuggestions(for: "Good")
        
        XCTAssertEqual(lowercaseSuggestions.count, uppercaseSuggestions.count)
        XCTAssertEqual(lowercaseSuggestions.count, mixedCaseSuggestions.count)
        
        // Check that the actual suggestions are the same
        let lowercaseWords = lowercaseSuggestions.map { $0.word }
        let uppercaseWords = uppercaseSuggestions.map { $0.word }
        let mixedCaseWords = mixedCaseSuggestions.map { $0.word }
        
        XCTAssertEqual(lowercaseWords, uppercaseWords)
        XCTAssertEqual(lowercaseWords, mixedCaseWords)
    }
    
    func testBuiltInSuggestionsForEmptyString() {
        let suggestions = mockService.getBuiltInSuggestions(for: "")
        
        XCTAssertFalse(suggestions.isEmpty, "Should return fallback suggestions for empty string")
        
        // Should return general alternatives
        let alternativeSuggestions = suggestions.filter { $0.type == .alternative }
        XCTAssertFalse(alternativeSuggestions.isEmpty, "Should include alternative suggestions for empty input")
    }
    
    // MARK: - OpenAI Response Validation Tests
    
    func testValidOpenAIResponse() {
        let validJSON = """
        [
            {"word": "excellent", "type": "synonym", "confidence": 0.9},
            {"word": "alternative", "type": "alternative", "confidence": 0.8},
            {"word": "related", "type": "related", "confidence": 0.7}
        ]
        """
        
        let suggestions = mockService.validateOpenAIResponse(validJSON)
        
        XCTAssertNotNil(suggestions, "Should parse valid JSON response")
        XCTAssertEqual(suggestions?.count, 3, "Should return 3 suggestions")
        
        if let suggestions = suggestions {
            XCTAssertEqual(suggestions[0].word, "excellent")
            XCTAssertEqual(suggestions[0].type, .synonym)
            XCTAssertEqual(suggestions[0].confidence, 0.9)
            
            XCTAssertEqual(suggestions[1].word, "alternative")
            XCTAssertEqual(suggestions[1].type, .alternative)
            XCTAssertEqual(suggestions[1].confidence, 0.8)
            
            XCTAssertEqual(suggestions[2].word, "related")
            XCTAssertEqual(suggestions[2].type, .related)
            XCTAssertEqual(suggestions[2].confidence, 0.7)
        }
    }
    
    func testInvalidOpenAIResponse() {
        let invalidJSON = "invalid json"
        let suggestions = mockService.validateOpenAIResponse(invalidJSON)
        
        XCTAssertNil(suggestions, "Should return nil for invalid JSON")
    }
    
    func testOpenAIResponseWithMissingFields() {
        let incompleteJSON = """
        [
            {"word": "excellent", "confidence": 0.9},
            {"type": "synonym", "confidence": 0.8}
        ]
        """
        
        let suggestions = mockService.validateOpenAIResponse(incompleteJSON)
        
        XCTAssertNotNil(suggestions, "Should handle incomplete entries")
        XCTAssertEqual(suggestions?.count, 0, "Should filter out incomplete entries")
    }
    
    func testOpenAIResponseWithUnknownType() {
        let unknownTypeJSON = """
        [
            {"word": "excellent", "type": "unknown", "confidence": 0.9}
        ]
        """
        
        let suggestions = mockService.validateOpenAIResponse(unknownTypeJSON)
        
        XCTAssertNotNil(suggestions, "Should handle unknown types")
        XCTAssertEqual(suggestions?.count, 1, "Should include suggestion with unknown type")
        XCTAssertEqual(suggestions?.first?.type, .alternative, "Should default unknown types to alternative")
    }
    
    // MARK: - Edge Case Tests
    
    func testSuggestionsForSingleCharacter() {
        let suggestions = mockService.getBuiltInSuggestions(for: "a")
        
        XCTAssertFalse(suggestions.isEmpty, "Should handle single character input")
    }
    
    func testSuggestionsForVeryLongString() {
        let longString = String(repeating: "verylongword", count: 100)
        let suggestions = mockService.getBuiltInSuggestions(for: longString)
        
        XCTAssertFalse(suggestions.isEmpty, "Should handle very long input strings")
    }
    
    func testSuggestionsForSpecialCharacters() {
        let specialChars = "!@#$%^&*()"
        let suggestions = mockService.getBuiltInSuggestions(for: specialChars)
        
        XCTAssertFalse(suggestions.isEmpty, "Should handle special characters")
    }
    
    func testSuggestionsForNumbers() {
        let numbers = "12345"
        let suggestions = mockService.getBuiltInSuggestions(for: numbers)
        
        XCTAssertFalse(suggestions.isEmpty, "Should handle numeric input")
    }
    
    // MARK: - Performance Tests
    
    func testSuggestionPerformance() {
        measure {
            for _ in 0..<100 {
                _ = mockService.getBuiltInSuggestions(for: "good")
            }
        }
    }
    
    func testLargeDictionaryPerformance() {
        let words = ["good", "bad", "big", "small", "fast", "slow", "happy", "sad"]
        
        measure {
            for word in words {
                _ = mockService.getBuiltInSuggestions(for: word)
            }
        }
    }
}
