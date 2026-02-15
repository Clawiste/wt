import Foundation

enum ShellError: LocalizedError {
    case commandFailed(command: String, output: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(_, output):
            return output
        }
    }
}

struct Shell: Sendable {
    @discardableResult
    func run(_ command: String) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw ShellError.commandFailed(command: command, output: output)
        }

        return output
    }
}
