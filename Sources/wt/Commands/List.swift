import ArgumentParser
import Noora

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List active worktrees."
    )

    func run() throws {
        let context = WtContext.resolve()
        ListWorktrees.printList(context: context)
    }
}

enum ListWorktrees {
    static func printList(context: WtContext) {
        let worktrees: [Worktree]
        do {
            worktrees = try context.git.listWorktrees(repoPrefix: context.config.repoPrefix)
        } catch {
            context.noora.error("Failed to list worktrees: \(error.localizedDescription)")
            return
        }

        guard !worktrees.isEmpty else {
            context.noora.info("No active worktrees.")
            return
        }

        context.noora.passthrough("\n\(.primary("Active worktrees:"))\n")

        let maxName = worktrees.map(\.name.count).max() ?? 0

        for worktree in worktrees {
            let padded = worktree.name.padding(toLength: maxName + 2, withPad: " ", startingAt: 0)
            context.noora.passthrough("  \(.success("●")) \(padded)\(.muted(worktree.path))")
        }

        context.noora.passthrough("")
    }
}
