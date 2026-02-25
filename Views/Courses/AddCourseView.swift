import SwiftUI

struct AddCourseView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var shortName = ""
    @State private var credits = 3.0
    @State private var minimumRequired = 75.0
    @State private var departmentRuleSet = DepartmentRuleSet.standard
    @State private var components: [AssessmentComponent] = []
    @State private var newComponentName = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Subject Name", text: $name)
                    TextField("Short Name", text: $shortName)
                    Stepper("Credits: \(credits, specifier: "%.1f")", value: $credits, in: 1...10, step: 0.5)
                } header: {
                    Text("Subject Info")
                }

                Section {
                    Stepper(value: $minimumRequired, in: 50...100, step: 1) {
                        Text("Minimum Required: \(Int(minimumRequired))%")
                    }
                } header: {
                    Text("Attendance Policy")
                }

                Section {
                    TextField("Component name", text: $newComponentName)

                    ForEach(components.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Name", text: $components[index].name)

                            Stepper(
                                "Max: \(Int(components[index].maxMarks.rounded()))",
                                value: Binding(
                                    get: { Int(components[index].maxMarks.rounded()) },
                                    set: { components[index].maxMarks = Double($0) }
                                ),
                                in: 1...200
                            )

                            Stepper(
                                "Wt: \(Int(components[index].weightage.rounded()))%",
                                value: Binding(
                                    get: { Int(components[index].weightage.rounded()) },
                                    set: { components[index].weightage = Double($0) }
                                ),
                                in: 0...100
                            )

                            Toggle("Best of", isOn: $components[index].isBestOf)
                        }
                        .padding(.vertical, 4)
                    }

                    Button("+ Add Component") {
                        components.append(
                            AssessmentComponent(
                                name: newComponentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Component" : newComponentName,
                                weightage: 20,
                                maxMarks: 20
                            )
                        )
                        newComponentName = ""
                    }
                } header: {
                    Text("Assessment Structure (CHO)")
                } footer: {
                    Text("e.g. FA 10%, ST1 20%, ST2 20% (Best of), End Term 50%.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    DisclosureGroup(
                        content: {
                        Picker("Department Rules", selection: $departmentRuleSet) {
                            ForEach(DepartmentRuleSet.allCases, id: \.self) { ruleSet in
                                Text(ruleSet.rawValue.capitalized).tag(ruleSet)
                            }
                        }
                        Text("This affects how CHO passing marks are calculated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        },
                        label: {
                            Text("Advanced (optional)")
                        }
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("New Subject")
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
                            departmentRuleSet: departmentRuleSet,
                            components: components
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
