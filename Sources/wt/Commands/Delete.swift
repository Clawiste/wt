import ArgumentParser
import Noora

struct Delete: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Delete a worktree."
    )

    @Argument(help: "Name of the worktree to delete.")
    var worktreeName: String?

    func run() throws {
        let context = WtContext.resolve()

        if let worktreeName {
            DeleteWorktree.directDelete(context: context, name: worktreeName)
        } else {
            DeleteWorktree.interactiveDelete(context: context)
        }
    }
}

enum DeleteWorktree {
    static func interactiveDelete(context: WtContext) {
        let worktrees: [Worktree]
        do {
            worktrees = try context.git.listWorktrees(repoPrefix: context.config.repoPrefix)
        } catch {
            context.noora.error("Failed to list worktrees: \(error.localizedDescription)")
            return
        }

        guard !worktrees.isEmpty else {
            context.noora.info("No worktrees to remove.")
            return
        }

        let selected = context.noora.singleChoicePrompt(
            title: "Worktree",
            question: "Which worktree to remove?",
            options: worktrees,
            filterMode: .toggleable
        )

        confirmAndDelete(context: context, worktree: selected)
    }

    static func directDelete(context: WtContext, name: String) {
        let worktrees: [Worktree]
        do {
            worktrees = try context.git.listWorktrees(repoPrefix: context.config.repoPrefix)
        } catch {
            context.noora.error("Failed to list worktrees: \(error.localizedDescription)")
            return
        }

        guard let worktree = worktrees.first(where: { $0.name == name }) else {
            context.noora.error("Worktree '\(name)' not found.")
            return
        }

        confirmAndDelete(context: context, worktree: worktree)
    }

    private static func confirmAndDelete(context: WtContext, worktree: Worktree) {
        let confirmed = context.noora.yesOrNoChoicePrompt(
            question: "Remove worktree \(.danger(worktree.name))?"
        )

        guard confirmed else {
            context.noora.info("Cancelled.")
            return
        }

        do {
            try context.git.removeWorktree(path: worktree.path)
            context.noora.success(.alert("Worktree \(.primary(worktree.name)) removed."))
        } catch {
            context.noora.error(.alert(
                "Failed to remove worktree",
                takeaways: ["\(.danger(error.localizedDescription))"]
            ))
        }
    }
}
