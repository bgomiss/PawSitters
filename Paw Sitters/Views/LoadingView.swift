import SwiftUI

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
    }
}

// Usage in ContentView:
if viewModel.isLoading {
    LoadingView(message: "Loading listings...")
} 