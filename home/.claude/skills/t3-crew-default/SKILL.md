---
name: t3-crew-default
description: Turns on crew mode with the default crew and no questions: dev = Claude Opus 5.5, reviewer = Cursor Auto. Same behavior as t3-crew otherwise. User-invoked only.
disable-model-invocation: true
argument-hint: "[task] | off"
---

# t3-crew-default

`/t3-crew` with the wizard skipped. Nothing happens until the user runs `/t3-crew-default`.

Arguments (`$ARGUMENTS`):
- empty: turn crew mode on, then wait for the task.
- text: turn crew mode on, then use the text as the first task.
- `off`: crew mode is off. Remove the head-icon thread-title prefix as `t3-crew` section 3 describes, say `👥 T3-CREW off`, stop using the banner, and work directly again. Stop here.

## Steps

1. Read `~/.claude/skills/t3-crew/SKILL.md` and follow its sections 1 (Load), 3 (Crew mode is now on), 4 (Per request) and Rules exactly. Skip its section 2 (Wizard); do not ask any questions.
2. Use this fixed crew:
   - dev: provider `claudeAgent`, model `claude-opus-5-5`, default options
   - reviewer: provider `cursor`, model `default` (Cursor's Auto), default options
3. Check both models exist in the `orchestrator_capabilities` catalog and that their providers can run child tasks. If either is missing or unavailable, say which and stop; do not substitute another model.
4. Save the crew to `~/.claude/t3-crew/last.json` in the same format `t3-crew` uses, so `/t3-crew last` matches it.
5. The banner is `👥 T3-CREW · dev: Claude Opus 5.5 · reviewer: Cursor Auto`.
