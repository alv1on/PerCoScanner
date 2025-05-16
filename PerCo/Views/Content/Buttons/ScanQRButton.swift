import SwiftUI

struct ScanQRButton: View {
    @Binding var isShowingScanner: Bool
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: { withAnimation { isShowingScanner = true } }) {
            Image(systemName: "qrcode.viewfinder")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.gray, .blue)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                        isAnimating.toggle()
                    }
                }
        }
    }
}
