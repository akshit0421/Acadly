import Foundation
import SwiftUI

final class DocumentScannerViewModel: ObservableObject {
    @Published var extractedText: String = ""
    @Published var detectedType: AcademicDocumentType = .unknown
    @Published var selectedType: AcademicDocumentType = .unknown

    @Published private(set) var timetableSubjects: [String] = []
    @Published private(set) var timetableSlots: [TimetableSlot] = []
    @Published private(set) var marksheetEntries: [MarksheetEntry] = []
    @Published private(set) var choEntries: [CHOEntry] = []
    @Published var isProcessing: Bool = false
    @Published var processingMessage: String = "Scanning document..."

    var sortedTimetableSlots: [TimetableSlot] {
        timetableSlots.sorted {
            let dayOrderLeft = weekdayOrder($0.day)
            let dayOrderRight = weekdayOrder($1.day)
            if dayOrderLeft != dayOrderRight {
                return dayOrderLeft < dayOrderRight
            }
            return minutesFromTimeText($0.startTimeText) < minutesFromTimeText($1.startTimeText)
        }
    }

    func processExtractedText(_ text: String) {
        extractedText = text
        detectedType = AcademicDocumentParser.classify(text)
        selectedType = detectedType
        refreshPreview()
    }

    func refreshPreview() {
        timetableSubjects = []
        timetableSlots = []
        marksheetEntries = []
        choEntries = []

        switch selectedType {
        case .timetable:
            timetableSlots = AcademicDocumentParser.parseTimetableSlots(from: extractedText)
            if timetableSlots.isEmpty {
                timetableSubjects = AcademicDocumentParser.parseTimetableSubjects(from: extractedText)
            } else {
                timetableSubjects = Array(Set(timetableSlots.map(\.subjectName))).sorted()
            }
        case .marksheet:
            marksheetEntries = AcademicDocumentParser.parseMarksheet(from: extractedText)
        case .cho:
            choEntries = AcademicDocumentParser.parseCHO(from: extractedText)
        case .unknown:
            break
        }
    }

    func applyParsedData(to coursesViewModel: CoursesViewModel) {
        switch selectedType {
        case .timetable:
            applyTimetable(to: coursesViewModel)
        case .marksheet:
            applyMarksheet(to: coursesViewModel)
        case .cho:
            applyCHO(to: coursesViewModel)
        case .unknown:
            break
        }
    }

    private func applyTimetable(to coursesViewModel: CoursesViewModel) {
        let existing = Set(coursesViewModel.subjects.map { $0.name.lowercased() })
        for name in timetableSubjects where !existing.contains(name.lowercased()) {
            coursesViewModel.addSubject(
                name: name,
                shortName: name,
                credits: 3,
                minimumRequired: 75,
                departmentRuleSet: .standard
            )
        }
    }

    private func applyMarksheet(to coursesViewModel: CoursesViewModel) {
        for entry in marksheetEntries {
            guard let subject = bestMatchSubject(named: entry.subjectName, in: coursesViewModel.subjects) else { continue }
            coursesViewModel.updateCHOConfiguration(
                for: subject.id,
                credits: subject.credits,
                internalMaxMarks: max(subject.internalMaxMarks, entry.total),
                endSemMaxMarks: subject.endSemMaxMarks,
                choPassingMarks: subject.choPassingMarks
            )
            coursesViewModel.updateInternalMarks(for: subject.id, value: entry.obtained)
        }
    }

    private func applyCHO(to coursesViewModel: CoursesViewModel) {
        for entry in choEntries {
            guard let subject = bestMatchSubject(named: entry.subjectName, in: coursesViewModel.subjects) else { continue }
            coursesViewModel.updateCHOConfiguration(
                for: subject.id,
                credits: entry.credits ?? subject.credits,
                internalMaxMarks: subject.internalMaxMarks,
                endSemMaxMarks: subject.endSemMaxMarks,
                choPassingMarks: entry.passingMarks ?? subject.choPassingMarks
            )
        }
    }

    private func bestMatchSubject(named rawName: String, in subjects: [Subject]) -> Subject? {
        let key = rawName.lowercased()
        return subjects.first(where: { key.contains($0.name.lowercased()) || $0.name.lowercased().contains(key) || key.contains($0.shortName.lowercased()) })
    }

    private func weekdayOrder(_ day: Weekday) -> Int {
        switch day {
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        case .sunday: return 7
        }
    }

    private func minutesFromTimeText(_ text: String) -> Int {
        let lower = text.lowercased().replacingOccurrences(of: ".", with: ":")
        let pattern = #"(\d{1,2})\s*:\s*(\d{2})\s*(am|pm)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return Int.max }
        let ns = lower as NSString
        guard let match = regex.firstMatch(in: lower, range: NSRange(location: 0, length: ns.length)), match.numberOfRanges >= 3 else {
            return Int.max
        }

        let hourRaw = Int(ns.substring(with: match.range(at: 1))) ?? 0
        let minute = Int(ns.substring(with: match.range(at: 2))) ?? 0
        let meridiem = match.numberOfRanges > 3 && match.range(at: 3).location != NSNotFound
            ? ns.substring(with: match.range(at: 3))
            : ""

        var hour = hourRaw
        if meridiem == "pm", hour < 12 { hour += 12 }
        if meridiem == "am", hour == 12 { hour = 0 }
        return (hour * 60) + minute
    }
}
