//
//  Message.swift
//  Paw Sitters
//
//  Created by aycan duskun on 16.07.2024.
//

import FirebaseFirestore

struct Message: Codable, Identifiable {
//    var id: String { documentId }
//    let documentId: String?
    @DocumentID var id: String?
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Timestamp
    let profileImageUrl: String?
    var receiverName: String?
    var senderName: String?
    
//    init(documentId: String, data: [String : Any]) {
//        self.documentId = documentId
//        self.senderId = data["senderId"] as? String ?? ""
//        self.receiverId = data["receiverId"] as? String ?? ""
//        self.content = data["content"] as? String ?? ""
//        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
//        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
//        self.receiverName = data["senderId"] as? String ?? ""
//        self.senderName = data["senderId"] as? String ?? ""
//    }
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

struct RecentMessage: Identifiable {
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

