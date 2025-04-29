import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainView = false
    
    var body: some View {
        Group {
            if showMainView {
                ContentView()
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        Image("perco-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                        
                        Text("PerCo")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showMainView = true
                }
            }
        }
    }
}
