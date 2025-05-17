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
                        Spacer()
                    
                        VStack {
                            Image("perco-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                            
                            Text("PerCo")
                                .font(.title)
                                .foregroundColor(.gray)
                                .padding(.top, 16)
                        }
                        .frame(maxHeight: .infinity)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("PerCo Time Tracker")
                            let currentYear = Calendar.current.component(.year, from: Date())
                            Text("Copyright © 2020-\(String(format: "%04d", currentYear))")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
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
