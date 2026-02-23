//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct AddScheduleView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coursesViewModel: CoursesViewModel

    @State private var selectedSubjectID: UUID?
    @State private var selectedDays: Set<Weekday> = [.monday]
    @State private var isDayPickerExpanded = false
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var lecture = ""
    @State private var building = ""

    var onSave: (ScheduleItem) -> Void

    var body: some View {
        NavigationStack {
            Form {

                Section("Subject") {
                    Picker("Course", selection: $selectedSubjectID) {
                        ForEach(coursesViewModel.subjects) { subject in
                            Text(subject.name)
                                .tag(Optional(subject.id))
                        }
                    }
                }

                Section("Schedule") {
                    DisclosureGroup(isExpanded: $isDayPickerExpanded) {
                        ForEach(Array(Weekday.allCases.enumerated()), id: \.offset) { _, day in
                            Button {
                                toggleDay(day)
                            } label: {
                            HStack {
                                    Text(day.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedDays.contains(day) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Repeat on Days")
                            Text(selectedDaysSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        .padding(.vertical, 2)
                    }

                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)

                    TextField("Lecture", text: $lecture)
                    TextField("Building (Optional)", text: $building)
                }
            }
            .navigationTitle("New Class")
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {

                        guard let subjectID = selectedSubjectID else { return }
                        guard !selectedDays.isEmpty else { return }

                        for day in Weekday.allCases where selectedDays.contains(day) {
                            let item = ScheduleItem(
                                id: UUID(),
                                subjectID: subjectID,
                                day: day,
                                startTime: startTime,
                                endTime: endTime,
                                lecture: lecture,
                                building: building
                            )

                            onSave(item)
                        }
                        dismiss()
                    }
                    .disabled(
                        selectedSubjectID == nil ||
                        selectedDays.isEmpty ||
                        lecture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }

    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    private var selectedDaysSummary: String {
        let selected = Weekday.allCases.filter { selectedDays.contains($0) }
        guard !selected.isEmpty else { return "None" }
        return selected.map { $0.shortName }.joined(separator: ", ")
    }
}
