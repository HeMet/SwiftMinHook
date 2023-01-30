import XCTest
import WinSDK
@testable import MinHook

final class SwiftMinHookTests: XCTestCase {
    fileprivate static var hookedFunctionCalled = false

    override func setUp() {
        SwiftMinHookTests.hookedFunctionCalled = false
        assert(MH_Initialize() == MH_OK)
    }

    override func tearDown() {
        assert(MH_Uninitialize() == MH_OK)
    }

    func testDestroyMenu() throws {
        // let dmm = unsafeBitCast(DestroyMenu, to: UnsafeMutableRawPointer.self)
        let dm = getProcAddress(moduleName: "USER32", procName: "DestroyMenu")
        print("!!! getProcAddress: \(dm)")
        withUnsafePointer(to: DestroyMenu) { ptr in
            print("!!! withUnsafePointer(to:): \(ptr)")

            ptr.withMemoryRebound(to: UnsafeRawPointer.self, capacity: 2) { ptr2 in
                let bp = UnsafeBufferPointer(start: ptr2, count: 2)
                print("!!! bp[0]: \(bp[0]) bp[1]: \(bp[1])")
            }
        }
        XCTAssertNotNil(dm)
        let hooked: DestroyMenuFunction = _hookedDestroyMenu
        var origin: UnsafeMutableRawPointer?
        XCTAssertEqual(MH_CreateHook(dm, unsafeBitCast(hooked, to: UnsafeMutableRawPointer.self), &origin), MH_OK)
        originDestroyMenu = origin.map { unsafeBitCast($0, to: DestroyMenuFunction.self) }

        XCTAssertEqual(MH_EnableHook(dm), MH_OK)

        let hmenu = CreateMenu()
        DestroyMenu(hmenu)

        XCTAssertTrue(SwiftMinHookTests.hookedFunctionCalled)

        XCTAssertEqual(MH_DisableHook(dm), MH_OK)
    }

    func testWrapped() {
        let dm = getProcAddress(moduleName: "USER32", procName: "DestroyMenu")
        XCTAssertNotNil(dm)
        do {
            originDestroyMenu = try MH.hook(DestroyMenuFunction.self, at: dm!, with: _hookedDestroyMenu)

            XCTAssertEqual(MH_EnableHook(dm), MH_OK)

            let hmenu = CreateMenu()
            DestroyMenu(hmenu)

            XCTAssertTrue(SwiftMinHookTests.hookedFunctionCalled)

            XCTAssertEqual(MH_DisableHook(dm), MH_OK)
        } catch {
            XCTAssert(false, "Show not throw")
        }
    }
}

typealias DestroyMenuFunction = (@convention(c) (HMENU?) -> Bool)

var originDestroyMenu: DestroyMenuFunction? = nil

var _hookedDestroyMenu: DestroyMenuFunction = { handle in
    SwiftMinHookTests.hookedFunctionCalled = true
    return originDestroyMenu?(handle) ?? false
}

func isExecutableAddress(_ address: LPVOID) -> Bool {
    var mi = MEMORY_BASIC_INFORMATION();
    VirtualQuery(address, &mi, UInt64(MemoryLayout<MEMORY_BASIC_INFORMATION>.size))
    let PAGE_EXECUTE_FLAGS = PAGE_EXECUTE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY
    return mi.State == MEM_COMMIT && (mi.Protect & UInt32(PAGE_EXECUTE_FLAGS) != 0)
}

extension String {
  /// Calls the given closure with a pointer to the contents of the string,
  /// represented as a null-terminated wchar_t array.
  func withWideChars<Result>(_ body: (UnsafePointer<wchar_t>) throws -> Result) rethrows -> Result {
      let u32 = self.unicodeScalars.map { wchar_t(bitPattern: Int16($0.value)) } + [0]
      return try u32.withUnsafeBufferPointer { try body($0.baseAddress!) }
  }
}

func getProcAddress(moduleName: String, procName: LPCSTR) -> UnsafeMutableRawPointer? {
    guard let module = moduleName.withWideChars({ GetModuleHandleW($0) }) else { return nil }
    guard let address = GetProcAddress(module, procName) else { return nil }
    return unsafeBitCast(address, to: UnsafeMutableRawPointer.self)
}

enum MH {
    struct APIError: Error {
        var code: MH_STATUS
    }

    struct Generic: Error { }

    static func hook<CFunction>(_ functionType: CFunction.Type, at functionAddress: UnsafeRawPointer, with substitute: CFunction) throws -> CFunction {
        let sp = unsafeBitCast(substitute, to: UnsafeMutableRawPointer.self)
        var origin: UnsafeMutableRawPointer?
        let status = MH_CreateHook(UnsafeMutableRawPointer(mutating: functionAddress), sp, &origin)

        guard status == MH_OK else { throw APIError(code: status) }
        guard let origin else { throw Generic() }

        return unsafeBitCast(origin, to: CFunction.self)
    }
}

final class Hook {
    init<CFunction>(_ functionType: CFunction.Type, at functionAddress: UnsafeRawPointer, with substitute: CFunction) throws {
        fatalError()
    }

    func enable() { }

    func disable() { }

    static func batch(enable: [Hook], disable: [Hook]) {

    }
}