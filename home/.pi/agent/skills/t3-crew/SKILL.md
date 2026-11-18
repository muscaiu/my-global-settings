---
name: t3-crew
description: Turns on crew mode: a preset crew of subagents (dev, dev + reviewer, or dev + tester + reviewer) from any provider, run as T3 child tasks, for every request until turned off. Asks which preset and which model each agent uses. User-invoked only.
disable-model-invocation: true
---

# t3-crew

Opt-in. Nothing happens until the user runs `/skill:t3-crew`. Fixed choices, never asked: agents are always T3 child tasks (`delegate_task`, async), always in the current checkout (no worktrees, no separate threads), at most 2 fix rounds. This thread is the orchestrator (pi); there is no orchestrator subagent.

Arguments (whatever the user typed after `/skill:t3-crew`):
- empty: run the wizard, then wait for the task.
- text: run the wizard, then use the text as the first task.
- `last`: skip the wizard and use `~/.claude/t3-crew/last.json` (shared by every harness). If it is missing, run the wizard.
- `off`: crew mode is off. Remove the head-icon prefix from this thread's title (see section 3), say `👥 T3-CREW off`, stop using the banner, and work directly again. Stop here.

## 1. Load

The T3 tools come from the `t3-code` MCP server: `orchestrator_capabilities`, `delegate_task`, `task_status`, `task_cancel`, `t3_thread_update`, `t3_thread_read`. Call them through whatever MCP mechanism pi gives you (load their schemas first if your harness defers them). Call `orchestrator_capabilities` for the live model catalog. If a T3 tool is missing, say so and stop; never fake the crew with pi's own subagents.

## 2. Wizard (two question rounds)

Use your structured question tool if you have one; otherwise ask in plain text with numbered options (the user can also answer with free text) and wait for the reply before moving on.

**Round 1: preset.** One question with three options. The preset fixes the roles, so roles are never asked:

| Preset | Roles | Use for |
|---|---|---|
| Dev + reviewer (recommended) | dev, reviewer | Most feature work and refactors. |
| Dev | dev | Small or low-risk changes. |
| Dev + tester + reviewer | dev, tester, reviewer | Riskier logic, bug fixes that need a regression test, anything user-facing or hard to undo. |

**Round 2: one model question per agent**, all asked together. Title each question with the role. Model options come from the live catalog: one model per enabled provider (skip any provider with `canRunChildTask: false` or no models). Aim for Anthropic (`claudeAgent`), OpenAI (`codex`), and Cursor (`cursor`), so three options plus free text for anything else. For each provider pick its most capable-looking listed model (for Cursor, skip the generic `default`/Auto entry). Put the provider and model name in each label and keep default options. Mark one as recommended: for the dev, this thread's own provider; for the reviewer and the tester, a provider different from the dev's, so their checks are independent.

No confirm step. The answers are the confirmation. Save them to `~/.claude/t3-crew/last.json` (create the directory) as a list of `{role, providerInstanceId, model}`, never the task.

## 3. Crew mode is now on

Make the mode visible in two places:

- **Thread title (always visible in the sidebar):** read this thread's current title with `t3_thread_read` (`threadId` is this thread, found as `parentThreadId` in the `orchestrator_capabilities` result), then `t3_thread_update` with `action: rename` and the title prefixed with one `👤` per agent in the crew plus a space (1 agent `👤`, 2 agents `👤👤`, 3 agents `👤👤👤`). If the title already starts with such a prefix (including the old `👥 `), replace it rather than stacking. On `off`, rename it back with the whole prefix removed. If the title was regenerated and lost the prefix, re-apply it on the next reply.
- **Banner (every reply):** until the user runs `/skill:t3-crew off`, every reply in this thread starts with this banner on its own line:

`👥 T3-CREW · <role>: <model> · <role>: <model> ...` (every agent, in table order)

If there is no task yet, print the banner and say "Crew is on. Send your task." and stop. A request that is only a question, or a one-line change, is not worth a crew: do it directly, keep the banner, and say the crew was skipped.

## 4. Per request

1. **Dev.** `delegate_task` with `role: implementation`, `mode: async`, `isolation: shared`, the dev's target, and a stable `clientRequestId`. The brief is self-contained: the task, repo conventions, what to run (lint, type-check, build or tests), and that the dev works in the current checkout, creates a feature branch off the current HEAD first if on the default branch, commits, and does not push or open a PR. End the turn and wait for the completion notification; do not poll.
2. **Tester** (if in the crew). After the dev result is in, `delegate_task` with `role: test`, `isolation: shared`, the tester's target, and a brief with the original task, the branch and commit, and the dev's summary. It exercises the change: runs lint, type-check, build and the existing tests, adds focused tests for the new behavior and edge cases where the repo has a test setup (if it has none, it checks by running the app and says so instead of adding a framework), and commits any tests it adds on the same branch. It does not change production code. It reports what it ran, what failed with a reproduction, and what it could not check.
3. **Reviewer** (if in the crew). After the dev (and tester) results are in, `delegate_task` with `role: review`, `isolation: shared`, the reviewer's target, and a brief with the original task, the branch and commit, and the earlier summaries. It reviews `git diff <base>...HEAD` in the same checkout, edits nothing, runs the checks, and returns findings ranked by severity with file:line and a concrete fix, separating real defects from nitpicks.
4. **Triage.** Read the tester's failures and the reviewer's findings. Pass on only the real ones plus anything cheap and clearly right. Drop findings that contradict the user's request, and say which and why.
5. **Fix round.** A new `delegate_task` to the dev each time (tasks do not remember earlier rounds), repeating the original brief, the earlier findings, and the responses, with a distinct `clientRequestId`. Re-run the tester and reviewer as needed. Stop when there are no blocking issues or after 2 fix rounds; if blocking issues remain at the cap, say so plainly.
6. **Report.** The banner, then: branch and commit SHAs, files changed, what each stage found and what was acted on, which checks were actually run, what was not verified, and what is left for the user. Never push or open a PR unless asked.

## Rules

- Keep the user's model choice exactly. If a model or option is unavailable, report it instead of substituting.
- If a task is interrupted, say so, report the checkout state (branch, uncommitted changes), and ask before resuming or discarding.
- `task_cancel` runaway tasks and tell the user.
