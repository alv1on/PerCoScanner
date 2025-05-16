struct QRAuthRequest: Encodable {
    let sessionId: String
    let login: String
    let password: String
}
