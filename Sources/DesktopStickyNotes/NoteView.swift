import AppKit
import SwiftUI

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published var note: NoteModel

    var onChange: ((NoteModel) -> Void)?
    var onDelete: (() -> Void)?

    init(note: NoteModel) {
        self.note = note
    }

    func setText(_ text: String) {
        note.text = text
        onChange?(note)
    }

    func setState(_ state: NoteState) {
        note.state = state
        onChange?(note)
    }

    func setPinned(_ pinned: Bool) {
        note.isPinned = pinned
        onChange?(note)
    }
}

struct NoteView: View {
    @ObservedObject var vm: NoteEditorViewModel
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            TextEditor(text: Binding(
                get: { vm.note.text },
                set: { vm.setText($0) }
            ))
            .font(.system(size: 14))
            .padding(10)
            .scrollContentBackground(.hidden)
            .background(backgroundColor.opacity(0.18))
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black.opacity(0.05), lineWidth: 1)
        )
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(vm.note.text, forType: .string)
            }
            Menu("Change State") {
                ForEach(NoteState.allCases) { state in
                    Button(stateMenuLabel(state)) {
                        vm.setState(state)
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .alert("Delete this note permanently?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                vm.onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                vm.setPinned(!vm.note.isPinned)
            } label: {
                Image(systemName: vm.note.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(NoteState.allCases) { state in
                    Button(stateMenuLabel(state)) {
                        vm.setState(state)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(stateIndicatorColor)
                        .frame(width: 8, height: 8)
                    Text(stateMenuLabel(vm.note.state))
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.black.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Spacer()

            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.03))
    }

    private var backgroundColor: Color {
        switch vm.note.state {
        case .normal:
            return Color(nsColor: NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        case .todo:
            return Color(nsColor: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.80, alpha: 1.0))
        case .inProgress:
            return Color(nsColor: NSColor(calibratedRed: 0.88, green: 0.97, blue: 0.86, alpha: 1.0))
        case .done:
            return Color(nsColor: NSColor(calibratedRed: 0.86, green: 0.92, blue: 1.0, alpha: 1.0))
        }
    }

    private var stateIndicatorColor: Color {
        switch vm.note.state {
        case .normal:
            return .gray
        case .todo:
            return .yellow
        case .inProgress:
            return .green
        case .done:
            return .blue
        }
    }

    private func stateMenuLabel(_ state: NoteState) -> String {
        switch state {
        case .normal:
            return "Note"
        case .todo:
            return "To Do"
        case .inProgress:
            return "In Progress"
        case .done:
            return "Done"
        }
    }
}
