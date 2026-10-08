// SPDX-License-Identifier: GPL-2.0-or-later
// Part of MacRazer, a control app for Razer mice on macOS. See LICENSE and NOTICE.md.

import Foundation

/// Settings MacRazer itself has successfully applied to a Basilisk V3 X HyperSpeed.
/// The mouse does not expose a complete configuration readback after reconnect, so this
/// per-device snapshot is the source for restoring only controls MacRazer owns.
struct BasiliskBluetoothSettingsSnapshot: Codable, Equatable {
    struct DPIStages: Codable, Equatable {
        var active: Int
        var values: [Int]
    }

    var dpiStages: DPIStages?
    var sleepTimeout: Int?
    var brightness: Int?

    static let empty = Self(dpiStages: nil, sleepTimeout: nil, brightness: nil)
}

struct BasiliskBluetoothSettingsStore {
    private let defaults: UserDefaults
    private let prefix = "basiliskBluetoothSettings-"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func snapshot(for deviceKey: String) -> BasiliskBluetoothSettingsSnapshot? {
        guard let data = defaults.data(forKey: prefix + deviceKey) else { return nil }
        return try? JSONDecoder().decode(BasiliskBluetoothSettingsSnapshot.self, from: data)
    }

    func update(for deviceKey: String,
                _ change: (inout BasiliskBluetoothSettingsSnapshot) -> Void) {
        var value = snapshot(for: deviceKey) ?? .empty
        change(&value)
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: prefix + deviceKey)
    }
}
