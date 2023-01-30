@_implementationOnly import MinHook

public final class Hook<CFunction> {
    private let target: UnsafeMutableRawPointer

    public let trampoline: CFunction

    convenience init(target: CFunction, detour: CFunction) throws {
        var targetCopy = target
        try self.init(targetAddress: &targetCopy, detour: detour)
    }

    init(targetAddress: UnsafeRawPointer, detour: CFunction) throws {
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

    func enable() throws {
        try withCheckedAPICall { MH_EnableHook(target) }
    }

    func disable() throws {
        try withCheckedAPICall { MH_DisableHook(target) }
    }

    private func queueEnable() throws {
        try withCheckedAPICall { MH_QueueEnableHook(target) }
    }

    private func queueDisable() throws {
        try withCheckedAPICall { MH_QueueDisableHook(target) }
    }
}

extension Hook where CFunction == Void {
    public static func setHookingEnabled(_ value: Bool) throws {
        try withCheckedAPICall { value ? MH_Initialize() : MH_Uninitialize() }
    }

    public static func batch(enable: [Hook], disable: [Hook]) throws {
        try enable.forEach { try $0.queueEnable() }
        try disable.forEach { try $0.queueDisable() }

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
        throw MinHookError(code: .init(rawValue: status.rawValue)!, description: "")
    }
}