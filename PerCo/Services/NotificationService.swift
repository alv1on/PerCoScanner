import UserNotifications

final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    init() {}
    @Published var isPermissionGranted: Bool = false
    
    // Запрос разрешения
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isPermissionGranted = granted
                if let error = error {
                    print("Недостаточно прав на уведомления: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        }
    }
    
    // Показ уведомления
    func showNotification(title: String, body: String, sound: UNNotificationSound = .default) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка отправки уведомления: \(error.localizedDescription)")
            }
        }
    }
    
    // Специальное уведомление о завершении работы
    func showWorkFinishedNotification() {
        // Запланировать уведомление через 10 секунд
        let triggerTime = DispatchTime.now() + 10.0 //todo на бэкграунд запрос
        
        DispatchQueue.main.asyncAfter(deadline: triggerTime) {
            self.showNotification(
                title: "Рабочий день завершен",
                body: "Вы отработали положенное время. Хорошего отдыха!"
            )
        }
    }
}
