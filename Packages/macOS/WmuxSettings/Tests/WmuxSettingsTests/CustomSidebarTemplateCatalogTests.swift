import Foundation
import Testing
@testable import WmuxSettings

@Suite
struct CustomSidebarTemplateCatalogTests {
    @Test
    func bundledManifestLoadsCuratedTemplates() throws {
        let catalog = CustomSidebarTemplateCatalog()
        let curatedIDs = ["agents-board", "btop-agents", "panel-sessions", "panel-subagents", "panel-todo", "workspaces"]
        let bundledTemplatesDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/WmuxSettings/Resources/CustomSidebarTemplates", isDirectory: true)
        let bundledFiles = catalog.templates.map(\.file).sorted()
        #expect(catalog.templates.map(\.id) == curatedIDs)
        #expect(catalog.templates.count == curatedIDs.count)
        for descriptor in catalog.templates {
            let bundledSource = try String(
                contentsOf: bundledTemplatesDirectory.appendingPathComponent(descriptor.file),
                encoding: .utf8
            )
            #expect(!bundledSource.isEmpty)
            #expect(catalog.template(id: descriptor.id)?.source.isEmpty == false)
            #expect(CustomSidebarTemplateCatalog.isValidInstallationName(descriptor.id))
        }
    }

    @Test(arguments: ["agents-board", "panel-sessions", "workspaces"])
    func metadataIsAvailable(id: String) throws {
        let descriptor = try #require(CustomSidebarTemplateCatalog().templates.first { $0.id == id })
        #expect(!descriptor.displayName.isEmpty)
        #expect(!descriptor.description.isEmpty)
        #expect([.left, .right, .both].contains(descriptor.kind))
    }

    @Test(arguments: ["agents_board", "../agents-board", "", "Agents-Board", "agents-board/", "agents-board\n", "agents-board\r\n", "agents-board\u{2028}"])
    func rejectsUnsafeInstallationNames(name: String) {
        #expect(!CustomSidebarTemplateCatalog.isValidInstallationName(name))
    }
}

@Suite
struct CustomSidebarTemplateInstallerTests {
    @Test
    func copiesTemplateAndRefusesOverwriteUntilForced() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("wmux-template-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let installer = CustomSidebarTemplateInstaller()
        let first = try installer.install(name: "my-agents", templateID: "agents-board", directory: root)
        #expect(first.pathExtension == "js")
        #expect(FileManager.default.fileExists(atPath: first.path))
        #expect(throws: CustomSidebarTemplateInstallError.alreadyExists) {
            try installer.install(name: "my-agents", templateID: "agents-board", directory: root)
        }
        let forced = try installer.install(name: "my-agents", templateID: "workspaces", directory: root, force: true)
        #expect(forced.pathExtension == "js")
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("my-agents.js").path))
    }

    @Test(arguments: ["../escape", "bad_name", "Bad-name", "bad/name"])
    func rejectsInvalidNames(_ name: String) {
        #expect(throws: CustomSidebarTemplateInstallError.invalidName) {
            try CustomSidebarTemplateInstaller().install(
                name: name,
                templateID: "agents-board",
                directory: FileManager.default.temporaryDirectory
            )
        }
    }

    @Test
    func rejectsUnknownTemplate() {
        #expect(throws: CustomSidebarTemplateInstallError.unknownTemplate) {
            try CustomSidebarTemplateInstaller().install(
                name: "unknown",
                templateID: "does-not-exist",
                directory: FileManager.default.temporaryDirectory
            )
        }
    }
}
