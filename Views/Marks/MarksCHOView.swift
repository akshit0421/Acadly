import SwiftUI

struct MarksCHOView: View {
    @EnvironmentObject private var viewModel: CoursesViewModel

    var body: some View {
        List {
            if viewModel.subjects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 52))
                        .foregroundStyle(.secondary)
                    Text("Add subjects to update CHO marks")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.subjects) { subject in
                    MarksCHOSubjectCard(subject: subject)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Marks & CHO")
    }
}

private struct MarksCHOSubjectCard: View {
    @EnvironmentObject private var viewModel: CoursesViewModel
    let subject: Subject

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(subject.name)
                    .font(.headline)
                Spacer()
                if subject.isCHORisk {
                    Label("At Risk", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

            Stepper(
                "Internal: \(Int(subject.internalMarksObtained))/\(Int(subject.internalMaxMarks))",
                onIncrement: { viewModel.updateInternalMarks(for: subject.id, value: subject.internalMarksObtained + 1) },
                onDecrement: { viewModel.updateInternalMarks(for: subject.id, value: subject.internalMarksObtained - 1) }
            )

            HStack {
                Text("Required End-Sem")
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(Int(subject.requiredEndSemMarks.rounded(.up))) / \(Int(subject.endSemMaxMarks))")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            ProgressView(value: subject.requiredEndSemMarks, total: max(1, subject.endSemMaxMarks))
                .tint(subject.isCHORisk ? .red : AppTheme.accent)

            Text("\(subject.shortName): You need \(Int(subject.requiredEndSemMarks.rounded(.up))) in End-Sem to pass CHO.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }
}
