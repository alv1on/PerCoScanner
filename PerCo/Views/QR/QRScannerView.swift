import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    var onQRCodeScanned: (String) -> Void
    var onDismiss: () -> Void
    var authService: AuthService
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let viewController = QRScannerViewController()
        viewController.onQRCodeScanned = onQRCodeScanned
        viewController.onDismiss = onDismiss
        viewController.authService = authService
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onQRCodeScanned: ((String) -> Void)?
    var onDismiss: (() -> Void)?
    var authService: AuthService!
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // UI элементы
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .gray
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let scanFrameView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 20
        view.backgroundColor = .clear
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Поместите QR-код в рамку"
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        layer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        return layer
    }()
    
    private var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Для анимации
    private var targetQRFrame: CGRect?
    private var isAnimatingToQR = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        setupActions()
        feedbackGenerator.prepare()
    }
    
    private func setupCamera() {
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showCameraError()
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                showCameraError()
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                showCameraError()
                return
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        } catch {
            showCameraError()
        }
    }
    
    private func setupUI() {
        let frameSize: CGFloat = min(view.frame.width, view.frame.height) * 0.65
        scanFrameView.frame = CGRect(
            x: (view.frame.width - frameSize)/2,
            y: (view.frame.height - frameSize)/2,
            width: frameSize,
            height: frameSize
        )
        
        if let metadataOutput = captureSession.outputs.first as? AVCaptureMetadataOutput {
            let rect = previewLayer.metadataOutputRectConverted(fromLayerRect: scanFrameView.frame)
            metadataOutput.rectOfInterest = rect
        }
        
        view.layer.addSublayer(maskLayer)
        view.addSubview(scanFrameView)
        view.addSubview(statusLabel)
        view.addSubview(closeButton)
        view.addSubview(loadingIndicator)
        updateMask()
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.bottomAnchor.constraint(equalTo: scanFrameView.topAnchor, constant: -20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        loadingIndicator.center = view.center
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    private func updateMask() {
        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(roundedRect: scanFrameView.frame,
                                cornerRadius: scanFrameView.layer.cornerRadius))
        maskLayer.path = path.cgPath
    }
    
    @objc private func closeTapped() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.onDismiss?()
            }
        }
    }
    
    private func showCameraError() {
        let alert = UIAlertController(
            title: "Ошибка камеры",
            message: "Не удалось получить доступ к камере. Пожалуйста, проверьте настройки разрешений.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.onDismiss?()
        })
        present(alert, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let stringValue = metadataObject.stringValue else { return }
        
        // Получаем координаты QR-кода в системе координат view
        let qrCodeBounds = previewLayer.transformedMetadataObject(for: metadataObject)?.bounds ?? .zero
        let qrCodeCenter = CGPoint(x: qrCodeBounds.midX, y: qrCodeBounds.midY)
        
        // Если QR-код находится в пределах текущей рамки сканера
        if scanFrameView.frame.insetBy(dx: -50, dy: -50).contains(qrCodeCenter) && !isAnimatingToQR {
            // Анимируем рамку к размеру QR-кода
            animateFrameToQRCode(qrCodeBounds: qrCodeBounds, stringValue: stringValue)
        }
    }
    
    private func animateFrameToQRCode(qrCodeBounds: CGRect, stringValue: String) {
        isAnimatingToQR = true
        captureSession.stopRunning()
        
        // Рассчитываем конечный размер рамки (немного больше QR-кода)
        let padding: CGFloat = 20
        let targetFrame = qrCodeBounds.insetBy(dx: -padding, dy: -padding)
        
        // Сохраняем оригинальный цвет рамки
        _ = scanFrameView.layer.borderColor
        
        // Анимация изменения размера рамки
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) {
            self.scanFrameView.frame = targetFrame
            self.scanFrameView.layer.borderColor = UIColor.systemGreen.cgColor
            self.updateMask()
        } completion: { _ in
            // Тактильный отклик
            self.feedbackGenerator.impactOccurred()
            
            // Мигание рамки
            UIView.animate(withDuration: 0.2, animations: {
                self.scanFrameView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.scanFrameView.transform = .identity
                } completion: { _ in
                    self.statusLabel.text = "QR-код распознан!"
                    self.statusLabel.textColor = .systemGreen
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.processScannedQRCode(stringValue)
                    }
                }
            }
        }
    }
    
    private func processScannedQRCode(_ qrString: String) {
        guard let urlComponents = URLComponents(string: qrString),
              let sessionId = urlComponents.queryItems?.first(where: { $0.name == "sessionId" })?.value else {
            showInvalidQRCodeAlert()
            return
        }
        
        // Проверяем, есть ли сохраненные данные для авторизации
        let hasSavedCredentials = AuthService.shared.hasSavedLogin() &&
                                (AuthService.shared.getKey(AuthService.shared.passwordKey) != nil)
        
        if hasSavedCredentials {
            // Если есть сохраненные данные, сразу показываем форму (она автоматически отправит запрос)
            showLoginForm(sessionId: sessionId)
        } else {
            // Если нет сохраненных данных, показываем форму для ручного ввода
            showLoginForm(sessionId: sessionId)
        }
    }
    
    private func showInvalidQRCodeAlert() {
        let alert = UIAlertController(
            title: "Неверный QR-код",
            message: "Пожалуйста, отсканируйте правильный QR-код для авторизации",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.resetScanner()
        })
        present(alert, animated: true)
    }
    
    private func showLoginForm(sessionId: String) {
        // Получаем сохраненные логин и пароль
        let savedLogin = AuthService.shared.getKey(AuthService.shared.loginKey) ?? ""
        let savedPassword = AuthService.shared.getKey(AuthService.shared.passwordKey) ?? ""
        
        // Если есть сохраненные данные, сразу отправляем запрос
        if !savedLogin.isEmpty && !savedPassword.isEmpty {
            sendAuthRequest(sessionId: sessionId, login: savedLogin.lowercased(), password: savedPassword)
            return
        }
    }
    
    private func sendAuthRequest(sessionId: String, login: String, password: String) {
        loadingIndicator.startAnimating()
        
        authService.loginWithQR(sessionId: sessionId, login: login, password: password) { [weak self] success in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                if success {
                    self?.onDismiss?()
                } else {
                    self?.showErrorAlert(message: AuthService.shared.errorMessage ?? "Неизвестная ошибка")
                    self?.resetScanner()
                }
            }
        }
    }
    
    private func handleUnauthorizedError() {
        showErrorAlert(message: "Неверные учетные данные. Пожалуйста, войдите снова.")
    }
    
    private func handleHTTPError(_ error: Error) {
        let errorMessage: String
        
        switch error {
        case NetworkError.unauthorized:
            errorMessage = "Неверный логин или пароль"
        case NetworkError.serverError(let statusCode):
            switch statusCode {
            case 403: errorMessage = "Доступ запрещен"
            case 404: errorMessage = "Сессия не найдена"
            default: errorMessage = "Ошибка сервера: \(statusCode)"
            }
        case NetworkError.noData:
            errorMessage = "Нет данных в ответе"
        case NetworkError.invalidResponse:
            errorMessage = "Некорректный ответ сервера"
        default:
            errorMessage = error.localizedDescription
        }
        
        showErrorAlert(message: errorMessage)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.resetScanner()
        })
        present(alert, animated: true)
    }
    
    private func resetScanner() {
        isAnimatingToQR = false
        
        // Возвращаем рамку к исходному размеру
        let frameSize: CGFloat = min(view.frame.width, view.frame.height) * 0.65
        let originalFrame = CGRect(
            x: (view.frame.width - frameSize)/2,
            y: (view.frame.height - frameSize)/2,
            width: frameSize,
            height: frameSize
        )
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) {
            self.scanFrameView.frame = originalFrame
            self.scanFrameView.layer.borderColor = UIColor.gray.cgColor
            self.updateMask()
        } completion: { _ in
            self.statusLabel.text = "Поместите QR-код в рамку"
            self.statusLabel.textColor = .gray
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
}
