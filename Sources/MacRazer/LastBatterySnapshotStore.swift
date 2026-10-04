// SPDX-License-Identifier: GPL-2.0-or-later
// Part of MacRazer, a control app for Razer mice on macOS. See LICENSE and NOTICE.md.

import Foundation

/// The last trusted battery reading, kept separately from the bounded discharge history so
/// the popover can still show a useful, explicitly stale reference while the mouse is away.
struct LastBatterySnapshot: Codable, Equatable {
    let deviceKey: String
    let productID: Int
    let deviceName: String
    let percent: Int
    let observedAt: Date
    let estimatedHoursRemaining: Double?
    let wasCharging: Bool

    var estimateText: String? {
        guard let hours = estimatedHoursRemaining, hours.isFinite, hours >= 0 else { return nil }
        return "~\(BatteryHistory.formatDuration(hours: hours)) left (est.)"
    }

    var isValid: Bool {
        !deviceKey.isEmpty && !deviceName.isEmpty && (0...100).contains(percent)
            && (estimatedHoursRemaining.map { $0.isFinite && $0 >= 0 } ?? true)
    }
}

/// Stores one latest snapshot, not a time series. Updates are throttled to avoid writing
/// preferences on every battery poll; meaningful state changes and shutdown/sleep are saved
/// immediately.
final class LastBatterySnapshotStore {
    static let storageKey = "lastBatterySnapshot.v1"
    static let saveInterval: TimeInterval = 5 * 60

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> LastBatterySnapshot? {
        guard let data = defaults.data(forKey: Self.storageKey),
              let snapshot = try? decoder.decode(LastBatterySnapshot.self, from: data),
              snapshot.isValid else { return nil }
        return snapshot
    }

    func save(_ snapshot: LastBatterySnapshot, force: Bool = false) {
        guard snapshot.isValid else { return }
        let previous = load()
        let stateChanged = previous.map {
            $0.deviceKey != snapshot.deviceKey || $0.productID != snapshot.productID
                || $0.deviceName != snapshot.deviceName || $0.percent != snapshot.percent
                || $0.wasCharging != snapshot.wasCharging
                || estimateChanged($0.estimatedHoursRemaining, snapshot.estimatedHoursRemaining)
        } ?? true
        guard force || stateChanged
                || Date().timeIntervalSince(previous?.observedAt ?? .distantPast) >= Self.saveInterval else { return }
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func estimateChanged(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return false
        case (.some, nil), (nil, .some): return true
        case let (.some(a), .some(b)): return abs(a - b) >= 1
        }
    }
}
