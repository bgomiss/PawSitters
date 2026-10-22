//
//  ApplicationsView.swift
//  Paw Sitters
//
//  Messages tab hub (chats + applications), the applications inbox with
//  accept / decline / withdraw actions, and the sheet used to apply to a listing.
//

import SwiftUI

/// The Messages tab: switches between chats and applications.
struct MessagesHubView: View {
    @Binding var userId: String
    @EnvironmentObject var applicationService: ApplicationService
    @ObservedObject private var notificationRouter = NotificationRouter.shared
    @State private var section: Section = .chats
    @State private var requestedBox: ApplicationsView.Box?

    enum Section: String, CaseIterable {
        case chats = "Chats"
        case applications = "Applications"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitle("Messages", icon: "bubble.left.and.bubble.right.fill")
            Picker("Section", selection: $section) {
                Text(Section.chats.rawValue).tag(Section.chats)
                Text(applicationService.pendingReceivedCount > 0
                     ? "Applications (\(applicationService.pendingReceivedCount))"
                     : Section.applications.rawValue)
                    .tag(Section.applications)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch section {
            case .chats:
                ConversationsView(userId: $userId, showsTitle: false)
            case .applications:
                ApplicationsView(userId: userId, requestedBox: $requestedBox)
            }
        }
        .onAppear { showApplicationsIfRequested() }
        .onChange(of: notificationRouter.showApplications) { _, _ in showApplicationsIfRequested() }
    }
    
    private func showApplicationsIfRequested() {
        guard let sent = notificationRouter.showApplications else { return }
        notificationRouter.showApplications = nil
        requestedBox = sent ? .sent : .received
        section = .applications
    }
}

struct ApplicationsView: View {
    let userId: String
    /// Box to switch to once (set when opening from a notification).
    @Binding var requestedBox: Box?
    @EnvironmentObject var applicationService: ApplicationService
    @EnvironmentObject var moderationService: ModerationService
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var userProfileService: UserProfileService
    @State private var box: Box = .received
    @State private var chatPartner: ChatPartner?

    enum Box: String, CaseIterable {
        case received = "Received"
        case sent = "Sent"
    }

    /// Wrapper so the chat cover can be driven by `item:`.
    struct ChatPartner: Identifiable {
        let id: String
    }

