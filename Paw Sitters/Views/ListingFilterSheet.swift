//
//  ListingFilterSheet.swift
//  Paw Sitters
//
//  Bottom sheet for filtering listings by location, dates and environment,
//  plus the compact filter button and active-filter chips used on the feed.
//

import SwiftUI

struct ListingFilterSheet: View {
    @Binding var filters: ListingFilters
    /// All loaded listings, used to show a live result count.
    let listings: [PetSittingListing]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var draft = ListingFilters()
    @State private var isCalendarExpanded = false
    /// The suggestion the user picked; hides the suggestion list until they type again.
    @State private var pickedLocation: String?
    @FocusState private var isLocationFocused: Bool
    private let theme = AppTheme.current

    private var resultCount: Int {
        listings.filter { draft.matches($0) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    locationSection
                    dateSection
                    environmentSection
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.text)
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear all") {
                        withAnimation(.snappy) {
                            draft = ListingFilters()
                            locationViewModel.location = ""
                            locationViewModel.citySuggestions = []
                        }
                    }
                    .foregroundStyle(draft.isEmpty ? theme.text.opacity(0.3) : theme.accent)
                    .disabled(draft.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    filters = draft
                    dismiss()
                } label: {
                    Text(resultCount == 1 ? "Show 1 listing" : "Show \(resultCount) listings")
                        .themedButton()
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            draft = filters
            locationViewModel.location = filters.location
            pickedLocation = filters.location.isEmpty ? nil : filters.location
            // Typing into the field updates the draft; suggestions only fill it in.
            locationViewModel.citySuggestions = []
        }
    }

    // MARK: - Sections

    private var locationSection: some View {
        FilterSection(title: "Where", icon: "mappin.and.ellipse") {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.text.opacity(0.5))
                    TextField("Search a city", text: $locationViewModel.location)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isLocationFocused)
                        .submitLabel(.done)
                        .onChange(of: locationViewModel.location) { _, newValue in
                            draft.location = newValue
                        }
                    if !locationViewModel.location.isEmpty {
                        Button {
                            locationViewModel.location = ""
                            locationViewModel.citySuggestions = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.text.opacity(0.35))
                        }
                        .accessibilityLabel("Clear location")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.secondary.opacity(0.7), lineWidth: 1)
                )

                if !locationViewModel.citySuggestions.isEmpty && locationViewModel.location != pickedLocation {
                    CitySuggestionList(cities: locationViewModel.citySuggestions) { city in
                        pickedLocation = city.name
                        locationViewModel.location = city.name
                        draft.location = city.name
                        locationViewModel.citySuggestions = []
                        isLocationFocused = false
                    }
                    .padding(.top, 6)
                }
            }
        }
    }

    private var dateSection: some View {
        FilterSection(title: "When", icon: "calendar") {
            VStack(spacing: 10) {
                Button {
                    withAnimation(.snappy) { isCalendarExpanded.toggle() }
                } label: {
                    HStack {
                        Text(dateSummary)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(draft.dateRange == nil ? theme.text.opacity(0.5) : theme.text)
                        Spacer()
                        if draft.dateRange != nil {
                            Button {
                                withAnimation(.snappy) { draft.dateRange = nil }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(theme.text.opacity(0.35))
                            }
                            .accessibilityLabel("Clear dates")
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.text.opacity(0.5))
                            .rotationEffect(.degrees(isCalendarExpanded ? 180 : 0))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.secondary.opacity(0.7), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if isCalendarExpanded {
                    HorizonCalendar(calendar: Calendar.current, monthsLayout: .vertical, selectedDateRange: $draft.dateRange)
                        .frame(height: 360)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var environmentSection: some View {
        FilterSection(title: "Environment", icon: "leaf.fill") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                ForEach(ListingFilters.environments, id: \.name) { option in
                    let isSelected = draft.environment == option.name
                    Button {
                        withAnimation(.snappy) {
                            draft.environment = isSelected ? "" : option.name
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: option.icon)
                                .font(.system(size: 20))
                            Text(option.name)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(isSelected ? .white : theme.text)
                        .background(isSelected ? theme.primary : Color.white,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? theme.primary : theme.secondary.opacity(0.7), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var dateSummary: String {
        guard let range = draft.dateRange else { return "Any dates" }
        let start = range.lowerBound.formatted(.dateTime.day().month(.abbreviated))
        let end = range.upperBound.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(start) – \(end)"
    }
}

/// Titled block inside the filter sheet.
private struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AppTheme.current.text)
            content
        }
    }
}

/// "Filters" capsule shown on the listings feed, with the number of active filters.
struct FilterButton: View {
    let activeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                Text("Filters")
                if activeCount > 0 {
                    Text("\(activeCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.current.primary)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(.white, in: Circle())
                }
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(activeCount > 0 ? .white : AppTheme.current.text)
            .background(activeCount > 0 ? AppTheme.current.primary : Color.white, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.current.secondary.opacity(activeCount > 0 ? 0 : 0.8), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(activeCount > 0 ? "Filters, \(activeCount) active" : "Filters")
    }
}

/// Row of removable chips for the filters that are currently applied.
struct ActiveFilterChips: View {
    @Binding var filters: ListingFilters

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !filters.trimmedLocation.isEmpty {
                    chip(ListingFilters.city(from: filters.trimmedLocation), icon: "mappin.and.ellipse") { filters.location = "" }
                }
                if let range = filters.dateRange {
                    chip("\(range.lowerBound.formatted(.dateTime.day().month(.abbreviated))) – \(range.upperBound.formatted(.dateTime.day().month(.abbreviated)))",
                         icon: "calendar") { filters.dateRange = nil }
                }
                if !filters.environment.isEmpty {
                    chip(filters.environment, icon: ListingFilters.icon(for: filters.environment)) { filters.environment = "" }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(_ text: String, icon: String, remove: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { remove() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(text)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(AppTheme.current.primary)
            .background(AppTheme.current.secondary.opacity(0.35), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove filter \(text)")
    }
}

/// Label whose icon uses the theme's accent color.
struct AccentIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundStyle(AppTheme.current.accent)
            configuration.title
        }
    }
}
