import Foundation
import Testing

@testable import WmuxCommandPalette

@Suite struct CommandPaletteRequestKindTests {
    @Test func notificationNamesMatchLegacyLiterals() {
        #expect(CommandPaletteRequestKind.commands.notificationName == "wmux.commandPaletteRequested")
        #expect(CommandPaletteRequestKind.agentInbox.notificationName == "wmux.agentInboxRequested")
        #expect(CommandPaletteRequestKind.switcher.notificationName == "wmux.commandPaletteSwitcherRequested")
        #expect(CommandPaletteRequestKind.renameTab.notificationName == "wmux.commandPaletteRenameTabRequested")
        #expect(CommandPaletteRequestKind.renameWorkspace.notificationName == "wmux.commandPaletteRenameWorkspaceRequested")
        #expect(
            CommandPaletteRequestKind.editWorkspaceDescription.notificationName
                == "wmux.commandPaletteEditWorkspaceDescriptionRequested"
        )
        #expect(CommandPaletteRequestKind.rename.notificationName == "wmux.commandPaletteRenameRequested")
    }

    @Test func everyKindMarksPending() {
        for kind in CommandPaletteRequestKind.allCases {
            #expect(kind.marksPending)
        }
    }

    @Test func notificationNamesAreDistinct() {
        let names = Set(CommandPaletteRequestKind.allCases.map(\.notificationName))
        #expect(names.count == CommandPaletteRequestKind.allCases.count)
    }
}
