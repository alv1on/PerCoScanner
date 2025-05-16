import SwiftUI

struct WorkItemPickerView: View {
    @EnvironmentObject var azureService: AzureService
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isRemoteWork: Bool
    @Binding var isOverTimeWork: Bool
    @Binding var comment: String
    @Binding var workType: String
    @Binding var projectScope: String
    @Binding var selectedWorkItem: WorkItem?
    @State private var selectedProjectType: ProjectType = .shate
    
    @State private var searchText = ""
    @State private var searchResults: [WorkItem] = []
    @State private var searchTask: DispatchWorkItem?
    @State private var showDetails = false
    @FocusState private var focusedField: Field?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private let workTypes: [String: String] = [
            "BusinessAnalysis": "Бизнес анализ",
            "Development": "Разработка",
            "Consultation": "Консультация",
            "Testing": "Тестирование",
            "Implementation": "Внедрение",
            "Design": "Дизайн",
            "CodeDesign": "Проектирование",
            "ExternalConsultation": "Внешняя консультация",
            "ChangeSettings": "Изменение данных/настроек",
            "Documentation": "Разработка документации"
        ]
    
    private enum Field: Hashable {
        case search, comment
    }
    
    var onCancel: () -> Void
    var onConfirm: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        // Добавлен сегментированный контрол для выбора типа проекта
                        Picker("Тип проекта", selection: $selectedProjectType) {
                            ForEach(ProjectType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        searchFieldView
                        
                        if !searchResults.isEmpty && selectedWorkItem == nil {
                            issuesListView
                        }
                        
                        if showDetails {
                            detailsView(proxy: proxy)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .onChange(of: focusedField) { _, newValue in
                    handleFocusChange(newValue, proxy: proxy)
                }
            }
            .navigationTitle("Учет времени")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово", action: onConfirm)
                        .disabled(selectedWorkItem == nil)
                }
            }
            .onAppear {
                focusedField = .search
                workType = "Development" 
            }
            .onChange(of: selectedWorkItem) { _, newValue in
                withAnimation {
                    showDetails = newValue != nil
                }
            }
        }
    }
    
    
    private var searchFieldView: some View {
        TextField("Поиск задачи...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .focused($focusedField, equals: .search)
            .onChange(of: searchText, initial: false) { _, newValue in
                handleSearchTextChange(newValue)
            }
            .onSubmit {
                focusedField = nil
            }
            .id(Field.search)
    }
    
    private var issuesListView: some View {
        List {
            ForEach(searchResults, id: \.workItemId) { workItem in
                Button(action: {
                    selectWorkItem(workItem)
                }) {
                    HStack {
                        Text("#\(workItem.workItemId): \(workItem.title)")
                        Spacer()
                        if selectedWorkItem?.workItemId == workItem.workItemId {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .frame(height: 200)
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func detailsView(proxy: ScrollViewProxy) -> some View {
        if let selectedWorkItem = selectedWorkItem {
            VStack(alignment: .leading) {
                Text("Выбрана задача:")
                    .font(.headline)
                
                HStack {
                    Text("#\(selectedWorkItem.workItemId) - \(selectedWorkItem.title)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = "#\(selectedWorkItem.workItemId) - \(selectedWorkItem.title)"
                        feedbackGenerator.impactOccurred()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .transition(.opacity)
        }
        
        timePickersView
        
        workTypePickerView
        
        toggleViews
        
        commentFieldView
            .id(Field.comment)
    }
    
    private var timePickersView: some View {
        TimePickerView(hours: $hours, minutes: $minutes)
            .transition(.opacity)
    }
    
    private var workTypePickerView: some View {
            Picker("Тип работы", selection: $workType) {
                ForEach(workTypes.sorted(by: { $0.value < $1.value }), id: \.key) { key, value in
                    Text(value).tag(key)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .transition(.opacity)
        }
    
    private var toggleViews: some View {
        VStack {
            Toggle("Удаленная работа", isOn: $isRemoteWork)
                .padding(.horizontal)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            Toggle("Сверурочная работа", isOn: $isOverTimeWork)
                .padding(.horizontal)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.top, 8)
    }
    
    private var commentFieldView: some View {
        TextField("Комментарий", text: $comment)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .padding(.top, 8)
            .focused($focusedField, equals: .comment)
            .transition(.opacity)
    }
    
    private func selectWorkItem(_ workItem: WorkItem) {
        selectedWorkItem = workItem
        projectScope = workItem.projectScope
        searchResults = []
        withAnimation {
            showDetails = true
        }
        focusedField = nil
    }
    
    private func clearSearchResults() {
        searchResults = []
        showDetails = false
        selectedWorkItem = nil
    }
    
    private func handleSearchTextChange(_ newValue: String) {
        searchTask?.cancel()
        
        if newValue.count < 2 {
            clearSearchResults()
            return
        }
        
        let task = DispatchWorkItem {
            azureService.searchIssues(
                searchText: newValue,
                projectScope: selectedProjectType.rawValue
            ) { result in
                DispatchQueue.main.async {
                    if selectedWorkItem == nil {
                        switch result {
                        case .success(let workItems):
                            searchResults = workItems
                        case .failure:
                            searchResults = []
                        }
                    }
                }
            }
        }
        
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: task)
    }
    
    private func handleFocusChange(_ newValue: Field?, proxy: ScrollViewProxy) {
        if newValue == .comment {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    proxy.scrollTo(Field.comment, anchor: .bottom)
                }
            }
        }
    }
}
