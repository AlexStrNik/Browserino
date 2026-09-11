//
//  Rule.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 02.12.2024.
//

import Foundation

struct Rule: Hashable, Codable {
    var regex: String
    var app: URL
    var profile: String?

    var target: BrowserTarget {
        BrowserTarget(app: app, profile: profile)
    }
}
