// SPDX-License-Identifier: GPL-2.0-or-later
// Part of MacRazer, a control app for Razer mice on macOS. See LICENSE and NOTICE.md.

import XCTest
@testable import MacRazer

final class ConnectionSoundSettingsTests: XCTestCase {
    func testConnectionSoundsDefaultToEnabledAndRespectStoredChoice() throws {
        let suiteName = "ConnectionSoundSettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(MouseController.connectionSoundsEnabled(defaults: defaults))

        defaults.set(false, forKey: MouseController.connectionSoundsEnabledKey)
        XCTAssertFalse(MouseController.connectionSoundsEnabled(defaults: defaults))

        defaults.set(true, forKey: MouseController.connectionSoundsEnabledKey)
        XCTAssertTrue(MouseController.connectionSoundsEnabled(defaults: defaults))
    }
}
