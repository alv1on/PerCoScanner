import SwiftUI

struct RedmineIssuePickerView: View {
    @EnvironmentObject var redmineService: RedmineService
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isRemoteWork: Bool
    @Binding var isOverTimeWork: Bool
    @Binding var comment: String
    @Binding var activityId: Int
    @Binding var selectedIssue: RedmineIssue?
    
    @State private var searchText = ""
    @State private var availableActivities: [RedmineActivity] = []
    @State private var searchResults: [RedmineIssue] = []
    @State private var searchTask: DispatchWorkItem?
    @State private var showDetails = false
    @FocusState private var focusedField: Field?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private enum Field: Hashable {
        case search, comment
    }
    
    var onCancel: () -> Void
    var onConfirm: () -> Void
    
    private let mockActivities = [
        RedmineActivity(id: 15, name: "Разработка")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        // MARK: - Поле поиска задач
                        searchFieldView
                        
                        // MARK: - Список найденных задач
                        if !searchResults.isEmpty && selectedIssue == nil {
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
                        .disabled(selectedIssue == nil)
                }
            }
            .onAppear {
                focusedField = .search
            }
            .onChange(of: selectedIssue) { _, newValue in
                withAnimation {
                    showDetails = newValue != nil
                }
            }
        }
    }
    
    // MARK: - Subviews
    
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
            ForEach(searchResults, id: \.id) { issue in
                Button(action: {
                    selectIssue(issue)
                }) {
                    HStack {
                        Text("#\(issue.id): \(issue.subject)")
                        Spacer()
                        if selectedIssue?.id == issue.id {
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
        // MARK: - Детали выбранной задачи
        if let selectedIssue = selectedIssue {
            VStack(alignment: .leading) {
                Text("Выбрана задача:")
                    .font(.headline)
                
                HStack {
                    Text("#\(selectedIssue.id) - \(selectedIssue.subject)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    // Кнопка копирования
                    Button(action: {
                        UIPasteboard.general.string = "#\(selectedIssue.id) - \(selectedIssue.subject)"
                        feedbackGenerator.impactOccurred() // Тактильная реакция
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
        
        // MARK: - Выбор времени
        timePickersView
        
        // MARK: - Выбор активности
        activityPickerView
        
        // MARK: - Переключатели
        toggleViews
        
        // MARK: - Поле комментария
        commentFieldView
            .id(Field.comment)
    }
    
    private var timePickersView: some View {
        TimePickerView(hours: $hours, minutes: $minutes)
            .transition(.opacity)
    }
    
    private var activityPickerView: some View {
        Picker("Activity", selection: $activityId) {
            ForEach(mockActivities, id: \.id) { activity in
                Text(activity.name).tag(activity.id)
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
    
    // MARK: - Private Methods
    
    private func selectIssue(_ issue: RedmineIssue) {
        selectedIssue = issue
        searchResults = []
        withAnimation {
            showDetails = true
        }
        focusedField = nil
    }
    
    private func clearSearchResults() {
        searchResults = []
        showDetails = false
        selectedIssue = nil
    }
    
    private func handleSearchTextChange(_ newValue: String) {
        searchTask?.cancel()
        
        if newValue.count < 2 {
            clearSearchResults()
            return
        }
        
        let task = DispatchWorkItem {
            redmineService.searchIssues(searchText: newValue) { result in
                DispatchQueue.main.async {
                    if selectedIssue == nil {
                        switch result {
                        case .success(let issues): searchResults = issues
                        case .failure: searchResults = []
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
