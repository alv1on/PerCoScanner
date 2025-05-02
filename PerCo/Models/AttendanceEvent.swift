struct AttendanceEvent: Codable {
    let dateTime: String
    let spentTime: String?
    let type: String
    let area: String?
    let description: String?
    let comment: String?
    let ownDayId: Int?
    let isRemoteWork: Bool
    let emails: [String]?
}
