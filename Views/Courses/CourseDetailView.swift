import SwiftUI

struct CourseDetailView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel

    let subjectID: UUID

    @State private var manualPresentText = ""
    @State private var manualTotalText = ""
    @State private var animateProgress = false
    @State private var whatIfClasses: Double = 0

    private var subject: Subject? {
        viewModel.subject(withID: subjectID)
    }

    var body: some View {
        Group {
            if let subject {
                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard(for: subject)
                        attendanceActions
                        whatIfCard(for: subject)
                        manualInputCard(for: subject)
                        assessmentCard(for: subject)
                    }
                    .padding(16)
                }
                .appScreenBackground()
                .onAppear {
                    manualPresentText = "\(subject.manualPresent)"
                    manualTotalText = "\(subject.manualTotal)"
                    whatIfClasses = 0
                }
                .navigationTitle(subject.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Course not found")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func summaryCard(for subject: Subject) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(subject.attendanceRisk.rawValue.capitalized, systemImage: riskSymbol(for: subject.attendanceRisk))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(riskColor(for: subject.attendanceRisk))

            HStack {
                ProgressRingView(progress: animateProgress ? min(1.0, max(0, subject.attendancePercentage / 100.0)) : 0)
                    .frame(width: 92, height: 92)
                    .animation(.spring(response: 0.4, dampingFraction: 0.82), value: animateProgress)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(subject.attendancePercentage.rounded()))%")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(riskColor(for: subject.attendanceRisk))
                        .monospacedDigit()
                    Text("Safe to miss: \(subject.classesCanMiss)")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            ProgressView(value: subject.attendancePercentage, total: 100)
                .tint(riskColor(for: subject.attendanceRisk))
                .scaleEffect(y: animateProgress ? 1.0 : 0.95, anchor: .center)
                .animation(.easeInOut(duration: 0.2), value: animateProgress)

            Text(subject.attendanceGuidance)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func whatIfCard(for subject: Subject) -> some View {
        let simulated = subject.projectedAttendance(afterAttending: Int(whatIfClasses))
        let neededForTarget = classesNeededFor(
            target: subject.minimumRequired,
            attended: subject.presentCount,
            total: subject.totalClasses
        )

        return VStack(alignment: .leading, spacing: 12) {
            Label("What-If Attendance", systemImage: "slider.horizontal.3")
                .font(.headline)

            HStack {
                Text("Attend next \(Int(whatIfClasses)) classes")
                    .font(.subheadline)
                Spacer()
                Text("\(String(format: "%.1f", simulated))%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }

            Slider(value: $whatIfClasses, in: 0...40, step: 1)
                .tint(AppTheme.accent)

            Text(neededForTarget > 0
                 ? "You need at least \(neededForTarget) consecutive present classes to reach \(Int(subject.minimumRequired))%."
                 : "You are above threshold. You can miss \(subject.classesCanMiss) classes safely.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private var attendanceActions: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.markAttendance(for: subjectID, isPresent: true)
                    animateProgress.toggle()
                }
                syncManualFields()
            } label: {
                Label("Mark Present", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppPrimaryButtonStyle())

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.markAttendance(for: subjectID, isPresent: false)
                    animateProgress.toggle()
                }
                syncManualFields()
            } label: {
                Label("Mark Absent", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppSecondaryButtonStyle())
        }
    }

    private func manualInputCard(for subject: Subject) -> some View {
        VStack(spacing: 12) {
            editableStatRow(title: "Manual Present", text: $manualPresentText, symbol: "person.fill.checkmark")
            editableStatRow(title: "Manual Total", text: $manualTotalText, symbol: "calendar")

            Button("Apply Manual Attendance") {
                let present = Int(manualPresentText) ?? subject.manualPresent
                let total = Int(manualTotalText) ?? subject.manualTotal
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.updateManualAttendance(for: subjectID, present: present, total: total)
                    animateProgress.toggle()
                }
                syncManualFields()
            }
            .buttonStyle(AppSecondaryButtonStyle())
            .frame(maxWidth: .infinity, alignment: .trailing)

            statRow(title: "Can Miss", value: "\(subject.classesCanMiss)", symbol: "pause.circle")
            statRow(
                title: "Must Attend to Recover",
                value: subject.isRecoveryPossible ? "\(subject.classesToRecover)" : "Not possible",
                symbol: "arrow.up.right.circle"
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func assessmentCard(for subject: Subject) -> some View {
        VStack(spacing: 12) {
            HStack {
                Label("Planner", systemImage: "list.clipboard")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Target", selection: Binding(
                    get: { subject.targetGrade },
                    set: { viewModel.updateTargetGrade(for: subjectID, grade: $0) }
                )) {
                    ForEach(GradeLetter.allCases) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                .pickerStyle(.menu)
            }

            if let percentage = subject.scoredPercentage {
                statRow(title: "Score", value: String(format: "%.1f%%", percentage), symbol: "percent")
            }
            if let weighted = subject.weightedScoredPercentage {
                statRow(title: "Weighted Score", value: String(format: "%.1f%%", weighted), symbol: "chart.bar")
            }
            statRow(
                title: "Target Planner x",
                value: subject.targetPlannerUnitsNeeded.isFinite ? String(format: "%.2f", subject.targetPlannerUnitsNeeded) : "∞",
                symbol: "function"
            )
            if subject.isTargetGradeImpossible {
                Label("Target grade is currently impossible with configured components.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            statRow(title: "Inferred Grade", value: subject.inferredGrade.rawValue, symbol: "graduationcap")
            statRow(
                title: "Department Rules",
                value: subject.academicProfile.departmentRuleSet.rawValue.capitalized,
                symbol: "building.2"
            )

            Divider().overlay(AppTheme.track)
            HStack {
                Text("Assessment Components")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    viewModel.addAssessmentComponent(for: subjectID)
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
            }

            ForEach(subject.assessmentComponents) { component in
                VStack(spacing: 8) {
                    TextField(
                        "Component Name",
                        text: Binding(
                            get: { component.name },
                            set: {
                                viewModel.updateAssessmentComponent(
                                    for: subjectID,
                                    componentID: component.id,
                                    name: $0,
                                    weightage: component.weightage,
                                    maxMarks: component.maxMarks,
                                    earnedMarks: component.earnedMarks,
                                    isBestOf: component.isBestOf
                                )
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("Wt \(Int(component.weightage))%")
                        Spacer()
                        Stepper("", value: Binding(
                            get: { Int(component.weightage) },
                            set: {
                                viewModel.updateAssessmentComponent(
                                    for: subjectID,
                                    componentID: component.id,
                                    name: component.name,
                                    weightage: Double($0),
                                    maxMarks: component.maxMarks,
                                    earnedMarks: component.earnedMarks,
                                    isBestOf: component.isBestOf
                                )
                            }
                        ), in: 0...100)
                        .labelsHidden()
                    }

                    HStack {
                        Text("Max \(Int(component.maxMarks))")
                        Spacer()
                        Stepper("", value: Binding(
                            get: { Int(component.maxMarks) },
                            set: {
                                viewModel.updateAssessmentComponent(
                                    for: subjectID,
                                    componentID: component.id,
                                    name: component.name,
                                    weightage: component.weightage,
                                    maxMarks: Double($0),
                                    earnedMarks: component.earnedMarks,
                                    isBestOf: component.isBestOf
                                )
                            }
                        ), in: 1...200)
                        .labelsHidden()
                    }

                    HStack {
                        Text("Scored \(Int((component.earnedMarks ?? 0).rounded()))")
                        Spacer()
                        Stepper("", value: Binding(
                            get: { Int((component.earnedMarks ?? 0).rounded()) },
                            set: {
                                viewModel.updateAssessmentComponent(
                                    for: subjectID,
                                    componentID: component.id,
                                    name: component.name,
                                    weightage: component.weightage,
                                    maxMarks: component.maxMarks,
                                    earnedMarks: Double($0),
                                    isBestOf: component.isBestOf
                                )
                            }
                        ), in: 0...max(0, Int(component.maxMarks)))
                        .labelsHidden()
                    }
                    Toggle("Best of", isOn: Binding(
                        get: { component.isBestOf },
                        set: {
                            viewModel.updateAssessmentComponent(
                                for: subjectID,
                                componentID: component.id,
                                name: component.name,
                                weightage: component.weightage,
                                maxMarks: component.maxMarks,
                                earnedMarks: component.earnedMarks,
                                isBestOf: $0
                            )
                        }
                    ))
                    .tint(AppTheme.accent)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.background.opacity(0.45)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func editableStatRow(title: String, text: Binding<String>, symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func statRow(title: String, value: String, symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func syncManualFields() {
        guard let refreshed = viewModel.subject(withID: subjectID) else { return }
        manualPresentText = "\(refreshed.manualPresent)"
        manualTotalText = "\(refreshed.manualTotal)"
    }

    private func classesNeededFor(target: Double, attended: Int, total: Int) -> Int {
        let p = min(0.99, max(0, target / 100))
        let a = Double(attended)
        let t = Double(total)
        let denominator = 1 - p
        guard denominator > 0 else { return 0 }
        let value = ceil(((p * t) - a) / denominator)
        return max(0, Int(value))
    }

    private func riskColor(for risk: AttendanceRisk) -> Color {
        switch risk {
        case .safe: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private func riskSymbol(for risk: AttendanceRisk) -> String {
        switch risk {
        case .safe: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}
