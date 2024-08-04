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
        
        //        let messageData = [
        //            "fromId": message.senderId,
        //            "toId": message.receiverId,
        //            "content": message.content,
        //            "timestamp": message.timestamp,
        //            "profileImageUrl": message.senderProfileImageUrl ?? "",
        //            "name": message.senderName ?? ""] as [String : Any]
        
        document.setData(senderMessage) { error in
            if let error = error {
                print("ERROR SAVING MESSAGE INTO FIRESTORE \(error.localizedDescription)")
                return
            }
            
        }
        
        let recipientMessageDocument = db.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        //        let receivermessageData = ["fromId": message.senderId, "toId": message.receiverId, "content": message.content, "timestamp": message.timestamp, "profileImageUrl": message.receiverProfileImageUrl ?? "", "name": message.receiverName ?? ""] as [String : Any]
        
        recipientMessageDocument.setData(senderMessage) { error in
            if let error = error {
                print("ERROR SAVING MESSAGE INTO FIRESTORE \(error.localizedDescription)")
                return
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
        
        //        let senderdata = [
        //            "timestamp": message.timestamp,
        //            "content": message.content,
        //            "fromId": message.senderId,
        //            "toId": message.receiverId,
        //            "profileImageUrl": message.senderProfileImageUrl ?? "",
        //            "name": message.senderName ?? ""
        //        ] as [String : Any]
        
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
        
        //        let receiverdata = [
        //            "timestamp": message.timestamp,
        //            "content": message.content,
        //            "fromId": message.senderId,
        //            "toId": message.receiverId,
        //            "profileImageUrl": message.receiverProfileImageUrl ?? "",
        //            "name": message.receiverName ?? ""
        //        ] as [String : Any]
        
        recipientRecentMessageDocument.setData(sentMessage) { error in
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
                
                DispatchQueue.main.async {
                    querySnapshot?.documentChanges.forEach({ change in
                        let docId = change.document.documentID
                        let data = change.document.data()

                        switch change.type {
                        case .added:
                            let newMessage = Message(documentId: docId, data: data)
                            self.messages.append(newMessage)
                            print("MESSAGES: \(self.messages)")
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
}
    
    
//    func addReceiverNamesToMessages(for userId: String, documentId: String, completion: @escaping () -> Void) {
//            db.collection("recent_messages")
//                .document(userId)
//                .collection("messages")
//                .document(documentId)
//                .getDocument { documentSnapshot, error in
//                    if let error = error {
//                        print(error.localizedDescription)
//                        completion()
//                        return
//                    }
//
//                    if let documentSnapshot = documentSnapshot, let data = documentSnapshot.data() {
//                        if let senderId = data["fromId"] as? String, !self.chatUser.contains(where: { $0.id == userId }) {
//                            self.userProfileService.fetchUserProfile(uid: senderId) { result in
//                                switch result {
//                                case .success(let profile):
//                                    DispatchQueue.main.async {
//                                        self.chatUser.append(profile)
//                                    }
//                                case .failure:
//                                    break
//                                }
//                                completion()
//                            }
//                        } else {
//                            completion()
//                        }
//                    } else {
//                        completion()
//                    }
//                }
//        }
    // Update filteredMessages based on the current recentMessages
//       func updateFilteredMessages() {
//           DispatchQueue.main.async {
//               self.filteredMessages = self.recentMessages
//           }
//       }

       // New function to filter messages for a specific user
       
    



//    }
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
//}
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
