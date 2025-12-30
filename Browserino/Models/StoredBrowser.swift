//
//  StoredBrowser.swift
//  Browserino
//
//  Created by GitHub Copilot on demand.
//

import Foundation

struct StoredBrowser: Identifiable, Codable, Hashable {
    let id: UUID
    var app: URL
    var name: String
    var hidden: Bool
    var privateArg: String

    init(id: UUID = UUID(), app: URL, name: String = "", hidden: Bool = false, privateArg: String = "") {
        self.id = id
        self.app = app
        self.name = name
        self.hidden = hidden
        self.privateArg = privateArg
    }

    static func from(url: URL, privateArg: String = "") -> StoredBrowser {
        let baseName = Bundle(url: url)?.infoDictionary?["CFBundleName"] as? String ?? url.lastPathComponent
        return StoredBrowser(app: url, name: baseName, hidden: false, privateArg: privateArg)
    }
}
