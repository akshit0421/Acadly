//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct AddScheduleView: View {

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var coursesViewModel: CoursesViewModel

    @State private var selectedSubjectID: UUID?
    @State private var selectedDay: Weekday = .monday
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var location = ""

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
                    Picker("Day", selection: $selectedDay) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.rawValue.capitalized)
                        }
                    }

                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)

                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("New Class")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {

                        guard let subjectID = selectedSubjectID else { return }

                        let item = ScheduleItem(
                            id: UUID(),
                            subjectID: subjectID,
                            day: selectedDay,
                            startTime: startTime,
                            endTime: endTime,
                            location: location
                        )

                        onSave(item)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedSubjectID == nil)
                }
            }
        }
    }
}
