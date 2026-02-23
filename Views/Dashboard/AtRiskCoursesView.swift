//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct AtRiskCoursesView: View {

    let subjects: [Subject]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Label("At Risk Courses", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)

            ForEach(subjects) { subject in
                HStack {
                    Text(subject.name)
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(subject.attendancePercentage * 100))%")
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
