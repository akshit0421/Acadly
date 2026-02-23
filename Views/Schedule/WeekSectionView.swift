//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct WeekSectionView: View {

    let day: Weekday
    let items: [ScheduleItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(day.displayName)
                .font(.title3.weight(.semibold))

            ForEach(items.sorted { $0.startTime < $1.startTime }) { item in
                ScheduleRowView(item: item)
            }
        }
    }
}
