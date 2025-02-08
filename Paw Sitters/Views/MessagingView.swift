//
//  MessagingView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI
import Firebase

struct MessagingView: View {
    @StateObject private var viewModel: MessagingViewModel
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var userProfileService: UserProfileService
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var selectedImage: [UIImage] = []

    init(userId: String, receiverId: String) {
        _viewModel = StateObject(wrappedValue: MessagingViewModel(receiverId: receiverId, userId: userId))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                MessageList(messages: viewModel.messages, userId: viewModel.userId)
                ChatBottomBar(viewModel: viewModel, showingImagePicker: $showingImagePicker)
            }
            .navigationBarTitle("MESSAGES", displayMode: .inline)
            .navigationBarItems(leading: backButton)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .onAppear {
            viewModel.messagingService = messagingService
            viewModel.storageService = storageService
            viewModel.userProfileService = userProfileService
            
            viewModel.fetchMessages()
            viewModel.fetchUserProfiles()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(images: $selectedImage, isForMessaging: true)
        }
        .onChange(of: selectedImage) { _, newValue in
            if let image = selectedImage.first {
                viewModel.uploadImage(image)
                //selectedImage = nil
            }
        }
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }
}

struct MessageList: View {
    let messages: [Message]
    let userId: String
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack {
                    ForEach(messages) { message in
                        MessageBubble(message: message, isCurrentUser: message.senderId == userId)
                    }
                }
                .padding(.top)
            }
            .onChange(of: messages) { _, newMessages in
                if let lastMessage = messages.last {
                    withAnimation {
                        scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct ChatBottomBar: View {
    @ObservedObject var viewModel: MessagingViewModel
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 22))
                    .foregroundColor(Color(.darkGray))
            }
            
            TextField("Type a message", text: $viewModel.newMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minHeight: 40)
                
            Button(action: viewModel.sendMessage) {
                Text("Send")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.newMessage.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName ?? "")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                if message.messageType == "image" {
                    AsyncImage(url: URL(string: message.content)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Text(message.content)
                        .padding(10)
                        .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(isCurrentUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MessagingView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingView(userId: "9FFPiZroJ2Nb9zneZer9NDleUpM2", receiverId: "9FFPiZroJ2Nb9zneZer9NDleUpM2")
    }
}
