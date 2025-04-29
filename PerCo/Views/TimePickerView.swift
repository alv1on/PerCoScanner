import SwiftUI

struct TimePickerView: View {
    @EnvironmentObject var ownDateService: OwnDateService
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isRemoteWork: Bool
    @Binding var selectedEmails: [String]
    @State private var availableEmails: [String] = []
    
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
                
                Toggle("Удаленная работа", isOn: $isRemoteWork)
                    .padding(.horizontal)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                if isRemoteWork {
                    List(availableEmails, id: \.self) { email in
                        MultipleSelectionRow(
                            title: email,
                            isSelected: selectedEmails.contains(email)
                        ) {
                            if selectedEmails.contains(email) {
                                selectedEmails.removeAll { $0 == email }
                            } else {
                                selectedEmails.append(email)
                            }
                        }
                    }
                    .frame(height: 200)
                    .listStyle(.plain) // или другой стиль по вашему вкусу
                }
                
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
            .onAppear {
                ownDateService.fetchUserEmails { result in
                    switch result {
                    case .success(let emails):
                        availableEmails = emails
                    case .failure(let error):
                        print("Error fetching emails: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
        }
        .foregroundColor(isSelected ? .blue : .primary)
    }
}
