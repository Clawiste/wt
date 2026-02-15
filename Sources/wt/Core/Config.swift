import Foundation
import Noora
import TOML

struct WtConfig: Sendable {
    let repoPrefix: String
    let requiredFiles: [String]
    let branchTypes: [String]
    let postCreate: String?

    static let defaultBranchTypes = ["fix", "feat", "docs", "infra", "chore"]

    static func load(repoRoot: String) -> WtConfig {
        let configPath = "\(repoRoot)/.worktree-cli"
        let directoryName = (repoRoot as NSString).lastPathComponent

        guard
            FileManager.default.fileExists(atPath: configPath),
            let tomlString = try? String(contentsOfFile: configPath, encoding: .utf8)
        else {
            return WtConfig(
                repoPrefix: directoryName,
                requiredFiles: [],
                branchTypes: defaultBranchTypes,
                postCreate: nil
            )
        }

        do {
            let decoded = try TOMLDecoder().decode(RawConfig.self, from: tomlString)
            return WtConfig(
                repoPrefix: decoded.repoPrefix ?? directoryName,
                requiredFiles: decoded.requiredFiles ?? [],
                branchTypes: decoded.branchTypes ?? defaultBranchTypes,
                postCreate: decoded.postCreate
            )
        } catch {
            Noora().warning("Failed to parse .worktree-cli: \(error.localizedDescription)")
            return WtConfig(
                repoPrefix: directoryName,
                requiredFiles: [],
                branchTypes: defaultBranchTypes,
                postCreate: nil
            )
        }
    }
}

private struct RawConfig: Decodable {
    let repoPrefix: String?
    let requiredFiles: [String]?
    let branchTypes: [String]?
    let postCreate: String?

    enum CodingKeys: String, CodingKey {
        case repoPrefix = "repo_prefix"
        case requiredFiles = "required_files"
        case branchTypes = "branch_types"
        case postCreate = "post_create"
    }
}
