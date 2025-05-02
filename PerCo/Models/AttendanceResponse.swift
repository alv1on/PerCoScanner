struct AttendanceResponse: Codable {
    let userId: Int
    let externalEmployeeId: String
    let total: String
    let totalNeeded: String
    let totalTrack: String
    let totalOvertime: String
    let totalDifference: String
    let attendances: [Attendance]
}

