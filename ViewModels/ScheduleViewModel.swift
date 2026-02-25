import Combine
import Foundation

final class ScheduleViewModel: ObservableObject {
    @Published private(set) var items: [ScheduleItem] = []
    @Published private(set) var persistenceErrorMessage: String?

    private let store: ScheduleStore
    private var cancellables = Set<AnyCancellable>()

    init(store: ScheduleStore = ScheduleStore()) {
        self.store = store
        loadItems()
        bindAutoSave()
    }

    func addItem(_ item: ScheduleItem) {
        items.append(item)
    }

    func items(for day: Weekday) -> [ScheduleItem] {
        items.filter { $0.day == day }
    }

    func currentOrUpcomingClass(on referenceDate: Date = Date()) -> (item: ScheduleItem, isCurrent: Bool)? {
        let today = weekday(for: referenceDate)
        let todayItems = items(for: today)

        guard !todayItems.isEmpty else { return nil }

        let nowMinutes = minutesSinceMidnight(referenceDate)
        let sorted = todayItems.sorted { minutesSinceMidnight($0.startTime) < minutesSinceMidnight($1.startTime) }

        if let current = sorted.first(where: {
            let start = minutesSinceMidnight($0.startTime)
            let end = minutesSinceMidnight($0.endTime)
            return nowMinutes >= start && nowMinutes <= end
        }) {
            return (current, true)
        }

        if let upcoming = sorted.first(where: { minutesSinceMidnight($0.startTime) > nowMinutes }) {
            return (upcoming, false)
        }

        return nil
    }

    func clearPersistenceError() {
        persistenceErrorMessage = nil
    }

    func resetAllData() {
        items = []
    }

    private func loadItems() {
        do {
            items = try store.load()
            persistenceErrorMessage = nil
        } catch {
            items = []
            persistenceErrorMessage = "Could not load saved schedule."
        }
    }

    private func saveItems() {
        do {
            try store.save(items)
            persistenceErrorMessage = nil
        } catch {
            persistenceErrorMessage = "Could not save schedule changes."
        }
    }

    private func bindAutoSave() {
        $items
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveItems()
            }
            .store(in: &cancellables)
    }

    private func weekday(for date: Date) -> Weekday {
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

    private func minutesSinceMidnight(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return hour * 60 + minute
    }
}
