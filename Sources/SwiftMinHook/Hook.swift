@_implementationOnly import MinHook

public final class Hook<CFunction> {
    private let target: UnsafeMutableRawPointer

    public let trampoline: CFunction

    public convenience init(target: CFunction, detour: CFunction) throws {
        var targetCopy = target
        try self.init(targetAddress: &targetCopy, detour: detour)
    }

    public convenience init(moduleName: String, functionName: String, detour: CFunction) throws {
        guard let module = moduleName.withWideChars({ GetModuleHandleW($0) }) else { throw Error.moduleNotFound }
        guard let address = GetProcAddress(module, functionName) else { throw Error.functionNotFound }
        let targetPtr = unsafeBitCast(address, to: UnsafeMutableRawPointer.self)
        try self.init(targetAddress: targetPtr, detour: detour)
    }

    public init(targetAddress: UnsafeRawPointer, detour: CFunction) throws {
        let target = UnsafeMutableRawPointer(mutating: targetAddress)
        let detour = unsafeBitCast(detour, to: UnsafeMutableRawPointer.self)

        var trampoline: UnsafeMutableRawPointer?
        try withCheckedAPICall { MH_CreateHook(target, detour, &trampoline) }

        guard let trampoline else { throw Error.noTrampoline }

        self.target = target
        self.trampoline = unsafeBitCast(trampoline, to: CFunction.self)
    }

    deinit {
        do {
            try withCheckedAPICall { MH_RemoveHook(target) }
        } catch {
            fatalError("Error was thrown during Hook deinitialization: \(error)")
        }
    }

    public func enable() throws {
        try withCheckedAPICall { MH_EnableHook(target) }
    }

    public func disable() throws {
        try withCheckedAPICall { MH_DisableHook(target) }
    }

    public func queueEnable() throws {
        try withCheckedAPICall { MH_QueueEnableHook(target) }
    }

    public func queueDisable() throws {
        try withCheckedAPICall { MH_QueueDisableHook(target) }
    }
}

extension Hook where CFunction == Void {
    public static func setHookingEnabled(_ value: Bool) throws {
        try withCheckedAPICall { value ? MH_Initialize() : MH_Uninitialize() }
    }

    public static func updateAll(_ body: () throws -> Void) throws {
        try body()
        try withCheckedAPICall { MH_ApplyQueued() }
    }

    public static func enableAll() throws {
        try withCheckedAPICall { MH_EnableHook(nil) }
    }

    public static func disableAll() throws {
        try withCheckedAPICall { MH_DisableHook(nil) }
    }
}

private func withCheckedAPICall(_ body: () -> MH_STATUS) throws {
    let status = body()
    if status != MH_OK {
        let cString = MH_StatusToString(status)!
        throw MinHookError(code: .init(rawValue: status.rawValue)!, description: String(cString: cString))
    }
}

private extension String {
  func withWideChars<Result>(_ body: (UnsafePointer<wchar_t>) throws -> Result) rethrows -> Result {
      let u32 = self.unicodeScalars.map { wchar_t(bitPattern: Int16($0.value)) } + [0]
      return try u32.withUnsafeBufferPointer { try body($0.baseAddress!) }
  }
}