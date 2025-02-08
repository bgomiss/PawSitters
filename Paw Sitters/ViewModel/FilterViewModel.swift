class FilterViewModel: ObservableObject {
    @Published var activeFilters: Set<FilterType> = []
    @Published var dateRange: ClosedRange<Date>?
    @Published var location: String?
    @Published var environment: String?
    
    enum FilterType {
        case date
        case location
        case environment
    }
    
    func applyFilters() {
        // Combine all active filters
        var query = baseQuery
        
        if activeFilters.contains(.date), let range = dateRange {
            query = query.filterByDate(range)
        }
        
        if activeFilters.contains(.location), let loc = location {
            query = query.filterByLocation(loc)
        }
        
        // etc...
    }
    
    func clearFilters() {
        activeFilters.removeAll()
        dateRange = nil
        location = nil
        environment = nil
    }
} 