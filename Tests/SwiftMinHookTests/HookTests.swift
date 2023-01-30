import XCTest
import WinSDK
@testable import SwiftMinHook

final class HookTests: XCTestCase {
    fileprivate static var hookedFunctionCalled = false

    override func setUp() {
        XCTAssertNoThrow(try Hook.setHookingEnabled(true))
    }

    override func tearDown() {
        XCTAssertNoThrow(try Hook.setHookingEnabled(false))
    }

    func testHook() {
        let dm = getProcAddress(moduleName: "USER32", procName: "DestroyMenu")
        XCTAssertNotNil(dm)
        do {
            let hook = try Hook(targetAddress: dm!, detour: _hookedDestroyMenu)
            originDestroyMenu = hook.trampoline

            XCTAssertNoThrow(try hook.enable())

            let hmenu = CreateMenu()
            DestroyMenu(hmenu)

            XCTAssertTrue(HookTests.hookedFunctionCalled)

            XCTAssertNoThrow(try hook.disable())
        } catch {
            XCTAssert(false, "Can install hook. \(error)")
        }
    }
}

typealias DestroyMenuFunction = (@convention(c) (HMENU?) -> Bool)

var originDestroyMenu: DestroyMenuFunction? = nil

var _hookedDestroyMenu: DestroyMenuFunction = { handle in
    HookTests.hookedFunctionCalled = true
    return originDestroyMenu?(handle) ?? false
}

func getProcAddress(moduleName: String, procName: LPCSTR) -> UnsafeMutableRawPointer? {
    guard let module = moduleName.withWideChars({ GetModuleHandleW($0) }) else { return nil }
    guard let address = GetProcAddress(module, procName) else { return nil }
    return unsafeBitCast(address, to: UnsafeMutableRawPointer.self)
}

extension String {
  /// Calls the given closure with a pointer to the contents of the string,
  /// represented as a null-terminated wchar_t array.
  func withWideChars<Result>(_ body: (UnsafePointer<wchar_t>) throws -> Result) rethrows -> Result {
      let u32 = self.unicodeScalars.map { wchar_t(bitPattern: Int16($0.value)) } + [0]
      return try u32.withUnsafeBufferPointer { try body($0.baseAddress!) }
  }
}