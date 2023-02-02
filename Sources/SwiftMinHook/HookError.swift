@_implementationOnly import MinHook

public struct MinHookError: Swift.Error {
    public enum Code: Int32 {
        case unknown = -1
        case alreadyInitialized = 1
        case notInitialized

        case alreadyCreated
        case notCreated

        case alreadyEnabled
        case disabled

        case notExecutable
        case unsupportedFunction
        case memoryAlloc
        case memoryProtect
        case moduleNotFound
        case functionNotFound
    }

    public var code: Code
    public var description: String

    public init(code: Code, description: String) {
        self.code = code
        self.description = description
    }
}

public enum Error: Swift.Error {
    case noTrampoline
    case moduleNotFound
    case functionNotFound
}
