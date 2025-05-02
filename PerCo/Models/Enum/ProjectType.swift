enum ProjectType: String, CaseIterable {
    case it = "IT"
    case shate = "SHATE"
    
    var displayName: String {
        rawValue
    }
}
