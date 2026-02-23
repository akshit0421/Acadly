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

            Text(day.rawValue.capitalized)
                .font(.title3.weight(.semibold))

            ForEach(items) { item in
                ScheduleRowView(item: item)
            }
        }
    }
}
