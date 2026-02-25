import SwiftUI

struct CoursesView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    @State private var showAddSheet = false
    @State private var selectedSubjectID: UUID?
    @State private var simExtraClasses: Double = 0
    @State private var animateList = false

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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                animateList = true
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: selectedSubjectID)
        .toolbar {
            if selectedSubject == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Course", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCourseView()
        }
    }

    private var subjectList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tap a subject to manage")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                ForEach(viewModel.subjects) { subject in
                    let p = subject.attendancePercentage
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            selectedSubjectID = subject.id
                            simExtraClasses = 0
                        }
                    } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(riskColor(for: p))
                                .frame(width: 3, height: 52)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(subject.name)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(subject.shortName) · \(String(format: "%.1f", subject.credits)) credits")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(AppTheme.track.opacity(0.35))
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(riskColor(for: p))
                                            .frame(width: geo.size.width * min(1, max(0, p / 100)))
                                    }
                                }
                                .frame(height: 4)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                Text("\(Int(p.rounded()))%")
                                    .font(.title3.weight(.black).monospacedDigit())
                                    .foregroundStyle(riskColor(for: p))
                                badge(riskLabel(for: p), color: riskColor(for: p))
                            }
                        }
                        .appCard()
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func subjectDetail(_ subject: Subject) -> some View {
        let p = subject.attendancePercentage
        let simulatedP = subject.projectedAttendance(afterAttending: Int(simExtraClasses))

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        selectedSubjectID = nil
                        simExtraClasses = 0
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.shortName)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)
                    Text(subject.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    badge(riskLabel(for: p), color: riskColor(for: p))
                }

                HStack(spacing: 16) {
                    ProgressRingView(progress: min(1, max(0, p / 100)))
                        .frame(width: 88, height: 88)
                        .overlay {
                            Text("\(Int(p.rounded()))%")
                                .font(.headline.weight(.bold).monospacedDigit())
                                .foregroundStyle(riskColor(for: p))
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        detailStat("Attended", "\(subject.presentCount)/\(subject.totalClasses)", .primary)
                        detailStat("Safe to Miss", subject.classesCanMiss > 0 ? "\(subject.classesCanMiss) classes" : "None", subject.classesCanMiss > 0 ? .green : .red)
                        if p < subject.minimumRequired {
                            detailStat("Need to Attend", "\(subject.classesToRecover) classes", .orange)
                        }
                    }
                    Spacer()
                }
                .appCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Mark")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)

                    HStack(spacing: 10) {
                        Button {
                            viewModel.markAttendance(for: subject.id, isPresent: true)
                        } label: {
                            Text("+ Present")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppPrimaryButtonStyle())

                        Button {
                            viewModel.markAttendance(for: subject.id, isPresent: false)
                        } label: {
                            Text("+ Absent")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppSecondaryButtonStyle())
                    }
                }
                .appCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("What-If Simulator")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .textCase(.uppercase)

                    Text("Attend \(Int(simExtraClasses)) more consecutive classes")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    Slider(value: $simExtraClasses, in: 0...20, step: 1)
                        .tint(AppTheme.accent)

                    HStack {
                        Text("Projected attendance")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text("\(Int(simulatedP.rounded()))%")
                            .font(.title3.weight(.black).monospacedDigit())
                            .foregroundStyle(simulatedP >= subject.minimumRequired ? .green : .orange)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill((simulatedP >= subject.minimumRequired ? Color.green : Color.orange).opacity(0.12))
                    )
                }
                .appCard()
            }
            .padding(16)
        }
    }

    private func detailStat(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
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

    private func riskColor(for percentage: Double) -> Color {
        if percentage >= 85 { return .green }
        if percentage >= 75 { return AppTheme.accent }
        if percentage >= 60 { return .orange }
        return .red
    }

    private func riskLabel(for percentage: Double) -> String {
        if percentage >= 85 { return "Safe" }
        if percentage >= 75 { return "On Track" }
        if percentage >= 60 { return "At Risk" }
        return "Critical"
    }
}
