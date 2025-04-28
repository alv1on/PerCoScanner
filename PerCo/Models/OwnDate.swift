import Foundation

struct OwnDate: Codable {
    let dateTimes: [String]
    let hours: Int
    let type: String
    let minutes: Int
    let comment: String
    let isRemoteWork: Bool
    let emails: [String]
    
    // Инициализатор с параметрами по умолчанию
    init(
        dateTimes: [String] = [ISO8601DateFormatter().string(from: Date())],
        type: String,
        hours: Int = 0,
        minutes: Int = 0,
        comment: String = "",
        isRemoteWork: Bool = false,
        emails: [String] = []
    ) {
        self.dateTimes = dateTimes
        self.type = type
        self.hours = hours
        self.minutes = minutes
        self.comment = comment
        self.isRemoteWork = isRemoteWork
        self.emails = emails
    }
}
