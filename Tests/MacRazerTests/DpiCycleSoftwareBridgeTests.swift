// SPDX-License-Identifier: GPL-2.0-or-later
// Part of MacRazer, a control app for Razer mice on macOS. See LICENSE and NOTICE.md.

import XCTest
import CoreGraphics
@testable import MacRazer

final class DpiCycleSoftwareBridgeTests: XCTestCase {
    private func remapper(_ suite: String = #function) -> (ButtonRemapper, UserDefaults) {
        let defaults = UserDefaults(suiteName: "MacRazerTests.\(suite)")!
        defaults.removePersistentDomain(forName: "MacRazerTests.\(suite)")
        return (ButtonRemapper(defaults: defaults), defaults)
    }

    func testSoftwareActionIsPerDeviceAndPersists() {
        let (first, defaults) = remapper()
        first.setActiveDevice("PM2533", deviceID: 0x00BA)
        let action = RemapAction.mediaKey(code: 16, name: "Play / Pause")
        first.saveDpiSoftwareAction(action)

        let second = ButtonRemapper(defaults: defaults)
        second.setActiveDevice("PM2533", deviceID: 0x00BA)
        XCTAssertEqual(second.dpiCycleSoftwareAction, action)
        second.saveDpiSoftwareAction(nil)
        XCTAssertNil(defaults.data(forKey: "dpiCycleSoftwareAction-PM2533"))
    }

    func testBridgeConfirmationAndRestoreGate() {
        let (remapper, _) = remapper()
        remapper.setActiveDevice("PM2533", deviceID: 0x00BA)
        XCTAssertFalse(remapper.shouldRestoreDpiBridge(binding: .dpiCycle, connected: true,
                                                       bluetooth: true, alreadyAttempted: false))
        remapper.saveDpiSoftwareAction(.mediaKey(code: 16, name: "Play / Pause"))
        XCTAssertTrue(remapper.shouldRestoreDpiBridge(binding: .dpiCycle, connected: true,
                                                      bluetooth: true, alreadyAttempted: false))
        remapper.confirmDpiBridge(binding: .softwareBridge)
        XCTAssertTrue(remapper.dpiBridgeBindingConfirmed)
        remapper.confirmDpiBridge(binding: .dpiCycle)
        XCTAssertFalse(remapper.dpiBridgeBindingConfirmed)
    }

    func testKeyboardTapMaskIsOptIn() {
        let mouseOnly = CGEventMask(1 << CGEventType.otherMouseDown.rawValue)
        let keyboard = mouseOnly | CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.keyUp.rawValue)
        XCTAssertFalse(ButtonRemapper.includesKeyboardEvents(mouseOnly))
        XCTAssertTrue(ButtonRemapper.includesKeyboardEvents(keyboard))
    }
}
