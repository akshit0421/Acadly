import SwiftUI

struct AtRiskCoursesView: View {
    let subjects: [Subject]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("At Risk Courses", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.accent)

            ForEach(subjects) { subject in
                HStack {
                    Text(subject.name)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(Int(subject.attendancePercentage.rounded()))%")
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.accent)
                        .monospacedDigit()
                }
            }
        }
        .appCard()
    }
}
