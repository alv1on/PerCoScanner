// APIConfig.swift
enum ApiConfig {
    private static let baseURL = "https://perco.shate-m.by/api/v1"
    
    enum Auth {
        static let login = "\(baseURL)/account/login"
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
