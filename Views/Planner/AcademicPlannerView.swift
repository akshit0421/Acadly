import SwiftUI

struct AcademicPlannerView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel

    @State private var selectedSubjectID: UUID?
    @State private var targetGrade: GradeLetter = .bPlus
    @State private var animateList = false

    private var selectedSubject: Subject? {
        guard let selectedSubjectID else { return nil }
        return viewModel.subject(withID: selectedSubjectID)
    }

    var body: some View {
        Group {
            if let subject = selectedSubject {
                gradesDetail(subject)
            } else {
                gradesList
            }
        }
        .appScreenBackground()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                animateList = true
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: selectedSubjectID)
    }

    private var gradesList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Grades")
                            .font(.title2.weight(.bold))
                        Text("Tap subject to plan grades")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Pred. SGPA")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .textCase(.uppercase)
                        Text(String(format: "%.2f", viewModel.currentSGPA))
                            .font(.largeTitle.weight(.black).monospacedDigit())
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                ForEach(viewModel.subjects) { subject in
                    let projected = predictGrade(for: subject, target: .bPlus)
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            selectedSubjectID = subject.id
                            targetGrade = subject.targetGrade
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(subject.name)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("\(String(format: "%.1f", subject.credits)) cr · Internal: \(Int(subject.internalMarksObtained))/\(Int(subject.internalMaxMarks))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                badge(projected.feasible ? "On Track" : "Review", color: projected.feasible ? .green : .orange)
                            }

                            HStack {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(AppTheme.track.opacity(0.35))
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(AppTheme.accent)
                                            .frame(width: geo.size.width * min(1, max(0, subject.internalMarksObtained / max(1, subject.internalMaxMarks))))
                                    }
                                }
                                .frame(height: 5)

                                Text("\(Int(((subject.internalMarksObtained / max(1, subject.internalMaxMarks)) * 100).rounded()))%")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .appCard()
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 8)
                    }
                    .buttonStyle(.plain)
                    .highTapTarget()
                }
            }
            .padding(16)
        }
    }

    private func gradesDetail(_ subject: Subject) -> some View {
        let prediction = predictGrade(for: subject, target: targetGrade)

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        selectedSubjectID = nil
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .highTapTarget()
                .foregroundStyle(AppTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.shortName)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)
                    Text(subject.name)
                        .font(.title2.weight(.bold))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Internal Marks")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)

                    Stepper(
                        "\(Int(subject.internalMarksObtained.rounded())) / \(Int(subject.internalMaxMarks))",
                        value: Binding(
                            get: { Int(subject.internalMarksObtained.rounded()) },
                            set: { viewModel.updateInternalMarks(for: subject.id, value: Double($0)) }
                        ),
                        in: 0...max(0, Int(subject.internalMaxMarks))
                    )

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.track.opacity(0.35))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.indigo)
                                .frame(width: geo.size.width * min(1, max(0, subject.internalMarksObtained / max(1, subject.internalMaxMarks))))
                        }
                    }
                    .frame(height: 6)

                    Text("Scaled to 50 → \(Int(prediction.internalScaled.rounded())) marks")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Target Grade")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(GradeLetter.allCases.filter { $0 != .f }) { grade in
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                    targetGrade = grade
                                    viewModel.updateTargetGrade(for: subject.id, grade: grade)
                                }
                            } label: {
                                Text(grade.rawValue)
                                    .font(.subheadline.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(targetGrade == grade ? Color.indigo : AppTheme.background.opacity(0.5))
                                    )
                                    .foregroundStyle(targetGrade == grade ? .white : AppTheme.textSecondary)
                                    .scaleEffect(targetGrade == grade ? 1 : 0.98)
                            }
                            .buttonStyle(.plain)
                            .highTapTarget()
                        }
                    }
                }
                .appCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("What You Need")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)

                    resultRow("Internal (scaled)", "\(Int(prediction.internalScaled.rounded())) / 50", .indigo)
                    resultRow("End-Sem needed", "\(Int(max(0, prediction.requiredEnd).rounded())) / 50", prediction.feasible ? AppTheme.accent : .red)

                    Text(prediction.feasible ? "✓ \(targetGrade.rawValue) is achievable" : "✗ \(targetGrade.rawValue) is out of reach")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(prediction.feasible ? .green : .red)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill((prediction.feasible ? Color.green : Color.red).opacity(0.12))
                        )
                }
                .appCard()
            }
            .padding(16)
        }
    }

    private func predictGrade(for subject: Subject, target: GradeLetter) -> (internalScaled: Double, requiredEnd: Double, feasible: Bool) {
        let internalScaled = (subject.internalMarksObtained / max(1, subject.internalMaxMarks)) * 50
        let requiredTotal = target.requiredPercentage
        let requiredEnd = requiredTotal - internalScaled
        let feasible = requiredEnd <= 50 && requiredEnd >= 0
        return (internalScaled, requiredEnd, feasible)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.13))
                    .overlay(Capsule(style: .continuous).stroke(color.opacity(0.4), lineWidth: 1))
            )
    }

    private func resultRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.title3.weight(.black).monospacedDigit())
                .foregroundStyle(color)
        }
    }
}
