#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
swiftc -swift-version 6 -module-cache-path /tmp/browserino-module-cache Browserino/Models/BrowserTarget.swift Browserino/Models/IntegrationPolicy.swift Browserino/Models/SettingsPolicy.swift Browserino/Models/Rule.swift Tests/Integration/main.swift -o /tmp/browserino-integration-tests
/tmp/browserino-integration-tests
swiftc -swift-version 6 -module-cache-path /tmp/browserino-module-cache Browserino/Extensions/Array+RawRepresentable.swift Browserino/Extensions/Bundle+AppDisplayName.swift Browserino/Models/IntegrationPolicy.swift Browserino/Models/BrowserTarget.swift Browserino/Models/Localization.swift Browserino/Models/ChromiumProfile.swift Tests/Profiles/main.swift -o /tmp/browserino-profile-tests
/tmp/browserino-profile-tests
