// SPDX-License-Identifier: GPL-2.0-or-later
// Part of MacRazer, a control app for Razer mice on macOS. See LICENSE and NOTICE.md.

import XCTest
@testable import MacRazer

final class BasiliskBluetoothSettingsStoreTests: XCTestCase {
    func testSnapshotsArePerDeviceAndUpdatesPreserveOtherOwnedSettings() throws {
        let suiteName = "BasiliskBluetoothSettingsStoreTests-\(UUID())"
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { suite.removePersistentDomain(forName: suiteName) }
        let store = BasiliskBluetoothSettingsStore(defaults: suite)

        store.update(for: "serial-a") { $0.dpiStages = .init(active: 2, values: [400, 800, 1600]) }
        store.update(for: "serial-a") { $0.sleepTimeout = 300 }
        store.update(for: "serial-b") { $0.brightness = 45 }

        XCTAssertEqual(store.snapshot(for: "serial-a"), BasiliskBluetoothSettingsSnapshot(
            dpiStages: .init(active: 2, values: [400, 800, 1600]),
            sleepTimeout: 300, brightness: nil))
        XCTAssertEqual(store.snapshot(for: "serial-b"), BasiliskBluetoothSettingsSnapshot(
            dpiStages: nil, sleepTimeout: nil, brightness: 45))
        XCTAssertNil(store.snapshot(for: "serial-c"))
    }

}
