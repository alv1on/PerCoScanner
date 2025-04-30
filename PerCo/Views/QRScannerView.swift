import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    var onQRCodeScanned: (String) -> Void
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let viewController = QRScannerViewController()
        viewController.onQRCodeScanned = onQRCodeScanned
        viewController.onDismiss = onDismiss
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onQRCodeScanned: ((String) -> Void)?
    var onDismiss: (() -> Void)?
    
    // UI элементы
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let scanFrameView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 20
        view.backgroundColor = .clear
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Поместите QR-код в рамку"
        label.textColor = .white
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
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        setupActions()
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
        
        let qrCodeCenter = CGPoint(
            x: metadataObject.bounds.midX * view.frame.width,
            y: metadataObject.bounds.midY * view.frame.height
        )
        
        if scanFrameView.frame.contains(qrCodeCenter) {
            captureSession.stopRunning()
            
            UIView.animate(withDuration: 0.2, animations: {
                self.scanFrameView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.scanFrameView.layer.borderColor = UIColor.systemGreen.cgColor
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.scanFrameView.transform = .identity
                }
            }
            
            statusLabel.text = "QR-код распознан!"
            statusLabel.textColor = .systemGreen
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.processScannedQRCode(stringValue)
            }
        }
    }
    
    private func processScannedQRCode(_ qrString: String) {
        guard let urlComponents = URLComponents(string: qrString),
              let sessionId = urlComponents.queryItems?.first(where: { $0.name == "sessionId" })?.value else {
            showInvalidQRCodeAlert()
            return
        }
        
        showLoginForm(sessionId: sessionId)
    }
    
    private func showInvalidQRCodeAlert() {
        let alert = UIAlertController(
            title: "Неверный QR-код",
            message: "Пожалуйста, отсканируйте правильный QR-код для авторизации",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.restartScanning()
        })
        present(alert, animated: true)
    }
    
    private func showLoginForm(sessionId: String) {
        let alert = UIAlertController(
            title: "Авторизация",
            message: "Введите email и пароль",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Пароль"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.restartScanning()
        })
        
        alert.addAction(UIAlertAction(title: "Войти", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text,
                  let password = alert.textFields?.last?.text else {
                return
            }
            self?.sendAuthRequest(sessionId: sessionId, email: email, password: password)
        })
        
        present(alert, animated: true)
    }
    
    private func sendAuthRequest(sessionId: String, email: String, password: String) {
        loadingIndicator.startAnimating()
        
        let url = URL(string: ApiConfig.Auth.loginQrCode)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "sessionId": sessionId,
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            showErrorAlert(message: "Ошибка формирования запроса")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                if let error = error {
                    self?.showErrorAlert(message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.showErrorAlert(message: "Некорректный ответ сервера")
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    self?.showSuccessAlert()
                } else {
                    self?.showErrorAlert(message: "Ошибка сервера: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.restartScanning()
        })
        present(alert, animated: true)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Успешно",
            message: "Авторизация прошла успешно",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.onDismiss?()
        })
        present(alert, animated: true)
    }
    
    private func restartScanning() {
        statusLabel.text = "Поместите QR-код в рамку"
        statusLabel.textColor = .white
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
}
