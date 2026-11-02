import Foundation
import Observation
import SwiftUI
import AppKit

/// Model representing an active or completed background subagent task.
public struct SubagentTaskItem: Identifiable, Sendable, Equatable {
    public enum Status: String, Sendable, Codable, Equatable {
        case running
        case done
        case error
    }

    public let id: String
    public var title: String
    public var accountID: String
    public var surfaceID: String
    public var startTime: Date
    public var status: Status

    public init(
        id: String,
        title: String,
        accountID: String = "",
        surfaceID: String = "",
        startTime: Date = Date(),
        status: Status = .running
    ) {
        self.id = id
        self.title = title
        self.accountID = accountID
        self.surfaceID = surfaceID
        self.startTime = startTime
        self.status = status
    }
}

extension SubagentTaskItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case accountID = "account_id"
        case account = "account"
        case surfaceID = "surface_id"
        case surfaceIdAlt = "surfaceId"
        case startTime = "start_time"
        case startTimeAlt = "startTime"
        case status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? id
        self.accountID = try container.decodeIfPresent(String.self, forKey: .accountID)
            ?? container.decodeIfPresent(String.self, forKey: .account)
            ?? ""
        self.surfaceID = try container.decodeIfPresent(String.self, forKey: .surfaceID)
            ?? container.decodeIfPresent(String.self, forKey: .surfaceIdAlt)
            ?? ""
        if let timestamp = try? container.decodeIfPresent(Double.self, forKey: .startTime) {
            self.startTime = Date(timeIntervalSince1970: timestamp)
        } else if let timestampInt = try? container.decodeIfPresent(Int.self, forKey: .startTime) {
            self.startTime = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        } else if let date = try? container.decodeIfPresent(Date.self, forKey: .startTime) {
            self.startTime = date
        } else if let dateStr = try? container.decodeIfPresent(String.self, forKey: .startTime),
                  let parsed = ISO8601DateFormatter().date(from: dateStr) {
            self.startTime = parsed
        } else {
            self.startTime = Date()
        }
        let rawStatus = try? container.decodeIfPresent(String.self, forKey: .status)
        self.status = Status(rawValue: rawStatus?.lowercased() ?? "") ?? .running
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(accountID, forKey: .account)
        try container.encode(surfaceID, forKey: .surfaceID)
        try container.encode(startTime.timeIntervalSince1970, forKey: .startTime)
        try container.encode(status.rawValue, forKey: .status)
    }
}

/// `@MainActor @Observable` store that tracks active subagent tasks by monitoring `~/.config/cmux/subagents/*.json`.
@MainActor
@Observable
public final class SubagentTaskStore {
    public static let shared = SubagentTaskStore()

    /// All active or recently completed subagent tasks.
    public private(set) var activeTasks: [SubagentTaskItem] = []

    /// Current reference timestamp refreshed periodically to update elapsed time UI.
    public private(set) var currentTimestamp: Date = Date()

    private let directoryURL: URL
    private var directorySource: (any DispatchSourceFileSystemObject)?
    private var directoryFileDescriptor: Int32 = -1
    private var tickerTask: Task<Void, Never>?

