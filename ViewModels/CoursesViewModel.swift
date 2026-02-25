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
    @Published var targetCGPA: Double = 8.5
    @Published var previousCGPA: Double = 0
    @Published var previousCredits: Double = 0
    @Published var selectedDepartment: DepartmentRuleSet = .standard
    @Published var currentSemester: Int = 1

    private let store: CoursesStore
    private var cancellables = Set<AnyCancellable>()
    private let preferencesStore = AcademicPreferencesStore()

    init(store: CoursesStore = CoursesStore()) {
        self.store = store
        loadSubjects()
        loadPreferences()
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

        let totalCredits = included.reduce(0.0) { $0 + $1.credits }
        let totalPoints = included.reduce(0) { partialResult, subject in
            partialResult + (subject.inferredGrade.points * subject.credits)
        }

        guard totalCredits > 0 else { return 0 }
        return totalPoints / totalCredits
    }

    var riskSubjects: [Subject] {
        subjects.filter { $0.attendanceRisk == .critical }
    }

    var attendancePreview: [SubjectAttendance] {
        subjects
            .map(SubjectAttendance.from)
            .sorted { $0.percentage < $1.percentage }
            .prefix(5)
            .map { $0 }
    }

    var currentSGPA: Double {
        predictedCGPA
    }

    var cumulativeCGPA: Double {
        let currentCredits = subjects.filter { $0.includeInGPA }.reduce(0.0) { $0 + $1.credits }
        let oldCredits = max(0, previousCredits)
        let totalCredits = oldCredits + currentCredits
        guard totalCredits > 0 else { return 0 }
        return ((max(0, previousCGPA) * oldCredits) + (currentSGPA * currentCredits)) / totalCredits
    }

    var cgpaDelta: Double {
        cumulativeCGPA - max(0, previousCGPA)
    }

    var targetProgress: Double {
        guard targetCGPA > 0 else { return 1 }
        return min(1, max(0, cumulativeCGPA / targetCGPA))
    }

    var improvementPotential: Double {
        max(0, targetCGPA - cumulativeCGPA)
    }

    var smartInsights: [String] {
        var insights: [String] = []

        for subject in subjects {
            if subject.attendancePercentage < 60 {
                insights.append("\(subject.shortName): High attendance risk. Immediate recovery needed.")
            } else if subject.attendancePercentage < 75 {
                insights.append("\(subject.shortName): Attend next \(subject.classesToRecover) classes to recover.")
            } else if subject.attendancePercentage > 85 {
                insights.append("\(subject.shortName): Safe margin. You can miss \(subject.classesCanMiss) classes.")
            }

            if subject.isTargetGradeImpossible {
                insights.append("\(subject.shortName): Target \(subject.targetGrade.rawValue) is currently impossible.")
            }
        }

        if cgpaDelta > 0.01 {
            insights.append("Great progress: cumulative CGPA improved by \(String(format: "%.2f", cgpaDelta)).")
        }

        return Array(insights.prefix(5))
    }

    var supportedUpcomingModules: [AcademicModule] {
        [.choMarksPrediction, .cgpaCalculator]
    }

    func addSubject(name: String, shortName: String, credits: Double, minimumRequired: Double, departmentRuleSet: DepartmentRuleSet) {
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

    func markAttendance(for subjectID: UUID, isPresent: Bool, count: Int = 1) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        let safeCount = max(1, count)
        for _ in 0..<safeCount {
            subjects[index].markAttendance(isPresent: isPresent)
        }
    }

    func adjustAttendance(for subjectID: UUID, presentDelta: Int, totalDelta: Int) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        let current = subjects[index]
        let updatedPresent = max(0, current.manualPresent + presentDelta)
        let updatedTotal = max(0, current.manualTotal + totalDelta)
        subjects[index].updateManualAttendance(present: updatedPresent, total: updatedTotal)
    }

    func updateManualAttendance(for subjectID: UUID, present: Int, total: Int) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        subjects[index].updateManualAttendance(present: present, total: total)
    }

    func updateInternalMarks(for subjectID: UUID, value: Double) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        let maxMarks = subjects[index].internalMaxMarks
        subjects[index].internalMarksObtained = min(max(0, value), maxMarks)
    }

    func updateCHOConfiguration(
        for subjectID: UUID,
        credits: Double,
        internalMaxMarks: Double,
        endSemMaxMarks: Double,
        choPassingMarks: Double
    ) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        subjects[index].credits = max(0, credits)
        subjects[index].internalMaxMarks = max(0, internalMaxMarks)
        subjects[index].endSemMaxMarks = max(0, endSemMaxMarks)
        subjects[index].choPassingMarks = max(0, choPassingMarks)
        subjects[index].internalMarksObtained = min(subjects[index].internalMarksObtained, subjects[index].internalMaxMarks)
    }

    func calculateRequiredEndSemMarks(for subjectID: UUID) -> Double {
        subject(withID: subjectID)?.requiredEndSemMarks ?? 0
    }

    func calculateOverallAttendance() -> Double {
        overallAttendance
    }

    func calculateCurrentCGPA() -> Double {
        predictedCGPA
    }

    func calculateProjectedCGPA(simulatedEndSemMarks: [UUID: Double]) -> Double {
        let included = subjects.filter { $0.includeInGPA }
        guard !included.isEmpty else { return 0 }

        let totalCredits = included.reduce(0.0) { $0 + $1.credits }
        let totalPoints = included.reduce(0.0) { partialResult, subject in
            let simulated = simulatedEndSemMarks[subject.id] ?? subject.requiredEndSemMarks
            let projected = subject.projectedOverallPercentage(simulatedEndSem: simulated)
            return partialResult + (GradeLetter.fromPercentage(projected).points * subject.credits)
        }

        guard totalCredits > 0 else { return 0 }
        return totalPoints / totalCredits
    }

    func insightForCHO(subjectID: UUID, simulatedEndSem: Double?) -> String? {
        guard let subject = subject(withID: subjectID) else { return nil }
        let target = simulatedEndSem ?? subject.requiredEndSemMarks
        let projected = calculateProjectedCGPA(simulatedEndSemMarks: [subjectID: target])
        return "You need \(Int(subject.requiredEndSemMarks.rounded(.up))) in End-Sem to pass CHO. Projected CGPA: \(String(format: "%.2f", projected))."
    }

    func clearPersistenceError() {
        persistenceErrorMessage = nil
    }

    func updateTargetCGPA(_ value: Double) {
        targetCGPA = min(10, max(0, value))
    }

    func updatePastAcademics(previousCGPA: Double, previousCredits: Double) {
        self.previousCGPA = max(0, previousCGPA)
        self.previousCredits = max(0, previousCredits)
    }

    func updateTargetGrade(for subjectID: UUID, grade: GradeLetter) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        subjects[index].targetGrade = grade
    }

    func updateCredits(for subjectID: UUID, value: Double) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        subjects[index].credits = max(0, value)
    }

    func updateDepartment(_ department: DepartmentRuleSet) {
        selectedDepartment = department
    }

    func updateSemester(_ semester: Int) {
        currentSemester = min(12, max(1, semester))
    }

    func resetAllData() {
        subjects = []
    }

    func addAssessmentComponent(for subjectID: UUID) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        subjects[index].assessmentComponents.append(
            AssessmentComponent(name: "Component \(subjects[index].assessmentComponents.count + 1)", weightage: 20, maxMarks: 20)
        )
    }

    func updateAssessmentComponent(
        for subjectID: UUID,
        componentID: UUID,
        name: String,
        weightage: Double,
        maxMarks: Double,
        earnedMarks: Double?,
        isBestOf: Bool
    ) {
        guard let subjectIndex = subjects.firstIndex(where: { $0.id == subjectID }) else { return }
        guard let componentIndex = subjects[subjectIndex].assessmentComponents.firstIndex(where: { $0.id == componentID }) else { return }
        subjects[subjectIndex].assessmentComponents[componentIndex].name = name
        subjects[subjectIndex].assessmentComponents[componentIndex].weightage = min(100, max(0, weightage))
        subjects[subjectIndex].assessmentComponents[componentIndex].maxMarks = max(0, maxMarks)
        if let earnedMarks {
            subjects[subjectIndex].assessmentComponents[componentIndex].earnedMarks = min(max(0, earnedMarks), maxMarks)
        } else {
            subjects[subjectIndex].assessmentComponents[componentIndex].earnedMarks = nil
        }
        subjects[subjectIndex].assessmentComponents[componentIndex].isBestOf = isBestOf
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

    private func loadPreferences() {
        let prefs = preferencesStore.load()
        targetCGPA = prefs.targetCGPA
        previousCGPA = prefs.previousCGPA
        previousCredits = prefs.previousCredits
        selectedDepartment = prefs.selectedDepartment
        currentSemester = prefs.currentSemester
    }

    private func savePreferences() {
        let prefs = AcademicPreferences(
            targetCGPA: targetCGPA,
            previousCGPA: previousCGPA,
            previousCredits: previousCredits,
            selectedDepartment: selectedDepartment,
            currentSemester: currentSemester
        )
        preferencesStore.save(prefs)
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

        Publishers.CombineLatest(
            Publishers.CombineLatest3($targetCGPA, $previousCGPA, $previousCredits),
            Publishers.CombineLatest($selectedDepartment, $currentSemester)
        )
            .dropFirst()
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
    }
}

private struct AcademicPreferences: Codable {
    var targetCGPA: Double = 8.5
    var previousCGPA: Double = 0
    var previousCredits: Double = 0
    var selectedDepartment: DepartmentRuleSet = .standard
    var currentSemester: Int = 1
}

private final class AcademicPreferencesStore {
    private let key = "attendify.academic.preferences.v1"

    func load() -> AcademicPreferences {
        guard let data = UserDefaults.standard.data(forKey: key),
              let prefs = try? JSONDecoder().decode(AcademicPreferences.self, from: data) else {
            return AcademicPreferences()
        }
        return prefs
    }

    func save(_ preferences: AcademicPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
