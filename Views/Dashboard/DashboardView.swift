import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DashboardView: View {
    private struct MarkedClassState {
        var status: String
        var lectureCount: Int
    }

    private struct UndoToastPayload: Identifiable {
        let id = UUID()
        let itemID: UUID
        let subjectID: UUID
        let previous: MarkedClassState?
        let current: MarkedClassState?
        let message: String
    }

    @EnvironmentObject private var viewModel: CoursesViewModel
    @EnvironmentObject private var scheduleViewModel: ScheduleViewModel

    @State private var now = Date()
    @State private var markedClasses: [UUID: MarkedClassState] = [:]
    @State private var expandedLectureEditorID: UUID?
    @State private var undoToast: UndoToastPayload?
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var animatedCheckItemID: UUID?
    @State private var animateIn = false

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                heroCard
                insightCard
                todayClassesSection
            }
            .padding(16)
        }
        .appScreenBackground()
        .overlay(alignment: .bottom) {
            if let undoToast {
                undoToastView(undoToast)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                animateIn = true
            }
        }
        .onReceive(timer) { value in
            now = value
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
            Text(greeting)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Here's your academic status")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var heroCard: some View {
        HStack(spacing: 16) {
            ProgressRingView(progress: min(1, max(0, overallAttendanceAverage / 100)))
                .frame(width: 88, height: 88)
                .overlay {
                    VStack(spacing: 1) {
                        Text("\(Int(overallAttendanceAverage.rounded()))%")
                            .font(.headline.weight(.bold).monospacedDigit())
                            .foregroundStyle(riskColor(for: overallAttendanceAverage))
                        Text("Attend")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                Text("Academic Health")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .textCase(.uppercase)
                statRow("Pred. CGPA", String(format: "%.2f", predictedCGPA), color: AppTheme.accent)
                statRow("At Risk", "\(riskCount) subj.", color: riskCount > 0 ? .orange : .green)
                statRow("Subjects", "\(viewModel.subjects.count)", color: AppTheme.textSecondary)
            }

            Spacer()
        }
        .appCard()
        .scaleEffect(animateIn ? 1 : 0.98)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: animateIn)
    }

    private var insightCard: some View {
        Text(insightMessage)
            .font(.footnote)
            .foregroundStyle(AppTheme.textSecondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
                    )
            )
    }

    private var todayClassesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Classes")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)

            ForEach(todayItems) { item in
                todayClassCard(item)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: todayItems.map(\.id))
    }

    private func todayClassCard(_ item: ScheduleItem) -> some View {
        let markedState = markedClasses[item.id]
        let marked = markedState?.status
        let subjectColor = (viewModel.subject(withID: item.subjectID)?.attendancePercentage).map(riskColor(for:)) ?? AppTheme.accent

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(marked == "present" ? Color.green : marked == "absent" ? Color.red : subjectColor)
                    .frame(width: 3, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.lecture)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(item.startTime.formatted(date: .omitted, time: .shortened)) · \(item.building ?? "Classroom")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    markActionButton(
                        systemImage: "checkmark",
                        title: "Present",
                        tint: .green,
                        isActive: marked == "present",
                        animated: animatedCheckItemID == item.id
                    ) {
                        handlePresentTap(for: item)
                    }
                    markActionButton(
                        systemImage: "xmark",
                        title: "Absent",
                        tint: .red,
                        isActive: marked == "absent",
                        animated: false
                    ) {
                        handleAbsentTap(for: item)
                    }
                }
            }

            if marked == "present", expandedLectureEditorID == item.id {
                let count = max(1, markedState?.lectureCount ?? 1)
                Stepper(value: lectureCountBinding(for: item), in: 1...8) {
                    Text("Lectures counted: \(count)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .tint(AppTheme.accent)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let marked {
                statusBadge(label: marked == "present" ? "Marked Present" : "Marked Absent", color: marked == "present" ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.track.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var todayItems: [ScheduleItem] {
        scheduleViewModel.items(for: weekday(from: now)).sorted { $0.startTime < $1.startTime }
    }

    private var overallAttendanceAverage: Double {
        guard !viewModel.subjects.isEmpty else { return 0 }
        let sum = viewModel.subjects.reduce(0.0) { $0 + $1.attendancePercentage }
        return sum / Double(viewModel.subjects.count)
    }

    private var predictedCGPA: Double {
        let raw = 7.2 + ((overallAttendanceAverage - 75) * 0.04)
        return min(10, max(4, raw))
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

    private var insightMessage: String {
        if let critical = viewModel.subjects.first(where: { $0.attendancePercentage < 65 }) {
            return "⚠ \(critical.name) is critical — attend next \(critical.classesToRecover) classes to recover."
        }
        if riskCount > 0 {
            return "\(riskCount) subject(s) need attention. Stay consistent this week."
        }
        return "✓ You're on track. Keep the momentum going."
    }

    private func handlePresentTap(for item: ScheduleItem) {
        let previous = markedClasses[item.id]

        if previous?.status == "present" {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                expandedLectureEditorID = item.id
            }
            triggerCheckAnimation(for: item.id)
            feedbackImpactLight()
            return
        }

        let current = MarkedClassState(status: "present", lectureCount: 1)
        applyStateChange(for: item, from: previous, to: current)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            expandedLectureEditorID = item.id
        }
        showUndoToast(for: item, previous: previous, current: current, message: "Marked \(item.lecture) present")
        triggerCheckAnimation(for: item.id)
        feedbackNotification(.success)
    }

    private func handleAbsentTap(for item: ScheduleItem) {
        let previous = markedClasses[item.id]
        let current = MarkedClassState(status: "absent", lectureCount: 1)
        applyStateChange(for: item, from: previous, to: current)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            if expandedLectureEditorID == item.id {
                expandedLectureEditorID = nil
            }
        }
        showUndoToast(for: item, previous: previous, current: current, message: "Marked \(item.lecture) absent")
        feedbackNotification(.warning)
    }

    private func applyStateChange(for item: ScheduleItem, from previous: MarkedClassState?, to current: MarkedClassState?) {
        let before = attendanceContribution(for: previous)
        let after = attendanceContribution(for: current)
        let presentDelta = after.present - before.present
        let totalDelta = after.total - before.total

        if presentDelta != 0 || totalDelta != 0 {
            viewModel.adjustAttendance(for: item.subjectID, presentDelta: presentDelta, totalDelta: totalDelta)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            undoToast = UndoToastPayload(
                itemID: item.id,
                subjectID: item.subjectID,
                previous: previous,
                current: current,
                message: message
            )
        }

        undoDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                undoToast = nil
            }
        }
    }

    private func undoLastAction() {
        guard let toast = undoToast else { return }
        let before = attendanceContribution(for: toast.current)
        let after = attendanceContribution(for: toast.previous)
        let presentDelta = after.present - before.present
        let totalDelta = after.total - before.total

        if presentDelta != 0 || totalDelta != 0 {
            viewModel.adjustAttendance(for: toast.subjectID, presentDelta: presentDelta, totalDelta: totalDelta)
        }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            if let previous = toast.previous {
                markedClasses[toast.itemID] = previous
                expandedLectureEditorID = previous.status == "present" ? toast.itemID : nil
            } else {
                markedClasses.removeValue(forKey: toast.itemID)
                if expandedLectureEditorID == toast.itemID {
                    expandedLectureEditorID = nil
                }
            }
            undoToast = nil
        }
        undoDismissTask?.cancel()
        feedbackImpactLight()
    }

    private func triggerCheckAnimation(for itemID: UUID) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.66)) {
            animatedCheckItemID = itemID
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.18)) {
                if animatedCheckItemID == itemID {
                    animatedCheckItemID = nil
                }
            }
        }
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

    private func riskColor(for percentage: Double) -> Color {
        if percentage >= 85 { return .green }
        if percentage >= 75 { return AppTheme.accent }
        if percentage >= 60 { return .orange }
        return .red
    }

    private func statRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
        }
    }

    private func statusBadge(label: String, color: Color) -> some View {
        Text(label.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.15))
                    .overlay(Capsule(style: .continuous).stroke(color.opacity(0.4), lineWidth: 1))
            )
    }

    private func markActionButton(
        systemImage: String,
        title: String,
        tint: Color,
        isActive: Bool,
        animated: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                    .scaleEffect(animated ? 1.18 : 1)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isActive ? .white : tint)
            .frame(minWidth: 96, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? tint : tint.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(tint.opacity(isActive ? 0 : 0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func undoToastView(_ toast: UndoToastPayload) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accent)
            Text(toast.message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo") {
                undoLastAction()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.track.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private func feedbackNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
#if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
#endif
    }

    private func feedbackImpactLight() {
#if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
#endif
    }
}
