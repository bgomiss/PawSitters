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
    @State private var message: Message?
    @State private var receiverId: String = ""
    @State private var isMessagingViewPresented = false
    var didSelectNewUser: (String) -> () = { _ in }
    
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
        .onChange(of: receiverId) { _, newReceiverId in
            receiverId = newReceiverId
        }
        .fullScreenCover(isPresented: $isMessagingViewPresented) {
            MessagingView(messagingService: messagingService, userId: $userId, receiverId: receiverId)
        }
    }
    
    private var conversationList: some View {
        VStack(spacing: 10) {
            ForEach(messagingService.filteredMessages) { message in
                HStack {
                    ImageView.userImageView(for: message, for: nil)
                        .onTapGesture {
                            self.message = message
                            receiverId = userId == message.senderId ? message.receiverId : message.senderId
                            isMessagingViewPresented.toggle()
                        }
                    userMessagesView(for: message)
                        .onTapGesture {
                            self.message = message
                            receiverId = userId == message.senderId ? message.receiverId : message.senderId
                            isMessagingViewPresented.toggle()

                        }
                    Spacer()
                }
                .padding()
                Divider()
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
        ConversationsView(messagingService: MessagingService(), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"))
            .environmentObject(MessagingService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(AuthService())
    }
}
