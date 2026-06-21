import SwiftUI

struct ContentView: View {
    @State private var viewModel = MainViewModel()

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
