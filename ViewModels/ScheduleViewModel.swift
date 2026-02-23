//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import Foundation
import SwiftUI

class ScheduleViewModel: ObservableObject {

    @Published var items: [ScheduleItem] = []

    init() {
        items = []
    }

    func addItem(_ item: ScheduleItem) {
        items.append(item)
    }

    func items(for day: Weekday) -> [ScheduleItem] {
        items.filter { $0.day == day }
    }
}
