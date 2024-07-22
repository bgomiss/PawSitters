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
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var userProfileService: UserProfileService
    @Binding var userId: String
    @State var message: Message?
    @State private var newMessage: String = ""
    @State var receiverId: String
    
    var body: some View {
        ScrollView {
            ForEach(messagingService.messages) { message in
                VStack {
                    if message.senderId == userId { 
                        HStack {
                            Spacer()
                            HStack {
                                Text(message.content)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    } else {
                        HStack {
                            HStack {
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
                .padding(.horizontal)
                .padding(.top, 8)
            }
            HStack { Spacer() }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .safeAreaInset(edge: .bottom) {
            chatBottomBar
        }
        .background(Color(.systemBackground)
            .ignoresSafeArea())
        .onAppear {
            messagingService.fetchMessages(receiverId)
        }
    }
        
//            messagingService.addMessagesListener(for: userId) { newMessage in
//                self.messages = newMessage
//            }
        
//
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

            message = Message(senderId: userId, receiverId: receiverId, content: newMessage, timestamp: Timestamp(date: Date()), profileImageUrl: "")

        messagingService.sendMessage(message ?? Message(senderId: "", receiverId: "", content: "", timestamp: Timestamp(date: Date()), profileImageUrl: ""))
            messagingService.persistRecentMessage(message ?? Message(senderId: "", receiverId: "", content: "", timestamp: Timestamp(date: Date()), profileImageUrl: ""))
            self.newMessage = ""
        }
    }

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingView(userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), receiverId: "HZHDnLPFWfftcb3e0Mjz4DIoYZn2")
            .environmentObject(MessagingService())
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
    }
}
