// SPDX-License-Identifier: GPL-2.0-or-later
// Part of MacRazer, a control app for Razer mice on macOS. See LICENSE and NOTICE.md.

import XCTest
@testable import MacRazer

final class LastBatterySnapshotStoreTests: XCTestCase {
    private func makeStore() throws -> (LastBatterySnapshotStore, UserDefaults, String) {
        let suiteName = "LastBatterySnapshotStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        return (LastBatterySnapshotStore(defaults: defaults), defaults, suiteName)
    }

    private func snapshot(key: String = "mouse-1", percent: Int = 84,
                          hours: Double? = 39, at date: Date = Date()) -> LastBatterySnapshot {
        LastBatterySnapshot(deviceKey: key, productID: 0x00BA,
                            deviceName: "Razer Basilisk V3 X HyperSpeed", percent: percent,
                            observedAt: date, estimatedHoursRemaining: hours, wasCharging: false)
    }

    func testPersistsOnlyTheLatestSnapshotAndCanClearIt() throws {
        let (store, defaults, suiteName) = try makeStore()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = snapshot(at: Date(timeIntervalSince1970: 1_700_000_000))
        store.save(first)
        XCTAssertEqual(store.load(), first)

        let latest = snapshot(key: "mouse-2", percent: 71, hours: 20)
        store.save(latest)
        XCTAssertEqual(store.load(), latest)

        store.clear()
        XCTAssertNil(store.load())
    }

    func testRejectsInvalidSnapshotInsteadOfPersistingIt() throws {
        let (store, defaults, suiteName) = try makeStore()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        store.save(snapshot(percent: 101), force: true)

        XCTAssertNil(store.load())
        XCTAssertNil(defaults.data(forKey: LastBatterySnapshotStore.storageKey))
    }

    func testFormatsTheSavedEstimateWithoutAdvancingIt() {
        let observedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let saved = snapshot(hours: 39.5, at: observedAt)

        XCTAssertEqual(saved.estimateText, "~1d 15h left (est.)")
        XCTAssertEqual(saved.observedAt, observedAt)
    }
}
