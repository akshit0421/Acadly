import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                cgpaPieCard
                riskDistributionCard
                fullAttendanceCard
                subjectComparisonCard
            }
            .padding(16)
        }
        .appScreenBackground()
        .navigationTitle("Analytics")
    }

    private var cgpaPieCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("CGPA Composition", systemImage: "chart.pie")
                .font(.headline)

            HStack {
                ZStack {
                    Circle()
                        .stroke(AppTheme.track, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: min(1, max(0, viewModel.cumulativeCGPA / 10.0)))
                        .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: min(1, max(0, viewModel.cumulativeCGPA / 10.0)), to: min(1, max(0, viewModel.targetCGPA / 10.0)))
                        .stroke(Color.green.opacity(0.75), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%.2f", viewModel.cumulativeCGPA))
                        .font(.title3.weight(.bold).monospacedDigit())
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Target: \(String(format: "%.2f", viewModel.targetCGPA))")
                        .font(.subheadline.weight(.semibold))
                    Text("Delta: \((viewModel.cgpaDelta >= 0 ? "+" : "") + String(format: "%.2f", viewModel.cgpaDelta))")
                        .font(.footnote)
                        .foregroundStyle(viewModel.cgpaDelta >= 0 ? .green : .red)
                }
                Spacer()
            }
        }
        .appCard()
    }

    private var riskDistributionCard: some View {
        let critical = viewModel.subjects.filter { $0.attendanceRisk == .critical }.count
        let warning = viewModel.subjects.filter { $0.attendanceRisk == .warning }.count
        let safe = viewModel.subjects.filter { $0.attendanceRisk == .safe }.count

        return VStack(alignment: .leading, spacing: 10) {
            Label("Risk Distribution", systemImage: "exclamationmark.shield")
                .font(.headline)

            riskRow(title: "Safe", count: safe, color: .green)
            riskRow(title: "Warning", count: warning, color: .yellow)
            riskRow(title: "Critical", count: critical, color: .red)
        }
        .appCard()
    }

    private var fullAttendanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Full Attendance", systemImage: "chart.bar.xaxis")
                .font(.headline)

            if viewModel.subjects.isEmpty {
                Text("No subjects yet.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(viewModel.subjects.map(SubjectAttendance.from).sorted { $0.percentage < $1.percentage }) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.shortName)
                            Spacer()
                            Text("\(Int(entry.percentage.rounded()))%")
                                .monospacedDigit()
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppTheme.track)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(barColor(for: entry.percentage))
                                    .frame(width: geo.size.width * min(1, max(0, entry.percentage / 100.0)))
                            }
                        }
                        .frame(height: 10)
                    }
                }
            }
        }
        .appCard()
    }

    private var subjectComparisonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Subject Comparison", systemImage: "list.number")
                .font(.headline)

            ForEach(viewModel.subjects.sorted { $0.inferredGrade.points > $1.inferredGrade.points }) { subject in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject.shortName)
                            .font(.subheadline.weight(.semibold))
                        Text("Attendance \(Int(subject.attendancePercentage.rounded()))%")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Text("GP \(String(format: "%.1f", subject.inferredGrade.points))")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                }
                .padding(.vertical, 4)
            }
        }
        .appCard()
    }

    private func riskRow(title: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
            Spacer()
            Text("\(count)")
                .monospacedDigit()
                .fontWeight(.semibold)
        }
    }

    private func barColor(for percentage: Double) -> Color {
        if percentage > 75 { return .green }
        if percentage >= 60 { return .yellow }
        return .red
    }
}
