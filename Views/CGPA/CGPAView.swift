import SwiftUI

struct CGPAView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    @State private var simulatedMarks: [UUID: Double] = [:]
    @State private var targetCGPAInput = ""
    @State private var previousCGPAInput = ""
    @State private var previousCreditsInput = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.subjects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 52))
                            .foregroundStyle(.secondary)
                        Text("Add subjects to calculate CGPA")
                            .font(.headline)
                    }
                    .padding(.top, 60)
                } else {
                    plannerInputsCard

                    StatCardView(
                        title: "Current SGPA",
                        value: String(format: "%.2f", viewModel.currentSGPA),
                        systemImage: "chart.bar.fill"
                    ) {
                        EmptyView()
                    }

                    StatCardView(
                        title: "Projected SGPA",
                        value: String(format: "%.2f", viewModel.calculateProjectedCGPA(simulatedEndSemMarks: simulatedMarks)),
                        systemImage: "chart.line.uptrend.xyaxis"
                    ) {
                        EmptyView()
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
        .onAppear {
            targetCGPAInput = String(format: "%.2f", viewModel.targetCGPA)
            previousCGPAInput = String(format: "%.2f", viewModel.previousCGPA)
            previousCreditsInput = String(format: "%.0f", viewModel.previousCredits)
        }
    }

    private var plannerInputsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("CGPA Impact Simulation", systemImage: "function")
                .font(.headline)

            HStack {
                Text("Target")
                Spacer()
                TextField("8.50", text: $targetCGPAInput)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 90)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.updateTargetCGPA(Double(targetCGPAInput) ?? viewModel.targetCGPA)
                    }
            }

            HStack {
                Text("Previous CGPA")
                Spacer()
                TextField("0", text: $previousCGPAInput)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 90)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Previous Credits")
                Spacer()
                TextField("0", text: $previousCreditsInput)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 90)
                    .textFieldStyle(.roundedBorder)
            }

            Button("Apply Simulation Base") {
                viewModel.updateTargetCGPA(Double(targetCGPAInput) ?? viewModel.targetCGPA)
                viewModel.updatePastAcademics(
                    previousCGPA: Double(previousCGPAInput) ?? viewModel.previousCGPA,
                    previousCredits: Double(previousCreditsInput) ?? viewModel.previousCredits
                )
            }
            .buttonStyle(AppSecondaryButtonStyle())
        }
        .appCard()
    }
}
