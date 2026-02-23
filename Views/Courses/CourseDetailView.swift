import SwiftUI

struct CourseDetailView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel

    let subjectID: UUID

    @State private var manualPresentText = ""
    @State private var manualTotalText = ""
    @State private var animateProgress = false

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
                        manualInputCard(for: subject)
                        assessmentCard(for: subject)
                    }
                    .padding(16)
                }
                .onAppear {
                    manualPresentText = "\(subject.manualPresent)"
                    manualTotalText = "\(subject.manualTotal)"
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

            Text("\(Int(subject.attendancePercentage.rounded()))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(riskColor(for: subject.attendanceRisk))
                .monospacedDigit()

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
                .fill(Color(.secondarySystemGroupedBackground))
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
            .buttonStyle(.borderedProminent)

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
            .buttonStyle(.bordered)
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
            .buttonStyle(.bordered)
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
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func assessmentCard(for subject: Subject) -> some View {
        VStack(spacing: 12) {
            if let percentage = subject.scoredPercentage {
                statRow(title: "Score", value: String(format: "%.1f%%", percentage), symbol: "percent")
            }
            statRow(title: "Inferred Grade", value: subject.inferredGrade.rawValue, symbol: "graduationcap")
            statRow(
                title: "Department Rules",
                value: subject.academicProfile.departmentRuleSet.rawValue.capitalized,
                symbol: "building.2"
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
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
