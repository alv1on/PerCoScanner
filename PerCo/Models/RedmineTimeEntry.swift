import SwiftUI

struct RedmineTimeEntry: Codable {
    let activityId: Int
    let comment: String
    let date: String
    let hours: Int
    let isOverTimeWork: Bool
    let isRemoteWork: Bool
    let issueId: String
    let minutes: Int
    
    // Инициализатор с параметрами по умолчанию
    init(
        date: String = ISO8601DateFormatter().string(from: Date()),
        activityId: Int = 0,
        issueId: String = "",
        hours: Int = 0,
        minutes: Int = 0,
        comment: String = "",
        isRemoteWork: Bool = false,
        isOverTimeWork: Bool = false
    ) {
        self.date = date
        self.activityId = activityId
        self.hours = hours
        self.minutes = minutes
        self.comment = comment
        self.isRemoteWork = isRemoteWork
        self.isOverTimeWork = isOverTimeWork
        self.issueId = issueId
    }
}
