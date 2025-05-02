import SwiftUI

struct WorkItem: Codable, Equatable {
    let workItemId: Int
    let workItemType: String
    let title: String
    let projectScope: String
    let isDeleted: Bool
}
