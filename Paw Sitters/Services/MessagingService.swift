//
//  MessagingService.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI

class MessagingService: ObservableObject {
    private var db = Firestore.firestore()
    @ObservedObject var userProfileService = UserProfileService(authService: AuthService())
    @ObservedObject var authService = AuthService()
    @Published var messages: [Message] = []
    @Published var chatUser: [UserProfile] = []
    @Published var users = [ChatUser]()
    @Published var recentMessages: [Message] = []
    // Add a new published property to hold filtered messages
    @Published var filteredMessages: [Message] = []
    @Published var count = 0
    
    //        init(userProfileService: UserProfileService) {
    //            self.userProfileService = userProfileService
    //        }
    
    func sendMessage(_ senderMessage: [String : Any]) {
        
        let fromId = senderMessage["senderId"] as! String
        let toId = senderMessage["receiverId"] as! String
        
        let document = db.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        DispatchQueue.main.async {
            document.setData(senderMessage) { error in
                if let error = error {
                    print("ERROR SAVING MESSAGE INTO FIRESTORE \(error.localizedDescription)")
                    return
                }
            }
            self.count += 1
        }
        
        let recipientMessageDocument = db.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        DispatchQueue.main.async {
            recipientMessageDocument.setData(senderMessage) { error in
                if let error = error {
                    print("ERROR SAVING MESSAGE INTO FIRESTORE \(error.localizedDescription)")
                    return
                }
            }
        }
    }
    
    func persistRecentMessage(_ sentMessage: [String : Any]) {
        guard let uid = authService.user?.uid else {return}
        
        let toId = sentMessage["receiverId"] as! String
        let fromId = sentMessage["senderId"] as! String
        
        let document = db.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        document.setData(sentMessage) { error in
            if let error = error {
                print("failed to save recent message: \(error.localizedDescription)")
                return
            }
        }
        
        let recipientRecentMessageDocument = db.collection("recent_messages")
            .document(toId)
            .collection("messages")
            .document(fromId)
        
        recipientRecentMessageDocument.setData(sentMessage) { error in
            if let error = error {
                print("failed to save recent message: \(error.localizedDescription)")
                return
            }
        }
    }
    
    func fetchMessages(_ toId: String) {
        guard let uid = authService.user?.uid else {return}
        self.messages.removeAll()
        db.collection("messages")
            .document(uid)
            .collection(toId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("FAILED TO LISTEM FOR MESSAGES: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    querySnapshot?.documentChanges.forEach({ change in
                        let docId = change.document.documentID
                        let data = change.document.data()
                        
                        switch change.type {
                        case .added:
                            if !self.messages.contains(where: { $0.documentId == docId }) {
                                let newMessage = Message(documentId: docId, data: data)
                                self.messages.append(newMessage)
                                DispatchQueue.main.async {
                                    self.count += 1
                                }
                            }
                        case .removed:
                            self.messages.removeAll() { $0.documentId == docId }
                        default:
                            break
                        }
                    })
                }
            }
        }
    
    
    func fetchRecentMessages() {
        
        guard let uid = authService.user?.uid else { return }
        db.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                DispatchQueue.main.async {
                    querySnapshot?.documentChanges.forEach { change in
                        let docId = change.document.documentID
                        let data = change.document.data()
                        
                        switch change.type {
                        case .added:
                            if !self.recentMessages.contains(where: { $0.documentId == docId }) {
                                let newMessage = Message(documentId: docId, data: data)
                                self.recentMessages.append(newMessage)
                                print("RECENT MESSAGES: \(self.recentMessages)")
                                
                            }
                        case .removed:
                            
                            self.recentMessages.removeAll() { $0.documentId == docId }
                            
                        default: break
                        }
                    }
                    self.filterMessages(for: uid)
                    print("ALL PROFILES FETCHED")
                    print("\(self.filteredMessages)")
                }
            }
    }
    
    func filterMessages(for userId: String) {
        self.filteredMessages = self.recentMessages.filter { $0.receiverId == userId || $0.senderId == userId }
    }
    
    
    func clearMessages() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }
}
    
