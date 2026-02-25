import SwiftUI

struct OnboardingFlowView: View {
    private struct SubjectDraft: Identifiable {
        let id = UUID()
        var name: String
        var credits: Int
        var days: Set<Weekday> = []
    }

    private enum Step: Int {
        case subjects
        case schedule
        case goal
    }

    @EnvironmentObject private var coursesViewModel: CoursesViewModel
    @EnvironmentObject private var scheduleViewModel: ScheduleViewModel

    let onComplete: () -> Void

    @State private var step: Step = .subjects
    @State private var drafts: [SubjectDraft] = []
    @State private var nameInput = ""
    @State private var creditsInput = 3
    @State private var attendanceGoal = 75.0

    private let activeDays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                pageIndicator

                switch step {
                case .subjects:
                    subjectsStep
                case .schedule:
                    scheduleStep
                case .goal:
                    goalStep
                }

                Spacer(minLength: 8)

                actionButtons
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .appScreenBackground()
            .interactiveDismissDisabled(true)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == step.rawValue ? AppTheme.accent : AppTheme.track.opacity(0.5))
                    .frame(width: index == step.rawValue ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: step.rawValue)
            }
        }
        .padding(.top, 8)
    }

    private var subjectsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add your subjects")
                .font(.title2.weight(.bold))
            Text("Add at least one subject to start tracking attendance.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                TextField("Subject name", text: $nameInput)
                    .textFieldStyle(.roundedBorder)

                Stepper("Credit hours: \(creditsInput)", value: $creditsInput, in: 1...8)

                Button("Add Subject") {
                    addDraftSubject()
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .appCard()

            if drafts.isEmpty {
                Text("No subjects added yet.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(drafts) { draft in
                        HStack {
                            Text(draft.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(draft.credits) credits")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.card)
                        )
                    }
                }
            }
        }
    }

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Set your weekly schedule")
                .font(.title2.weight(.bold))
            Text("Pick weekdays for each subject.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(draft.name)
                                .font(.subheadline.weight(.semibold))
                            dayPickerRow(
                                selected: draft.days,
                                onToggle: { day in
                                    toggleDay(day, for: index)
                                }
                            )
                        }
                        .appCard()
                    }
                }
            }
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Set your attendance goal")
                .font(.title2.weight(.bold))
            Text("This will be applied to all added subjects.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("\(Int(attendanceGoal.rounded()))% minimum attendance")
                    .font(.headline)

                Slider(value: $attendanceGoal, in: 60...95, step: 1)
                    .tint(AppTheme.accent)

                Text("I need to attend at least \(classesOutOfFour) of every 4 classes.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .appCard()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(step == .goal ? "Finish" : "Continue") {
                continueAction()
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(step == .subjects && drafts.isEmpty)

            if step != .subjects {
                Button("Skip for now") {
                    skipAction()
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
        }
    }

    private var classesOutOfFour: Int {
        min(4, max(1, Int((attendanceGoal / 100.0 * 4.0).rounded())))
    }

    private func addDraftSubject() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        drafts.append(SubjectDraft(name: trimmed, credits: max(1, creditsInput)))
        nameInput = ""
        creditsInput = 3
    }

    private func toggleDay(_ day: Weekday, for index: Int) {
        guard drafts.indices.contains(index) else { return }
        if drafts[index].days.contains(day) {
            drafts[index].days.remove(day)
        } else {
            drafts[index].days.insert(day)
        }
    }

    private func dayPickerRow(selected: Set<Weekday>, onToggle: @escaping (Weekday) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(activeDays, id: \.id) { day in
                Button(day.shortName) {
                    onToggle(day)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected.contains(day) ? Color.white : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected.contains(day) ? AppTheme.accent : AppTheme.track.opacity(0.28))
                )
                .buttonStyle(.plain)
            }
        }
    }

    private func continueAction() {
        switch step {
        case .subjects:
            guard !drafts.isEmpty else { return }
            step = .schedule
        case .schedule:
            step = .goal
        case .goal:
            finishOnboarding()
        }
    }

    private func skipAction() {
        if step == .schedule {
            step = .goal
        } else if step == .goal {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        for (index, draft) in drafts.enumerated() {
            let shortName = acronym(for: draft.name)
            guard let subjectID = coursesViewModel.addSubject(
                name: draft.name,
                shortName: shortName,
                credits: Double(draft.credits),
                minimumRequired: attendanceGoal,
                departmentRuleSet: coursesViewModel.selectedDepartment
            ) else {
                continue
            }

            let orderedDays = activeDays.filter { draft.days.contains($0) }
            for day in orderedDays {
                let (start, end) = defaultTimeSlot(for: index)
                let item = ScheduleItem(
                    subjectID: subjectID,
                    day: day,
                    startTime: start,
                    endTime: end,
                    lecture: draft.name,
                    building: nil,
                    lecturesCount: 1
                )
                scheduleViewModel.addItem(item)
            }
        }

        onComplete()
    }

    private func acronym(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count > 1 {
            let code = words.compactMap(\.first).prefix(6)
            return String(code).uppercased()
        }
        return String(name.prefix(6)).uppercased()
    }

    private func defaultTimeSlot(for index: Int) -> (Date, Date) {
        let startHour = min(18, 9 + (index % 8))
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: base) ?? Date()
        let end = calendar.date(bySettingHour: startHour + 1, minute: 0, second: 0, of: base) ?? start.addingTimeInterval(3600)
        return (start, end)
    }
}

