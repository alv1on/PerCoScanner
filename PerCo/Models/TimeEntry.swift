import SwiftUI

struct TimeEntry: Codable {
    let id: Int?
    let comment: String
    let date: String
    let hours: Int
    let isOverTimeWork: Bool
    let isRemoteWork: Bool
    let workItemId: Int
    let minutes: Int
    let workType: String
    let employeeId: String?
    let projectScope: String
    
    init(
        workItemId: Int,
        hours: Int,
        minutes: Int,
        comment: String,
        workType: String,
        isRemoteWork: Bool,
        isOverTimeWork: Bool,
        projectScope: String,
        employeeId: String? = nil,
        date: String = ISO8601DateFormatter().string(from: Date()),
        id: Int? = nil
    ) {
        self.workItemId = workItemId
        self.hours = hours
        self.minutes = minutes
        self.comment = comment
        self.workType = workType
        self.isRemoteWork = isRemoteWork
        self.isOverTimeWork = isOverTimeWork
        self.projectScope = projectScope
        self.employeeId = employeeId
        self.date = date
        self.id = id
    }
}
