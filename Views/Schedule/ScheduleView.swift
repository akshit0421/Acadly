//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct ScheduleView: View {
    
    @State private var viewModel = ScheduleViewModel()
    @State private var showAddSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                ForEach(Weekday.allCases, id: \.self) { day in
                    let dayItems = viewModel.items(for: day)
                    
                    if !dayItems.isEmpty {
                        WeekSectionView(
                            day: day,
                            items: dayItems
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .navigationTitle("Schedule")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddScheduleView { newItem in
                viewModel.addItem(newItem)
            }
        }
    }
}