    nonisolated public static var defaultDirectoryURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/cmux/subagents")
    }

    public init(directoryURL: URL = SubagentTaskStore.defaultDirectoryURL) {
        self.directoryURL = directoryURL
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        reloadTasks()
        startMonitoring()
    }

    deinit {
        MainActor.assumeIsolated {
            tickerTask?.cancel()
            if let directorySource {
                directorySource.cancel()
            } else if directoryFileDescriptor >= 0 {
                close(directoryFileDescriptor)
            }
        }
    }

    /// Resolves any surface representation (UUID string, "surface:<UUID>", or short handle ref like "surface:1") to its canonical UUID.
    public static func resolveSurfaceUUID(_ surfaceID: String) -> UUID? {
        let trimmed = surfaceID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 1. Direct UUID
        if let uuid = UUID(uuidString: trimmed) {
            return uuid
        }
        // 2. "surface:<UUID>" format
        if trimmed.lowercased().hasPrefix("surface:") {
            let tail = String(trimmed.dropFirst("surface:".count))
            if let uuid = UUID(uuidString: tail) {
                return uuid
            }
        }
        // 3. Resolve handle ref format (e.g. "surface:1") via TerminalController
        let handle = trimmed.lowercased().hasPrefix("surface:") ? trimmed : "surface:\(trimmed)"
        if let resolved = TerminalController.shared.v2ResolveHandleRef(handle) {
            return resolved
        }
        TerminalController.shared.v2RefreshKnownRefs()
        return TerminalController.shared.v2ResolveHandleRef(handle)
    }

    /// Reloads all `.json` task manifests from the subagents directory.
    public func reloadTasks() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directoryURL.path) else {
            if !activeTasks.isEmpty {
                activeTasks = []
            }
            return
        }

        guard let urls = try? fm.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return
        }

        let jsonURLs = urls.filter { $0.pathExtension == "json" }
        var loaded: [SubagentTaskItem] = []

        for url in jsonURLs {
            guard let data = try? Data(contentsOf: url),
                  let item = try? JSONDecoder().decode(SubagentTaskItem.self, from: data) else {
                continue
            }

            // Self-healing prune: If the terminal surface is no longer alive in cmux,
            // prune the manifest file regardless of status to prevent stuck ghost tasks.
            if !item.surfaceID.isEmpty, let delegate = AppDelegate.shared {
                if let uuid = Self.resolveSurfaceUUID(item.surfaceID) {
                    if delegate.locateSurface(surfaceId: uuid) == nil {
                        try? fm.removeItem(at: url)
                        delegate.geminiTerminalCoordinator.completeTask(surfaceID: uuid)
                        continue
                    }
                }
            }

            // Early-release account concurrency once task finishes (status done or error),
            // while preserving terminal surface open for user inspection.
            if item.status != .running, !item.surfaceID.isEmpty {
                if let uuid = Self.resolveSurfaceUUID(item.surfaceID) {
                    AppDelegate.shared?.geminiTerminalCoordinator.completeTask(surfaceID: uuid)
                }
            }

            loaded.append(item)
        }

        // Sort: running tasks first, then by startTime descending
        loaded.sort { a, b in
            if a.status == .running && b.status != .running { return true }
            if a.status != .running && b.status == .running { return false }
            return a.startTime > b.startTime
        }

        self.currentTimestamp = Date()
        if self.activeTasks != loaded {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.activeTasks = loaded
            }
        }
    }

    private func startMonitoring() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { break }
                self.reloadTasks()
            }
        }

        let fd = open(directoryURL.path, O_EVTONLY)
        if fd >= 0 {
            directoryFileDescriptor = fd
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .extend, .attrib, .link, .rename, .delete],
                queue: .main
            )
            source.setEventHandler { [weak self] in
                self?.reloadTasks()
            }
            source.setCancelHandler {
                close(fd)
            }
            source.resume()
            directorySource = source
        }
    }

    /// Focuses the workspace pane/surface corresponding to the subagent task.
    public func focusSurface(surfaceID: String) {
        guard let uuid = Self.resolveSurfaceUUID(surfaceID) else { return }

        if let located = AppDelegate.shared?.locateSurface(surfaceId: uuid) {
            _ = AppDelegate.shared?.focusMainWindow(windowId: located.windowId)
            if let tab = located.tabManager.tabs.first(where: { $0.id == located.workspaceId }) {
                located.tabManager.selectTab(tab)
                located.tabManager.focusSurface(tabId: located.workspaceId, surfaceId: uuid)
            }
        }
    }

    // MARK: - Testing / Mutation Helpers

    public func addTask(_ task: SubagentTaskItem) {
        if let idx = activeTasks.firstIndex(where: { $0.id == task.id }) {
            activeTasks[idx] = task
        } else {
            activeTasks.append(task)
        }
    }

    public func removeTask(id: String) {
        activeTasks.removeAll { $0.id == id }
    }
}
