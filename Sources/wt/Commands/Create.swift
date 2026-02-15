import ArgumentParser
import Foundation
import Noora

struct Create: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Create a new worktree."
    )

    @Option(name: [.short, .long], help: "Branch prefix type (e.g. fix, feat, docs).")
    var type: String?

    @Option(name: [.short, .long], help: "Feature name for the branch.")
    var name: String?

    @Option(name: [.short, .long], help: "Base branch to create from.")
    var base: String?

    @Flag(name: [.short, .long], help: "Use an existing branch instead of creating a new one.")
    var existing = false

    @Flag(name: .long, help: "Skip copying required files.")
    var noCopy = false

    func run() throws {
        let context = WtContext.resolve()

        if existing {
            CreateWorktree.existingBranchFlow(context: context)
        } else {
            CreateWorktree.newBranchFlow(
                context: context,
                type: type,
                name: name,
                base: base,
                skipCopy: noCopy
            )
        }
    }
}

enum CreateWorktree {
    static func interactiveCreate(context: WtContext) {
        let mode: BranchMode = context.noora.singleChoicePrompt(
            title: "Branch",
            question: "New branch or existing?"
        )

        switch mode {
        case .new:
            newBranchFlow(context: context, type: nil, name: nil, base: nil, skipCopy: false)
        case .existing:
            existingBranchFlow(context: context)
        }
    }

    static func newBranchFlow(
        context: WtContext,
        type: String?,
        name: String?,
        base: String?,
        skipCopy: Bool
    ) {
        let prefix: String
        if let type {
            prefix = type
        } else {
            let branchTypes = context.config.branchTypes + ["custom"]

            let selected: String = context.noora.singleChoicePrompt(
                title: "Type",
                question: "Type of change?",
                options: branchTypes
            )

            if selected == "custom" {
                prefix = context.noora.textPrompt(
                    prompt: "Custom branch prefix?",
                    validationRules: [NonEmptyValidationRule(error: "Prefix cannot be empty.")]
                )
            } else {
                prefix = selected
            }
        }

        let featureName: String
        if let name {
            featureName = name
        } else {
            featureName = context.noora.textPrompt(
                prompt: "Feature name?",
                description: "e.g. my-feature, login-redesign",
                validationRules: [
                    NonEmptyValidationRule(error: "Feature name cannot be empty."),
                    RegexValidationRule(
                        pattern: "^[a-zA-Z0-9_-]+$",
                        error: "Only letters, numbers, hyphens, and underscores allowed."
                    ),
                ]
            )
        }

        let baseBranch: String
        if let base {
            baseBranch = base
        } else {
            let branches: [String]
            do {
                branches = try context.git.baseBranches()
            } catch {
                context.noora.error("Failed to list branches: \(error.localizedDescription)")
                return
            }

            baseBranch = context.noora.singleChoicePrompt(
                title: "Base",
                question: "Base branch?",
                options: branches,
                filterMode: .toggleable
            )
        }

        let branch = "\(prefix)/\(featureName)"
        let path = context.manager.worktreePath(for: branch)

        do {
            context.noora.passthrough(
                "\n\(.muted("Creating worktree at")) \(.primary(path)) \(.muted("from")) \(.primary(baseBranch))\(.muted("..."))"
            )
            try context.git.addWorktree(newBranch: branch, path: path, base: baseBranch)
        } catch {
            context.noora.error(.alert(
                "Failed to create worktree",
                takeaways: ["\(.danger(error.localizedDescription))"]
            ))
            return
        }

        if !skipCopy {
            context.manager.copyRequiredFiles(to: path)
        }

        context.manager.runPostCreateHook(in: path)
        context.manager.writeCdFile(path: path)
        context.noora.success(.alert("Worktree ready at \(.primary(path))"))
    }

    static func existingBranchFlow(context: WtContext) {
        let branches: [String]
        do {
            branches = try context.git.availableBranches()
        } catch {
            context.noora.error("No branches available: \(error.localizedDescription)")
            return
        }

        guard !branches.isEmpty else {
            context.noora.info("No available branches found.")
            return
        }

        let selectedBranch = context.noora.singleChoicePrompt(
            question: "Which branch?",
            options: branches,
            filterMode: .toggleable
        )

        let cleanBranch: String
        if selectedBranch.hasPrefix("remotes/origin/") {
            cleanBranch = String(selectedBranch.dropFirst("remotes/origin/".count))
        } else {
            cleanBranch = selectedBranch
        }

        let path = context.manager.worktreePath(for: cleanBranch)

        do {
            context.noora.passthrough(
                "\n\(.muted("Creating worktree at")) \(.primary(path))\(.muted("..."))"
            )
            try context.git.addWorktree(path: path, branch: cleanBranch)
        } catch {
            context.noora.error(.alert(
                "Failed to create worktree",
                takeaways: ["\(.danger(error.localizedDescription))"]
            ))
            return
        }

        context.manager.copyRequiredFiles(to: path)
        context.manager.runPostCreateHook(in: path)
        context.manager.writeCdFile(path: path)
        context.noora.success(.alert("Worktree ready at \(.primary(path))"))
    }
}

enum BranchMode: String, CaseIterable, CustomStringConvertible {
    case new
    case existing

    var description: String {
        switch self {
        case .new: "Create new branch"
        case .existing: "Use existing branch"
        }
    }
}
