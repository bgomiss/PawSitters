//
//  ChatBubbles.swift
//  Paw Sitters
//
//  Created by aycan duskun on 16.07.2024.
//

import SwiftUI

struct SenderBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing) {
                Text(message.senderName ?? "")
                    .font(.caption)
                HStack {
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ReceiverBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(message.receiverName ?? "")
                    .font(.caption)
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text(message.content)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
