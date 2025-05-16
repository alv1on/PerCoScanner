import SwiftUI

struct EventTypePickerView: View {
    @Binding var selectedEventType: String
    var onCancel: () -> Void
    var onConfirm: () -> Void
    
    private let eventTypes: [String: String] = [
        "OwnExpenses": "За счет переработок",
        "Vacation": "Отпуск",
        "VacationFact": "Отпуск (факт)",
        "OwnExpensesOfficial": "За свой счет (официально)",
        "SickDay": "SickDay",
        "SickLeave": "Больничный",
        "Trip": "Командировка"
    ]
    
    private var sortedKeys: [String] {
        Array(eventTypes.keys).sorted()
    }
    
    var body: some View {
            NavigationStack {
                List(sortedKeys, id: \.self) { key in
                    HStack {
                        Text(eventTypes[key] ?? key)
                        Spacer()
                        if selectedEventType == key {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEventType = key
                    }
                }
                .navigationTitle("Тип события")
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
