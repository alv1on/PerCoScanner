struct Attendance: Codable {
    let date: String
    let isHoliday: Bool
    let neededTime: String
    let neededTimeInHours: Double
    let officeTime: String
    let overTimeInHours: Double
    let overTime: String
    let officeTimeInHours: Double
    let outTime: String
    let outTimeInHours: Double
    let remoteTime: String
    let remoteTimeInHours: Double
    let trackTime: String
    let trackTimeInHours: String
    let workedTimeTotal: String
    let workedTimeTotalInHours: Double
    let lastCalcDateTime: String
    let isMoreThanNeeded: Bool
    let isNeedReCalcTotalTime: Bool
    let events: [AttendanceEvent]
}
