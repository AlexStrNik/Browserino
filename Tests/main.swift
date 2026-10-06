import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    if !condition { print("FAIL: \(name)"); failures += 1 }
}
func wrapped(_ value: String) -> URL {
    var components = URLComponents(string: "browserino://open")!
    components.queryItems = [URLQueryItem(name: "url", value: Data(value.utf8).base64EncodedString())]
    return components.url!
}
let web = URL(string: "https://example.com/path?q=1")!
check(web.browserinoIncomingURL == web, "preserves HTTPS")
check(wrapped(web.absoluteString).browserinoIncomingURL == web, "decodes wrapper")
for value in ["javascript:alert(1)", "file:///etc/passwd", "data:text/html,test", "browserino://open", "https:", "https:///path"] {
    check(wrapped(value).browserinoIncomingURL == nil, "rejects wrapped \(value)")
}
check(URL(string: "file:///tmp/page.html")!.browserinoIncomingURL != nil, "preserves local HTML documents")
check(URL(string: "browserino://other")!.browserinoIncomingURL == nil, "rejects unknown command")
check(URL(string: "browserino://open?url=invalid")!.browserinoIncomingURL == nil, "rejects malformed base64")
check(URL(string: "https://example.com")!.matchesHost("example.com"), "matches domain")
check(!URL(string: "https://evil-example.com")!.matchesHost("example.com"), "rejects suffix spoof")
if failures > 0 { exit(1) }
print("All URL security checks passed")
