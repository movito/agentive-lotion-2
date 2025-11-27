# ADR-0003: JSON + File System for Initial Storage

**Status**: Accepted

**Date**: 2025-11-27

**Deciders**: rem (coordinator), user

## Context

### Problem Statement

The 6-stage processing pipeline generates multiple intermediate outputs:
- Extracted text, images, tables (Stage 1)
- Document structure and hierarchy (Stage 2)
- Thematic clusters and connections (Stage 3)
- Citation graphs and links (Stage 4)
- Image metadata and context (Stage 5)
- Final canvas state (Stage 6)

We need a storage strategy that:
- Preserves intermediate stages for debugging and agent review
- Enables learning loops and quality improvement
- Allows easy inspection during development
- Doesn't over-engineer for scale prematurely

### Forces at Play

**Technical Requirements:**
- Store structured data (text, metadata, relationships)
- Store binary data (extracted images)
- Support agent-based review of intermediate stages
- Enable rollback to previous stages for refinement
- Human-readable for debugging

**Constraints:**
- Single-user desktop application
- Processing 2-50 page documents (<50MB)
- Not building a multi-user service
- Development velocity is priority over optimization

**Assumptions:**
- Documents processed one at a time
- Intermediate stages small enough to fit in memory
- No concurrent processing requirements
- Can defer database complexity until proven necessary

## Decision

**Use JSON files on disk for structured data, file system folders for binary content.**

### Core Principles

1. **Simplicity First**: Use the file system as the database until proven insufficient
2. **Inspectability**: All data human-readable and agent-reviewable
3. **Progressive Enhancement**: Can migrate to database later without API changes
4. **Agent-Friendly**: JSON format directly consumable by review agents

### Implementation Details

**Directory Structure:**
```
processing_output/
├── {document_id}/
│   ├── stage_1_extraction/
│   │   ├── text.json              # Extracted text with positions
│   │   ├── tables.json            # Extracted tables
│   │   ├── metadata.json          # PDF metadata
│   │   └── images/                # Extracted image files
│   │       ├── img_001.png
│   │       └── img_002.png
│   ├── stage_2_structure/
│   │   ├── outline.json           # Document outline
│   │   ├── sections.json          # Section boundaries
│   │   └── hierarchy.json         # Structural relationships
│   ├── stage_3_themes/
│   │   ├── clusters.json          # Thematic groupings
│   │   ├── connections.json       # Inter-theme links
│   │   └── tags.json              # Generated tags
│   ├── stage_4_citations/
│   │   ├── reference_graph.json   # Citation network
│   │   └── links.json             # Text-to-reference mappings
│   ├── stage_5_visual/
│   │   ├── images/                # Enhanced image files
│   │   └── image_metadata.json    # Context and descriptions
│   ├── stage_6_canvas/
│   │   └── tldraw_state.json      # Final canvas state
│   └── manifest.json              # Processing metadata
```

**JSON Schema Examples:**

```json
// manifest.json
{
  "document_id": "uuid-here",
  "original_filename": "paper.pdf",
  "processing_started": "2025-11-27T10:00:00Z",
  "processing_completed": "2025-11-27T10:05:23Z",
  "stages_completed": ["1", "2", "3", "4", "5", "6"],
  "quality_metrics": {
    "extraction_accuracy": "95%",
    "stage_errors": []
  }
}

// stage_3_themes/clusters.json
{
  "clusters": [
    {
      "id": "cluster-001",
      "theme": "Machine Learning Methods",
      "tags": ["ML", "neural networks", "training"],
      "content_ids": ["text-001", "text-045", "text-078"],
      "confidence": 0.89
    }
  ]
}
```

**File Management:**
- One directory per processed document
- Unique document IDs (UUID or timestamp-based)
- Atomic writes (write to temp, then move)
- Optional cleanup of intermediate stages after successful completion

**Benefits for Agent Review:**
- Agents can read JSON directly with Read tool
- Each stage independently reviewable
- Easy to spot errors in structured data
- Can generate stage-specific quality reports

## Consequences

### Positive

- ✅ **Simplicity**: No database setup, migrations, or ORM complexity
- ✅ **Inspectability**: Can open any JSON file and understand state
- ✅ **Agent-Friendly**: Review agents can read/validate without special tools
- ✅ **Version Control**: Can commit sample outputs to git for regression testing
- ✅ **Debugging**: Easy to reproduce issues by replaying from intermediate stages
- ✅ **Development Velocity**: No schema migrations or database management overhead

### Negative

- ⚠️ **No Querying**: Can't easily query across documents (e.g., "find all documents about ML")
- ⚠️ **No Transactions**: Risk of partial writes if process crashes
- ⚠️ **File System Limits**: Large documents could create many small files
- ⚠️ **No Indexing**: Searching requires reading all files

### Neutral

- 📊 **Performance**: File I/O fast enough for single-document processing
- 📊 **Scalability**: Good for 10s-100s of documents, would need DB for 1000s+
- 📊 **Portability**: JSON + files works on all platforms

## Alternatives Considered

### Alternative 1: SQLite Database

**Description**: Use embedded SQLite database for all structured data.

**Rejected because**:
- ❌ Adds complexity without clear benefit at current scale
- ❌ Less inspectable (need SQL client to view data)
- ❌ Schema migrations add development friction
- ❌ Binary format harder for agents to review
- 💡 **Can reconsider** when we need cross-document queries or have 100+ documents

### Alternative 2: PostgreSQL/MongoDB

**Description**: Use full-featured database server.

**Rejected because**:
- ❌ Massive overkill for single-user desktop app
- ❌ Requires database server installation and management
- ❌ Adds deployment complexity
- ❌ Network overhead unnecessary
- 💡 **Can reconsider** only if building multi-user cloud service

### Alternative 3: In-Memory Only

**Description**: Keep all data in memory, only persist final canvas state.

**Rejected because**:
- ❌ Loses intermediate stages needed for agent review
- ❌ Can't debug or replay processing stages
- ❌ No learning loop data for quality improvement
- ❌ User loses work if process crashes

## Real-World Results

[To be filled after Phase 1 implementation]

**Metrics to track:**
- File I/O performance for typical documents
- Disk space usage per document
- Agent review effectiveness with JSON format
- Time spent debugging with inspectable files

## Related Decisions

- ADR-0002: Python Backend + TypeScript Frontend (backend processes create these files)
- ADR-0008: Preserve Intermediate Stages (decision to keep all stages enables this approach)

## References

- [JSON Schema Specification](https://json-schema.org/)
- [Atomic File Writes Pattern](https://github.com/untitaker/python-atomicwrites)

## Revision History

- 2025-11-27: Initial decision (Accepted)
- [Future]: Add "Migration to SQLite" section if/when we hit file system limits

---

**Template Version**: 1.1.0
**Project**: Agentive Lotion 2
**Naming Convention**: ADR-####-description.md
