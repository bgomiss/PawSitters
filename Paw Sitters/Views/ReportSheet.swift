//
//  ReportSheet.swift
//  Paw Sitters
//
//  Sheet for reporting a listing, user or review, with an option to also
//  block the person responsible. Also the "Blocked users" list in Profile.
//

import SwiftUI

struct ReportSheet: View {
    let target: ReportTarget
    @EnvironmentObject var moderationService: ModerationService
    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason?
    @State private var details = ""
    @State private var alsoBlock = true
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var didSend = false
    @FocusState private var isDetailsFocused: Bool
    private let theme = AppTheme.current

    private var title: String {
        switch target {
        case .listing: return "Report listing"
        case .user: return "Report user"
        case .review: return "Report review"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if didSend {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(theme.primary)
                        Text("Thanks for letting us know")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.text)
                        Text("Our team reviews every report within 24 hours and removes content that breaks our rules.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Button("Done") { dismiss() }
                            .themedButton()
                            .padding(.top, 8)
                    }
                    .padding(32)
                    .frame(maxHeight: .infinity)
                } else {
                    form
                }
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !didSend {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isDetailsFocused = false }
                }
            }
        }
        // Don't lose a half-written report to an accidental swipe.
        .interactiveDismissDisabled(!didSend && (reason != nil || !details.isEmpty))
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's wrong?")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)

                VStack(spacing: 0) {
                    ForEach(ReportReason.allCases) { option in
                        Button {
                            reason = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(theme.text)
                                Spacer()
                                Image(systemName: reason == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(reason == option ? theme.primary : theme.text.opacity(0.3))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if option != ReportReason.allCases.last { Divider().padding(.leading, 14) }
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                TextField("Add details (optional)", text: $details, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($isDetailsFocused)
                    .padding(12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Toggle(isOn: $alsoBlock) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Also block this person")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text("You won't see their listings or messages anymore.")
                            .font(.caption)
                            .foregroundStyle(theme.text.opacity(0.6))
                    }
                }
                .tint(theme.primary)
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(action: send) {
                    Group {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send report")
                        }
                    }
                    .themedButton(Color.red.opacity(reason == nil ? 0.4 : 0.85))
                    .frame(maxWidth: .infinity)
                }
                .disabled(reason == nil || isSending)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func send() {
        guard let reason else { return }
        isSending = true
        errorMessage = nil
        moderationService.report(target, reason: reason,
                                 details: details.trimmingCharacters(in: .whitespacesAndNewlines)) { error in
            isSending = false
            if let error {
                errorMessage = "Couldn't send the report: \(error.localizedDescription)"
                return
            }
            if alsoBlock { moderationService.block(target.reportedUserId) }
            withAnimation { didSend = true }
        }
    }
}

/// "…" menu with Report and Block actions for content made by another user.
struct ModerationMenu: View {
    let target: ReportTarget
    var tint: Color = AppTheme.current.text
    @EnvironmentObject var moderationService: ModerationService
    @State private var isReportPresented = false
    @State private var confirmBlock = false

    var body: some View {
        Menu {
            Button(role: .destructive) {
                isReportPresented = true
            } label: {
                Label("Report", systemImage: "exclamationmark.bubble")
            }
            if moderationService.isBlocked(target.reportedUserId) {
                Button {
                    moderationService.unblock(target.reportedUserId)
                } label: {
                    Label("Unblock", systemImage: "hand.raised.slash")
                }
            } else {
                Button(role: .destructive) {
                    confirmBlock = true
                } label: {
                    Label("Block", systemImage: "hand.raised.fill")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .accessibilityLabel("More options")
        }
        .sheet(isPresented: $isReportPresented) {
            ReportSheet(target: target)
        }
        .confirmationDialog("Block this person?", isPresented: $confirmBlock, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                moderationService.block(target.reportedUserId)
            }
        } message: {
            Text("You won't see their listings, applications or messages, and they won't be able to reach you through Paw Sitters.")
        }
    }
}

/// Profile section listing blocked users with an Unblock button.
struct BlockedUsersSection: View {
    @EnvironmentObject var moderationService: ModerationService
    @EnvironmentObject var userProfileService: UserProfileService
    private let theme = AppTheme.current

    var body: some View {
        if !moderationService.blockedIds.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Blocked users", systemImage: "hand.raised.fill")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)
                ForEach(moderationService.blockedIds.sorted(), id: \.self) { userId in
                    HStack {
                        Text(userProfileService.cachedProfile(uid: userId)?.name ?? "Paw Sitters user")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.text)
                        Spacer()
                        Button("Unblock") { moderationService.unblock(userId) }
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.primary)
                    }
                }
            }
            .padding(18)
            .themedCard()
        }
    }
}
