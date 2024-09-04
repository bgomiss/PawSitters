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
    @ObservedObject var storageService: StorageService
    @EnvironmentObject var userProfileService: UserProfileService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) var isPresented
    @Binding var userId: String
    @State var message: Message?
    @State private var images: [UIImage] = []
    @State private var newMessage: String = ""
    @State private var senderProfileImageUrl: String = ""
    @State private var senderName: String = ""
    @State private var receiverProfileImageUrl: String = ""
    @State private var receiverName: String = ""
    @State private var showingImagePicker = false
    @State var receiverId: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                messagesView
            }
            //        .navigationBarItems(trailing: Button(action: {
            //            messagingService.count += 1
            //        }, label: {
            //            Text("Count: \(messagingService.count)")
            //        }))
            .navigationBarTitle("MESSAGES")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground)
                .ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                    }
                }
            .onAppear {
                messagingService.fetchMessages(receiverId)
                fetchTheUser()
            }
            .onChange(of: receiverId) { _, newReceiverId in
                messagingService.clearMessages()
                messagingService.fetchMessages(newReceiverId)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(images: $images, isForMessaging: true)
        }
        .onChange(of: images) {_, newImages in
            if let selectedImage = newImages.first {
                storageService.uploadImageToFirestore(image: selectedImage) { imageURL in
                    if let imageURL = imageURL {
                        sendImageMessage(imageURL: imageURL) // Resim yüklendikten sonra mesaj gönder
                        } else {
                            print("Failed to upload image")
                    }
                }
            }
        }
    }

    private func sendImageMessage(imageURL: String) {
        let sentMessage = [
            "senderId": userId,
            "receiverId": receiverId,
            "content": imageURL, // Send image URL instead of text
            "timestamp": Timestamp(date: Date()),
            "senderProfileImageUrl": self.senderProfileImageUrl,
            "receiverProfileImageUrl": self.receiverProfileImageUrl,
            "receiverName": self.receiverName,
            "senderName": self.senderName,
            "messageType": "image" // Add a message type to differentiate image and text
        ] as [String : Any]

        messagingService.sendMessage(sentMessage)
        messagingService.persistRecentMessage(sentMessage)
    }
    
    private var backButton: some View {
        Button(action: {
            withAnimation(.snappy(duration: 2)) {
                dismiss()
            }
        }) {
            HStack(spacing: 1) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                    .padding(.leading, 5)
                    //.background(Color.black.opacity(0.6))
                Text("Back")
                Spacer()
            }
            .padding()
        }
    }
    
    struct MessageView: View {
        
        let message: Message
        @EnvironmentObject var authService: AuthService
        
        var body: some View {
            VStack {
                if message.senderId == authService.user?.uid {
                    HStack {
                        Spacer()
                        HStack {
                            if message.messageType == "image" {
                                // Display image from URL
                                AsyncImage(url: URL(string: message.content)) { image in
                                    image.resizable()
                                         .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 200, height: 200)
                            } else {
                                Text(message.content)
                                    .foregroundColor(.white)
                                //ImageView.userImageView(for: nil, for: message)
                            }
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
            } else {
                HStack {
                    HStack {
                        if message.messageType == "image" {
                            if message.messageType == "image" {
                                // Display image from URL
                                AsyncImage(url: URL(string: message.content)) { image in
                                    image.resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 200, height: 200)
                            } else {
                                //  ImageView.userImageView(for: message, for: nil)
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
        }
        .padding(.horizontal)
        .padding(.top, 8)
        }
    }
    
    static let emptyScrollToString = "Empty"
    
    private var messagesView: some View {
        VStack {
            ScrollView {
                ScrollViewReader { ScrollViewProxy in
                    VStack {
                        ForEach(messagingService.messages) { message in
                            MessageView(message: message)
                        }
                        HStack { Spacer() }
                        .id(Self.emptyScrollToString)
                    }
                    .onReceive(messagingService.$count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            ScrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                        }
                    }
                }
                
                    //                .onChange(of: message) { _, newMessage in
                    //                    withAnimation {
                    //                        proxy.scrollTo(messagingService.messages.last)
                    //                    }
                    //                }
                    //                .onAppear {
                    //                    proxy.scrollTo(messagingService.messages.last, anchor: .bottom)
                    //                }
                }
                .background(Color(.init(white: 0.95, alpha: 1)))
                .safeAreaInset(edge: .bottom) {
                    chatBottomBar
                        .background(Color(.systemBackground)
                            .ignoresSafeArea())
                }
             }
        }
    
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
                .onTapGesture {
                    showingImagePicker = true
                }
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $newMessage)
                    .opacity(newMessage.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
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
    
    private struct DescriptionPlaceholder: View {
        var body: some View {
            HStack {
                Text("Enter Message")
                    .foregroundColor(Color(.gray))
                    .font(.system(size: 17))
                    .padding(.leading, 5)
                    .padding(.top, -4)
                Spacer()
            }
        }
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
