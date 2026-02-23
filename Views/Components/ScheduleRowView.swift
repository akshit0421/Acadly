//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct ScheduleRowView: View {
    @EnvironmentObject private var coursesViewModel: CoursesViewModel

    let item: ScheduleItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(timeRangeText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(item.lecture)
                .font(.headline)

            Text(subjectShortName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let building = item.building, !building.isEmpty {
                Label(building, systemImage: "building.2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var subjectShortName: String {
        coursesViewModel.subject(withID: item.subjectID)?.shortName ?? "Course"
    }

    private var timeRangeText: String {
        "\(item.startTime.formatted(date: .omitted, time: .shortened)) - \(item.endTime.formatted(date: .omitted, time: .shortened))"
    }
}
