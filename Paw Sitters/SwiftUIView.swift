//
//  SwiftUIView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 14.09.2024.
//

import SwiftUI

struct SwiftUIView: View {
    
    
  
        @State private var isExpanded = false

        var body: some View {
            VStack {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Öne Çıkanlar")
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .rotationEffect(.degrees(isExpanded ? 0 : 180))
                            .animation(.snappy, value: isExpanded)
                    }
                    .padding()
                }

                if isExpanded {
                                    VStack(alignment: .leading) {
                                        Text("Anahtar kelimeleri otomatik olarak bulun")
                                        Text("Hedef anahtar kelimeler veya ürünler")
                                    }
                                    .padding()
                                }
            }
            .border(Color.gray, width: 1)
            .padding()
        }
    }




#Preview {
    SwiftUIView()
}
