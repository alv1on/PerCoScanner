struct AttendanceRequest: Codable {
    let extEmpIds: [String]
    let beginDate: String
    let endDate: String
}
