import Combine
import Foundation

enum AcademicModule: String, CaseIterable {
    case attendance
    case choMarksPrediction
    case cgpaCalculator
}

final class CoursesViewModel: ObservableObject {
    @Published private(set) var subjects: [Subject] = []
    @Published private(set) var persistenceErrorMessage: String?

    private let store: CoursesStore
    private var cancellables = Set<AnyCancellable>()

    init(store: CoursesStore = CoursesStore()) {
        self.store = store
        loadSubjects()
        bindAutoSave()
    }

    var overallAttendance: Double {
        let total = subjects.reduce(0) { $0 + $1.totalClasses }
        let attended = subjects.reduce(0) { $0 + $1.presentCount }
        guard total > 0 else { return 100.0 }
        return (Double(attended) / Double(total)) * 100.0
    }

    var predictedCGPA: Double {
        let included = subjects.filter { $0.includeInGPA }
        guard !included.isEmpty else { return 0 }

        let totalCredits = included.reduce(0) { $0 + $1.credits }
        let totalPoints = included.reduce(0) { partialResult, subject in
            partialResult + (subject.inferredGrade.points * Double(subject.credits))
        }

        guard totalCredits > 0 else { return 0 }
        return totalPoints / Double(totalCredits)
    }

    var riskSubjects: [Subject] {
        subjects.filter { $0.attendanceRisk == .critical }
    }

    var supportedUpcomingModules: [AcademicModule] {
        [.choMarksPrediction, .cgpaCalculator]
    }

    func addSubject(name: String, shortName: String, credits: Int, minimumRequired: Double, departmentRuleSet: DepartmentRuleSet) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let trimmedShortName = shortName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalShortName = trimmedShortName.isEmpty ? trimmedName : trimmedShortName

        let subject = Subject(
            name: trimmedName,
            shortName: finalShortName,
            credits: credits,
            minimumRequired: minimumRequired,
            academicProfile: SubjectAcademicProfile(departmentRuleSet: departmentRuleSet)
        )

        subjects.append(subject)
    }

    func delete(at offsets: IndexSet) {
        subjects.remove(atOffsets: offsets)
    }

    func subject(withID id: UUID) -> Subject? {
        subjects.first(where: { $0.id == id })
    }

    func markAttendance(for subjectID: UUID, isPresent: Bool) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        subjects[index].markAttendance(isPresent: isPresent)
    }

    func updateManualAttendance(for subjectID: UUID, present: Int, total: Int) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        subjects[index].updateManualAttendance(present: present, total: total)
    }

    func clearPersistenceError() {
        persistenceErrorMessage = nil
    }

    private func loadSubjects() {
        do {
            subjects = try store.load()
            persistenceErrorMessage = nil
        } catch {
            subjects = []
            persistenceErrorMessage = "Could not load saved subjects."
        }
    }

    private func saveSubjects() {
        do {
            try store.save(subjects)
            persistenceErrorMessage = nil
        } catch {
            persistenceErrorMessage = "Could not save your updates."
        }
    }

    private func bindAutoSave() {
        $subjects
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSubjects()
            }
            .store(in: &cancellables)
    }
}
