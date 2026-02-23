//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct ScheduleRowView: View {

    let item: ScheduleItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {

                Text(item.location)
                    .font(.headline)

                Text(item.day.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
