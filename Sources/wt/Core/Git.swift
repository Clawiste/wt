import Foundation

struct Worktree: Equatable, CustomStringConvertible {
    let path: String
    let name: String
    let branch: String

    var description: String { name }
}

struct Git: Sendable {
    let shell: Shell
    let repoRoot: String

    private var git: String { "git -C \"\(repoRoot)\"" }

    func addWorktree(newBranch: String, path: String, base: String) throws {
        try shell.run("\(git) worktree add -b \"\(newBranch)\" \"\(path)\" \"\(base)\"")
    }

    func addWorktree(path: String, branch: String) throws {
        try shell.run("\(git) worktree add \"\(path)\" \"\(branch)\"")
    }

    func removeWorktree(path: String) throws {
        try shell.run("\(git) worktree remove \"\(path)\"")
    }

    func currentBranch() throws -> String {
        try shell.run("\(git) rev-parse --abbrev-ref HEAD")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func baseBranches() throws -> [String] {
        let current = (try? currentBranch()) ?? "main"

        let output = try shell.run("\(git) branch --format='%(refname:short)'")
        var branches = output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        branches.removeAll { $0 == current }
        branches.insert(current, at: 0)

        return branches
    }

    func availableBranches() throws -> [String] {
        let worktreeOutput = try shell.run("\(git) worktree list --porcelain")
        let checkedOutBranches = worktreeOutput
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix("branch ") }
            .map { $0.replacingOccurrences(of: "branch refs/heads/", with: "") }

        let localOutput = try shell.run("\(git) branch --format='%(refname:short)'")
        let localBranches = localOutput
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }

        let remoteOutput = try shell.run("\(git) branch -r --format='%(refname:short)'")
        let remoteBranches = remoteOutput
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty && !$0.contains("HEAD") }

        let localSet = Set(localBranches)
        let extraRemote = remoteBranches.filter { remote in
            let short = remote.replacingOccurrences(of: "origin/", with: "")
            return !localSet.contains(short)
        }

        let allBranches = localBranches + extraRemote
        let checkedOutSet = Set(checkedOutBranches)

        return allBranches.filter { branch in
            let short = branch.replacingOccurrences(of: "origin/", with: "")
            return !checkedOutSet.contains(short)
        }
    }

    func listWorktrees(repoPrefix: String) throws -> [Worktree] {
        let output = try shell.run("\(git) worktree list --porcelain")
        let blocks = output.components(separatedBy: "\n\n")

        var worktrees: [Worktree] = []
        for block in blocks {
            let lines = block.components(separatedBy: "\n")
            guard let worktreeLine = lines.first(where: { $0.hasPrefix("worktree ") }) else { continue }
            let path = String(worktreeLine.dropFirst("worktree ".count))
            let name = (path as NSString).lastPathComponent

            if name == repoPrefix || !name.hasPrefix("\(repoPrefix)-") {
                continue
            }

            let branch = lines
                .first { $0.hasPrefix("branch ") }
                .map { $0.replacingOccurrences(of: "branch refs/heads/", with: "") } ?? "detached"

            worktrees.append(Worktree(path: path, name: name, branch: branch))
        }

        return worktrees
    }
}
