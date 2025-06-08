import Foundation

struct WordSuggestion {
    let word: String
    let type: SuggestionType
    let confidence: Double
    
    enum SuggestionType: String, Codable {
        case synonym
        case alternative
        case related
        case rhyme
    }
}

class WordSuggestionService {
    private let openAIAPIKey = "" // Add your OpenAI API key here
    private let session = URLSession.shared
    
    func getSuggestions(for text: String, completion: @escaping ([WordSuggestion]) -> Void) {
        // Clean the input text
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if openAIAPIKey.isEmpty {
            // Fallback to built-in suggestions if no API key
            getBuiltInSuggestions(for: cleanText, completion: completion)
            return
        }
        
        // Use OpenAI API for intelligent suggestions
        getOpenAISuggestions(for: cleanText, completion: completion)
    }
    
    private func getOpenAISuggestions(for text: String, completion: @escaping ([WordSuggestion]) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        For the word or phrase "\(text)", provide exactly 8 suggestions in the following categories:
        - 3 synonyms (words with similar meaning)
        - 2 alternatives (different words that could work in context)
        - 2 related words (conceptually related)
        - 1 creative alternative
        
        Respond ONLY with a JSON array of objects with this format:
        [{"word": "example", "type": "synonym", "confidence": 0.9}]
        
        Types must be: "synonym", "alternative", "related", or "creative"
        Confidence should be between 0.0 and 1.0
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 300,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion([])
            return
        }
        
        session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Parse the JSON response
                    if let jsonData = content.data(using: .utf8),
                       let suggestions = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                        
                        let wordSuggestions = suggestions.compactMap { dict -> WordSuggestion? in
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
                        
                        DispatchQueue.main.async {
                            completion(wordSuggestions)
                        }
                        return
                    }
                }
            } catch {
                print("Error parsing OpenAI response: \(error)")
            }
            
            // Fallback to built-in suggestions
            DispatchQueue.main.async {
                self.getBuiltInSuggestions(for: text, completion: completion)
            }
        }.resume()
    }
    
    private func getBuiltInSuggestions(for text: String, completion: @escaping ([WordSuggestion]) -> Void) {
        var suggestions: [WordSuggestion] = []
        
        // Built-in synonym dictionary
        let synonymMap: [String: [String]] = [
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
        ]
        
        let lowercaseText = text.lowercased()
        
        // Look for exact matches
        if let synonyms = synonymMap[lowercaseText] {
            suggestions = synonyms.prefix(5).map { 
                WordSuggestion(word: $0, type: .synonym, confidence: 0.8) 
            }
        }
        
        // Look for partial matches
        if suggestions.isEmpty {
            for (key, synonyms) in synonymMap {
                if key.contains(lowercaseText) || lowercaseText.contains(key) {
                    suggestions = synonyms.prefix(3).map { 
                        WordSuggestion(word: $0, type: .related, confidence: 0.6) 
                    }
                    break
                }
            }
        }
        
        // Add some general alternatives if we still don't have enough
        if suggestions.count < 3 {
            let generalAlternatives = ["alternative", "option", "choice", "variant", "substitute"]
            for alt in generalAlternatives.prefix(5 - suggestions.count) {
                suggestions.append(WordSuggestion(word: alt, type: .alternative, confidence: 0.4))
            }
        }
        
        completion(suggestions)
    }
}
