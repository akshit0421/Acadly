import SwiftUI

struct AtRiskCoursesView: View {
    let subjects: [Subject]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("At Risk Courses", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(subjects) { subject in
                HStack {
                    Text(subject.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(subject.attendancePercentage.rounded()))%")
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
