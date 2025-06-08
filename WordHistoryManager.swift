import Foundation
import Cocoa

struct WordHistoryEntry: Codable {
    let id: UUID
    let originalWord: String
    let selectedSuggestion: String?
    let suggestions: [String]
    let timestamp: Date
    let sourceApplication: String?
    let suggestionType: WordSuggestion.SuggestionType?
    
    init(originalWord: String, selectedSuggestion: String? = nil, suggestions: [String] = [], sourceApplication: String? = nil, suggestionType: WordSuggestion.SuggestionType? = nil) {
        self.id = UUID()
        self.originalWord = originalWord
        self.selectedSuggestion = selectedSuggestion
        self.suggestions = suggestions
        self.timestamp = Date()
        self.sourceApplication = sourceApplication
        self.suggestionType = suggestionType
    }
}

struct WordStatistics {
    let totalWords: Int
    let totalSuggestions: Int
    let mostUsedWord: (word: String, count: Int)?
    let averageSuggestionsPerWord: Double
    let topApplications: [(app: String, count: Int)]
    let usageByHour: [Int: Int] // Hour of day -> count
    let usageByDay: [Int: Int] // Day of week -> count
}

class WordHistoryManager {
    static let shared = WordHistoryManager()
    
    private let fileManager = FileManager.default
    private let historyFileName = "word_history.json"
    private var historyFileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("WordSuggest")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        return appDirectory.appendingPathComponent(historyFileName)
    }
    
    private var entries: [WordHistoryEntry] = []
    private let maxEntries = 10000 // Limit to prevent excessive memory usage
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    func addEntry(originalWord: String, suggestions: [WordSuggestion], sourceApp: String? = nil) {
        guard UserSettings.shared.enableAnalytics else { return }
        
        let suggestionStrings = suggestions.map { $0.word }
        let entry = WordHistoryEntry(
            originalWord: originalWord,
            suggestions: suggestionStrings,
            sourceApplication: sourceApp
        )
        
        entries.insert(entry, at: 0)
        
        // Trim if necessary
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        
        saveHistory()
        notifyHistoryUpdated()
    }
    
    func recordSuggestionUsed(originalWord: String, selectedSuggestion: String, suggestionType: WordSuggestion.SuggestionType) {
        guard UserSettings.shared.enableAnalytics else { return }
        
        // Find the most recent entry for this word and update it
        if let index = entries.firstIndex(where: { $0.originalWord == originalWord && $0.selectedSuggestion == nil }) {
            let oldEntry = entries[index]
            let updatedEntry = WordHistoryEntry(
                originalWord: oldEntry.originalWord,
                selectedSuggestion: selectedSuggestion,
                suggestions: oldEntry.suggestions,
                sourceApplication: oldEntry.sourceApplication,
                suggestionType: suggestionType
            )
            
            entries[index] = updatedEntry
            saveHistory()
            notifyHistoryUpdated()
        }
    }
    
    func getAllEntries() -> [WordHistoryEntry] {
        return entries
    }
    
    func getEntriesForWord(_ word: String) -> [WordHistoryEntry] {
        return entries.filter { $0.originalWord.lowercased() == word.lowercased() }
    }
    
    func getStatistics() -> WordStatistics {
        let totalWords = entries.count
        let totalSuggestions = entries.compactMap { $0.selectedSuggestion }.count
        
        // Most used word
        let wordCounts = Dictionary(grouping: entries, by: { $0.originalWord })
            .mapValues { $0.count }
        let mostUsedWord = wordCounts.max(by: { $0.value < $1.value })
            .map { (word: $0.key, count: $0.value) }
        
        // Average suggestions per word
        let averageSuggestions = totalWords > 0 ? Double(totalSuggestions) / Double(totalWords) : 0.0
        
        // Top applications
        let appCounts = Dictionary(grouping: entries.compactMap { $0.sourceApplication }, by: { $0 })
            .mapValues { $0.count }
        let topApps = Array(appCounts.sorted(by: { $0.value > $1.value }).prefix(5))
            .map { (app: $0.key, count: $0.value) }
        
        // Usage by hour
        let calendar = Calendar.current
        let usageByHour = Dictionary(grouping: entries, by: { calendar.component(.hour, from: $0.timestamp) })
            .mapValues { $0.count }
        
        // Usage by day of week
        let usageByDay = Dictionary(grouping: entries, by: { calendar.component(.weekday, from: $0.timestamp) })
            .mapValues { $0.count }
        
        return WordStatistics(
            totalWords: totalWords,
            totalSuggestions: totalSuggestions,
            mostUsedWord: mostUsedWord,
            averageSuggestionsPerWord: averageSuggestions,
            topApplications: topApps,
            usageByHour: usageByHour,
            usageByDay: usageByDay
        )
    }
    
    func exportToCSV() -> String {
        var csv = "Date,Time,Original Word,Selected Suggestion,Source Application,Suggestion Type\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        for entry in entries {
            let date = dateFormatter.string(from: entry.timestamp)
            let time = timeFormatter.string(from: entry.timestamp)
            let originalWord = escapeCSVField(entry.originalWord)
            let selectedSuggestion = escapeCSVField(entry.selectedSuggestion ?? "")
            let sourceApp = escapeCSVField(entry.sourceApplication ?? "")
            let suggestionType = escapeCSVField(entry.suggestionType?.rawValue ?? "")
            
            csv += "\(date),\(time),\(originalWord),\(selectedSuggestion),\(sourceApp),\(suggestionType)\n"
        }
        
        return csv
    }
    
    func clearHistory() {
        entries.removeAll()
        saveHistory()
        notifyHistoryUpdated()
    }
    
    func searchEntries(query: String) -> [WordHistoryEntry] {
        let lowercaseQuery = query.lowercased()
        return entries.filter { entry in
            entry.originalWord.lowercased().contains(lowercaseQuery) ||
            entry.selectedSuggestion?.lowercased().contains(lowercaseQuery) == true ||
            entry.sourceApplication?.lowercased().contains(lowercaseQuery) == true
        }
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() {
        guard fileManager.fileExists(atPath: historyFileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: historyFileURL)
            entries = try JSONDecoder().decode([WordHistoryEntry].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
            entries = []
        }
    }
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: historyFileURL)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    private func notifyHistoryUpdated() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .wordHistoryUpdated, object: nil)
        }
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}


