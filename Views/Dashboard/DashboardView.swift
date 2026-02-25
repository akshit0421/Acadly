import SwiftUI

struct DashboardView: View {
    private struct MarkedClassState {
        var status: String
        var lectureCount: Int
    }

    private struct UndoPayload {
        var itemID: UUID
        var subjectID: UUID
        var previous: MarkedClassState?
        var current: MarkedClassState?
        var message: String
    }

    @EnvironmentObject private var viewModel: CoursesViewModel
    @EnvironmentObject private var scheduleViewModel: ScheduleViewModel

    @State private var now = Date()
    @State private var markedClasses: [UUID: MarkedClassState] = [:]
    @State private var expandedLectureEditorID: UUID?
    @State private var isHealthExpanded = false

    @State private var showUndo = false
    @State private var undoPayload: UndoPayload?
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var feedbackTrigger = 0

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            Section {
                DisclosureGroup(isExpanded: $isHealthExpanded) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Predicted CGPA: \(String(format: "%.2f", viewModel.currentSGPA))")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(insightMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.top, 4)
                } label: {
                    Label {
                        Text(healthSummaryText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    } icon: {
                        Image(systemName: riskCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(riskCount == 0 ? Color.green : Color.orange)
                    }
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.card)
            )

            Section("Today's Classes") {
                if todayItems.isEmpty {
                    VStack(spacing: 12) {
                        Label("No classes today", systemImage: "moon.zzz")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)

                        if scheduleViewModel.items.isEmpty && !viewModel.subjects.isEmpty {
                            NavigationLink(destination: ScheduleView()) {
                                Text("Set up your weekly schedule →")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(todayItems) { item in
                        todayClassRow(item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .appScreenBackground()
        .navigationTitle(greeting)
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottom) {
            if showUndo, let undoPayload {
                undoToastView(message: undoPayload.message)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .successSensoryFeedback(trigger: feedbackTrigger)
        .onReceive(timer) { value in
            now = value
        }
    }

    private func todayClassRow(_ item: ScheduleItem) -> some View {
        let markedState = markedClasses[item.id]
        let marked = markedState?.status
        let isPresent = marked == "present"
        let isAbsent = marked == "absent"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.lecture)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(item.startTime.formatted(date: .omitted, time: .shortened)) · \(item.building ?? "Classroom")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                if isPresent {
                    Label(
                        expandedLectureEditorID == item.id ? "Adjust lectures" : "1 lecture",
                        systemImage: expandedLectureEditorID == item.id ? "chevron.up" : "number.circle"
                    )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }

            if isPresent, expandedLectureEditorID == item.id {
                Stepper(value: lectureCountBinding(for: item), in: 1...8) {
                    Text("How many lectures in this class?")
                        .font(.subheadline)
                }
                .tint(AppTheme.accent)
            }

            if isPresent || isAbsent {
                Label(isPresent ? "Marked Present" : "Marked Absent", systemImage: isPresent ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isPresent ? Color.green : Color.red)
            }

            if markedState == nil {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                    Text("Swipe to mark")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(14)
        .frame(minHeight: 44, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.track.opacity(0.28), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard isPresent else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                expandedLectureEditorID = expandedLectureEditorID == item.id ? nil : item.id
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                handlePresentSwipe(for: item)
            } label: {
                Label("Present", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
            .accessibilityLabel("Mark present")
            .accessibilityHint("Marks this class as attended")
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                handleAbsentSwipe(for: item)
            } label: {
                Label("Absent", systemImage: "xmark.circle.fill")
            }
            .tint(.red)
            .accessibilityLabel("Mark absent")
            .accessibilityHint("Marks this class as missed")
        }
    }

    private var todayItems: [ScheduleItem] {
        scheduleViewModel.items(for: weekday(from: now)).sorted { $0.startTime < $1.startTime }
    }

    private var riskCount: Int {
        viewModel.subjects.filter { $0.attendancePercentage < 75 }.count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var healthSummaryText: String {
        if riskCount == 0 { return "On Track ✓" }
        if riskCount == 1 { return "1 subject at risk ⚠" }
        return "\(riskCount) subjects at risk ⚠"
    }

    private var insightMessage: String {
        if let critical = viewModel.subjects.first(where: { $0.attendancePercentage < 65 }) {
            return "\(critical.name) needs recovery: attend next \(critical.classesToRecover) classes."
        }
        if riskCount > 0 {
            return "Focus this week: \(riskCount) subject(s) are below target attendance."
        }
        return "You are currently in a safe attendance range."
    }

    private func handlePresentSwipe(for item: ScheduleItem) {
        let previous = markedClasses[item.id]
        if previous?.status == "present" {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                expandedLectureEditorID = item.id
            }
            return
        }

        let current = MarkedClassState(status: "present", lectureCount: 1)
        applyStateChange(for: item, from: previous, to: current)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            expandedLectureEditorID = item.id
        }
        showUndoToast(for: item, previous: previous, current: current, message: "Marked \(item.lecture) present")
    }

    private func handleAbsentSwipe(for item: ScheduleItem) {
        let previous = markedClasses[item.id]
        let current = MarkedClassState(status: "absent", lectureCount: 1)
        applyStateChange(for: item, from: previous, to: current)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            if expandedLectureEditorID == item.id {
                expandedLectureEditorID = nil
            }
        }
        showUndoToast(for: item, previous: previous, current: current, message: "Marked \(item.lecture) absent")
    }

    private func applyStateChange(for item: ScheduleItem, from previous: MarkedClassState?, to current: MarkedClassState?) {
        let before = attendanceContribution(for: previous)
        let after = attendanceContribution(for: current)
        let presentDelta = after.present - before.present
        let totalDelta = after.total - before.total

        if presentDelta != 0 || totalDelta != 0 {
            viewModel.adjustAttendance(for: item.subjectID, presentDelta: presentDelta, totalDelta: totalDelta)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            if let current {
                markedClasses[item.id] = current
            } else {
                markedClasses.removeValue(forKey: item.id)
            }
        }
    }

    private func attendanceContribution(for state: MarkedClassState?) -> (present: Int, total: Int) {
        guard let state else { return (0, 0) }
        let count = max(1, state.lectureCount)
        if state.status == "present" {
            return (count, count)
        }
        return (0, count)
    }

    private func lectureCountBinding(for item: ScheduleItem) -> Binding<Int> {
        Binding(
            get: { max(1, markedClasses[item.id]?.lectureCount ?? 1) },
            set: { newValue in
                guard let old = markedClasses[item.id], old.status == "present" else { return }
                let updatedCount = max(1, newValue)
                guard old.lectureCount != updatedCount else { return }

                let updated = MarkedClassState(status: "present", lectureCount: updatedCount)
                applyStateChange(for: item, from: old, to: updated)
            }
        )
    }

    private func showUndoToast(
        for item: ScheduleItem,
        previous: MarkedClassState?,
        current: MarkedClassState?,
        message: String
    ) {
        undoDismissTask?.cancel()
        undoPayload = UndoPayload(itemID: item.id, subjectID: item.subjectID, previous: previous, current: current, message: message)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            showUndo = true
        }

        feedbackTrigger += 1

        undoDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                showUndo = false
            }
        }
    }

    private func undoLastAction() {
        guard let undoPayload else { return }
        let before = attendanceContribution(for: undoPayload.current)
        let after = attendanceContribution(for: undoPayload.previous)
        let presentDelta = after.present - before.present
        let totalDelta = after.total - before.total

        if presentDelta != 0 || totalDelta != 0 {
            viewModel.adjustAttendance(for: undoPayload.subjectID, presentDelta: presentDelta, totalDelta: totalDelta)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
            if let previous = undoPayload.previous {
                markedClasses[undoPayload.itemID] = previous
                expandedLectureEditorID = previous.status == "present" ? undoPayload.itemID : nil
            } else {
                markedClasses.removeValue(forKey: undoPayload.itemID)
                if expandedLectureEditorID == undoPayload.itemID {
                    expandedLectureEditorID = nil
                }
            }
            showUndo = false
        }

        undoDismissTask?.cancel()
    }

    private func undoToastView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(AppTheme.accent)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo") {
                undoLastAction()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.track.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func weekday(from date: Date) -> Weekday {
        switch Calendar.current.component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
}

private extension View {
    @ViewBuilder
    func successSensoryFeedback(trigger: Int) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.success, trigger: trigger)
        } else {
            self
        }
    }
}
