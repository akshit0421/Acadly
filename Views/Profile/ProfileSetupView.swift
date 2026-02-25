import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var coursesViewModel: CoursesViewModel
    @EnvironmentObject private var scheduleViewModel: ScheduleViewModel

    @AppStorage("attendify.profile.name") private var profileName: String = "Student"

    @State private var baselineCGPA = ""
    @State private var baselineCredits = ""
    @State private var showResetAlert = false
    @State private var saved = false
    @State private var animateIn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("System")
                    .font(.title2.weight(.bold))
                Text("Your academic profile")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                snapshotCard
                statsRow
                profileSetupCard
                dangerZoneCard
            }
            .padding(16)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 8)
        }
        .appScreenBackground()
        .onAppear {
            baselineCGPA = String(format: "%.2f", coursesViewModel.previousCGPA)
            baselineCredits = String(format: "%.0f", coursesViewModel.previousCredits)
            withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                animateIn = true
            }
        }
        .alert("Reset all data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                coursesViewModel.resetAllData()
                scheduleViewModel.resetAllData()
            }
        } message: {
            Text("This will remove all attendance, grades, and schedule data.")
        }
    }

    private var snapshotCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Academic Snapshot")
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
                .textCase(.uppercase)
            Text("Sem \(coursesViewModel.currentSemester) · \(Int(coursesViewModel.overallAttendance.rounded()))% avg attendance · Pred. SGPA \(String(format: "%.2f", coursesViewModel.currentSGPA)) · \(coursesViewModel.riskSubjects.count) subject(s) at risk")
                .font(.footnote)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Auto-generated · Fully offline")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile("Attendance", "\(Int(coursesViewModel.overallAttendance.rounded()))%", color: riskColor(for: coursesViewModel.overallAttendance))
            statTile("Pred. SGPA", String(format: "%.2f", coursesViewModel.currentSGPA), color: AppTheme.accent)
            statTile("At Risk", "\(coursesViewModel.riskSubjects.count)", color: coursesViewModel.riskSubjects.isEmpty ? .green : .orange)
        }
    }

    private var profileSetupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile Setup")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)

            entryField("Name", text: $profileName)

            VStack(alignment: .leading, spacing: 4) {
                Text("Department")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                Picker("Department", selection: Binding(
                    get: { coursesViewModel.selectedDepartment },
                    set: { coursesViewModel.updateDepartment($0) }
                )) {
                    ForEach(DepartmentRuleSet.allCases, id: \.self) { item in
                        Text(item.rawValue.capitalized).tag(item)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Semester")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                Stepper(
                    "\(coursesViewModel.currentSemester)",
                    value: Binding(
                        get: { coursesViewModel.currentSemester },
                        set: { coursesViewModel.updateSemester($0) }
                    ),
                    in: 1...12
                )
            }

            entryField("Baseline CGPA", text: $baselineCGPA, keyboard: .decimalPad)
            entryField("Previous Credits", text: $baselineCredits, keyboard: .numberPad)

            Button {
                coursesViewModel.updatePastAcademics(
                    previousCGPA: Double(baselineCGPA) ?? coursesViewModel.previousCGPA,
                    previousCredits: Double(baselineCredits) ?? coursesViewModel.previousCredits
                )
                withAnimation(.easeInOut(duration: 0.2)) {
                    saved = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        saved = false
                    }
                }
            } label: {
                Text(saved ? "✓ Saved" : "Save Profile")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppPrimaryButtonStyle())
        }
        .appCard()
    }

    private var dangerZoneCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Danger Zone")
                .font(.caption)
                .foregroundStyle(.red)
                .textCase(.uppercase)
            Text("Permanently clear all attendance and grade data. This cannot be undone.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
            Button("Reset All Data", role: .destructive) {
                showResetAlert = true
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(AppSecondaryButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func statTile(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.black).monospacedDigit())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.card)
        )
    }

    private func entryField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
            TextField("", text: text)
                .keyboardType(keyboard)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func riskColor(for attendance: Double) -> Color {
        if attendance >= 85 { return .green }
        if attendance >= 75 { return AppTheme.accent }
        if attendance >= 60 { return .orange }
        return .red
    }
}
