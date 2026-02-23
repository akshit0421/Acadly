import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StatCardView(
                    title: "Overall Attendance",
                    value: "\(Int(viewModel.overallAttendance.rounded()))%",
                    systemImage: "checkmark.circle.fill"
                ) {
                    ProgressRingView(progress: viewModel.overallAttendance / 100.0)
                        .frame(width: 80, height: 80)
                }

                StatCardView(
                    title: "Predicted CGPA",
                    value: String(format: "%.2f", viewModel.predictedCGPA),
                    systemImage: "chart.pie.fill"
                ) {
                    ProgressRingView(progress: min(1.0, max(0.0, viewModel.predictedCGPA / 10.0)))
                        .frame(width: 80, height: 80)
                }

                if !viewModel.riskSubjects.isEmpty {
                    AtRiskCoursesView(subjects: viewModel.riskSubjects)
                }
            }
            .padding(16)
        }
        .navigationTitle("Dashboard")
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
