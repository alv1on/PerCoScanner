// APIConfig.swift
enum ApiConfig {
    private static let baseURL = "https://perco-prerelease.shate-m.by/api/v1"
    
    enum Auth {
        static let login = "\(baseURL)/account/login"
        static let loginQrCode = "\(baseURL)/account/loginViaQr"
    }
    
    enum OwnDate {
        static let ownDate = "\(baseURL)/ownDate/"
    }
    
    enum Account {
        static let userInfo = "\(baseURL)/account/userinfo"
    }
    
    enum User {
        static let userEmails = "\(baseURL)/user/userEmails"
    }
}
