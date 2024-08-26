//
//  MessagingView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI
import Firebase

struct MessagingView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var messagingService: MessagingService
    @EnvironmentObject var userProfileService: UserProfileService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) var isPresented
    @Binding var userId: String
    @State var message: Message?
    @State private var newMessage: String = ""
    @State private var senderProfileImageUrl: String = ""
    @State private var senderName: String = ""
    @State private var receiverProfileImageUrl: String = ""
    @State private var receiverName: String = ""
    @State var receiverId: String
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(messagingService.messages) { message in
                    
                    if message.senderId == userId {
                        HStack {
                            Spacer()
                            HStack {
                                Text(message.content)
                                    .foregroundColor(.white)
                                ImageView.userImageView(for: nil, for: message)
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    } else {
                        HStack {
                            HStack {
                                ImageView.userImageView(for: message, for: nil)
                                Text(message.content)
                                    .foregroundColor(.black)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            Spacer()
                        }
                    }
                }
                .id(message)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            HStack { Spacer() }
                .onChange(of: message) { _, newMessage in
                    withAnimation {
                        proxy.scrollTo(messagingService.messages.last)
                    }
                }
                .onAppear {
                    proxy.scrollTo(messagingService.messages.last, anchor: .bottom)
                }
            }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .padding(.bottom, 5)
        .safeAreaInset(edge: .bottom) {
            chatBottomBar
        }
        .safeAreaInset(edge: .top) {
            if isPresented {
                backButton
            }
        }
        .background(Color(.systemBackground)
            .ignoresSafeArea())
        .onAppear {
            messagingService.fetchMessages(receiverId)
            fetchTheUser()
        }
        .onChange(of: receiverId) { _, newReceiverId in
            messagingService.clearMessages()
            messagingService.fetchMessages(newReceiverId)
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
                Spacer()
            }
            .padding()
        }
    }
    
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            TextField("Enter Message", text: $newMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: sendMessage) {
                Text("Send")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue) // Set background color to blue
                    .foregroundColor(.white) // Set text color to white
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    
     private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
       let sentMessage = [
            "senderId": userId,
            "receiverId": receiverId,
            "content": newMessage,
            "timestamp": Timestamp(date: Date()),
            "senderProfileImageUrl": self.senderProfileImageUrl,
            "receiverProfileImageUrl": self.receiverProfileImageUrl,
            "receiverName": self.receiverName,
            "senderName": self.senderName] as [String : Any]
        
        messagingService.sendMessage(sentMessage)
        messagingService.persistRecentMessage(sentMessage)
        self.newMessage = ""
    }
    
    
    private func fetchTheUser() {
        guard let currentUserId = authService.user?.uid else { return }
        
        // Fetch current user
        userProfileService.fetchUserProfile(uid: currentUserId) { _ in
            DispatchQueue.main.async {
                self.senderProfileImageUrl = userProfileService.userProfile?.profileImageUrl ?? ""
                self.senderName = userProfileService.userProfile?.name ?? ""
            }
        }
        
        // Fetch receiver user
        userProfileService.fetchUserProfile(uid: receiverId) { _ in
            DispatchQueue.main.async {
                self.receiverProfileImageUrl = userProfileService.userProfile?.profileImageUrl ?? ""
                self.receiverName = userProfileService.userProfile?.name ?? ""
            }
        }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingView(messagingService: MessagingService(), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), receiverId: "HZHDnLPFWfftcb3e0Mjz4DIoYZn2")
            .environmentObject(MessagingService())
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
    }
}
