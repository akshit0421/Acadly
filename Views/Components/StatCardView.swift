//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct StatCardView<Content: View>: View {
    
    let title: String
    let value: String
    let systemImage: String
    let content: Content
    
    init(
        title: String,
        value: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        HStack {
            
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.largeTitle.bold())
            }
            
            Spacer()
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
