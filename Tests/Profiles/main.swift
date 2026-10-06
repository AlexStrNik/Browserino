import Foundation
func check(_ value: Bool, _ label: String) { if !value { fatalError(label) } }
let root = FileManager.default.temporaryDirectory.appendingPathComponent("BrowserinoProfiles-" + UUID().uuidString)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: root) }
let app = root.appendingPathComponent("Browser.app")
check(ChromiumProfileService.readProfiles(forAppAt: app, root: root) == nil, "unreadable is unknown")
let localState = root.appendingPathComponent("Local State")
try Data(#"{"profile":{"info_cache":{}}}"#.utf8).write(to: localState)
check(ChromiumProfileService.readProfiles(forAppAt: app, root: root)?.isEmpty == true, "readable empty is empty")
let outside = root.appendingPathComponent("outside")
try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
try Data([0]).write(to: outside.appendingPathComponent("avatar.png"))
let profile = root.appendingPathComponent("Profile 1")
try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
try FileManager.default.createSymbolicLink(at: profile.appendingPathComponent("avatar.png"), withDestinationURL: URL(fileURLWithPath: "/tmp/outside.png"))
try Data(#"{"profile":{"info_cache":{"Profile 2":{"name":"Second"},"Profile 1":{"name":"First","gaia_picture_file_name":"avatar.png"},"../escape":{"name":"Escape"},"Default":{"name":"Main"},"Profile 3":{"name":"Ephemeral","is_ephemeral":true}},"profiles_order":["Profile 2"]}}"#.utf8).write(to: localState)
let profiles = ChromiumProfileService.readProfiles(forAppAt: root.appendingPathComponent("New.app"), root: root)!
check(profiles.map(\.directory) == ["Profile 2", "Default", "Profile 1"], "deterministic order and unsafe/ephemeral filtering")
check(profiles.first(where: { $0.directory == "Profile 1" })?.avatar == nil, "avatar symlink rejected")
print("Profile discovery fixture checks passed")
