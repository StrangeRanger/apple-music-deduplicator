import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        NavigationSplitView {
            PlaylistSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        } detail: {
            ReviewPane(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 560, ideal: 820)
        }
        .frame(minWidth: 920, minHeight: 620)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.loadPlaylists()
                } label: {
                    Label("Reload Playlists", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.workState != .idle)

                Button {
                    viewModel.scanSelectedPlaylists()
                } label: {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(!viewModel.canScan)
            }
        }
        .alert(
            "Music Automation",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            viewModel.loadPlaylists()
        }
    }
}

private struct PlaylistSidebar: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            TextField("Filter playlists", text: $viewModel.filterText)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .top], 12)
                .padding(.bottom, 8)

            List(viewModel.filteredPlaylists) { playlist in
                PlaylistSelectionRow(
                    playlist: playlist,
                    isSelected: viewModel.selectedPlaylistIDs.contains(playlist.id)
                ) { selected in
                    viewModel.setSelected(selected, playlistID: playlist.id)
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack(spacing: 12) {
                StatusIndicator(workState: viewModel.workState)

                Text(viewModel.selectedCountText)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    viewModel.scanSelectedPlaylists()
                } label: {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canScan)
            }
            .padding(12)
        }
    }
}

private struct PlaylistSelectionRow: View {
    let playlist: PlaylistSummary
    let isSelected: Bool
    let onChange: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { isSelected }, set: { newValue in onChange(newValue) })) {
            HStack(spacing: 10) {
                Image(systemName: playlist.canRemoveTracks ? "music.note.list" : "lock")
                    .foregroundStyle(playlist.canRemoveTracks ? Color.accentColor : Color.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(playlist.name)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("\(playlist.trackCount) tracks")
                        Text(playlist.kindLabel)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.checkbox)
        .help(playlist.canRemoveTracks ? playlist.name : "\(playlist.name) can be scanned but not edited")
        .padding(.vertical, 3)
    }
}

private struct ReviewPane: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            ReviewToolbar(viewModel: viewModel)

            Divider()

            if viewModel.workState == .loading {
                ProgressStateView(title: "Loading playlists")
            } else if viewModel.workState == .scanning {
                ProgressStateView(title: "Scanning playlists")
            } else if viewModel.duplicates.isEmpty {
                EmptyReviewState(
                    selectedCount: viewModel.selectedPlaylistIDs.count,
                    statusMessage: viewModel.statusMessage
                )
            } else {
                DuplicateList(viewModel: viewModel)
            }
        }
    }
}

private struct ReviewToolbar: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review")
                        .font(.title3.weight(.semibold))

                    Text(reviewStatus)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    viewModel.resetReviewChoices()
                } label: {
                    Label("Keep All", systemImage: "checkmark.circle")
                }
                .disabled(viewModel.duplicates.isEmpty || viewModel.workState != .idle)

                Button {
                    viewModel.applyRemovals()
                } label: {
                    Label("Apply Removals", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canApplyRemovals)
            }

            if viewModel.workState == .applying, let progress = viewModel.removalProgress {
                RemovalProgressView(progress: progress)
            }
        }
        .padding(16)
    }

    private var reviewStatus: String {
        if viewModel.workState == .applying {
            return "Applying removals"
        }

        let pending = viewModel.pendingRemovals.count
        if pending > 0 {
            return "\(pending) pending removals"
        }

        return viewModel.statusMessage.isEmpty ? "No pending removals" : viewModel.statusMessage
    }
}

private struct RemovalProgressView: View {
    let progress: RemovalProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: progress.fractionCompleted)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Removing \(progress.countText)")
                    .font(.caption.weight(.medium))

                Text("\(progress.removedEntries) entries removed")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(currentItemText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var currentItemText: String {
        guard !progress.currentPlaylistName.isEmpty else {
            return progress.currentTrackTitle
        }

        return "\(progress.currentTrackTitle) / \(progress.currentPlaylistName)"
    }
}

private struct DuplicateList: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        List {
            if let result = viewModel.lastRemovalResult {
                RemovalResultSection(result: result)
            }

            ForEach(viewModel.duplicates) { duplicate in
                DuplicateSongRow(duplicate: duplicate, viewModel: viewModel)
            }
        }
        .listStyle(.inset)
    }
}

private struct DuplicateSongRow: View {
    let duplicate: DuplicateSong
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duplicate.title)
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(duplicate.artist)
                        if !duplicate.album.isEmpty {
                            Text(duplicate.album)
                        }
                        if !duplicate.time.isEmpty {
                            Text(duplicate.time)
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer()

                Text("\(duplicate.occurrences.count) playlists")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 8) {
                ForEach(duplicate.occurrences) { occurrence in
                    GridRow {
                        Toggle(
                            "Keep",
                            isOn: Binding(
                                get: {
                                    viewModel.keepSelections[duplicate.id, default: []]
                                        .contains(occurrence.playlistID)
                                },
                                set: { keep in
                                    viewModel.setKeep(
                                        keep,
                                        duplicateID: duplicate.id,
                                        playlistID: occurrence.playlistID
                                    )
                                }
                            )
                        )
                        .toggleStyle(.checkbox)
                        .disabled(!occurrence.canRemove)

                        Text(occurrence.playlistName)
                            .lineLimit(1)

                        Button {
                            viewModel.keepOnly(
                                playlistID: occurrence.playlistID,
                                duplicateID: duplicate.id
                            )
                        } label: {
                            Image(systemName: "scope")
                        }
                        .buttonStyle(.borderless)
                        .disabled(!occurrence.canRemove)
                        .help("Keep only this editable playlist")
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
}

private struct RemovalResultSection: View {
    let result: RemovalResult

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Removed \(result.removedEntries) playlist entries")
                    .font(.headline)

                if !result.failures.isEmpty {
                    ForEach(result.failures) { failure in
                        Text("\(failure.trackTitle) / \(failure.playlistName): \(failure.message)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

private struct EmptyReviewState: View {
    let selectedCount: Int
    let statusMessage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.weight(.semibold))

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconName: String {
        selectedCount >= 2 ? "checkmark.seal" : "music.note.list"
    }

    private var title: String {
        selectedCount >= 2 ? "No duplicates found" : "Select at least two playlists"
    }
}

private struct ProgressStateView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StatusIndicator: View {
    let workState: MainViewModel.WorkState

    var body: some View {
        Group {
            if workState == .idle {
                Image(systemName: "circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.green)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(width: 18, height: 18)
    }
}
