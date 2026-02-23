import AppKit
import Foundation

enum NoteState: String, Codable, CaseIterable, Identifiable {
    case normal
    case todo
    case inProgress
    case done

    var id: String { rawValue }
}

struct NoteModel: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var state: NoteState
    var frame: CGRect
    var isPinned: Bool
    var isClosed: Bool
    var closedAt: Date?
}
