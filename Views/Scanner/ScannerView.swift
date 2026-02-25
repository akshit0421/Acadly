import SwiftUI
#if canImport(VisionKit)
@preconcurrency import VisionKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(Vision)
import Vision
#endif
#if canImport(UIKit)
import UIKit
#endif

struct ScannerView: View {
    @EnvironmentObject private var coursesViewModel: CoursesViewModel
    @StateObject private var scannerViewModel = DocumentScannerViewModel()

    @State private var showScanner = false
    @State private var showPreview = false
    @State private var scannerUnavailable = false
    @State private var scannerUnavailableMessage = "VisionKit is not available in this environment."
#if canImport(PhotosUI)
    @State private var selectedPhotoItem: PhotosPickerItem?
#endif
    private var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    if isRunningInPreview {
                        scannerUnavailableMessage = "Live scanner is unavailable in Xcode Preview. Use photo import in simulator/device."
                        scannerUnavailable = true
                        return
                    }
#if canImport(VisionKit)
                    if VNDocumentCameraViewController.isSupported {
                        showScanner = true
                    } else {
                        scannerUnavailableMessage = "Live document scanner is not supported on this device. Use photo import."
                        scannerUnavailable = true
                    }
#else
                    scannerUnavailable = true
#endif
                } label: {
                    Label("Scan Academic Document", systemImage: "doc.text.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(scannerViewModel.isProcessing)

#if canImport(PhotosUI)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Label("Import From Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppSecondaryButtonStyle())
                .disabled(scannerViewModel.isProcessing)
#endif

                if !scannerViewModel.extractedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Scan")
                            .font(.headline)
                        Text(scannerViewModel.detectedType.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text(scannerViewModel.extractedText)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(8)
                    }
                    .appCard()
                }
            }
            .padding(16)
        }
        .appScreenBackground()
        .navigationTitle("Scanner")
        .sheet(isPresented: $showScanner) {
#if canImport(VisionKit)
            DocumentCameraSheet { text in
                scannerViewModel.processExtractedText(text)
                showPreview = true
            }
#else
            EmptyView()
#endif
        }
        .sheet(isPresented: $showPreview) {
            ScannerPreviewSheet(viewModel: scannerViewModel) {
                scannerViewModel.applyParsedData(to: coursesViewModel)
                showPreview = false
            }
        }
#if canImport(PhotosUI)
        .onChange(of: selectedPhotoItem) { newValue in
            Task {
                await handleImportedPhoto(newValue)
            }
        }
#endif
        .alert("Scanner Unavailable", isPresented: $scannerUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(scannerUnavailableMessage)
        }
        .overlay {
            if scannerViewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    VStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.large)
                        Text(scannerViewModel.processingMessage)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

#if canImport(PhotosUI)
    private func handleImportedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        await MainActor.run {
            scannerViewModel.processingMessage = "Reading image..."
            scannerViewModel.isProcessing = true
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                await MainActor.run {
                    scannerViewModel.isProcessing = false
                }
                return
            }
            await MainActor.run {
                scannerViewModel.processingMessage = "Scanning timetable and classes..."
            }
            let text = await Task.detached(priority: .userInitiated) {
                OCRTextRecognizer.extractText(from: [image])
            }.value
            await MainActor.run {
                scannerViewModel.isProcessing = false
                if !text.isEmpty {
                    scannerViewModel.processExtractedText(text)
                    showPreview = true
                } else {
                    scannerUnavailableMessage = "No readable text found in the image."
                    scannerUnavailable = true
                }
            }
        } catch {
            await MainActor.run {
                scannerViewModel.isProcessing = false
                scannerUnavailableMessage = "Could not read selected image."
                scannerUnavailable = true
            }
        }
    }
#endif
}

struct ScannerPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DocumentScannerViewModel
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Document Type") {
                    Picker("Detected", selection: $viewModel.selectedType) {
                        ForEach(AcademicDocumentType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .onChange(of: viewModel.selectedType) { _ in
                        viewModel.refreshPreview()
                    }
                }

                Section("Preview") {
                    if viewModel.selectedType == .timetable {
                        if !viewModel.sortedTimetableSlots.isEmpty {
                            ForEach(orderedDays, id: \.self) { day in
                                let slots = slots(for: day)
                                if !slots.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(day.displayName)
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.textPrimary)

                                        ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                                            HStack(alignment: .top, spacing: 12) {
                                                PreviewTimelineIndicator(isLast: index == slots.count - 1)
                                                TimetableSlotPreviewCard(slot: slot)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        } else if viewModel.timetableSubjects.isEmpty {
                            Text("No timetable slots detected. Try a clearer timetable image.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.timetableSubjects, id: \.self) { subject in
                                TimetableFallbackCard(subject: subject)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            }
                        }
                    } else if viewModel.selectedType == .marksheet {
                        if viewModel.marksheetEntries.isEmpty {
                            Text("No marks detected.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.marksheetEntries) { entry in
                                HStack {
                                    Text(entry.subjectName)
                                    Spacer()
                                    Text("\(Int(entry.obtained))/\(Int(entry.total))")
                                }
                            }
                        }
                    } else if viewModel.selectedType == .cho {
                        if viewModel.choEntries.isEmpty {
                            Text("No CHO data detected.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.choEntries) { entry in
                                VStack(alignment: .leading) {
                                    Text(entry.subjectName)
                                    Text("Credits: \(entry.credits.map { String(format: "%.1f", $0) } ?? "-") • Passing: \(entry.passingMarks.map { String(Int($0)) } ?? "-")")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("Unknown document type. Select manually to proceed.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Review Scan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm & Save") {
                        onConfirm()
                    }
                }
            }
        }
    }

    private var orderedDays: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }

    private func slots(for day: Weekday) -> [TimetableSlot] {
        viewModel.sortedTimetableSlots.filter { $0.day == day }
    }
}

private struct TimetableSlotPreviewCard: View {
    let slot: TimetableSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.timeRangeText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)

            Text(slot.subjectName)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("At \(slot.startTimeText), you have \(slot.subjectName).")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card)
        )
    }
}

private struct TimetableFallbackCard: View {
    let subject: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Not Parsed")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)

            Text(subject)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Class detected, but time/day could not be read clearly from the image.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card)
        )
    }
}

private struct PreviewTimelineIndicator: View {
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 10, height: 10)

            if !isLast {
                Rectangle()
                    .fill(AppTheme.timeline)
                    .frame(width: 2, height: 88)
                    .padding(.top, 4)
            }
        }
        .frame(width: 14)
        .padding(.top, 12)
    }
}

#if canImport(VisionKit)
struct DocumentCameraSheet: UIViewControllerRepresentable {
    let onTextExtracted: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextExtracted: onTextExtracted)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onTextExtracted: (String) -> Void

        init(onTextExtracted: @escaping (String) -> Void) {
            self.onTextExtracted = onTextExtracted
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            let text = OCRTextRecognizer.extractText(from: images)
            onTextExtracted(text)
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }
    }
}
#endif

private enum OCRTextRecognizer {
    static func extractText(from images: [UIImage]) -> String {
        images
            .compactMap(recognizeText(from:))
            .joined(separator: "\n")
    }

    private static func recognizeText(from image: UIImage) -> String? {
#if canImport(Vision)
        guard let cgImage = image.cgImage else { return nil }

        var recognizedText: String?
        let request = VNRecognizeTextRequest { request, _ in
            recognizedText = (request.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
        }
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            return recognizedText
        } catch {
            return nil
        }
#else
        return nil
#endif
    }
}
