//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct RootTabView: View {

    var body: some View {
        TabView {

            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
            }

            NavigationStack {
                CoursesView()
            }
            .tabItem {
                Label("Courses", systemImage: "book.fill")
            }

            NavigationStack {
                ScheduleView()
            }
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }
        }
    }
}
