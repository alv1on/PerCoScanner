import SwiftUI

struct RedmineIssue: Codable, Identifiable, Equatable {
    let id: Int
    let subject: String
}
