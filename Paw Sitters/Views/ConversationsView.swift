//
//  ConversationsView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.07.2024.
//

import SwiftUI
import Firebase

struct ConversationsView: View {
    @ObservedObject var messagingService: MessagingService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @Binding var userId: String
    @State private var receiverId: String?
    @State private var isMessagingViewPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                conversationList
                    .navigationBarTitle("MESSAGES")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            backButton
                        }
                    }
            }
        }
        .onAppear {
            messagingService.fetchRecentMessages()
        }
        .fullScreenCover(isPresented: $isMessagingViewPresented) {
                MessagingView(messagingService: messagingService, userId: $userId, receiverId: $receiverId)
        }
    }
    
    private var conversationList: some View {
        VStack(spacing: 10) {
            ForEach(messagingService.filteredMessages) { message in
                HStack {
                    ImageView.userImageView(for: message, for: nil)
                        .onTapGesture {
                            setReceiverAndShowMessagingView(message: message)
                        }
                    userMessagesView(for: message)
                        .onTapGesture {
                           setReceiverAndShowMessagingView(message: message)
                        }
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private func userMessagesView(for message: Message) -> some View {
        VStack {
            if userId == message.senderId {
                Text(message.receiverName ?? "")
            } else {
                Text(message.senderName ?? "")
            }
        }
    }
        
    
    
    private var backButton: some View {
        Button(action: {
            withAnimation(.snappy(duration: 2)) {
                dismiss()
            }
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }
    
    private func setReceiverAndShowMessagingView(message: Message) {
        DispatchQueue.main.async {
            if userId == message.senderId {
                receiverId = message.receiverId
            } else {
                receiverId = message.senderId
            }
            isMessagingViewPresented = true
        }
    }
}



struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView(messagingService: MessagingService(), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"))
            .environmentObject(MessagingService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(AuthService())
    }
}
