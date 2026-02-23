import AppKit
import Combine
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = NoteStore()
    private lazy var windowManager = NoteWindowManager(store: store)

    private var statusItem: NSStatusItem?
    private var notesCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyAppIcon()
        buildMainMenu()
        buildStatusItem()
        windowManager.restoreOpenNotesOnLaunch()

        notesCancellable = store.$notes.sink { [weak self] _ in
            guard let self else { return }
            self.rebuildMenu()
            self.refreshMainMenuClosedNotesSubmenu()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowManager.prepareForTermination()
    }

    func menuWillOpen(_ menu: NSMenu) {
        if menu == statusItem?.menu {
            rebuildMenu()
            return
        }

        if menu.title == "File" {
            refreshMainMenuClosedNotesSubmenu()
        }
    }

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "Sticky Notes")
            ?? NSImage(systemSymbolName: "note.text", accessibilityDescription: "Sticky Notes")
        {
            image.isTemplate = true
            item.button?.image = image
        } else {
            item.button?.title = "SN"
        }
        statusItem = item
        rebuildMenu()
    }

    private func applyAppIcon() {
        guard
            let resourcePath = Bundle.main.resourcePath
        else {
            return
        }
        let iconPath = (resourcePath as NSString).appendingPathComponent("AppIcon.icns")
        if let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }
    }

    private func rebuildMenu() {
        guard let statusItem else { return }

        let menu = NSMenu()
        menu.delegate = self

        let newNote = NSMenuItem(title: "New Note", action: #selector(handleNewNote), keyEquivalent: "")
        newNote.target = self
        menu.addItem(newNote)

        let closedRoot = NSMenuItem(title: "Show Closed Notes", action: nil, keyEquivalent: "")
        let closedMenu = makeClosedNotesMenu()
        menu.setSubmenu(closedMenu, for: closedRoot)
        menu.addItem(closedRoot)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        let quit = NSMenuItem(title: "Quit DesktopStickyNotes", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        appMenu.addItem(quit)
        mainMenu.setSubmenu(appMenu, for: appMenuItem)

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileMenu.delegate = self

        let newNote = NSMenuItem(title: "New Note", action: #selector(handleNewNote), keyEquivalent: "n")
        newNote.target = self
        fileMenu.addItem(newNote)

        let closedRoot = NSMenuItem(title: "Show Closed Notes", action: nil, keyEquivalent: "")
        fileMenu.setSubmenu(makeClosedNotesMenu(), for: closedRoot)
        fileMenu.addItem(closedRoot)

        mainMenu.setSubmenu(fileMenu, for: fileItem)
        NSApp.mainMenu = mainMenu
    }

    private func makeClosedNotesMenu() -> NSMenu {
        let closedMenu = NSMenu()
        let hasClosed = !store.closedNotes.isEmpty

        let showAll = NSMenuItem(title: "Show All", action: #selector(handleReopenAllClosed), keyEquivalent: "")
        showAll.target = self
        showAll.isEnabled = hasClosed
        closedMenu.addItem(showAll)
        closedMenu.addItem(.separator())

        if store.closedNotes.isEmpty {
            let empty = NSMenuItem(title: "No closed notes", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            closedMenu.addItem(empty)
        } else {
            for note in store.closedNotes {
                let item = NSMenuItem(
                    title: closedNoteTitle(for: note),
                    action: #selector(handleReopen(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = note.id.uuidString
                closedMenu.addItem(item)
            }
        }
        return closedMenu
    }

    private func refreshMainMenuClosedNotesSubmenu() {
        guard
            let mainMenu = NSApp.mainMenu,
            mainMenu.items.count > 1,
            let fileMenu = mainMenu.items[1].submenu,
            let closedRoot = fileMenu.items.first(where: { $0.title == "Show Closed Notes" })
        else {
            return
        }
        fileMenu.setSubmenu(makeClosedNotesMenu(), for: closedRoot)
    }

    private func closedNoteTitle(for note: NoteModel) -> String {
        let firstLine = note.text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let firstLine, !firstLine.isEmpty {
            return firstLine
        }
        return "Note \(note.id.uuidString.prefix(8))"
    }

    @objc private func handleNewNote() {
        windowManager.createNewNote()
    }

    @objc private func handleReopen(_ sender: NSMenuItem) {
        guard
            let raw = sender.representedObject as? String,
            let id = UUID(uuidString: raw)
        else {
            return
        }
        windowManager.reopenClosedNote(id: id)
    }

    @objc private func handleReopenAllClosed() {
        windowManager.reopenAllClosedNotes()
    }

    @objc private func handleQuit() {
        windowManager.prepareForTermination()
        NSApp.terminate(nil)
    }
}

@main
enum DesktopStickyNotesApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        let menuBarOnly = ProcessInfo.processInfo.environment["STICKY_NOTES_MENU_BAR_ONLY"] == "1"
        app.setActivationPolicy(menuBarOnly ? .accessory : .regular)
        app.run()
    }
}
