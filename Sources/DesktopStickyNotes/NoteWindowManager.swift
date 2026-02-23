import AppKit
import SwiftUI

@MainActor
final class NoteWindowManager: ObservableObject {
    private let store: NoteStore
    private var controllers: [UUID: NoteWindowController] = [:]
    private var isTerminating = false

    init(store: NoteStore) {
        self.store = store
    }

    func createNewNote() {
        let note = store.createNote()
        openWindow(for: note)
    }

    func restoreOpenNotesOnLaunch() {
        for note in store.activeNotes {
            openWindow(for: note)
        }
    }

    func reopenClosedNote(id: UUID) {
        guard let note = store.reopen(id: id) else { return }
        openWindow(for: note)
    }

    func reopenAllClosedNotes() {
        let ids = store.closedNotes.map(\.id)
        for id in ids {
            reopenClosedNote(id: id)
        }
    }

    func prepareForTermination() {
        isTerminating = true
    }

    private func openWindow(for note: NoteModel) {
        if let existing = controllers[note.id] {
            existing.showWindow(nil)
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NoteWindowController(note: note) { [weak self] event in
            self?.handle(event)
        }
        controllers[note.id] = controller
        controller.showWindow(nil)
    }

    private func handle(_ event: NoteWindowEvent) {
        switch event {
        case let .didChange(note):
            store.update(note)
        case let .didMoveOrResize(id, frame):
            store.updateFrame(id: id, frame: frame)
        case let .didClose(id, frame):
            store.updateFrame(id: id, frame: frame)
            if !isTerminating {
                store.markClosed(id: id)
            }
            controllers[id] = nil
        case let .didDelete(id):
            store.delete(id: id)
            controllers[id] = nil
        }
    }
}

private enum NoteWindowEvent {
    case didChange(NoteModel)
    case didMoveOrResize(UUID, CGRect)
    case didClose(UUID, CGRect)
    case didDelete(UUID)
}

@MainActor
private final class NoteWindowController: NSWindowController, NSWindowDelegate {
    private let viewModel: NoteEditorViewModel
    private let onEvent: (NoteWindowEvent) -> Void
    private var isDeleting = false

    init(note: NoteModel, onEvent: @escaping (NoteWindowEvent) -> Void) {
        self.viewModel = NoteEditorViewModel(note: note)
        self.onEvent = onEvent

        let window = NSWindow(
            contentRect: note.frame,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.minSize = CGSize(width: 220, height: 180)
        window.level = note.isPinned ? .floating : .normal
        window.delegate = self

        let view = NoteView(vm: viewModel)
        let hosting = NSHostingController(rootView: view)
        window.contentViewController = hosting

        wireCallbacks()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func prepareForDelete() {
        isDeleting = true
    }

    private func wireCallbacks() {
        viewModel.onChange = { [weak self] note in
            guard let self else { return }
            self.window?.level = note.isPinned ? .floating : .normal
            self.onEvent(.didChange(note))
        }
        viewModel.onDelete = { [weak self] in
            guard let self else { return }
            self.isDeleting = true
            self.onEvent(.didDelete(self.viewModel.note.id))
            self.close()
        }
    }

    func windowDidMove(_ notification: Notification) {
        guard let frame = window?.frame else { return }
        onEvent(.didMoveOrResize(viewModel.note.id, frame))
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        guard let frame = window?.frame else { return }
        onEvent(.didMoveOrResize(viewModel.note.id, frame))
    }

    func windowWillClose(_ notification: Notification) {
        guard !isDeleting else { return }
        guard let frame = window?.frame else { return }
        onEvent(.didClose(viewModel.note.id, frame))
    }
}
