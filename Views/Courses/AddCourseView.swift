//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct AddCourseView: View {

    @Environment(\.presentationMode) private var presentationMode

    @State private var name = ""
    @State private var shortName = ""
    @State private var credits = 3

    var onSave: (Subject) -> Void

    var body: some View {
        NavigationStack {
            Form {

                Section("Course Info") {
                    TextField("Course Name", text: $name)
                    TextField("Short Name", text: $shortName)

                    Stepper("Credits: \(credits)", value: $credits, in: 1...10)
                }
            }
            .navigationTitle("New Course")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let subject = Subject(
                            name: name,
                            shortName: shortName.isEmpty ? name : shortName,
                            credits: credits
                        )

                        onSave(subject)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
