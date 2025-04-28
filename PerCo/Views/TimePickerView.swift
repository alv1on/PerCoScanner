import SwiftUI

struct TimePickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isRemoteWork: Bool
    
    var onCancel: () -> Void
    var onConfirm: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 0) {
                    Picker("Часы", selection: $hours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour) ч").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("Минуты", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text("\(minute) мин").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 150)
                
                // Переключатель "Удаленная работа"
                Toggle("Удаленная работа", isOn: $isRemoteWork)
                    .padding(.horizontal)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Spacer()
            }
            .padding()
            .navigationTitle("Выберите время")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово", action: onConfirm)
                }
            }
        }
    }
}
