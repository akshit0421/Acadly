import SwiftUI

struct CGPAView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    @State private var simulatedMarks: [UUID: Double] = [:]
    @State private var selectedGrades: [UUID: GradeLetter] = [:]
    @State private var marksInput: [UUID: String] = [:]
    @State private var previousCGPAInput: String = ""
    @State private var previousCreditsInput: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.subjects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Add subjects to calculate CGPA")
                            .font(.headline)
                    }
                    .padding(.top, 60)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SGPA Summary")
                            .font(.headline)

                        let current = viewModel.currentSGPA
                        let projected = viewModel.calculateProjectedSGPA(simulatedEndSemMarks: simulatedMarks)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current SGPA")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2f", current))
                                    .font(.title.bold().monospacedDigit())
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Projected SGPA")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2f", projected))
                                    .font(.title.bold().monospacedDigit())
                                    .foregroundStyle(projected >= current ? AppTheme.accent : .orange)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Divider()

                        ForEach(viewModel.subjects) { subject in
                            HStack {
                                Text(subject.shortName)
                                    .font(.subheadline)
                                Spacer()
                                Text(subject.inferredGrade.rawValue)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(gradeColor(subject.inferredGrade))
                                Text("(\(String(format: "%.1f", subject.inferredGrade.points)) GP)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            statTile(
                                title: "Prev CGPA",
                                value: viewModel.previousCGPA,
                                valueColor: .secondary
                            )
                            statTile(
                                title: "This Sem",
                                value: viewModel.currentSGPA,
                                valueColor: AppTheme.accent
                            )
                            statTile(
                                title: "New CGPA",
                                value: viewModel.cumulativeCGPA,
                                valueColor: viewModel.cgpaDelta >= 0 ? .green : .orange
                            )
                        }

                        let delta = viewModel.cgpaDelta
                        Text((delta >= 0 ? "▲ +" : "▼ ") + String(format: "%.2f", delta))
                            .font(.headline.weight(.black))
                            .foregroundStyle(delta >= 0 ? Color.green : Color.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill((delta >= 0 ? Color.green : Color.red).opacity(0.12))
                            )
                            .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target: \(String(format: "%.2f", viewModel.targetCGPA))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ProgressView(value: viewModel.targetProgress)
                                .tint(viewModel.cumulativeCGPA >= viewModel.targetCGPA ? .green : AppTheme.accent)
                            if viewModel.improvementPotential > 0.01 {
                                Text("\(String(format: "%.2f", viewModel.improvementPotential)) points to target")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("✓ Target CGPA reached!")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }

                        HStack(spacing: 8) {
                            Text("Prev CGPA")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $previousCGPAInput)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: previousCGPAInput) { _ in
                                    savePastAcademicsFromInputs()
                                }
                            Text("×")
                                .foregroundStyle(.secondary)
                            TextField("0", text: $previousCreditsInput)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: previousCreditsInput) { _ in
                                    savePastAcademicsFromInputs()
                                }
                            Text("cr")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Set") {
                                savePastAcademicsFromInputs()
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .appCard()

                    ForEach(viewModel.subjects) { subject in
                        let simulated = simulatedMarks[subject.id] ?? subject.requiredEndSemMarks
                        let projectedGrade = GradeLetter.fromPercentage(subject.projectedOverallPercentage(simulatedEndSem: simulated))
                        let selectedGrade = selectedGrades[subject.id] ?? subject.targetGrade
                        let requiredDistribution = subject.requiredMarksDistribution

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(subject.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(String(format: "%.1f", subject.credits)) cr")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.track.opacity(0.25))
                                    .clipShape(Capsule())
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target Grade")
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                    ForEach([GradeLetter.aPlus, .a, .bPlus, .b, .cPlus, .c, .d], id: \.self) { grade in
                                        Button {
                                            selectedGrades[subject.id] = grade
                                            viewModel.updateTargetGrade(for: subject.id, grade: grade)
                                        } label: {
                                            Text(grade.rawValue)
                                                .font(.subheadline.weight(.semibold))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .fill(selectedGrade == grade ? AppTheme.accent : AppTheme.card)
                                                )
                                                .foregroundStyle(selectedGrade == grade ? Color.white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Simulate End-Sem Marks")
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)

                                Slider(
                                    value: Binding(
                                        get: { simulated },
                                        set: { simulatedMarks[subject.id] = $0 }
                                    ),
                                    in: 0...max(1, subject.endSemMaxMarks)
                                )
                                .tint(AppTheme.accent)

                                HStack {
                                    Text("\(Int(simulated.rounded())) / \(Int(subject.endSemMaxMarks)) marks")
                                        .font(.subheadline.monospacedDigit())
                                    Spacer()
                                    Text(projectedGrade.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(projectedGradeColor(projectedGrade))
                                }
                            }

                            if !requiredDistribution.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What you need")
                                        .font(.caption)
                                        .textCase(.uppercase)
                                        .foregroundStyle(.secondary)

                                    ForEach(requiredDistribution, id: \.component.id) { entry in
                                        HStack {
                                            Text(entry.component.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text("\(Int(entry.required.rounded())) / \(Int(entry.component.maxMarks))")
                                                .font(.title3.weight(.black).monospacedDigit())
                                                .foregroundStyle(requiredEntryColor(required: entry.required, max: entry.component.maxMarks))
                                        }
                                    }

                                    Text(subject.isTargetFeasible ? "✓ Target achievable" : "✗ Adjust target grade")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(subject.isTargetFeasible ? Color.green : Color.red)
                                        .clipShape(Capsule())
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter your marks")
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)

                                ForEach(subject.assessmentComponents) { component in
                                    if let earned = component.earnedMarks {
                                        HStack {
                                            Text(component.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text("✓ \(Int(earned.rounded())) / \(Int(component.maxMarks))")
                                                .foregroundStyle(.green)
                                                .monospacedDigit()
                                        }
                                    } else {
                                        HStack {
                                            Text(component.name + (component.isBestOf ? " (Best of)" : ""))
                                                .font(.subheadline)
                                            Spacer()
                                            TextField("—", text: marksBinding(for: component))
                                                .keyboardType(.numberPad)
                                                .multilineTextAlignment(.trailing)
                                                .frame(width: 60)
                                                .textFieldStyle(.roundedBorder)
                                                .onChange(of: marksInput[component.id] ?? "") { newValue in
                                                    let parsed = Double(newValue) ?? 0
                                                    let clamped = min(component.maxMarks, max(0, parsed))
                                                    viewModel.updateAssessmentComponent(
                                                        for: subject.id,
                                                        componentID: component.id,
                                                        name: component.name,
                                                        weightage: component.weightage,
                                                        maxMarks: component.maxMarks,
                                                        earnedMarks: clamped,
                                                        isBestOf: component.isBestOf
                                                    )
                                                }
                                            Text("/ \(Int(component.maxMarks))")
                                                .foregroundStyle(.secondary)
                                                .monospacedDigit()
                                        }
                                    }
                                }

                                Text("Entering marks recalculates what you need in remaining assessments.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }

                            Text("Grade Point: \(String(format: "%.1f", projectedGrade.points)) • Credits: \(String(format: "%.1f", subject.credits))")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .appCard()
                    }
                }
            }
            .padding(16)
        }
        .appScreenBackground()
        .navigationTitle("CGPA")
        .onAppear {
            previousCGPAInput = String(format: "%.2f", viewModel.previousCGPA)
            previousCreditsInput = String(format: "%.0f", viewModel.previousCredits)
            for subject in viewModel.subjects {
                selectedGrades[subject.id] = subject.targetGrade
            }
            syncMarksInputs()
        }
        .onChange(of: viewModel.subjects) { _ in
            syncMarksInputs()
        }
    }

    private func projectedGradeColor(_ grade: GradeLetter) -> Color {
        gradeColor(grade)
    }

    private func gradeColor(_ grade: GradeLetter) -> Color {
        switch grade {
        case .aPlus, .a:
            return .green
        case .bPlus, .b:
            return AppTheme.accent
        case .cPlus, .c:
            return .orange
        default:
            return .red
        }
    }

    private func requiredEntryColor(required: Double, max: Double) -> Color {
        if required <= max * 0.7 { return .green }
        if required <= max { return .orange }
        return .red
    }

    private func statTile(title: String, value: Double, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", value))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.track.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func savePastAcademicsFromInputs() {
        viewModel.updatePastAcademics(
            previousCGPA: Double(previousCGPAInput) ?? viewModel.previousCGPA,
            previousCredits: Double(previousCreditsInput) ?? viewModel.previousCredits
        )
    }

    private func marksBinding(for component: AssessmentComponent) -> Binding<String> {
        Binding(
            get: { marksInput[component.id] ?? "" },
            set: { marksInput[component.id] = $0 }
        )
    }

    private func syncMarksInputs() {
        for subject in viewModel.subjects {
            for component in subject.assessmentComponents {
                if let earned = component.earnedMarks {
                    marksInput[component.id] = "\(Int(earned.rounded()))"
                } else if marksInput[component.id] == nil {
                    marksInput[component.id] = ""
                }
            }
        }
    }
}
