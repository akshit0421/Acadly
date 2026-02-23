import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var viewModel: ScheduleViewModel
    @State private var showAddSheet = false
    @State private var selectedDate: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            dayStrip
                .padding(.horizontal, 16)
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 16) {
                    if dayItems.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No Classes")
                                .font(.headline)
                            Text("No schedule entries for \(selectedWeekday.displayName), \(selectedDate.formatted(date: .abbreviated, time: .omitted)).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(dayItems.enumerated()), id: \.element.id) { index, item in
                                HStack(alignment: .top, spacing: 12) {
                                    timelineIndicator(isLast: index == dayItems.count - 1)
                                    ScheduleRowView(item: item)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Schedule")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Class", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddScheduleView { newItem in
                viewModel.addItem(newItem)
            }
        }
        .alert("Storage Issue", isPresented: isShowingPersistenceError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.persistenceErrorMessage ?? "An unknown error occurred.")
        }
    }

    private var isShowingPersistenceError: Binding<Bool> {
        Binding(
            get: { viewModel.persistenceErrorMessage != nil },
            set: { shouldShow in
                if !shouldShow {
                    viewModel.clearPersistenceError()
                }
            }
        )
    }

    private var dayItems: [ScheduleItem] {
        viewModel.items(for: selectedWeekday).sorted { $0.startTime < $1.startTime }
    }

    private var selectedWeekday: Weekday {
        weekday(from: selectedDate)
    }

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(weekDates, id: \.self) { date in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = date
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(weekday(from: date).shortName.uppercased())
                                .font(.caption.weight(.semibold))
                            Text(date.formatted(.dateTime.day()))
                                .font(.headline.weight(.bold))
                        }
                        .frame(width: 64, height: 68)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSameDay(date, selectedDate) ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(isSameDay(date, selectedDate) ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func timelineIndicator(isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)

            if !isLast {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 2, height: 104)
                    .padding(.top, 4)
            }
        }
        .frame(width: 14)
        .padding(.top, 14)
    }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let base = selectedDate
        let weekdayIndex = calendar.component(.weekday, from: base)
        let firstWeekday = calendar.firstWeekday
        let distance = (weekdayIndex - firstWeekday + 7) % 7
        let startOfWeek = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -distance, to: base) ?? base)

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    private func weekday(from date: Date) -> Weekday {
        let weekdayValue = Calendar.current.component(.weekday, from: date)
        switch weekdayValue {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }

    private func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        Calendar.current.isDate(lhs, inSameDayAs: rhs)
    }
}
