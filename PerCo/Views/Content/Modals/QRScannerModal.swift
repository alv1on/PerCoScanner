import SwiftUI

struct QRScannerModal: View {
    @Binding var isPresented: Bool
    @Binding var scannedCode: String?
    let authService: AuthService
    
    var body: some View {
        QRScannerView(
            onQRCodeScanned: { code in
                scannedCode = code
                isPresented = false
            },
            onDismiss: { isPresented = false },
            authService: authService
        )
        .edgesIgnoringSafeArea(.all)
    }
}
