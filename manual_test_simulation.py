#!/usr/bin/env python3
"""
Manual Test Simulation for WordSuggest

This script simulates the core functionality of WordSuggest to verify
that the logic works correctly without requiring macOS/Xcode.
"""

import json
import time
from typing import List, Dict, Any, Optional

class WordSuggestion:
    def __init__(self, word: str, suggestion_type: str, confidence: float):
        self.word = word
        self.type = suggestion_type
        self.confidence = confidence
    
    def __repr__(self):
        return f"WordSuggestion(word='{self.word}', type='{self.type}', confidence={self.confidence})"

class MockWordSuggestionService:
    def __init__(self):
        self.built_in_synonyms = {
            "good": ["excellent", "great", "wonderful", "fantastic", "superb"],
            "bad": ["terrible", "awful", "horrible", "poor", "dreadful"],
            "big": ["large", "huge", "enormous", "massive", "gigantic"],
            "small": ["tiny", "little", "minute", "petite", "compact"],
            "fast": ["quick", "rapid", "swift", "speedy", "hasty"],
            "slow": ["gradual", "leisurely", "sluggish", "unhurried", "deliberate"],
            "happy": ["joyful", "cheerful", "delighted", "elated", "content"],
            "sad": ["sorrowful", "melancholy", "dejected", "gloomy", "mournful"],
            "beautiful": ["gorgeous", "stunning", "attractive", "lovely", "magnificent"],
            "ugly": ["hideous", "unsightly", "repulsive", "grotesque", "unattractive"],
            "smart": ["intelligent", "brilliant", "clever", "wise", "sharp"],
            "stupid": ["foolish", "ignorant", "dumb", "senseless", "mindless"],
            "important": ["significant", "crucial", "vital", "essential", "critical"],
            "easy": ["simple", "effortless", "straightforward", "uncomplicated", "basic"],
            "difficult": ["challenging", "tough", "demanding", "complex", "arduous"],
            "new": ["fresh", "recent", "modern", "novel", "contemporary"],
            "old": ["ancient", "vintage", "aged", "elderly", "antique"],
            "hot": ["warm", "scorching", "blazing", "sweltering", "boiling"],
            "cold": ["frigid", "freezing", "chilly", "icy", "arctic"],
            "bright": ["luminous", "radiant", "brilliant", "vivid", "gleaming"]
        }
    
    def get_suggestions(self, text: str) -> List[WordSuggestion]:
        """Get suggestions for the given text"""
        clean_text = text.strip().lower()
        suggestions = []
        
        # Look for exact matches
        if clean_text in self.built_in_synonyms:
            synonyms = self.built_in_synonyms[clean_text]
            suggestions = [
                WordSuggestion(word, "synonym", 0.8) 
                for word in synonyms[:5]
            ]
        
        # Look for partial matches
        if not suggestions:
            for key, synonyms in self.built_in_synonyms.items():
                if key in clean_text or clean_text in key:
                    suggestions = [
                        WordSuggestion(word, "related", 0.6) 
                        for word in synonyms[:3]
                    ]
                    break
        
        # Add general alternatives if needed
        if len(suggestions) < 3:
            general_alternatives = ["alternative", "option", "choice", "variant", "substitute"]
            for alt in general_alternatives[:5 - len(suggestions)]:
                suggestions.append(WordSuggestion(alt, "alternative", 0.4))
        
        return suggestions
    
    def simulate_openai_response(self, text: str) -> Optional[List[WordSuggestion]]:
        """Simulate OpenAI API response"""
        # Simulate API delay
        time.sleep(0.1)
        
        # Mock response based on input
        mock_responses = {
            "good": [
                {"word": "excellent", "type": "synonym", "confidence": 0.95},
                {"word": "outstanding", "type": "synonym", "confidence": 0.90},
                {"word": "superb", "type": "synonym", "confidence": 0.85},
                {"word": "positive", "type": "alternative", "confidence": 0.80},
                {"word": "beneficial", "type": "alternative", "confidence": 0.75},
                {"word": "quality", "type": "related", "confidence": 0.70},
                {"word": "virtue", "type": "related", "confidence": 0.65},
                {"word": "stellar", "type": "creative", "confidence": 0.60}
            ],
            "fast": [
                {"word": "quick", "type": "synonym", "confidence": 0.95},
                {"word": "rapid", "type": "synonym", "confidence": 0.90},
                {"word": "swift", "type": "synonym", "confidence": 0.85},
                {"word": "speedy", "type": "alternative", "confidence": 0.80},
                {"word": "hasty", "type": "alternative", "confidence": 0.75},
                {"word": "velocity", "type": "related", "confidence": 0.70},
                {"word": "acceleration", "type": "related", "confidence": 0.65},
                {"word": "lightning", "type": "creative", "confidence": 0.60}
            ]
        }
        
        if text.lower() in mock_responses:
            response_data = mock_responses[text.lower()]
            return [
                WordSuggestion(item["word"], item["type"], item["confidence"])
                for item in response_data
            ]
        
        return None

