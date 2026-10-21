//
//  ReviewsView.swift
//  Paw Sitters
//
//  Star rating components, the sheet for leaving a review, and the list of
//  reviews a user has received.
//

import SwiftUI

/// Read-only row of five stars, filled to the given rating (supports halves).
struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbol(for: star))
                    .font(.system(size: size))
                    .foregroundStyle(AppTheme.current.accent)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "%.1f out of 5 stars", rating))
    }

    private func symbol(for star: Int) -> String {
        let value = rating - Double(star - 1)
        if value >= 0.75 { return "star.fill" }
        if value >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Compact "★ 4.5 (3)" label; shows "New" when there are no reviews yet.
struct RatingBadge: View {
    let summary: RatingSummary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: summary.count == 0 ? "sparkles" : "star.fill")
                .foregroundStyle(AppTheme.current.accent)
            Text(summary.count == 0 ? "New" : String(format: "%.1f (%d)", summary.average, summary.count))
                .foregroundStyle(AppTheme.current.text)
        }
        .font(.system(.subheadline, design: .rounded).weight(.semibold))
    }
}

/// Tappable 1–5 star picker.
struct StarPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { rating = star }
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 34))
                        .foregroundStyle(star <= rating ? AppTheme.current.accent : AppTheme.current.text.opacity(0.25))
                        .scaleEffect(star == rating ? 1.15 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
            }
        }
    }
}

/// Sheet for reviewing the other person of an accepted application.
struct ReviewSheet: View {
    let application: Application
    let revieweeName: String
    @EnvironmentObject var reviewService: ReviewService
    @EnvironmentObject var userProfileService: UserProfileService
    @Environment(\.dismiss) private var dismiss
    @State private var rating = 0
    @State private var comment = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    private let theme = AppTheme.current

    private var ratingCaption: String {
        ["Tap a star to rate", "Poor", "Fair", "Good", "Very good", "Excellent"][rating]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("How was your experience with \(revieweeName.isEmpty ? "them" : revieweeName)?")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.text)
                            .multilineTextAlignment(.center)
                        Text(application.listingTitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.text.opacity(0.65))
                    }
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        StarPicker(rating: $rating)
                        Text(ratingCaption)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(rating == 0 ? theme.text.opacity(0.45) : theme.accent)
                    }

                    TextEditor(text: $comment)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .frame(minHeight: 130)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(theme.secondary.opacity(0.7), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            if comment.isEmpty {
                                Text("Share what went well and anything others should know.")
                                    .foregroundStyle(theme.text.opacity(0.4))
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action: submit) {
                        Group {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Label("Submit review", systemImage: "star.bubble.fill")
                            }
                        }
                        .themedButton()
                    }
                    .disabled(isSending)
                }
                .padding()
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Leave a review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        guard rating > 0 else {
            errorMessage = "Choose a star rating first."
            return
        }
        isSending = true
        errorMessage = nil
        reviewService.submitReview(for: application,
                                   reviewerName: userProfileService.userProfile?.name ?? "",
                                   rating: rating,
                                   comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)) { error in
            isSending = false
            if let error {
                errorMessage = "Couldn't save your review: \(error.localizedDescription)"
            } else {
                dismiss()
            }
        }
    }
}

/// Rating summary plus the latest reviews a user has received.
struct ReviewsSection: View {
    let userId: String
    var title = "Reviews"
    var limit: Int?
    @EnvironmentObject var reviewService: ReviewService
    private let theme = AppTheme.current

    var body: some View {
        let reviews = reviewService.reviews(for: userId)
        let summary = reviewService.summary(for: userId)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)
                Spacer()
                RatingBadge(summary: summary)
            }

            if reviews.isEmpty {
                Text("No reviews yet. Reviews appear after a confirmed stay.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.55))
            } else {
                ForEach(limit.map { Array(reviews.prefix($0)) } ?? reviews) { review in
                    Divider()
                    ReviewRow(review: review)
                }
            }
        }
        .padding(18)
        .themedCard()
        .onAppear { reviewService.loadReviews(for: userId) }
    }
}

struct ReviewRow: View {
    let review: Review
    private let theme = AppTheme.current

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.reviewerName.isEmpty ? "Paw Sitters user" : review.reviewerName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.text)
                Spacer()
                StarRatingView(rating: Double(review.rating), size: 12)
            }
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.85))
            }
            Text("\(review.listingTitle) · \(review.createdAt.dateValue().formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(theme.text.opacity(0.5))
        }
    }
}
