//
//  ConversationsView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.07.2024.
//

import SwiftUI
import Firebase

struct ConversationsView: View {
    @ObservedObject var messagingService: MessagingService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @Binding var userId: String // Örnek olarak currentUserId
    @State private var conversations: [String] = []
    @State private var receiverNames: [String] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(messagingService.recentMessages) { user in
                        HStack {
//                            let url = URL(string: user.profileImageUrl ?? "")
//                            AsyncImage(url: url)
//                                .aspectRatio(contentMode: .fill)
//                                .frame(width: 50, height: 50)
//                                .clipShape(Circle())
                            
                            //                         Image(systemName: "person.crop.circle")
                            //                               .resizable()
                            //                               .frame(width: 64, height: 64)
                            //                               .clipped()
                            //                               .clipShape(.circle)
                            
                            Text(user.content)
                                .font(.caption)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding()
                    }
                    //            List(receiverNames.indices, id: \.self) { index in
                    //                let receiverId = conversations[index]
                    //                let receiverName = receiverNames[index]
                    //                NavigationLink(destination: MessagingView(userId: $userId, receiverId: receiverId)) {
                }
                .navigationBarTitle("MESSAGES")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 2)) {
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            messagingService.fetchRecentMessages()
        }
    }
}
    


struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView(messagingService: MessagingService(), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"))
            .environmentObject(MessagingService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(AuthService())
    }
}
