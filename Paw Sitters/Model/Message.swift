//
//  Message.swift
//  Paw Sitters
//
//  Created by aycan duskun on 16.07.2024.
//

import FirebaseFirestore

struct Message: Codable, Identifiable, Hashable {
    var id: String { documentId }
    let documentId: String
    //@DocumentID var id: String?
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Timestamp
    let senderProfileImageUrl: String?
    let receiverProfileImageUrl: String?
    var receiverName: String?
    var senderName: String?
    var messageType: String?
    
    init(documentId: String, data: [String : Any]) {
        self.documentId = documentId
        self.senderId = data["senderId"] as? String ?? ""
        self.receiverId = data["receiverId"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.senderProfileImageUrl = data["senderProfileImageUrl"] as? String ?? ""
        self.receiverProfileImageUrl = data["receiverProfileImageUrl"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.receiverName = data["receiverName"] as? String ?? ""
        self.senderName = data["senderName"] as? String ?? ""
        self.messageType = data["messageType"] as? String ?? ""
    }
}

struct ChatMessage: Identifiable {
    var id: String { documentId }
    let documentId: String
    let timestamp: Timestamp
    let senderId, receiverId, content : String
    init(documentId: String, data: [String : Any]) {
        self.documentId = documentId
        self.senderId = data["fromId"] as? String ?? ""
        self.receiverId = data["toId"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}

struct RecentMessage: Hashable, Identifiable {
    var id: String { documentId }
    let documentId: String
    let timestamp: Timestamp
    let senderId, receiverId, content : String
    init(documentId: String, data: [String : Any]) {
        self.documentId = documentId
        self.senderId = data["fromId"] as? String ?? ""
        self.receiverId = data["toId"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        }
    }

