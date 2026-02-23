//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import SwiftUI

struct ProgressRingView: View {
    
    var progress: Double // 0...1
    
    private var clampedProgress: Double {
        min(1.0, max(0.0, progress))
    }
    
    var body: some View {
        ZStack {
            
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: clampedProgress)
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }
}
