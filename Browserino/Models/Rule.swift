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

    init(regex: String, app: URL, profile: String? = nil) {
        self.regex = regex; self.app = app; self.profile = profile
    }
    private enum CodingKeys: String, CodingKey { case regex, app, profile, profileDirectory }
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        regex = try values.decode(String.self, forKey: .regex)
        app = try values.decode(URL.self, forKey: .app)
        profile = try values.decodeIfPresent(String.self, forKey: .profile)
            ?? values.decodeIfPresent(String.self, forKey: .profileDirectory)
    }
    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(regex, forKey: .regex)
        try values.encode(app, forKey: .app)
        try values.encodeIfPresent(profile, forKey: .profile)
    }

    var target: BrowserTarget {
        BrowserTarget(app: app, profile: profile)
    }
}
