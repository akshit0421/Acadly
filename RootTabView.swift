//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct RootTabView: View {
    private enum Tab: Hashable {
        case dashboard
        case subjects
        case cgpa
        case analytics
        case profile
    }

    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                DashboardView()
            }
            .tag(Tab.dashboard)
            .tabItem {
                Label("Dashboard", systemImage: selectedTab == .dashboard ? "house.fill" : "house")
            }

            NavigationStack {
                CoursesView()
            }
            .tag(Tab.subjects)
            .tabItem {
                Label("Subjects", systemImage: selectedTab == .subjects ? "books.vertical.fill" : "books.vertical")
            }

            NavigationStack {
                CGPAView()
            }
            .tag(Tab.cgpa)
            .tabItem {
                Label("CGPA", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                AnalyticsView()
            }
            .tag(Tab.analytics)
            .tabItem {
                Label("Analytics", systemImage: "chart.bar")
            }

            NavigationStack {
                ProfileSetupView()
            }
            .tag(Tab.profile)
            .tabItem {
                Label("Profile", systemImage: selectedTab == .profile ? "person.crop.circle.fill" : "person.crop.circle")
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
