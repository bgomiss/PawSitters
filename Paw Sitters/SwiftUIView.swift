//
//  SwiftUIView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 14.09.2024.
//

import SwiftUI

struct CustomTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Custom segmented control
            HStack {
                // Yaklaşan Talimatlarım Button
                Button(action: {
                    selectedTab = 0
                }) {
                    Text("Yaklaşan Talimatlarım")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTab == 0 ? .black : .gray)
                }

                // Son Talimatlarım Button
                Button(action: {
                    selectedTab = 1
                }) {
                    Text("Son Talimatlarım")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTab == 1 ? .black : .gray)
                }
                
                // Ödeme Talimatları Button
                Button(action: {
                    selectedTab = 2
                }) {
                    Text("Ödeme Talimatları")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTab == 2 ? .black : .gray)
                }
            }
            .padding(.vertical, 8)

            // Progress Indicator
            HStack(spacing: 0) {
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(selectedTab == 0 ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)

                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(selectedTab == 1 ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)

                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(selectedTab == 2 ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
            }
            .padding(.bottom, 8)

            // Swipeable views
            TabView(selection: $selectedTab) {
                // View for "Yaklaşan Talimatlarım"
                VStack {
                    Spacer()
                    Text("Yaklaşan talimatınız bulunmamaktadır.")
                        .font(.headline)
                    Spacer()
                    Button(action: {}) {
                        Text("Fatura Ödeme Talimatları")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    Button(action: {}) {
                        Text("Kredi Kartı Otomatik Ödeme Talimatları")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                    Spacer()
                }
                .tag(0)

                // View for "Son Talimatlarım"
                VStack {
                    Spacer()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ödemeler")
                                .font(.headline)
                                .padding(.leading)
                            ForEach(0..<5) { index in
                                Text("ALICI ADI alıcısına \(index * 200 + 100),00 TL ödeme yapıldı.")
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("Fatura Ödeme Talimatları")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)

                    Button(action: {}) {
                        Text("Kredi Kartı Otomatik Ödeme Talimatları")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                    Spacer()
                }
                .tag(1)

                // View for "Ödeme Talimatları"
                VStack {
                    Spacer()
                    Text("Ödeme Talimatları Sayfası")
                        .font(.headline)
                    Spacer()
                    Button(action: {}) {
                        Text("Fatura Ödeme Talimatları")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)

                    Button(action: {}) {
                        Text("Kredi Kartı Otomatik Ödeme Talimatları")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                    Spacer()
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabView()
    }
}
