import SwiftUI

struct CourseRowView: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(subject.name)
                    .font(.headline)

                Text(subject.shortName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(subject.attendanceGuidance)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(Int(subject.attendancePercentage.rounded()))%")
                    .font(.headline)
                    .foregroundStyle(riskColor)
                    .monospacedDigit()

                ProgressView(value: subject.attendancePercentage, total: 100)
                    .frame(width: 72)
                    .tint(riskColor)
            }
        }
        .padding(.vertical, 8)
    }

    private var riskColor: Color {
        switch subject.attendanceRisk {
        case .safe: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
