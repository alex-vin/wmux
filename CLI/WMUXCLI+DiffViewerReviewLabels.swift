import Foundation

extension WMUXCLI.DiffViewerLabels {
    /// Labels for the review-parity controls (viewed state, file filter,
    /// generated and large-diff collapse). Kept out of `wmux_open.swift`,
    /// which is over the file length budget; `localized()` merges them.
    static var reviewParityLabels: [String: String] {
        [
            "changedSinceViewed": WMUXDiffViewerLocalization.string("diffViewer.changedSinceViewed", defaultValue: "Changed since viewed"),
            "clearFileFilter": WMUXDiffViewerLocalization.string("diffViewer.clearFileFilter", defaultValue: "Clear filter"),
            "filesViewedProgress": WMUXDiffViewerLocalization.string("diffViewer.filesViewedProgress", defaultValue: "{viewed} of {total} files viewed"),
            "filterAddedFiles": WMUXDiffViewerLocalization.string("diffViewer.filterAddedFiles", defaultValue: "Added"),
            "filterDeletedFiles": WMUXDiffViewerLocalization.string("diffViewer.filterDeletedFiles", defaultValue: "Deleted"),
            "filterFiles": WMUXDiffViewerLocalization.string("diffViewer.filterFiles", defaultValue: "Filter files"),
            "filterModifiedFiles": WMUXDiffViewerLocalization.string("diffViewer.filterModifiedFiles", defaultValue: "Modified"),
            "filterRenamedFiles": WMUXDiffViewerLocalization.string("diffViewer.filterRenamedFiles", defaultValue: "Renamed"),
            "generatedFile": WMUXDiffViewerLocalization.string("diffViewer.generatedFile", defaultValue: "Generated file"),
            "hideViewedFiles": WMUXDiffViewerLocalization.string("diffViewer.hideViewedFiles", defaultValue: "Hide viewed files"),
            "largeDiff": WMUXDiffViewerLocalization.string("diffViewer.largeDiff", defaultValue: "Large diff"),
            "loadDiff": WMUXDiffViewerLocalization.string("diffViewer.loadDiff", defaultValue: "Load diff"),
            "markNotViewed": WMUXDiffViewerLocalization.string("diffViewer.markNotViewed", defaultValue: "Mark as not viewed"),
            "markViewed": WMUXDiffViewerLocalization.string("diffViewer.markViewed", defaultValue: "Mark as viewed"),
            "noFilesMatchFilter": WMUXDiffViewerLocalization.string("diffViewer.noFilesMatchFilter", defaultValue: "No files match the filter."),
            "showViewedFiles": WMUXDiffViewerLocalization.string("diffViewer.showViewedFiles", defaultValue: "Show viewed files"),
            "viewed": WMUXDiffViewerLocalization.string("diffViewer.viewed", defaultValue: "Viewed"),
        ]
    }
}
