//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

@main
struct AttendiFyApp: App {

    @StateObject private var coursesViewModel = CoursesViewModel()
    @StateObject private var scheduleViewModel = ScheduleViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(coursesViewModel)
                .environmentObject(scheduleViewModel)
        }
    }
}
