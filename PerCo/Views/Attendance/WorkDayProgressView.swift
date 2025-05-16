import SwiftUI

struct WorkDayProgressView: View {
    let progress: Double
    let timeWorked: String
    let timeRemaining: String
    let expectedFinishTime: String
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Рабочий день")
                    .font(.headline)
                Spacer()
                
                if isLoading {
                    ProgressView()
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .animation(.easeInOut, value: progress)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Отработано")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeWorked)
                        .font(.body.monospacedDigit())
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Осталось")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeRemaining)
                        .font(.body.monospacedDigit())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Закончу в")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(expectedFinishTime)
                        .font(.body.monospacedDigit())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.75 {
            return .yellow
        } else if progress >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}
