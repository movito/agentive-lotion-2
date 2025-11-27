# ADR-0005: TLDraw Composition over Fork

**Status**: Accepted

**Date**: 2025-11-27

**Deciders**: rem (coordinator), user

## Context

### Problem Statement

We need a canvas-based visualization that supports:
- Node rendering (text blocks, images, concept cards)
- Edge connections (citations, semantic links, relationships)
- Interactive editing (drag-and-drop, reorganization)
- Visual clustering (color-coding, grouping, themes)
- Spatial layouts (auto-positioning, manual adjustment)

TLDraw is the leading open-source canvas library, but requires customization for our domain-specific needs (thematic clusters, PDF content types, custom interactions).

We must decide how to integrate TLDraw: use it as-is, extend it, or fork it.

### Forces at Play

**Technical Requirements:**
- Custom shape types (PDF page nodes, theme clusters, citation cards)
- Custom interaction patterns (theme refinement, "bad fit" indicators)
- Auto-layout algorithms for thematic positioning
- Color-coding and visual styling for themes
- Persistent canvas state (save/load)

**Constraints:**
- TLDraw is actively developed (frequent updates)
- Team has limited resources to maintain a fork
- Need to ship features quickly
- TLDraw's core is well-designed and feature-rich

**Assumptions:**
- TLDraw's extension API is sufficient for our needs
- Upstream improvements (performance, features) are valuable
- Staying close to upstream reduces maintenance burden
- Breaking changes manageable with version pinning

## Decision

**Use TLDraw as a library dependency, extend via composition and plugins, avoid forking.**

### Core Principles

1. **Leverage Upstream**: Benefit from TLDraw's ongoing development
2. **Extend, Don't Modify**: Use TLDraw's extension points rather than modifying core
3. **Isolate Customizations**: Keep our domain logic separate from canvas framework
4. **Version Carefully**: Pin versions, test updates before upgrading

### Implementation Details

**Extension Strategy:**

```typescript
// frontend/src/canvas/shapes/ThemeClusterShape.tsx
import { BaseBoxShapeUtil, TLBaseShape } from '@tldraw/tldraw'

// Define custom shape for theme clusters
export type ThemeClusterShape = TLBaseShape<
  'theme-cluster',
  {
    themeId: string
    themeName: string
    color: string
    tags: string[]
    contentIds: string[]
  }
>

export class ThemeClusterShapeUtil extends BaseBoxShapeUtil<ThemeClusterShape> {
  // Custom rendering, hit testing, editing logic
}

// Register custom shapes
const customShapes = [ThemeClusterShapeUtil, PDFPageShapeUtil, CitationCardShapeUtil]
```

**Custom Tools:**

```typescript
// frontend/src/canvas/tools/ThemeConnectorTool.ts
import { StateNode } from '@tldraw/tldraw'

// Custom tool for connecting themes
export class ThemeConnectorTool extends StateNode {
  static override id = 'theme-connector'
  // Custom interaction logic
}
```

**Layout Integration:**

```typescript
// frontend/src/canvas/layout/ThematicLayout.ts
// Our auto-layout algorithms, not part of TLDraw
export class ThematicLayoutEngine {
  calculatePositions(clusters: ThemeCluster[]): NodePositions {
    // Force-directed, hierarchical, or grid layout
  }
}

// Apply layout by updating TLDraw shape positions
editor.updateShapes(shapesWithPositions)
```

**Versioning Strategy:**
- Pin TLDraw to specific minor version (e.g., `"@tldraw/tldraw": "2.5.x"`)
- Test major updates in separate branch before upgrading
- Document any workarounds for TLDraw limitations
- Contribute bug fixes/features back to upstream when possible

**What We DON'T Do:**
- ❌ Fork TLDraw repository
- ❌ Modify TLDraw core source files
- ❌ Patch TLDraw at build time
- ❌ Vendor TLDraw into our codebase

## Consequences

### Positive

- ✅ **Upstream Benefits**: Automatic performance improvements, bug fixes, new features
- ✅ **Reduced Maintenance**: Don't maintain canvas framework internals
- ✅ **Community Support**: Can get help from TLDraw community
- ✅ **Documentation**: Can reference official TLDraw docs
- ✅ **Hiring**: Developers familiar with TLDraw can onboard faster
- ✅ **Updates**: Security patches and improvements flow automatically

### Negative

- ⚠️ **Breaking Changes**: Major TLDraw updates may require migration work
- ⚠️ **Extension Limits**: Constrained by TLDraw's extension API design
- ⚠️ **Workarounds**: May need hacky solutions if API doesn't support our needs
- ⚠️ **Version Lag**: May not adopt latest TLDraw features immediately (pinned version)

### Neutral

- 📊 **Coupling**: We're coupled to TLDraw's architecture and decisions
- 📊 **Bundle Size**: Inherit TLDraw's bundle size (mitigated by it being well-optimized)
- 📊 **Customization Depth**: Some deep customizations may be impossible

## Alternatives Considered

### Alternative 1: Fork TLDraw

**Description**: Create our own fork to modify internals freely.

**Rejected because**:
- ❌ Massive maintenance burden (TLDraw is ~100k LOC)
- ❌ Lose upstream improvements and bug fixes
- ❌ Difficult to merge upstream changes
- ❌ Team size too small to maintain a fork
- ❌ Would fall behind on performance/features
- 💡 **Only reconsider** if extension API proves fundamentally insufficient

### Alternative 2: Build Canvas from Scratch

**Description**: Implement our own canvas using React + SVG/Canvas API.

**Rejected because**:
- ❌ Would take months to reach TLDraw's feature parity
- ❌ Complex problems already solved (undo/redo, zoom, selection, etc.)
- ❌ Not our core competency or differentiator
- ❌ Massive time sink for features that already exist
- 💡 **Never reconsider** unless TLDraw is abandoned

### Alternative 3: Different Canvas Library (e.g., Excalidraw, Konva)

**Description**: Use alternative canvas framework.

**Rejected because**:
- ❌ TLDraw specifically designed for this use case
- ❌ Excalidraw less extensible (more opinionated)
- ❌ Konva lower-level (more work to build features)
- ❌ TLDraw has best TypeScript support and React integration
- 💡 **Could reconsider** if TLDraw development stops

## Real-World Results

[To be filled after Phase 3 canvas implementation]

**Metrics to track:**
- Number of TLDraw version upgrades completed
- Breaking changes encountered per upgrade
- Custom shapes/tools successfully implemented
- Performance with 50+ nodes on canvas
- Any features blocked by extension API limits

## Related Decisions

- ADR-0002: Python Backend + TypeScript Frontend (frontend uses TLDraw)
- ADR-0007: User-Driven Theme Refinement (canvas interactions implemented via TLDraw)

## References

- [TLDraw Documentation](https://tldraw.dev/)
- [TLDraw GitHub](https://github.com/tldraw/tldraw)
- [TLDraw Custom Shapes Guide](https://tldraw.dev/docs/shapes)
- [TLDraw Extension Examples](https://github.com/tldraw/tldraw/tree/main/apps/examples)

## Revision History

- 2025-11-27: Initial decision (Accepted)

---

**Template Version**: 1.1.0
**Project**: Agentive Lotion 2
**Naming Convention**: ADR-####-description.md
