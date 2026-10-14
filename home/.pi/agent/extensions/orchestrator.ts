// /orchestrator on|off|status — mirrors ~/.claude/commands/orchestrator.md and
// ~/.config/opencode/agents/orchestrator.md: toggles orchestrator mode for the
// current project and, while active, injects the live Herdr layout plus the
// dev/reviewer delegation contract on every turn. Shares the same per-project
// state file (~/.claude/orchestrator-state/<sha256(cwd)>.json) so `/orchestrator
// status` agrees no matter which harness (Claude, OpenCode, or pi) is acting
// as coordinator for this project.
//
// Usage: run pi inside a Herdr pane, then `/orchestrator on`, `/orchestrator
// off`, or `/orchestrator status`. Adoption only — this never creates,
// closes, or resizes panes; it just delegates to whatever sibling panes are
// already running next to it.

import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATE_DIR = path.join(os.homedir(), ".claude", "orchestrator-state");
const LAYOUT_SCRIPT = path.join(os.homedir(), ".claude", "scripts", "herdr-layout-context.py");

const CONTRACT = `Orchestrator ACTIVE (🎭 ORCHESTRATOR). The live Herdr layout is injected below on every turn — use it, and do not re-run \`herdr pane layout\` unless it is missing. Do not reuse pane IDs from earlier turns. Never create, close, split, resize, restart, respawn, or reconfigure panes or agents.

Assign roles from the injected layout:
- Two or more sibling panes: leftmost sibling = dev, next sibling = reviewer. Ignore the rest.
- One sibling pane: it is the dev; you are also the reviewer.
- No sibling panes: implement, verify, and review yourself.

Use the agent and model already running in each pane as-is; do not inspect or change its kind or model.

For each task: delegate implementation to the dev pane (or do it yourself), resolve blockers, verify the diff/status/focused tests, then send the diff to the reviewer pane (or review it yourself) defect-first with severity and file:line, plus a security pass covering auth, injection, secrets/data exposure, unsafe file/command/network access, and dependency/config risks. Report \`Security: no findings\` when clean; critical/high findings block completion unless the user accepts the risk.

Delegate with \`herdr agent prompt <pane-id> "<task>" --wait --until idle --until done --until blocked --timeout 300000\` and read progress with \`herdr agent read <pane-id> --lines 200\`.

Never read credentials.json. Preserve unrelated changes; never approve destructive actions, secrets, publishing, commits, or pushes without explicit user authorization. Turn off with /orchestrator off.`;

type OrchestratorState = {
  active?: boolean;
  panes?: { coordinator?: { pane_id?: string } };
  [key: string]: unknown;
};

function stateFile(cwd: string): string {
  const hash = createHash("sha256").update(cwd).digest("hex");
  return path.join(STATE_DIR, `${hash}.json`);
}

function readState(cwd: string): OrchestratorState {
  try {
    return JSON.parse(fs.readFileSync(stateFile(cwd), "utf8"));
  } catch {
    return { active: false };
  }
}

function writeState(cwd: string, state: OrchestratorState): void {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(stateFile(cwd), JSON.stringify(state, null, 2));
}

function layoutContext(): string {
  if (process.env.HERDR_ENV !== "1") return "";
  try {
    return execFileSync("python3", [LAYOUT_SCRIPT], {
      encoding: "utf8",
      timeout: 5000,
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return "";
  }
}

function isCoordinatorHere(state: OrchestratorState): boolean {
  const pane = process.env.HERDR_PANE_ID;
  const coordPane = state.panes?.coordinator?.pane_id;
  if (!pane || !coordPane) return true;
  return pane === coordPane;
}

function refreshBadge(ctx: ExtensionContext, state: OrchestratorState): void {
  if (state.active && isCoordinatorHere(state)) {
    const theme = ctx.ui.theme;
    ctx.ui.setStatus("orchestrator", theme.fg("accent", "🎭 ORCHESTRATOR"));
  } else {
    ctx.ui.setStatus("orchestrator", undefined);
  }
}

export default function orchestrator(pi: ExtensionAPI) {
  pi.registerCommand("orchestrator", {
    description: "Toggle orchestrator mode (on/off/status) for this project",
    handler: async (args, ctx) => {
      const action = (args || "").trim().toLowerCase() || "on";
      const state = readState(ctx.cwd);

      if (action === "on") {
        state.active = true;
        const pane = process.env.HERDR_PANE_ID;
        if (pane) {
          state.panes = { ...state.panes, coordinator: { pane_id: pane } };
        }
        writeState(ctx.cwd, state);
        refreshBadge(ctx, state);
        ctx.ui.notify("🎭 Orchestrator mode ON for this project.", "info");
        return;
      }

      if (action === "off") {
        state.active = false;
        writeState(ctx.cwd, state);
        refreshBadge(ctx, state);
        ctx.ui.notify("Orchestrator mode OFF for this project.", "info");
        return;
      }

      if (action === "status") {
        ctx.ui.notify(
          `Orchestrator: ${state.active ? "ON" : "OFF"}\n${JSON.stringify(state, null, 2)}`,
          "info",
        );
        return;
      }

      ctx.ui.notify(`Unknown action "${action}". Use on, off, or status.`, "warning");
    },
  });

  pi.on("session_start", (_event, ctx) => {
    refreshBadge(ctx, readState(ctx.cwd));
  });

  pi.on("before_agent_start", (event, ctx) => {
    const state = readState(ctx.cwd);
    refreshBadge(ctx, state);
    if (!state.active) return;

    const parts = [CONTRACT, layoutContext()].filter(Boolean);
    const existing = event.systemPromptOptions.appendSystemPrompt ?? "";
    event.systemPromptOptions.appendSystemPrompt = existing
      ? `${existing}\n\n${parts.join("\n\n")}`
      : parts.join("\n\n");
  });
}
