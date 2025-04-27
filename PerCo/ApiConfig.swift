// APIConfig.swift
enum ApiConfig {
    private static let baseURL = "https://perco.shate-m.by/api/v1"
    
    enum Auth {
        static let login = "\(baseURL)/account/login"
    }
    
    enum OwnDate {
        static let ownDate = "\(baseURL)/ownDate/"
    }
}
