struct Attendance: Codable {
    let date: String
    let isHoliday: Bool
    let neededTime: String
    let neededTimeInHours: Int
    let officeTime: String
    let overTimeInHours: Int
    let overTime: String
    let officeTimeInHours: Int
    let outTime: String
    let outTimeInHours: Int
    let remoteTime: String
    let remoteTimeInHours: Int
    let trackTime: String
    let trackTimeInHours: String
    let workedTimeTotal: String
    let workedTimeTotalInHours: Int
    let lastCalcDateTime: String
    let isMoreThanNeeded: Bool
    let isNeedReCalcTotalTime: Bool
    let events: [AttendanceEvent]
}
