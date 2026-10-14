#!/usr/bin/env python3
"""Emit a compact Herdr layout role assignment for orchestrator hooks.

Prints plain text to stdout, or exits 0 with no output when Herdr/layout is
unavailable. Never raises — hooks must fail open.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys


def run_json(args: list[str]) -> dict | None:
    try:
        proc = subprocess.run(
            args,
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None


def layout_payload() -> dict | None:
    herdr = shutil.which("herdr")
    if not herdr:
        return None
    pane = os.environ.get("HERDR_PANE_ID", "").strip()
    if pane:
        data = run_json([herdr, "pane", "layout", "--pane", pane])
        if data:
            return data
    return run_json([herdr, "pane", "layout", "--current"])


def agent_by_pane() -> dict[str, dict]:
    herdr = shutil.which("herdr")
    if not herdr:
        return {}
    data = run_json([herdr, "agent", "list"])
    if not data:
        return {}
    agents = data.get("result", {}).get("agents") or data.get("agents") or []
    out: dict[str, dict] = {}
    for agent in agents:
        pane_id = agent.get("pane_id")
        if isinstance(pane_id, str) and pane_id:
            out[pane_id] = agent
    return out


def panes_from_layout(data: dict) -> tuple[str | None, list[dict]]:
    layout = data.get("result", {}).get("layout") or data.get("layout") or {}
    panes = list(layout.get("panes") or [])
    self_id = (
        os.environ.get("HERDR_PANE_ID", "").strip()
        or layout.get("focused_pane_id")
        or next((p.get("pane_id") for p in panes if p.get("focused")), None)
    )
    return self_id, panes


def sort_key(pane: dict) -> tuple[int, int, str]:
    rect = pane.get("rect") or {}
    return (
        int(rect.get("x") or 0),
        int(rect.get("y") or 0),
        str(pane.get("pane_id") or ""),
    )


def describe(pane_id: str, agents: dict[str, dict]) -> str:
    agent = agents.get(pane_id) or {}
    kind = agent.get("agent") or "unknown"
    status = agent.get("agent_status") or "unknown"
    return f"{pane_id} ({kind}, {status})"


def main() -> int:
    data = layout_payload()
    if not data:
        return 0

    self_id, panes = panes_from_layout(data)
    if not self_id:
        return 0

    siblings = sorted(
        (p for p in panes if p.get("pane_id") and p.get("pane_id") != self_id),
        key=sort_key,
    )
    agents = agent_by_pane()

    lines = [
        "Herdr layout (live, this turn — use these roles; do not re-run herdr pane layout unless this block is missing):",
        f"- coordinator: {describe(self_id, agents)}",
    ]

    if len(siblings) >= 2:
        dev_id = siblings[0]["pane_id"]
        review_id = siblings[1]["pane_id"]
        lines.append(f"- dev: {describe(dev_id, agents)}")
        lines.append(f"- reviewer: {describe(review_id, agents)}")
        ignored = ", ".join(p["pane_id"] for p in siblings[2:])
        if ignored:
            lines.append(f"- ignored siblings: {ignored}")
    elif len(siblings) == 1:
        dev_id = siblings[0]["pane_id"]
        lines.append(f"- dev: {describe(dev_id, agents)}")
        lines.append("- reviewer: coordinator (local)")
    else:
        lines.append("- no sibling panes; implement, verify, and review locally")

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        raise SystemExit(0)
