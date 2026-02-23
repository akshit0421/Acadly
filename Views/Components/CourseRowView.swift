//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct CourseRowView: View {

    let subject: Subject

    var body: some View {
        HStack {

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.name)
                    .font(.headline)

                Text(subject.shortName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(Int(subject.attendancePercentage * 100))%")
                    .font(.headline)

                ProgressView(value: subject.attendancePercentage)
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 6)
    }
}
