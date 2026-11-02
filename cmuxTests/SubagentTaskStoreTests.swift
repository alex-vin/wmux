import Foundation
import Testing

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@Suite("SubagentTaskStoreTests")
@MainActor
struct SubagentTaskStoreTests {
    private func makeTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("subagents_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    @Test("SubagentTaskItem JSON serialization and deserialization")
    func itemSerialization() throws {
        let item = SubagentTaskItem(
            id: "task-123",
            title: "Code Review",
            accountID: "alex@example.com",
            surfaceID: "surface:abc",
            startTime: Date(timeIntervalSince1970: 1700000000),
            status: .running
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(item)
        let decoded = try JSONDecoder().decode(SubagentTaskItem.self, from: data)

        #expect(decoded.id == item.id)
        #expect(decoded.title == item.title)
        #expect(decoded.accountID == item.accountID)
        #expect(decoded.surfaceID == item.surfaceID)
        #expect(decoded.status == .running)
    }

    @Test("SubagentTaskStore loads tasks from directory")
    func storeLoadsFromDirectory() throws {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let item1 = SubagentTaskItem(
            id: "task-1",
            title: "Task One",
            accountID: "user1@example.com",
            surfaceID: "surf-1",
            startTime: Date(timeIntervalSince1970: 1700000000),
            status: .running
        )
        let item2 = SubagentTaskItem(
            id: "task-2",
            title: "Task Two",
            accountID: "user2@example.com",
            surfaceID: "surf-2",
            startTime: Date(timeIntervalSince1970: 1700000100),
            status: .done
        )

        let file1 = tempDir.appendingPathComponent("task-1.json")
        let file2 = tempDir.appendingPathComponent("task-2.json")

        try JSONEncoder().encode(item1).write(to: file1)
        try JSONEncoder().encode(item2).write(to: file2)

        let store = SubagentTaskStore(directoryURL: tempDir)
        #expect(store.activeTasks.count == 2)
        #expect(store.activeTasks.first?.id == "task-1")
        #expect(store.activeTasks.first?.status == .running)
    }

    @Test("SubagentTaskStore handles task addition and removal")
    func storeMutation() {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = SubagentTaskStore(directoryURL: tempDir)
        #expect(store.activeTasks.isEmpty)

        let task = SubagentTaskItem(
            id: "custom-task",
            title: "Custom Task",
            accountID: "test@domain.com",
            surfaceID: "surf-123",
            status: .running
        )

        store.addTask(task)
        #expect(store.activeTasks.count == 1)
        #expect(store.activeTasks.first?.id == "custom-task")

        store.removeTask(id: "custom-task")
        #expect(store.activeTasks.isEmpty)
    }

    @Test("SubagentTaskStore focusSurface handles various handle formats safely")
    func focusSurfaceFormats() {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = SubagentTaskStore(directoryURL: tempDir)
        store.focusSurface(surfaceID: "")
        store.focusSurface(surfaceID: "surface:1")
        store.focusSurface(surfaceID: "surface:\(UUID().uuidString)")
        store.focusSurface(surfaceID: UUID().uuidString)
    }
}
