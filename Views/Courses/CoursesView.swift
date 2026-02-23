//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct CoursesView: View {

    @EnvironmentObject var viewModel: CoursesViewModel
    @State private var showAddSheet = false

    var body: some View {
        List {
            ForEach($viewModel.subjects) { $subject in
                NavigationLink {
                    CourseDetailView(subject: $subject)
                } label: {
                    CourseRowView(subject: subject)
                }
            }
            .onDelete(perform: viewModel.delete)
        }
        .navigationTitle("Courses")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCourseView { newSubject in
                viewModel.addSubject(newSubject)
            }
        }
    }
}
