import SwiftUI

struct CoursesView: View {
    private enum DetailSection: String, CaseIterable, Identifiable {
        case attendance = "Attendance"
        case marksGoals = "Marks & Goals"

        var id: String { rawValue }
    }

    @EnvironmentObject private var viewModel: CoursesViewModel
    @State private var showAddSheet = false
    @State private var selectedSubjectID: UUID?
    @State private var selectedDetailSection: DetailSection = .attendance
    @State private var simExtraClasses: Double = 0

    private var selectedSubject: Subject? {
        guard let selectedSubjectID else { return nil }
        return viewModel.subject(withID: selectedSubjectID)
    }

    var body: some View {
        Group {
            if let subject = selectedSubject {
                subjectDetail(subject)
            } else {
                subjectList
            }
        }
        .appScreenBackground()
        .navigationTitle(selectedSubject?.name ?? "Subjects")
        .navigationBarTitleDisplayMode(selectedSubject == nil ? .large : .inline)
        .toolbar {
            if selectedSubject == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Subject", systemImage: "plus")
                    }
                    .highTapTarget()
                }
            } else {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        selectedSubjectID = nil
                        selectedDetailSection = .attendance
                        simExtraClasses = 0
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .highTapTarget()
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCourseView()
        }
    }

    private var subjectList: some View {
        List {
            Section {
                ForEach(viewModel.subjects) { subject in
                    Button {
                        selectedSubjectID = subject.id
                        selectedDetailSection = .attendance
                        simExtraClasses = 0
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subject.name)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(subject.shortName) · \(String(format: "%.1f", subject.credits)) credits")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            Text(riskLabel(for: subject.attendancePercentage))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(riskBadgeColor(for: subject.attendancePercentage))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(riskBadgeColor(for: subject.attendancePercentage).opacity(0.15))
                                .clipShape(.capsule)
                                .accessibilityLabel("Attendance risk: \(riskAccessibilityLevel(for: subject.attendancePercentage))")
                                .accessibilityHint("Indicates attendance risk level")
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .highTapTarget()
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                }
            } header: {
                Text("Tap a subject to manage")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func subjectDetail(_ subject: Subject) -> some View {
        List {
            if selectedDetailSection == .attendance {
                attendanceSections(subject)
            } else {
                marksGoalSections(subject)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            Picker("Detail Section", selection: $selectedDetailSection) {
                ForEach(DetailSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    private func attendanceSections(_ subject: Subject) -> some View {
        let p = subject.attendancePercentage
        let simulated = subject.projectedAttendance(afterAttending: Int(simExtraClasses))

        Section("This Week") {
            LabeledContent("Attendance") {
                Text("\(Int(p.rounded()))%")
                    .monospacedDigit()
            }
            LabeledContent("Attended") {
                Text("\(subject.presentCount)/\(subject.totalClasses)")
                    .monospacedDigit()
            }
            LabeledContent("Safe to Miss") {
                Text(subject.classesCanMiss > 0 ? "\(subject.classesCanMiss)" : "0")
                    .monospacedDigit()
            }
            if p < subject.minimumRequired {
                LabeledContent("Need to Attend") {
                    Text("\(subject.classesToRecover)")
                        .monospacedDigit()
                }
            }
        }

        Section("Quick Actions") {
            HStack(spacing: 10) {
                Button {
                    viewModel.markAttendance(for: subject.id, isPresent: true)
                } label: {
                    Label("Present", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .accessibilityLabel("Mark present")
                .accessibilityHint("Adds one attended class")
                .highTapTarget()

                Button {
                    viewModel.markAttendance(for: subject.id, isPresent: false)
                } label: {
                    Label("Absent", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel("Mark absent")
                .accessibilityHint("Adds one missed class")
                .highTapTarget()
            }
            .padding(.vertical, 4)
        }

        Section("Simulator") {
            VStack(alignment: .leading, spacing: 10) {
                Label("Attend additional consecutive classes", systemImage: "slider.horizontal.3")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Slider(value: $simExtraClasses, in: 0...20, step: 1)
                    .accessibilityLabel("Attendance what if slider")
                    .accessibilityHint("Adjusts simulated attendance percentage")

                Text("Projected attendance: \(Int(simulated.rounded()))%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(simulated >= subject.minimumRequired ? Color.green : Color.orange)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func marksGoalSections(_ subject: Subject) -> some View {
        let prediction = predictGrade(for: subject, target: subject.targetGrade)

        Section("Internal Marks") {
            Stepper(
                "\(Int(subject.internalMarksObtained.rounded())) / \(Int(subject.internalMaxMarks))",
                value: Binding(
                    get: { Int(subject.internalMarksObtained.rounded()) },
                    set: { viewModel.updateInternalMarks(for: subject.id, value: Double($0)) }
                ),
                in: 0...max(0, Int(subject.internalMaxMarks))
            )
            ProgressView(value: subject.internalMarksObtained, total: max(1, subject.internalMaxMarks))
                .tint(AppTheme.accent)
            Text("Out of 50 (your weightage): \(Int(prediction.internalScaled.rounded()))")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .monospacedDigit()
        }

        Section("Target Grade") {
            Picker("Target", selection: Binding(
                get: { subject.targetGrade },
                set: { viewModel.updateTargetGrade(for: subject.id, grade: $0) }
            )) {
                ForEach(GradeLetter.allCases.filter { $0 != .f }) { grade in
                    Text(grade.rawValue).tag(grade)
                }
            }
            .pickerStyle(.menu)
        }

        Section("What You Need to Pass") {
            LabeledContent("Your internal marks") {
                Text("\(Int(prediction.internalScaled.rounded())) / 50")
                    .monospacedDigit()
            }
            LabeledContent("End-sem score needed") {
                Text("\(Int(max(0, prediction.requiredEnd).rounded())) out of \(Int(subject.endSemMaxMarks))")
                    .monospacedDigit()
            }

            if prediction.feasible {
                Label("Target achievable", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Target not achievable", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    private func predictGrade(for subject: Subject, target: GradeLetter) -> (internalScaled: Double, requiredEnd: Double, feasible: Bool) {
        let internalScaled = (subject.internalMarksObtained / max(1, subject.internalMaxMarks)) * 50
        let requiredTotal = target.requiredPercentage
        let requiredEnd = requiredTotal - internalScaled
        let feasible = requiredEnd <= subject.endSemMaxMarks && requiredEnd >= 0
        return (internalScaled, requiredEnd, feasible)
    }

    private func riskLabel(for percentage: Double) -> String {
        if percentage >= 85 { return "Safe" }
        if percentage >= 75 { return "On Track" }
        if percentage >= 60 { return "At Risk" }
        return "Critical"
    }

    private func riskAccessibilityLevel(for percentage: Double) -> String {
        if percentage >= 85 { return "Low" }
        if percentage >= 75 { return "Medium" }
        return "High"
    }

    private func riskBadgeColor(for percentage: Double) -> Color {
        if percentage >= 85 { return .green }
        if percentage >= 75 { return .blue }
        if percentage >= 60 { return .orange }
        return .red
    }

}
