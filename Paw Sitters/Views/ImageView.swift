//
//  ImageView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 4.08.2024.
//

import SwiftUI

struct ImageView {
    
    static func userImageView(for recieverMessage: Message?, for senderMessage: Message?) -> some View {
        Group {
            if let url = URL(string: recieverMessage?.receiverProfileImageUrl ?? "") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(10)
            } else {
                if let url = URL(string: senderMessage?.senderProfileImageUrl ?? "") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .cornerRadius(10)
                }
            }
        }
    }
}
