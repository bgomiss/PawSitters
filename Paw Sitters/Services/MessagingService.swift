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
    @EnvironmentObject var userProfileService: UserProfileService
    @ObservedObject var authService = AuthService()
    @Published var messages: [ChatMessage] = []
    @Published var chatUser: [UserProfile] = []
    @Published var users = [ChatUser]()
    @Published var recentMessages: [RecentMessage] = []

//    init(userProfileService: UserProfileService) {
//        self.userProfileService = userProfileService
//    }
    
    func sendMessage(_ message: Message) {
        let document = db.collection("messages")
            .document(message.senderId)
            .collection(message.receiverId)
            .document()
        
        let messageData = ["fromId": message.senderId, "toId": message.receiverId, "content": message.content, "timestamp": message.timestamp] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print("ERROR SAVING MESSAGE INTO FIRESTORE \(error.localizedDescription)")
                return
            }
            
        }
        
        let recipientMessageDocument = db.collection("messages")
            .document(message.receiverId)
            .collection(message.senderId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                print("ERROR SAVING MESSAGE INTO FIRESTORE \(error.localizedDescription)")
                return
            }
        }
        
        
    }
    
    func persistRecentMessage(_ message: Message) {
        guard let uid = authService.user?.uid else {return}
        
        let document = db.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(message.receiverId)
        
        let data = [
            "timestamp": message.timestamp,
            "content": message.content,
            "fromId": message.senderId,
            "toId": message.receiverId
        ] as [String : Any]
        
        document.setData(data) { error in
            if let error = error {
                print("failed to save recent message: \(error.localizedDescription)")
                return
            }
        }
    }
    
    func fetchMessages(_ toId: String) {
        guard let uid = authService.user?.uid else {return}
        db.collection("messages")
            .document(uid)
            .collection(toId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("FAILED TO LISTEM FOR MESSAGES: \(error.localizedDescription)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        DispatchQueue.main.async {
                            let newMessage = ChatMessage(documentId: change.document.documentID, data: data)
                            self.messages.append(newMessage)
                        }
                    }
                })
            }
        
    }
    
    func fetchRecentMessages() {
        guard let uid = authService.user?.uid else {return}
            db.collection("recent_messages")
            .document(uid)
            .collection("messages")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                   // if change.type == .added {
                        let docId = change.document.documentID
                        self.recentMessages.append(.init(documentId: docId, data: change.document.data()))
                    })
                }
            }
//    }
    
//    func addMessagesListener(for userId: String, onUpdate: @escaping ([Message]) -> Void) {
//        listener = db.collection("messages")
//            .whereField("receiverId", isEqualTo: userId)
//            .order(by: "timestamp", descending: false)
//            .addSnapshotListener { snapshot, error in
//                var newMessages: [Message] = []
//                if let snapshot = snapshot {
//                    let messages = snapshot.documents.compactMap { document -> Message? in
//                        try? document.data(as: Message.self)
//                    }
//                    newMessages.append(contentsOf: messages)
//                }
//                
//                self.db.collection("messages")
//                    .whereField("senderId", isEqualTo: userId)
//                    .order(by: "timestamp", descending: false)
//                    .getDocuments { snapshot, error in
//                        if let snapshot = snapshot {
//                            let sentMessages = snapshot.documents.compactMap { document -> Message? in
//                                try? document.data(as: Message.self)
//                            }
//                            newMessages.append(contentsOf: sentMessages)
//                            onUpdate(newMessages)
//                        }
//                    }
//            }
//    }
//    
//    func removeMessagesListener() {
//        listener?.remove()
//    }
    
    
    
//    func addReceiverNamesToMessages(for userId: String) {
//        let group = DispatchGroup()
//        db.collection("recent_messages")
//        .document(userId)
//        .collection("messages")
//        .addSnapshotListener { querySnapshot, error in
//            if let error = error {
//                print(error.localizedDescription)
//                return
//            }
//        
//            
//            
//                if let document = querySnapshot {
//                    if let data = document.documents {
//                        let receiverIds = Array(data.indices)
//                        
//                        for receiverId in receiverIds {
//                            group.enter()
//                            self.userProfileService.fetchUserProfile(uid: receiverId) { result in
//                                switch result {
//                                case .success(let profile):
//                                    DispatchQueue.main.async {
//                                        self.chatUser.append(profile)
//                                    }
//                                case .failure:
//                                    break
//                                }
//                                group.leave()
//                            }
//                        }
//                        
//                        group.notify(queue: .main) {
//                            print("All profiles fetched")
//                        }
//                    }
//                } else {
//                    print("Document does not exist")
//                }
//            }
//    }
}
//
//    func fetchConversations(for userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
//            db.collection("messages")
//            .document(userId)
//            .collection(receiverId)
//                .getDocuments { snapshot, error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else if let snapshot = snapshot {
//                        let senders = snapshot.documents.compactMap { document -> String? in
//                            let data = document.data()
//                            return data["senderId"] as? String
//                        }
//                        completion(.success(Array(Set(senders))))
//                    }
//                }
//        }
    
    //.environmentObject(MessagingService(userProfileService: UserProfileService(authService: AuthService())))
