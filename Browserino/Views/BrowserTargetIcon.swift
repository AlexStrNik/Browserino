//
//  BrowserTargetIcon.swift
//  Browserino
//

import SwiftUI

/// The browser's icon, badged with the profile picture when there is one, so that
/// several profiles of the same browser stay distinguishable at a glance.
struct BrowserTargetIcon: View {
    let target: BrowserTarget
    var badgeSize: CGFloat = 14

    var body: some View {
        Image(nsImage: target.icon)
            .resizable()
            .overlay(alignment: .bottomTrailing) {
                if let avatar = target.chromiumProfile?.avatar,
                   let image = ChromiumProfileService.avatarImage(avatar) {
                    Image(nsImage: image)
                        .resizable()
                        .clipShape(.circle)
                        .frame(width: badgeSize, height: badgeSize)
                        .overlay {
                            Circle().strokeBorder(.background, lineWidth: 1.5)
                        }
                        .offset(x: badgeSize / 4, y: badgeSize / 4)
                }
            }
    }
}
