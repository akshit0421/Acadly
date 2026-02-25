import SwiftUI

struct CGPAView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    @State private var simulatedMarks: [UUID: Double] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.subjects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Add subjects to calculate CGPA")
                            .font(.headline)
                    }
                    .padding(.top, 60)
                } else {
                    Text("Set your baseline CGPA in Profile → Profile Setup")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    StatCardView(
                        title: "Current SGPA",
                        value: String(format: "%.2f", viewModel.currentSGPA),
                        systemImage: "chart.bar.fill"
                    ) {
                        Text("This semester's grade points")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    StatCardView(
                        title: "Projected SGPA",
                        value: String(format: "%.2f", viewModel.calculateProjectedCGPA(simulatedEndSemMarks: simulatedMarks)),
                        systemImage: "chart.line.uptrend.xyaxis"
                    ) {
                        Text("Based on your end-sem simulation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    StatCardView(
                        title: "Cumulative CGPA",
                        value: String(format: "%.2f", viewModel.cumulativeCGPA),
                        systemImage: "target"
                    ) {
                        Text(
                            (viewModel.cgpaDelta >= 0 ? "+" : "")
                            + String(format: "%.2f", viewModel.cgpaDelta)
                        )
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(viewModel.cgpaDelta >= 0 ? .green : .red)
                    }

                    ForEach(viewModel.subjects) { subject in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(subject.name)
                                .font(.headline)

                            let simulated = simulatedMarks[subject.id] ?? subject.requiredEndSemMarks
                            HStack {
                                Text("Simulated End-Sem")
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text("\(Int(simulated.rounded())) / \(Int(subject.endSemMaxMarks))")
                                    .fontWeight(.semibold)
                            }

                            Slider(
                                value: Binding(
                                    get: { simulated },
                                    set: { simulatedMarks[subject.id] = $0 }
                                ),
                                in: 0...max(1, subject.endSemMaxMarks)
                            )
                            .tint(AppTheme.accent)

                            Text("Grade Point: \(String(format: "%.1f", GradeLetter.fromPercentage(subject.projectedOverallPercentage(simulatedEndSem: simulated)).points)) • Credits: \(String(format: "%.1f", subject.credits))")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .appCard()
                    }
                }
            }
            .padding(16)
        }
        .appScreenBackground()
        .navigationTitle("CGPA")
    }
}
