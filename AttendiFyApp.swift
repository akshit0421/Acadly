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
    @AppStorage("attendify.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(coursesViewModel)
                .environmentObject(scheduleViewModel)
                .fullScreenCover(isPresented: onboardingPresentationBinding) {
                    OnboardingFlowView {
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(coursesViewModel)
                    .environmentObject(scheduleViewModel)
                }
        }
    }

    private var onboardingPresentationBinding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { isPresented in
                if !isPresented {
                    hasCompletedOnboarding = true
                }
            }
        )
    }
}
