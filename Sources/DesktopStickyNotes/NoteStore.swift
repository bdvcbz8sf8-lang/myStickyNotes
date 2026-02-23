import AppKit
import Foundation

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [NoteModel] = []

    private let defaultsKey = "desktop_sticky_notes_v1"

    init() {
        load()
    }

    var activeNotes: [NoteModel] {
        notes.filter { !$0.isClosed }
    }

    var closedNotes: [NoteModel] {
        notes
            .filter { $0.isClosed }
            .sorted {
                ($0.closedAt ?? .distantPast) > ($1.closedAt ?? .distantPast)
            }
    }

    func note(with id: UUID) -> NoteModel? {
        notes.first(where: { $0.id == id })
    }

    @discardableResult
    func createNote() -> NoteModel {
        let note = NoteModel(
            id: UUID(),
            text: "",
            state: .normal,
            frame: defaultFrame(),
            isPinned: false,
            isClosed: false,
            closedAt: nil
        )
        notes.append(note)
        save()
        return note
    }

    func update(_ note: NoteModel) {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[idx] = note
        save()
    }

    func updateFrame(id: UUID, frame: CGRect) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].frame = frame
        save()
    }

    func markClosed(id: UUID) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].isClosed = true
        notes[idx].closedAt = Date()
        save()
    }

    @discardableResult
    func reopen(id: UUID) -> NoteModel? {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return nil }
        notes[idx].isClosed = false
        notes[idx].closedAt = nil
        save()
        return notes[idx]
    }

    func delete(id: UUID) {
        notes.removeAll(where: { $0.id == id })
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do {
            notes = try JSONDecoder().decode([NoteModel].self, from: data)
        } catch {
            notes = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            // Keep app flow simple for MVP; failing persistence should not crash UI.
        }
    }

    private func defaultFrame() -> CGRect {
        let size = CGSize(width: 340, height: 280)
        if let screen = NSScreen.main?.visibleFrame {
            let x = screen.midX - (size.width / 2)
            let y = screen.midY - (size.height / 2)
            return CGRect(origin: CGPoint(x: x, y: y), size: size)
        }
        return CGRect(origin: CGPoint(x: 180, y: 180), size: size)
    }
}
