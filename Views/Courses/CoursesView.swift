import SwiftUI

struct CoursesView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    @State private var showAddSheet = false

    var body: some View {
        List {
            ForEach(viewModel.subjects) { subject in
                NavigationLink {
                    CourseDetailView(subjectID: subject.id)
                } label: {
                    CourseRowView(subject: subject)
                }
            }
            .onDelete(perform: viewModel.delete)
        }
        .navigationTitle("Courses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Course", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCourseView()
        }
        .alert("Storage Issue", isPresented: isShowingPersistenceError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.persistenceErrorMessage ?? "An unknown error occurred.")
        }
    }

    private var isShowingPersistenceError: Binding<Bool> {
        Binding(
            get: { viewModel.persistenceErrorMessage != nil },
            set: { shouldShow in
                if !shouldShow {
                    viewModel.clearPersistenceError()
                }
            }
        )
    }
}