    private var applications: [Application] {
        (box == .received ? applicationService.received : applicationService.sent)
            .filter { !moderationService.isBlocked(box == .received ? $0.applicantId : $0.listingOwnerId) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(Box.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.snappy) { box = option }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundStyle(box == option ? .white : AppTheme.current.text)
                            .background(box == option ? AppTheme.current.primary : Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if applications.isEmpty {
                EmptyStateView(icon: box == .received ? "tray.fill" : "paperplane.fill",
                               title: box == .received ? "No applications yet" : "You haven't applied yet",
                               message: box == .received
                                   ? "When someone applies to one of your listings, it'll show up here."
                                   : "Find a listing you like and tap Apply.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(applications) { application in
                            ApplicationRow(application: application,
                                           isReceived: box == .received,
                                           onMessage: {
                                               chatPartner = ChatPartner(id: box == .received ? application.applicantId : application.listingOwnerId)
                                           })
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear { applyRequestedBox() }
        .onChange(of: requestedBox) { _, _ in applyRequestedBox() }
        .fullScreenCover(item: $chatPartner) { partner in
            MessagingView(userId: userId, receiverId: partner.id)
                .environmentObject(messagingService)
                .environmentObject(storageService)
                .environmentObject(userProfileService)
        }
    }
}

extension ApplicationsView {
    fileprivate func applyRequestedBox() {
        guard let requested = requestedBox else { return }
        box = requested
        requestedBox = nil
    }
}

struct ApplicationRow: View {
    let application: Application
    let isReceived: Bool
    var onMessage: () -> Void
    @EnvironmentObject var applicationService: ApplicationService
    @EnvironmentObject var reviewService: ReviewService
    @EnvironmentObject var userProfileService: UserProfileService
    @State private var confirmDecline = false
    @State private var isReviewSheetPresented = false
    private let theme = AppTheme.current
    
    private var otherPartyId: String { isReceived ? application.applicantId : application.listingOwnerId }
    private var otherPartyName: String { isReceived ? application.applicantName : application.listingOwnerName }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(application.listingTitle.isEmpty ? "Listing" : application.listingTitle)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(theme.text)
                    HStack(spacing: 8) {
                        Label(otherPartyName, systemImage: isReceived ? "person.crop.circle.fill" : "house.fill")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.text.opacity(0.7))
                        if userProfileService.cachedProfile(uid: otherPartyId)?.emailVerified == true {
                            VerifiedBadge(showsText: false)
                        }
                        // Helps the owner judge an applicant (and vice versa).
                        RatingBadge(summary: reviewService.summary(for: otherPartyId))
                            .font(.caption)
                    }
                    .onAppear { reviewService.loadReviews(for: otherPartyId) }
                }
                Spacer()
                StatusBadge(status: application.status)
            }

            if !application.message.isEmpty {
                Text("“\(application.message)”")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.85))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Text(application.updatedAt.dateValue().formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundStyle(theme.text.opacity(0.5))

            HStack(spacing: 10) {
                if isReceived && application.status == .pending {
                    actionButton("Accept", icon: "checkmark", color: theme.primary, filled: true) {
                        applicationService.updateStatus(of: application, to: .accepted)
                    }
                    actionButton("Decline", icon: "xmark", color: .red, filled: false) {
                        confirmDecline = true
                    }
                }
                if !isReceived && application.status == .pending {
                    actionButton("Withdraw", icon: "arrow.uturn.backward", color: .red, filled: false) {
                        applicationService.updateStatus(of: application, to: .withdrawn)
                    }
                }
                if application.status == .accepted {
                    if reviewService.hasReviewed(application) {
                        Label("Reviewed", systemImage: "checkmark")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.text.opacity(0.5))
                    } else {
                        actionButton("Review", icon: "star.fill", color: theme.primary, filled: true) {
                            isReviewSheetPresented = true
                        }
                    }
                }
                Spacer()
                actionButton("Message", icon: "bubble.left.fill", color: theme.accent, filled: false, action: onMessage)
            }
        }
        .padding(14)
        .themedCard()
        .sheet(isPresented: $isReviewSheetPresented) {
            ReviewSheet(application: application, revieweeName: otherPartyName)
        }
        .confirmationDialog("Decline this application?", isPresented: $confirmDecline, titleVisibility: .visible) {
            Button("Decline", role: .destructive) {
                applicationService.updateStatus(of: application, to: .declined)
            }
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(filled ? .white : color)
                .background(filled ? color : color.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let status: ApplicationStatus

    private var color: Color {
        switch status {
        case .pending: return AppTheme.current.accent
        case .accepted: return AppTheme.current.primary
        case .declined: return .red
        case .withdrawn: return .gray
        }
    }

    var body: some View {
        Label(status.title, systemImage: status.icon)
            .font(.system(.caption, design: .rounded).weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
    }
}

/// Sheet where a user writes a short note and applies to a listing.
struct ApplySheet: View {
    let listing: PetSittingListing
    @EnvironmentObject var applicationService: ApplicationService
    @EnvironmentObject var userProfileService: UserProfileService
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    private let theme = AppTheme.current

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    if !listing.name.isEmpty {
                        Label(listing.name, systemImage: "person.crop.circle.fill")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.text.opacity(0.7))
                    }
                }

                Text("Introduce yourself")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)

                TextEditor(text: $message)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 140)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.secondary.opacity(0.7), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Tell them about your experience with pets and why you're a good fit.")
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

                Spacer()

                Button(action: send) {
                    Group {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Label("Send application", systemImage: "paperplane.fill")
                        }
                    }
                    .themedButton()
                }
                .frame(maxWidth: .infinity)
                .disabled(isSending)
            }
            .padding()
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Apply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func send() {
        let note = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else {
            errorMessage = "Write a short note so the owner knows who you are."
            return
        }
        isSending = true
        errorMessage = nil
        applicationService.apply(to: listing,
                                 applicantName: userProfileService.userProfile?.name ?? "",
                                 message: note) { error in
            isSending = false
            if let error {
                errorMessage = "Couldn't send your application: \(error.localizedDescription)"
            } else {
                dismiss()
            }
        }
    }
}
