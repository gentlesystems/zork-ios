import SwiftUI

/// Root view exported by the ZorkUI package.
/// Embed in the host app's `WindowGroup` (or any container) to host the game.
public struct ZorkGameView: View {

    private let engine = GameEngine.shared
    @State private var command      = ""
    @State private var showSettings = false
    @State private var inputFocused = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TerminalTextView(text: engine.outputText, adaptive: engine.adaptiveSizingEnabled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .overlay(Color.green.opacity(0.4))

                commandBar
            }
            .background(Color.black)
            .navigationTitle("Dungeon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                    .tint(.green)
                    .accessibilityLabel("Game settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                ZorkSettingsSheet(engine: engine)
            }
            .onAppear {
                engine.start()
                inputFocused = true
            }
            .onDisappear {
                engine.autosave()
            }
            .onChange(of: engine.hasEnded) { _, ended in
                if ended { engine.restart() }
            }
        }
    }

    // MARK: - Command bar

    private var commandBar: some View {
        HStack(spacing: 8) {
            Text(">")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.green)

            ZorkInputField(
                text: $command,
                isFocused: $inputFocused,
                isEnabled: !engine.hasEnded,
                onSubmit: sendCommand
            )
            .frame(maxWidth: .infinity)

            if !command.isEmpty {
                Button(action: sendCommand) {
                    Image(systemName: "return")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black)
    }

    // MARK: - Actions

    private func sendCommand() {
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        engine.send(trimmed)
        command = ""
    }
}

// MARK: - Settings sheet

private struct ZorkSettingsSheet: View {
    let engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var saveExists        = false

    var body: some View {
        NavigationStack {
            Form {
                // Save / restore
                Section {
                    Toggle("Autosave & Restore", isOn: Binding(
                        get: { engine.autosaveEnabled },
                        set: { engine.autosaveEnabled = $0 }
                    ))
                } header: {
                    Text("Save Game")
                } footer: {
                    Text("When enabled, your progress is saved whenever you leave this screen and restored when you return.")
                }

                if saveExists {
                    Section {
                        Button("Delete Save File", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    } footer: {
                        Text("Removes the saved game. The next session will start a new game.")
                    }
                }

                // Display
                Section {
                    Toggle("Adaptive Text Size", isOn: Binding(
                        get: { engine.adaptiveSizingEnabled },
                        set: { engine.adaptiveSizingEnabled = $0 }
                    ))
                } header: {
                    Text("Display")
                } footer: {
                    Text("Automatically shrinks the terminal font so the game's wide lines fit the screen. Turn off to use the system text size from Settings → Display & Brightness.")
                }

                // How to play
                Section("How to Play") {
                    LabeledContent("Game information") {
                        Text("type **info**")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Commands & instructions") {
                        Text("type **help**")
                            .foregroundStyle(.secondary)
                    }
                }

                // Attribution
                Section {
                    Link(destination: URL(string: "https://github.com/devshane/zork")!) {
                        Label("devshane/zork on GitHub", systemImage: "link")
                    }
                } header: {
                    Text("Acknowledgements")
                } footer: {
                    Text("This game is powered by the public domain C port of Dungeon (Zork 2.6). Thank you to so many people for creating and then making this piece of interactive fiction history freely available.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Dungeon Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete Save File?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    engine.deleteSave()
                    saveExists = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your saved progress will be permanently lost.")
            }
            .onAppear {
                saveExists = engine.hasSaveFile()
            }
        }
    }
}

#Preview {
    ZorkGameView()
}
