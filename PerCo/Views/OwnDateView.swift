import SwiftUI

struct OwnDateView: View {
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
                TimePickerView(hours: $hours, minutes: $minutes)
                
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
                    .listStyle(.plain) 
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
                        print("Ошибка получения emails: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
