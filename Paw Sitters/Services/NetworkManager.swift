class NetworkManager: ObservableObject {
    @Published var isLoading = false
    private let networkMonitor = NetworkMonitor()
    
    func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        guard networkMonitor.isConnected else {
            throw AppError.networkError("No internet connection")
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError("Server error")
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
} 