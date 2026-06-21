import SwiftUI

struct ReviewPane: View {
    let viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            ReviewToolbar(viewModel: viewModel)

            Divider()

            if viewModel.workState == .loading {
                ProgressStateView(title: "Loading playlists")
            } else if viewModel.workState == .scanning {
                ProgressStateView(title: "Scanning playlists")
            } else if viewModel.workState == .verifyingRemovals {
                ProgressStateView(title: "Verifying removals and checking for duplicates")
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
    let viewModel: MainViewModel

    var body: some View {
        let pendingRemovalCount = viewModel.pendingRemovals.count

        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review")
                        .font(.title3.weight(.semibold))

                    Text(reviewStatus(pendingRemovalCount: pendingRemovalCount))
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
                .disabled(pendingRemovalCount == 0 || viewModel.workState != .idle)
            }

            if viewModel.workState == .applying, let progress = viewModel.removalProgress {
                RemovalProgressView(progress: progress)
            }
        }
        .padding(16)
    }

    private func reviewStatus(pendingRemovalCount: Int) -> String {
        if viewModel.workState == .applying {
            return "Applying removals"
        }

        if pendingRemovalCount > 0 {
            return "\(pendingRemovalCount) pending removals"
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
    let viewModel: MainViewModel

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
    let viewModel: MainViewModel

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
                        .disabled(!occurrence.canRemove || viewModel.workState != .idle)

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
                        .disabled(!occurrence.canRemove || viewModel.workState != .idle)
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
