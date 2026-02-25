import SwiftUI

struct AddCourseView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var shortName = ""
    @State private var credits = 3.0
    @State private var minimumRequired = 75.0
    @State private var departmentRuleSet = DepartmentRuleSet.standard

    var body: some View {
        NavigationStack {
            Form {
                Section("Course Info") {
                    TextField("Course Name", text: $name)
                    TextField("Short Name", text: $shortName)
                    Stepper("Credits: \(credits, specifier: "%.1f")", value: $credits, in: 1...10, step: 0.5)
                }

                Section("Attendance Policy") {
                    Stepper(value: $minimumRequired, in: 50...100, step: 1) {
                        Text("Minimum Required: \(Int(minimumRequired))%")
                    }
                }

                Section("Academic Setup") {
                    Picker("Department Rules", selection: $departmentRuleSet) {
                        ForEach(DepartmentRuleSet.allCases, id: \.self) { ruleSet in
                            Text(ruleSet.rawValue.capitalized).tag(ruleSet)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("New Course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addSubject(
                            name: name,
                            shortName: shortName,
                            credits: credits,
                            minimumRequired: minimumRequired,
                            departmentRuleSet: departmentRuleSet
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
