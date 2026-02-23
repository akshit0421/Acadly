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

    func clearPersistenceError() {
        persistenceErrorMessage = nil
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
}
