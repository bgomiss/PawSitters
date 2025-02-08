//
//  File.swift
//  Paw Sitters
//
//  Created by aycan duskun on 8.10.2024.
//

import SwiftUI
import Firebase

class MessagingViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessage: String = ""
    @Published var senderProfileImageUrl: String = ""
    @Published var senderName: String = ""
    @Published var receiverProfileImageUrl: String = ""
    @Published var receiverName: String = ""
    
    let userId: String
    let receiverId: String
    
    var messagingService: MessagingService?
    var storageService: StorageService?
    var userProfileService: UserProfileService?
    
    init(receiverId: String, userId: String) {
        self.receiverId = receiverId
        self.userId = userId
    }
    
    func fetchMessages() {
        guard let messagingService = messagingService else { return }
        messagingService.fetchMessages(receiverId)
        // Subscribe to messages updates
        messagingService.$messages.assign(to: &$messages)
    }
    
    func sendMessage() {
        guard !newMessage.isEmpty, let messagingService = messagingService else { return }
        
        let sentMessage: [String: Any] = [
            "senderId": userId,
            "receiverId": receiverId,
            "content": newMessage,
            "timestamp": Timestamp(date: Date()),
            "senderProfileImageUrl": self.senderProfileImageUrl,
            "receiverProfileImageUrl": self.receiverProfileImageUrl,
            "receiverName": self.receiverName,
            "senderName": self.senderName,
            "messageType": "text"
        ]
        
        messagingService.sendMessage(sentMessage)
        messagingService.persistRecentMessage(sentMessage)
        self.newMessage = ""
    }
    
    func sendImageMessage(imageURL: String) {
        guard let messagingService = messagingService else { return }

        let sentMessage: [String: Any] = [
            "senderId": userId,
            "receiverId": receiverId,
            "content": imageURL,
            "timestamp": Timestamp(date: Date()),
            "senderProfileImageUrl": self.senderProfileImageUrl,
            "receiverProfileImageUrl": self.receiverProfileImageUrl,
            "receiverName": self.receiverName,
            "senderName": self.senderName,
            "messageType": "image"
        ]
        
        messagingService.sendMessage(sentMessage)
        messagingService.persistRecentMessage(sentMessage)
    }
    
    func fetchUserProfiles() {
        guard let userProfileService = userProfileService else { return }

        // Fetch current user
        userProfileService.fetchUserProfile(uid: userId) { [weak self] _ in
            DispatchQueue.main.async {
                self?.senderProfileImageUrl = userProfileService.userProfile?.profileImageUrl ?? ""
                self?.senderName = userProfileService.userProfile?.name ?? ""
            }
        }
        
        // Fetch receiver user
        userProfileService.fetchUserProfile(uid: receiverId) { [weak self] _ in
            DispatchQueue.main.async {
                self?.receiverProfileImageUrl = userProfileService.userProfile?.profileImageUrl ?? ""
                self?.receiverName = userProfileService.userProfile?.name ?? ""
            }
        }
    }
    
    func uploadImage(_ image: UIImage) {
        guard let storageService = storageService else { return }
        
        storageService.uploadImageToFirestore(image: image) { [weak self] imageURL in
            if let imageURL = imageURL {
                self?.sendImageMessage(imageURL: imageURL)
            } else {
                print("Failed to upload image")
            }
        }
    }
}



