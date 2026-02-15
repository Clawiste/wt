import Foundation
import Noora

struct FileCopier: Sendable {
    let noora: Noora

    func copy(files: [String], from repoRoot: String, to worktreePath: String) {
        for file in files {
            let source = "\(repoRoot)/\(file)"
            let destination = "\(worktreePath)/\(file)"
            let destinationDir = (destination as NSString).deletingLastPathComponent

            do {
                try FileManager.default.createDirectory(
                    atPath: destinationDir,
                    withIntermediateDirectories: true
                )
                if FileManager.default.fileExists(atPath: source) {
                    try FileManager.default.copyItem(atPath: source, toPath: destination)
                    noora.passthrough("  \(.success("✓")) \(.muted(file))")
                } else {
                    noora.passthrough("  \(.danger("⚠")) \(.muted("\(file) (not found, skipping)"))")
                }
            } catch {
                noora.passthrough("  \(.danger("⚠")) \(.muted("\(file) (\(error.localizedDescription))"))")
            }
        }
    }
}
