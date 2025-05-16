import SwiftUI

struct QRScannerSheet: View {
    @EnvironmentObject var authService: AuthService
    @Binding var formState: FormInputState
    @Binding var modalState: ModalSheetsState
    
    var body: some View {
        QRScannerView(
            onQRCodeScanned: { code in
                formState.scannedCode = code
                modalState.isShowingScanner = false
            },
            onDismiss: { modalState.isShowingScanner = false },
            authService: authService
        )
        .edgesIgnoringSafeArea(.all)
    }
}
