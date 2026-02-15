import ArgumentParser
import Foundation
import Noora

@main
struct Wt: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wt",
        abstract: "Interactive git worktree manager.",
        discussion: """
        Run without arguments for the full interactive menu, \
        or use a subcommand to jump directly to an action.

        Shell integration (add to ~/.zshrc or ~/.bashrc):

          wt() {
              command wt "$@"
              if [ -f /tmp/.wt-cd ]; then
                  dir=$(cat /tmp/.wt-cd)
                  rm -f /tmp/.wt-cd
                  cd "$dir" || return
              fi
          }
        """,
        version: "1.0.0",
        subcommands: [Create.self, Delete.self, List.self]
    )

    func run() throws {
        let context = WtContext.resolve()

        let action: Action = context.noora.singleChoicePrompt(
            title: "Worktree",
            question: "What would you like to do?"
        )

        switch action {
        case .create:
            CreateWorktree.interactiveCreate(context: context)
        case .delete:
            DeleteWorktree.interactiveDelete(context: context)
        case .list:
            ListWorktrees.printList(context: context)
        }
    }
}

enum Action: String, CaseIterable, CustomStringConvertible {
    case create
    case delete
    case list

    var description: String {
        switch self {
        case .create: "Create a new worktree"
        case .delete: "Delete a worktree"
        case .list: "List worktrees"
        }
    }
}

struct WtContext: Sendable {
    let noora: Noora
    let git: Git
    let config: WtConfig
    let manager: WorktreeManager
    let repoRoot: String

    static func resolve() -> WtContext {
        let shell = Shell()
        let repoRoot = (try? shell.run("git rev-parse --show-toplevel"))
            ?? FileManager.default.currentDirectoryPath
        let noora = Noora()
        let config = WtConfig.load(repoRoot: repoRoot)
        let git = Git(shell: shell, repoRoot: repoRoot)
        let manager = WorktreeManager(noora: noora, git: git, config: config, repoRoot: repoRoot)

        return WtContext(
            noora: noora,
            git: git,
            config: config,
            manager: manager,
            repoRoot: repoRoot
        )
    }
}