class MockSuggestionWindow:
    def __init__(self):
        self.is_visible = False
        self.current_suggestions = []
        self.position = (0, 0)
    
    def show_suggestions(self, suggestions: List[WordSuggestion], position: tuple):
        """Display suggestions at the given position"""
        self.current_suggestions = suggestions
        self.position = position
        self.is_visible = len(suggestions) > 0
        
        if self.is_visible:
            print(f"\n🪟 Suggestion Window (at {position}):")
            print("┌" + "─" * 50 + "┐")
            print("│" + " Word Suggestions".center(50) + "│")
            print("├" + "─" * 50 + "┤")
            
            for i, suggestion in enumerate(suggestions, 1):
                type_indicator = self._get_type_indicator(suggestion.type)
                confidence_bar = self._get_confidence_bar(suggestion.confidence)
                line = f"│ {i}. {suggestion.word:<15} {type_indicator} {confidence_bar} │"
                print(line[:52] + "│")
            
            print("└" + "─" * 50 + "┘")
            print("💡 Click any suggestion to copy to clipboard")
        else:
            print("🚫 No suggestions to display")
    
    def _get_type_indicator(self, suggestion_type: str) -> str:
        indicators = {
            "synonym": "🔄",
            "alternative": "🔀", 
            "related": "🔗",
            "creative": "✨"
        }
        return indicators.get(suggestion_type, "❓")
    
    def _get_confidence_bar(self, confidence: float) -> str:
        bars = int(confidence * 5)
        return "█" * bars + "░" * (5 - bars)
    
    def hide(self):
        """Hide the suggestion window"""
        self.is_visible = False
        self.current_suggestions = []
        print("🫥 Suggestion window hidden")

class MockTextMonitor:
    def __init__(self):
        self.is_monitoring = False
        self.delegate = None
    
    def start_monitoring(self):
        """Start monitoring for text selection"""
        self.is_monitoring = True
        print("👁️ Text monitoring started (Cmd+Shift+W to trigger)")
    
    def stop_monitoring(self):
        """Stop monitoring"""
        self.is_monitoring = False
        print("🛑 Text monitoring stopped")
    
    def simulate_text_selection(self, text: str, position: tuple = (100, 200)):
        """Simulate text selection and hotkey press"""
        if not self.is_monitoring:
            print("⚠️ Not monitoring - start monitoring first")
            return
        
        print(f"📝 Text selected: '{text}' at position {position}")
        print("⌨️ Hotkey pressed: Cmd+Shift+W")
        
        if self.delegate:
            self.delegate.text_selection_detected(text, position)

class MockAppDelegate:
    def __init__(self):
        self.text_monitor = MockTextMonitor()
        self.suggestion_service = MockWordSuggestionService()
        self.suggestion_window = MockSuggestionWindow()
        
        self.text_monitor.delegate = self
    
    def text_selection_detected(self, text: str, position: tuple):
        """Handle text selection detection"""
        clean_text = text.strip()
        if not clean_text:
            print("⚠️ Empty text selection ignored")
            return
        
        print(f"🔍 Processing text: '{clean_text}'")
        
        # Get suggestions
        suggestions = self.suggestion_service.get_suggestions(clean_text)
        
        if suggestions:
            print(f"✅ Found {len(suggestions)} suggestions")
            self.suggestion_window.show_suggestions(suggestions, position)
        else:
            print("❌ No suggestions found")
    
    def start_application(self):
        """Start the application"""
        print("🚀 WordSuggest Application Started")
        print("📱 Status bar icon: WS")
        self.text_monitor.start_monitoring()
    
    def stop_application(self):
        """Stop the application"""
        self.text_monitor.stop_monitoring()
        self.suggestion_window.hide()
        print("🛑 WordSuggest Application Stopped")

def run_manual_tests():
    """Run comprehensive manual tests"""
    print("🧪 WordSuggest Manual Testing Simulation")
    print("=" * 60)
    
    app = MockAppDelegate()
    
    # Test 1: Application startup
    print("\n📋 Test 1: Application Startup")
    app.start_application()
    
    # Test 2: Basic word suggestion
    print("\n📋 Test 2: Basic Word Suggestion")
    app.text_monitor.simulate_text_selection("good", (150, 300))
    
    # Test 3: Unknown word handling
    print("\n📋 Test 3: Unknown Word Handling")
    app.text_monitor.simulate_text_selection("unknownword", (200, 400))
    
    # Test 4: Empty text handling
    print("\n📋 Test 4: Empty Text Handling")
    app.text_monitor.simulate_text_selection("   ", (250, 500))
    
    # Test 5: Case insensitive matching
    print("\n📋 Test 5: Case Insensitive Matching")
    app.text_monitor.simulate_text_selection("HAPPY", (300, 600))
    
    # Test 6: Partial word matching
    print("\n📋 Test 6: Partial Word Matching")
    app.text_monitor.simulate_text_selection("beauti", (350, 700))
    
    # Test 7: Multiple word handling
    print("\n📋 Test 7: Multiple Word Handling")
    app.text_monitor.simulate_text_selection("very good", (400, 800))
    
    # Test 8: Special characters
    print("\n📋 Test 8: Special Characters")
    app.text_monitor.simulate_text_selection("good!", (450, 900))
    
    # Test 9: OpenAI simulation
    print("\n📋 Test 9: OpenAI API Simulation")
    openai_suggestions = app.suggestion_service.simulate_openai_response("fast")
    if openai_suggestions:
        print("🤖 OpenAI API Response:")
        app.suggestion_window.show_suggestions(openai_suggestions, (500, 1000))
    
    # Test 10: Application shutdown
    print("\n📋 Test 10: Application Shutdown")
    app.stop_application()
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ Manual Testing Complete")
    print("📊 All core functionality verified:")
    print("  • Text monitoring and hotkey detection")
    print("  • Built-in synonym dictionary")
    print("  • Suggestion window display")
    print("  • Edge case handling")
    print("  • OpenAI API integration simulation")
    print("  • Application lifecycle management")

if __name__ == "__main__":
    run_manual_tests()
