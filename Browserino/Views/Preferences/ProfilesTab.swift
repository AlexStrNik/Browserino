//
//  ProfilesTab.swift
//  Browserino
//

import SwiftUI

struct ProfilesTab: View {
    @AppStorage("chromeProfiles") private var chromeProfiles: [ChromeProfile] = []
    @AppStorage("chromeProfilesEnabled") private var chromeProfilesEnabled: Bool = true

    @State private var hasDetected = false

    private var chromeInstalled: Bool {
        ChromeProfileUtil.chromeURL() != nil
    }

    private func detectProfiles() {
        let detected = ChromeProfileUtil.detectProfiles()

        var merged: [ChromeProfile] = []
        for profile in detected {
            if let existing = chromeProfiles.first(where: { $0.directoryName == profile.directoryName }) {
                merged.append(ChromeProfile(
                    directoryName: existing.directoryName,
                    displayName: existing.displayName,
                    isHidden: existing.isHidden
                ))
            } else {
                merged.append(profile)
            }
        }

        chromeProfiles = merged
        hasDetected = true
    }

    private func displayName(at index: Int) -> Binding<String> {
        Binding(
            get: { chromeProfiles[index].displayName },
            set: { chromeProfiles[index].displayName = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            if !chromeInstalled {
                Spacer()
                Text("Google Chrome is not installed.")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                HStack(spacing: 16) {
                    Toggle(isOn: $chromeProfilesEnabled) {
                        Text("Show Chrome profiles as separate items in the picker")
                            .font(.callout)
                    }

                    Spacer()

                    Button(action: detectProfiles) {
                        Text("Detect Profiles")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                List {
                    ForEach(Array(chromeProfiles.enumerated()), id: \.element.directoryName) { index, profile in
                        HStack {
                            TextField("Display name", text: displayName(at: index))
                                .font(.system(size: 14))
                                .frame(maxWidth: 200)

                            Spacer()
                                .frame(width: 16)

                            Text(profile.directoryName)
                                .font(.system(size: 12).monospaced())
                                .foregroundStyle(.secondary)

                            Spacer()

                            ShortcutButton(
                                browserId: "\(ChromeProfileUtil.chromeBundleID)::\(profile.directoryName)"
                            )

                            Spacer()
                                .frame(width: 8)

                            Button(action: {
                                chromeProfiles[index].isHidden.toggle()
                            }) {
                                Image(
                                    systemName: profile.isHidden
                                        ? "eye.slash.fill" : "eye.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }

                Text("Detect Chrome profiles and show them as separate picker items. Assign shortcuts and hide profiles you don't use.")
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 20)
        .onAppear {
            if !hasDetected && chromeInstalled && chromeProfiles.isEmpty {
                detectProfiles()
            }
        }
    }
}

#Preview {
    ProfilesTab()
}
