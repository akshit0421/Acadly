//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct CourseDetailView: View {

    @Binding var subject: Subject

    var body: some View {
        Form {

            Section("Attendance") {

                HStack {
                    Text("Present")
                    Spacer()
                    Stepper(value: $subject.manualPresent, in: 0...subject.manualTotal) {
                        Text("\(subject.manualPresent)")
                    }
                }

                HStack {
                    Text("Total Classes")
                    Spacer()
                    Stepper(value: $subject.manualTotal, in: 0...500) {
                        Text("\(subject.manualTotal)")
                    }
                }

                HStack {
                    Text("Attendance")
                    Spacer()
                    Text("\(Int(subject.attendancePercentage * 100))%")
                        .foregroundStyle(color(for: subject.attendanceRisk))
                }
            }

            Section("Assessment") {

                if let percentage = subject.scoredPercentage {
                    HStack {
                        Text("Score")
                        Spacer()
                        Text(String(format: "%.1f%%", percentage))
                    }
                }

                HStack {
                    Text("Inferred Grade")
                    Spacer()
                    Text(subject.inferredGrade.rawValue)
                }
            }
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func color(for risk: AttendanceRisk) -> Color {
        switch risk {
        case .safe: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
