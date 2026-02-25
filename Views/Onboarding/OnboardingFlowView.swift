import SwiftUI

struct OnboardingFlowView: View {
    private struct SubjectDraft: Identifiable {
        let id = UUID()
        var name: String
        var credits: Int
    }

    private enum Step: Int, CaseIterable {
        case subjects
        case goal
    }

    @EnvironmentObject private var coursesViewModel: CoursesViewModel

    let onComplete: () -> Void

    @State private var step: Step = .subjects
    @State private var drafts: [SubjectDraft] = []
    @State private var nameInput = ""
    @State private var creditsInput = 3
    @State private var attendanceGoal = 75.0

    var body: some View {
        TabView(selection: $step) {
            addSubjectsStep
                .tag(Step.subjects)

            attendanceGoalStep
                .tag(Step.goal)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .gesture(DragGesture(), including: .gesture)
        .safeAreaInset(edge: .bottom) {
            bottomActions
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
        }
        .appScreenBackground()
        .interactiveDismissDisabled(true)
    }

    private var addSubjectsStep: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Add your subjects to start attendance tracking.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Your Subjects") {
                    TextField("Subject name", text: $nameInput)
                        .submitLabel(.done)

                    Stepper("Credit hours: \(creditsInput)", value: $creditsInput, in: 1...8)

                    Button {
                        addDraftSubject()
                    } label: {
                        Label("Add Subject", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .highTapTarget()
                    .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !drafts.isEmpty {
                    Section("Added") {
                        ForEach(drafts) { draft in
                            HStack {
                                Text(draft.name)
                                Spacer()
                                Text("\(draft.credits) credits")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add your subjects")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var attendanceGoalStep: some View {
        NavigationStack {
            Form {
                Section("Attendance Goal") {
                    Slider(value: $attendanceGoal, in: 60...95, step: 1)

                    Text("I need to attend at least \(classesOutOfFour) of every 4 classes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Set your attendance goal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 12) {
            Button(step == .goal ? "Finish" : "Continue") {
                continueAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(step == .subjects && drafts.isEmpty)

            if step != .subjects {
                Button("Skip for now") {
                    skipAction()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .highTapTarget()
            }
        }
    }

    private var classesOutOfFour: Int {
        min(4, max(1, Int((attendanceGoal / 100.0 * 4.0).rounded())))
    }

    private func addDraftSubject() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        drafts.append(SubjectDraft(name: trimmed, credits: max(1, creditsInput)))
        nameInput = ""
        creditsInput = 3
    }

    private func continueAction() {
        switch step {
        case .subjects:
            guard !drafts.isEmpty else { return }
            step = .goal
        case .goal:
            finishOnboarding()
        }
    }

    private func skipAction() {
        if step == .goal {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        for draft in drafts {
            let shortName = acronym(for: draft.name)
            _ = coursesViewModel.addSubject(
                name: draft.name,
                shortName: shortName,
                credits: Double(draft.credits),
                minimumRequired: attendanceGoal,
                departmentRuleSet: coursesViewModel.selectedDepartment
            )
        }

        onComplete()
    }

    private func acronym(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count > 1 {
            let code = words.compactMap(\.first).prefix(6)
            return String(code).uppercased()
        }
        return String(name.prefix(6)).uppercased()
    }
}
