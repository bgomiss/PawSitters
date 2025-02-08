// Create new file for centralized error handling
enum AppError: LocalizedError {
    case authError(String)
    case networkError(String)
    case databaseError(String)
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .authError(let message): return "Authentication Error: \(message)"
        case .networkError(let message): return "Network Error: \(message)"
        case .databaseError(let message): return "Database Error: \(message)"
        case .invalidInput(let message): return "Invalid Input: \(message)"
        }
    }
} 