# ADR-0001: System Prompt Size Considerations

**Status**: Accepted
**Date**: 2025-11-25
**Context**: Agent launcher passes full agent markdown as system prompt

## Context

The agentive-starter-kit uses a launcher script (`agents/launch`) that passes the entire agent markdown file as a system prompt via `--append-system-prompt`. Large agent definitions can increase request processing time and make API overload errors more likely.

### Observed Issue

On 2025-11-25, the `rem` agent (495 lines, ~17KB) triggered repeated `overloaded_error` responses:

```json
{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"},"request_id":null}
```

The error resolved after ~7 retry attempts (approximately 3-4 minutes).

### Root Cause Analysis

The `overloaded_error` is an Anthropic API capacity issue, not a prompt size error. However:
- Larger system prompts increase request payload size
- More tokens require more processing time
- During high-demand periods, larger requests may be more susceptible to overload rejection

## Decision

**Keep the current embedded approach** but document guidelines for agent size management:

### Agent Size Guidelines

| Agent Type | Recommended Max | Notes |
|------------|-----------------|-------|
| Coordinator agents | 500 lines | May include detailed workflows |
| Specialized agents | 300 lines | Focus on single responsibility |
| Simple agents | 150 lines | Minimal context needed |

### Mitigation Options (if issues persist)

1. **Externalize detailed content**: Move verbose instructions (like onboarding flows) to `.agent-context/` files that agents read on demand
2. **Lazy loading**: Agent reads detailed context only when needed
3. **Model selection**: Consider lighter models for less complex agents

### When to Externalize

Consider moving content to external files if:
- Agent markdown exceeds 600 lines
- Repeated overload errors occur (>5 retries)
- Content is rarely needed (e.g., first-run only)

## Consequences

### Positive
- Simple architecture (single file per agent)
- All context immediately available to agent
- Easy to version and review

### Negative
- Larger request payload
- Potentially longer time-to-first-response
- More susceptible to overload during high-demand periods

### Monitoring

Track these indicators:
- Retry attempts before successful connection
- Time-to-first-response for different agents
- Agent file sizes over time

## Future Considerations

If overload issues become frequent:
1. Implement the externalization pattern for `rem.md` onboarding
2. Create a "slim" variant of agents for high-load periods
3. Consider caching or preloading mechanisms

## Related

- `agents/launch` - Agent launcher script
- `.claude/agents/rem.md` - Largest agent (495 lines)
- Anthropic API documentation on rate limits and overload handling
