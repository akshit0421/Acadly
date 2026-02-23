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

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(coursesViewModel)
        }
    }
}
