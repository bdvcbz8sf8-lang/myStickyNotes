# Desktop Sticky Notes (MVP)

Minimal macOS sticky notes app (menu bar + floating note windows), built with Swift + AppKit/SwiftUI.

## Features

- Menu-based app flow:
  - `New Note`
  - `Show Closed Notes`
  - `Show All` (reopen all closed notes)
  - `Quit`
- Each note is an independent floating `NSWindow`.
- Notes are draggable and resizable.
- Pin support (`isPinned`):
  - off -> normal window level
  - on -> floating window level
- Note states with color backgrounds:
  - `Note`
  - `To Do`
  - `In Progress`
  - `Done`
- Context menu on note:
  - `Copy`
  - `Change State`
  - `Delete`
- Permanent delete with confirmation dialog.
- Local persistence in `UserDefaults` (no network/cloud/auth).
- Autosave triggers:
  - text edits
  - window move/resize
  - state changes
  - pin changes
  - close/reopen/delete
- Launch restore:
  - reopens notes that were open before quit
  - keeps closed notes in `Show Closed Notes`
- Closed-notes UX:
  - sorted by most recently closed first
  - empty state (`No closed notes`) without crashes

## Tech Stack

- Swift
- SwiftUI (note content UI)
- AppKit (`NSApplication`, `NSWindow`, menu/status integration)
- Swift Package Manager

## Project Structure

- `Sources/DesktopStickyNotes/DesktopStickyNotesApp.swift` - app lifecycle, menu/status integration
- `Sources/DesktopStickyNotes/NoteWindowManager.swift` - note windows management
- `Sources/DesktopStickyNotes/NoteStore.swift` - persistence and note mutations
- `Sources/DesktopStickyNotes/NoteView.swift` - note UI and interactions
- `Sources/DesktopStickyNotes/NoteModel.swift` - note/state models

## Run

```bash
cd /Users/kuddelmuddel/Desktop/Notes/DesktopStickyNotes
swift run
```

Or open `Package.swift` in Xcode and run there.

## Current Scope (MVP)

This repository intentionally excludes:
- cloud sync
- tags/folders/search/archive
- drag-and-drop files
- onboarding/settings/history
