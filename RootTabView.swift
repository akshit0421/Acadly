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
                Label("Dashboard", systemImage: "house.fill")
            }

            NavigationStack {
                CoursesView()
            }
            .tabItem {
                Label("Subjects", systemImage: "book.fill")
            }

            NavigationStack {
                AcademicPlannerView()
            }
            .tabItem {
                Label("Planner", systemImage: "target")
            }

            NavigationStack {
                ProfileSetupView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
        .tint(AppTheme.accent)
        .appScreenBackground()
    }
}

#Preview {
    RootTabView()
        .environmentObject(CoursesViewModel())
        .environmentObject(ScheduleViewModel())
}
