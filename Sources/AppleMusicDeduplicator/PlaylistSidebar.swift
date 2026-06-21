import SwiftUI

struct PlaylistSidebar: View {
    let viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 0) {
            TextField(
                "Filter playlists",
                text: Binding(
                    get: { viewModel.filterText },
                    set: { viewModel.filterText = $0 }
                )
            )
            .textFieldStyle(.roundedBorder)
            .padding([.horizontal, .top], 12)
            .padding(.bottom, 8)

            List(viewModel.filteredPlaylists) { playlist in
                PlaylistSelectionRow(
                    playlist: playlist,
                    isSelected: viewModel.selectedPlaylistIDs.contains(playlist.id),
                    isEnabled: viewModel.workState == .idle
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
    let isEnabled: Bool
    let onChange: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { isSelected }, set: { onChange($0) })) {
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
        .disabled(!isEnabled)
        .help(playlist.canRemoveTracks ? playlist.name : "\(playlist.name) can be scanned but not edited")
        .padding(.vertical, 3)
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
