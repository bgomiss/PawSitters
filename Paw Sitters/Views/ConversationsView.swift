//
//  ConversationsView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.07.2024.
//

import SwiftUI
import Firebase

struct ConversationsView: View {
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var storageService: StorageService
    @Environment(\.dismiss) private var dismiss
    @Binding var userId: String
    @State private var message: Message?
    @State private var receiverId: String = ""
    @State private var isMessagingViewPresented = false
    var didSelectNewUser: (String) -> () = { _ in }
    
    var body: some View {
        // Shown inside ContentView's NavigationStack, so no navigation container of its own here.
        VStack {
            ScreenTitle("Messages", icon: "bubble.left.and.bubble.right.fill")
            ScrollView {
                conversationList
            }
            .overlay {
                if messagingService.filteredMessages.isEmpty {
                    EmptyStateView(icon: "bubble.left.and.text.bubble.right.fill",
                                   title: "No conversations yet",
                                   message: "Apply to a listing to start chatting.")
                }
            }
        }
        .onAppear {
            messagingService.fetchRecentMessages()
        }
        .onChange(of: receiverId) { _, newReceiverId in
            receiverId = newReceiverId
        }
        .fullScreenCover(isPresented: $isMessagingViewPresented) {
            MessagingView(userId: userId, receiverId: receiverId)
                .environmentObject(authService)
                .environmentObject(messagingService)
                .environmentObject(storageService)
                .environmentObject(userProfileService)

        }
    }
    
    private var conversationList: some View {
        LazyVStack(spacing: 10) {
            ForEach(messagingService.filteredMessages.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) { message in
                Button {
                    self.message = message
                    receiverId = userId == message.senderId ? message.receiverId : message.senderId
                    isMessagingViewPresented.toggle()
                } label: {
                    conversationRow(for: message)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    /// One conversation: the other person's photo and name, plus the latest message.
    private func conversationRow(for message: Message) -> some View {
        let isMine = userId == message.senderId
        let otherName = (isMine ? message.receiverName : message.senderName) ?? ""
        let otherImageUrl = (isMine ? message.receiverProfileImageUrl : message.senderProfileImageUrl) ?? ""
        let theme = AppTheme.current
        
        return HStack(spacing: 12) {
            AsyncImage(url: URL(string: otherImageUrl)) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(theme.secondary.opacity(0.45))
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherName.isEmpty ? "Paw Sitters user" : otherName)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(theme.text)
                    Spacer()
                    Text(message.timestamp.dateValue().formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(theme.text.opacity(0.5))
                }
                Text(message.messageType == "image" ? "📷 Photo" : (isMine ? "You: " : "") + message.content)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(12)
        .themedCard()
    }
    
    private func handleUserSelection(message: Message) {
        let selectedReceiverId = userId == message.senderId ? message.receiverId : message.senderId
        didSelectNewUser(selectedReceiverId)
        receiverId = selectedReceiverId
//        DispatchQueue.main.async {
//            isMessagingViewPresented.toggle()
//        }
    }
}

    struct ConversationView_Previews: PreviewProvider {
        static var previews: some View {
            ConversationsView(userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"))
            .environmentObject(MessagingService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(AuthService())
    }
}
