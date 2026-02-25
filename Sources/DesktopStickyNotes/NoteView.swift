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
    @State private var showingStateMenu = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                topBar
                NoteTextEditor(text: Binding(
                    get: { vm.note.text },
                    set: { vm.setText($0) }
                ))
                .padding(10)
                .background(backgroundColor.opacity(0.18))
                .onTapGesture {
                    showingStateMenu = false
                }
            }

            if showingStateMenu {
                Color.clear
                    .contentShape(Rectangle())
                    .padding(.top, 36)
                    .onTapGesture {
                        showingStateMenu = false
                    }
                    .zIndex(10)

                stateMenu
                    .padding(.top, 36)
                    .padding(.leading, 34)
                    .zIndex(11)
            }
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
                        showingStateMenu = false
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
        .animation(.easeOut(duration: 0.15), value: showingStateMenu)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                showingStateMenu = false
                vm.setPinned(!vm.note.isPinned)
            } label: {
                Image(systemName: vm.note.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)

            Button {
                showingStateMenu.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(stateMenuLabel(vm.note.state))
                        .font(.system(size: 11.4, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(.black.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()

            Button(role: .destructive) {
                showingStateMenu = false
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

    private var stateMenu: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(NoteState.allCases) { state in
                Button {
                    vm.setState(state)
                    showingStateMenu = false
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(colorDot(for: state))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle().stroke(.white.opacity(0.55), lineWidth: 0.8)
                            )

                        Text(stateMenuLabel(state))
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(.black.opacity(0.8))

                        Spacer(minLength: 0)

                        if vm.note.state == state {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 188)
        .background(Color(nsColor: NSColor(calibratedWhite: 0.965, alpha: 0.98)))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
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

    private func colorDot(for state: NoteState) -> Color {
        switch state {
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
            return "Notes"
        case .todo:
            return "To Do"
        case .inProgress:
            return "In Progress"
        case .done:
            return "Done"
        }
    }
}

private struct NoteTextEditor: NSViewRepresentable {
    @Binding var text: String

    final class ShortcutTextView: NSTextView {
        override func keyDown(with event: NSEvent) {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasShortcutModifier = flags.contains(.command) || flags.contains(.control)
            if hasShortcutModifier && !flags.contains(.option) {
                // Use physical key codes so shortcuts work in any keyboard layout.
                switch event.keyCode {
                case 8: // C
                    copy(self)
                    return
                case 9: // V
                    paste(self)
                    return
                case 7: // X
                    cut(self)
                    return
                case 0: // A
                    selectAll(self)
                    return
                default:
                    break
                }
            }
            super.keyDown(with: event)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NoteTextEditor

        init(parent: NoteTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = ShortcutTextView(frame: .zero, textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [NSView.AutoresizingMask.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.string = text

        // Keep text clear of the overlay scrollbar.
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.textContainer?.lineFragmentPadding = 2

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
}
