//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var viewModel: CoursesViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                StatCardView(
                    title: "Overall Attendance",
                    value: "\(Int(viewModel.overallAttendance * 100))%",
                    systemImage: "checkmark.circle.fill"
                ) {
                    ProgressRingView(progress: viewModel.overallAttendance)
                        .frame(width: 80, height: 80)
                }

                StatCardView(
                    title: "Predicted CGPA",
                    value: String(format: "%.2f", predictedCGPA),
                    systemImage: "chart.pie.fill"
                ) {
                    ProgressRingView(progress: predictedCGPA / 10)
                        .frame(width: 80, height: 80)
                }

                if !viewModel.riskSubjects.isEmpty {
                    AtRiskCoursesView(subjects: viewModel.riskSubjects)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .navigationTitle("Dashboard")
    }

    private var predictedCGPA: Double {
        let included = viewModel.subjects.filter { $0.includeInGPA }

        guard !included.isEmpty else { return 0 }

        let totalCredits = included.reduce(0) { $0 + $1.credits }
        let totalPoints = included.reduce(0) {
            $0 + ($1.inferredGrade.points * Double($1.credits))
        }

        guard totalCredits > 0 else { return 0 }

        return totalPoints / Double(totalCredits)
    }
}
