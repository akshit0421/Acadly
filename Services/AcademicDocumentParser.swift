import Foundation

enum AcademicDocumentType: String, CaseIterable, Identifiable {
    case timetable
    case marksheet
    case cho
    case unknown

    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

struct MarksheetEntry: Identifiable {
    let id = UUID()
    let subjectName: String
    let obtained: Double
    let total: Double
}

struct CHOEntry: Identifiable {
    let id = UUID()
    let subjectName: String
    let credits: Double?
    let passingMarks: Double?
}

struct TimetableSlot: Identifiable, Hashable {
    let id = UUID()
    let day: Weekday
    let startTimeText: String
    let endTimeText: String
    let subjectName: String

    var timeRangeText: String {
        "\(startTimeText) - \(endTimeText)"
    }
}

enum AcademicDocumentParser {
    static func classify(_ text: String) -> AcademicDocumentType {
        let lower = text.lowercased()

        // Strong timetable signal: explicit parsed slots.
        if !parseTimetableSlots(from: text).isEmpty {
            return .timetable
        }

        let hasMarksPattern = lower.range(of: #"\b\d{1,3}\s*/\s*\d{1,3}\b"#, options: .regularExpression) != nil
        if hasMarksPattern && (lower.contains("marks") || lower.contains("total")) { return .marksheet }

        if lower.contains("credit") || lower.contains("passing marks") || lower.contains("cho") || lower.contains("weightage") {
            return .cho
        }

        let dayHitCount = countMatches(
            lower,
            pattern: #"\b(mon(day)?|tue(s|sday)?|wed(nesday)?|thu(r|rs|rsday)?|fri(day)?|sat(urday)?|sun(day)?)\b"#
        )
        let timeHitCount = countMatches(
            lower,
            pattern: #"\b\d{1,2}\s*(?:[:.]\s*\d{2})?\s*(am|pm)\b|\b\d{1,2}\s*[:.]\s*\d{2}\b"#
        )
        let rangeHitCount = countMatches(
            lower,
            pattern: #"\b\d{1,2}\s*(?:[:.]\s*\d{2})?\s*(?:am|pm)?\s*(?:-|–|to)\s*\d{1,2}\s*(?:[:.]\s*\d{2})?\s*(?:am|pm)?\b"#
        )
        let timetableKeywordHits = ["lecture", "class", "period", "room", "lab", "schedule", "timetable"]
            .filter { lower.contains($0) }
            .count

        // OCR can be noisy; use a score instead of a hard condition.
        let timetableScore = (dayHitCount * 2) + min(timeHitCount, 4) + (rangeHitCount * 2) + timetableKeywordHits
        if timetableScore >= 5 {
            return .timetable
        }

        return .unknown
    }

    static func parseTimetableSubjects(from text: String) -> [String] {
        let slots = parseTimetableSlots(from: text)
        if !slots.isEmpty {
            return Array(Set(slots.map(\.subjectName))).sorted()
        }

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let blocked = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "room", "lab", "am", "pm"]

        var results: [String] = []
        for line in lines {
            let lower = line.lowercased()
            if blocked.contains(where: { lower.contains($0) }) { continue }
            if lower.range(of: #"\d"#, options: .regularExpression) != nil { continue }
            if line.count < 4 { continue }
            results.append(line)
        }

        return Array(Set(results)).sorted()
    }

    static func parseTimetableSlots(from text: String) -> [TimetableSlot] {
        let rawLines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var slots: [TimetableSlot] = []
        var currentDay: Weekday?

        for (index, line) in rawLines.enumerated() {
            if let dayOnly = parseDayOnly(line) {
                currentDay = dayOnly
                continue
            }

            let dayInLine = parseDay(in: line)
            if let dayInLine {
                currentDay = dayInLine
            }

            guard let (startTime, endTime) = parseTimeRange(in: line) else { continue }
            let day = dayInLine ?? currentDay ?? .monday

            var subject = subjectFromTimetableLine(line)
            if subject.isEmpty, index + 1 < rawLines.count {
                let next = rawLines[index + 1]
                if parseTimeRange(in: next) == nil, parseDayOnly(next) == nil, parseDay(in: next) == nil {
                    subject = subjectFromTimetableLine(next)
                }
            }

            guard !subject.isEmpty else { continue }

            slots.append(
                TimetableSlot(
                    day: day,
                    startTimeText: normalizedTimeText(startTime),
                    endTimeText: normalizedTimeText(endTime),
                    subjectName: subject
                )
            )
        }

        var seen: Set<String> = []
        return slots.filter { slot in
            let key = "\(slot.day.rawValue)|\(slot.startTimeText)|\(slot.endTimeText)|\(slot.subjectName.lowercased())"
            return seen.insert(key).inserted
        }
    }

    static func parseMarksheet(from text: String) -> [MarksheetEntry] {
        let pattern = #"([A-Za-z][A-Za-z\s&-]{2,})\s+(\d{1,3})\s*/\s*(\d{1,3})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))

        return matches.compactMap { match in
            guard match.numberOfRanges == 4 else { return nil }
            let name = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            let obtained = Double(ns.substring(with: match.range(at: 2))) ?? 0
            let total = Double(ns.substring(with: match.range(at: 3))) ?? 0
            return MarksheetEntry(subjectName: name, obtained: obtained, total: total)
        }
    }

    static func parseCHO(from text: String) -> [CHOEntry] {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var entries: [CHOEntry] = []

        for line in lines where !line.isEmpty {
            let lower = line.lowercased()
            guard lower.contains("credit") || lower.contains("passing") || lower.contains("cho") else { continue }

            let subject = line.components(separatedBy: ":").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let credits = firstDouble(in: line, matching: #"credit[s]?\s*[:=]?\s*(\d+(?:\.\d+)?)"#)
            let passing = firstDouble(in: line, matching: #"passing\s*marks?\s*[:=]?\s*(\d+(?:\.\d+)?)"#)

            if !subject.isEmpty {
                entries.append(CHOEntry(subjectName: subject, credits: credits, passingMarks: passing))
            }
        }

        return entries
    }

    private static func firstDouble(in text: String, matching pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)), match.numberOfRanges > 1 else {
            return nil
        }
        return Double(ns.substring(with: match.range(at: 1)))
    }

    private static func parseDayOnly(_ line: String) -> Weekday? {
        let lettersOnly = line
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .joined()
        switch lettersOnly {
        case "monday", "mon": return .monday
        case "tuesday", "tue", "tues": return .tuesday
        case "wednesday", "wed": return .wednesday
        case "thursday", "thu", "thurs": return .thursday
        case "friday", "fri": return .friday
        case "saturday", "sat": return .saturday
        case "sunday", "sun": return .sunday
        default: return nil
        }
    }

    private static func parseDay(in line: String) -> Weekday? {
        let lower = line.lowercased().replacingOccurrences(of: ".", with: " ")
        if lower.range(of: #"\bmon(day)?\b"#, options: .regularExpression) != nil { return .monday }
        if lower.range(of: #"\btue(s|sday)?\b"#, options: .regularExpression) != nil { return .tuesday }
        if lower.range(of: #"\bwed(nesday)?\b"#, options: .regularExpression) != nil { return .wednesday }
        if lower.range(of: #"\bthu(r|rs|rsday)?\b"#, options: .regularExpression) != nil { return .thursday }
        if lower.range(of: #"\bfri(day)?\b"#, options: .regularExpression) != nil { return .friday }
        if lower.range(of: #"\bsat(urday)?\b"#, options: .regularExpression) != nil { return .saturday }
        if lower.range(of: #"\bsun(day)?\b"#, options: .regularExpression) != nil { return .sunday }
        return nil
    }

    private static func parseTimeRange(in line: String) -> (String, String)? {
        let pattern = #"\b(\d{1,2}\s*(?:[:.]\s*\d{2})?\s*(?:am|pm)?)\s*(?:-|–|to|\s{2,})\s*(\d{1,2}\s*(?:[:.]\s*\d{2})?\s*(?:am|pm)?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)), match.numberOfRanges == 3 else {
            return nil
        }
        let start = ns.substring(with: match.range(at: 1))
        let end = ns.substring(with: match.range(at: 2))
        return (start, end)
    }

    private static func subjectFromTimetableLine(_ line: String) -> String {
        var subject = line

        let dayPattern = #"\b(mon(day)?|tue(sday)?|wed(nesday)?|thu(rsday)?|fri(day)?|sat(urday)?|sun(day)?)\b"#
        if let dayRegex = try? NSRegularExpression(pattern: dayPattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: (subject as NSString).length)
            subject = dayRegex.stringByReplacingMatches(in: subject, options: [], range: range, withTemplate: "")
        }

        let timePattern = #"\b\d{1,2}[:.]\d{2}\s?(?:am|pm)?\b"#
        if let timeRegex = try? NSRegularExpression(pattern: timePattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: (subject as NSString).length)
            subject = timeRegex.stringByReplacingMatches(in: subject, options: [], range: range, withTemplate: "")
        }

        subject = subject
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "–", with: " ")
            .replacingOccurrences(of: "to", with: " ", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return subject
    }

    private static func normalizedTimeText(_ value: String) -> String {
        value
            .replacingOccurrences(of: ".", with: ":")
            .replacingOccurrences(of: " :", with: ":")
            .replacingOccurrences(of: ": ", with: ":")
            .replacingOccurrences(of: "  ", with: " ")
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func countMatches(_ text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return 0 }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).count
    }
}
