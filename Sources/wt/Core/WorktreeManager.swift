import Foundation
import Noora

struct WorktreeManager: Sendable {
    let noora: Noora
    let git: Git
    let config: WtConfig
    let repoRoot: String

    var parentDir: String {
        (repoRoot as NSString).deletingLastPathComponent
    }

    func worktreePath(for branch: String) -> String {
        let sanitized = branch.replacingOccurrences(of: "/", with: "-")
        let folderName = "\(config.repoPrefix)-\(sanitized)"
        return "\(parentDir)/\(folderName)"
    }

    func copyRequiredFiles(to path: String) {
        guard !config.requiredFiles.isEmpty else { return }
        noora.passthrough("\n\(.muted("Copying required files..."))")
        let copier = FileCopier(noora: noora)
        copier.copy(files: config.requiredFiles, from: repoRoot, to: path)
    }

    func runPostCreateHook(in path: String) {
        guard let postCreate = config.postCreate else { return }
        noora.passthrough("\n\(.muted("Running post-create hook..."))")
        let shell = Shell()
        do {
            try shell.run("cd \"\(path)\" && \(postCreate)")
            noora.passthrough("  \(.success("✓")) \(.muted(postCreate))")
        } catch {
            noora.passthrough("  \(.danger("⚠")) \(.muted("Hook failed: \(error.localizedDescription)"))")
        }
    }

    func writeCdFile(path: String) {
        try? path.write(toFile: "/tmp/.wt-cd", atomically: true, encoding: .utf8)
    }
}
