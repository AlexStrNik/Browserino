//  BrowserSearchLocationsTab.swift
//  Browserino
//
//  Created by byt3m4st3r.
//

import SwiftUI

struct Directory: Codable, Hashable {
    var directoryPath: String
}

struct BrowserSearchLocations: View {
    @Binding var directories: [Directory]
    @State private var explorerPresented = false

    var body: some View {
        HStack {
            Text("Add a new location by selecting a directory (use ⇧⌘G in the Finder to enter the path).")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                explorerPresented.toggle()
            }) {
                Text("Select directory")
            }
            .fileImporter(
                isPresented: $explorerPresented,
                allowedContentTypes: [.directory]
            ) { result in
                if case let .success(dir) = result {
                    let newDirectory = Directory(directoryPath: dir.path)
                    if !directories.contains(newDirectory) {
                        directories.append(newDirectory)
                    }
                }
            }
        }
        .padding(10)
    }
}

struct DirectoryItem: View {
    @Binding var directory: Directory
    @Binding var directories: [Directory]

    var body: some View {
        HStack {
            Text(directory.directoryPath)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)

            
            Button(action: {
                deleteDirectory()
            }) {
                Image(
                    systemName: "trash")
            }
            .disabled(directory.directoryPath == "/Applications")
            .buttonStyle(.plain)
        }
        .padding(10)
    }

    private func deleteDirectory() {
        if let index = directories.firstIndex(of: directory) {
            directories.remove(at: index)
        }
    }
}

struct BrowserSearchLocationsTab: View {
    @AppStorage("directories") private var directories: [Directory] = []

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(Array($directories.enumerated()), id: \.offset) { _, directory in
                    DirectoryItem(directory: directory, directories: $directories)
                }
                BrowserSearchLocations(directories: $directories)
            }

            Text("Manage browser search locations (don't forget to rescan)")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.5))
                .frame(maxWidth: .infinity)
        }
        .onAppear(perform: loadDirectories)
        .padding(.bottom, 20)
    }

    private func loadDirectories() {
        // Always add "/Applications" as default browser search directory
        if directories.isEmpty {
            let defaultDirectory = Directory(directoryPath: "/Applications")
            directories.append(defaultDirectory)
        }
    }
}

#Preview {
    BrowserSearchLocationsTab()
}
