import SwiftUI

// Общий компонент для выбора времени
struct TimePickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("Часы", selection: $hours) {
                ForEach(0..<24, id: \.self) { hour in
                    Text("\(hour) ч").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 150, height: 150)
            
            // Пикер минут
            Picker("Минуты", selection: $minutes) {
                ForEach(0..<60, id: \.self) { minute in
                    Text("\(minute) мин").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 150, height: 150)
        }
        .frame(height: 150)
    }
}
