import SwiftUI

struct CourseRowView: View {
    let subject: Subject
    let onPresent: () -> Void
    let onAbsent: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(subject.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subject.shortName)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(subject.attendanceGuidance)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(riskLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(riskColor)
                Text("\(Int(subject.attendancePercentage.rounded()))%")
                    .font(.headline)
                    .foregroundStyle(riskColor)
                    .monospacedDigit()

                ProgressView(value: subject.attendancePercentage, total: 100)
                    .frame(width: 72)
                    .tint(riskColor)
            }
        }

            HStack(spacing: 12) {
                Button(action: onPresent) {
                    Label("Present", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryButtonStyle())

                Button(action: onAbsent) {
                    Label("Absent", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
        }
        .appCard()
    }

    private var riskColor: Color {
        switch subject.attendanceRisk {
        case .safe: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private var riskLabel: String {
        switch subject.attendanceRisk {
        case .safe: return "Safe"
        case .warning: return "Warning"
        case .critical: return "High Risk"
        }
    }
}
