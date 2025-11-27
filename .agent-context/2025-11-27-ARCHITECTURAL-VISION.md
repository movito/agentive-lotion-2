# Architectural Vision: Agentive Lotion 2

**Date**: 2025-11-27
**Version**: 0.1.0
**Status**: Initial Planning

## Executive Summary

Agentive Lotion 2 is a tool that transforms academic PDFs into interactive, thematic knowledge canvases. Unlike simple extraction tools, it analyzes document structure, extracts themes, and creates a visual graph of interconnected concepts on a TLDraw canvas.

## Vision

Transform linear academic papers into explorable knowledge graphs where:
- **Themes** emerge as visual clusters (color-coded, tagged)
- **Connections** are explicit (citations, references, semantic links)
- **Content** is preserved with high fidelity (text, images, tables)
- **Structure** is intelligent (not just page-by-page extraction)

## Target Users & Use Cases

### Primary Target
- **Academic researchers** working with papers (2-50 pages, <50MB)
- **Single-user desktop application** (local processing)

### Core Workflow
1. **Drop PDF** onto application
2. **Automated processing** extracts and analyzes content
3. **Canvas generation** creates thematic visual layout
4. **User refinement** through drag-and-drop reorganization
5. **Feedback loop** improves future thematic clustering

## System Architecture

### High-Level Pipeline

```
PDF Input
    ↓
[1] PDF Disassembly & Quality Validation
    ↓ (extracted content + metadata)
[2] Document Structure Analysis
    ↓ (sections, hierarchy, relationships)
[3] Thematic Parsing & Grouping
    ↓ (themes, clusters, connections)
[4] Source & Citation Linking
    ↓ (footnotes, endnotes, references)
[5] Image Extraction & Preservation
    ↓ (images with metadata and context)
[6] Canvas Construction
    ↓
Interactive TLDraw Canvas
```

### Stage Details

#### Stage 1: PDF Disassembly
**Purpose**: Extract content with quality validation

**Key Functions**:
- Text extraction with position/formatting preservation
- OCR/computer vision for poorly formatted PDFs
- Quality checks (detect page numbers in body text, misplaced captions)
- Table extraction and structuring
- Initial metadata extraction

**Quality Concerns**:
- Page numbers embedded in paragraphs
- Photo descriptions misplaced in titles
- Inconsistent formatting across pages

#### Stage 2: Document Structure Analysis
**Purpose**: Create hierarchical understanding

**Key Functions**:
- Table of Contents extraction/reconstruction
- Section hierarchy detection (intro, methods, results, discussion)
- Abstract and conclusion identification
- Overall document structure mapping

**Outputs**:
- Document outline (JSON)
- Section boundaries and relationships
- Structural metadata

#### Stage 3: Thematic Parsing
**Purpose**: Group content by themes and concepts

**Key Functions**:
- Semantic analysis of content
- Thematic clustering (concepts, methods, findings)
- Connection detection between themes
- Tag generation for clusters

**Outputs**:
- Theme definitions with member content
- Inter-theme relationships
- Conceptual graph structure

#### Stage 4: Source & Citation Linking
**Purpose**: Connect citations to references

**Key Functions**:
- Footnote/endnote extraction
- Reference list parsing
- Link creation between citations and text
- OCR/CV for complex citation formats

**Outputs**:
- Citation graph
- Hyperlinks between text and references
- Source metadata

#### Stage 5: Image Extraction
**Purpose**: Preserve visual content with context

**Key Functions**:
- Image extraction with quality preservation
- Caption/description extraction
- Photo credit detection
- Context linking (which chapter/paragraph)

**Outputs**:
- Image files with metadata
- Image-to-text relationships
- Visual content positioning data

#### Stage 6: Canvas Construction
**Purpose**: Build interactive TLDraw visualization

**Key Functions**:
- Spatial layout generation (theme clusters)
- Node creation (text, images, concepts)
- Edge creation (connections, citations)
- Color-coding and visual styling
- Interactive behaviors

**Outputs**:
- TLDraw canvas state (JSON)
- Editable, explorable interface

## Technology Stack

### Backend (Python)
- **PDF Processing**: PyMuPDF, pdfplumber
- **OCR/Vision**: Claude Code with vision (initially), hooks for Tesseract/LayoutParser
- **NLP/Analysis**: For thematic clustering (TBD: specific libraries)
- **API Framework**: TBD (FastAPI, Flask)

### Frontend (TypeScript/React)
- **Canvas**: TLDraw (use upstream, extend via composition)
- **UI Framework**: React
- **State Management**: TBD

### Data Storage
- **Intermediate Stages**: JSON files + file system
- **Reasoning**: Easy inspection, agent review, debugging
- **Future**: Database for large-scale use (later iteration)

### AI/ML Services
- **Primary**: Claude Code with vision
- **Fallback/Local**: Keep hooks for local models
- **Reasoning**: Balance cloud quality with local privacy

## Data Flow & Persistence

### Processing Pipeline
```
PDF File (input)
    ↓
Stage 1 Output: extracted_content/
    ├── text.json
    ├── images/
    ├── tables.json
    └── metadata.json
    ↓
Stage 2 Output: structure/
    ├── outline.json
    ├── sections.json
    └── hierarchy.json
    ↓
Stage 3 Output: themes/
    ├── clusters.json
    ├── connections.json
    └── tags.json
    ↓
Stage 4 Output: citations/
    ├── reference_graph.json
    └── links.json
    ↓
Stage 5 Output: visual_content/
    ├── images/ (enhanced)
    └── image_metadata.json
    ↓
Stage 6 Output: canvas/
    └── tldraw_state.json
```

### Intermediate Stage Preservation
- **Initially**: All stages preserved for debugging
- **Agent Review**: Specialized agents validate each stage
- **Learning Loops**: Feed corrections back into models
- **Later**: Option to disable for production use

## Quality & Success Metrics

### Extraction Accuracy (Band-Based)
- **Target**: "95% of body text extracted within 99% accuracy"
- **Reasoning**: Accounts for variable PDF quality
- **Measurement**: Per-document bands, aggregate statistics

### Theme Coherence
- **Feedback Mechanism**: "This doesn't belong here" indicators
- **User Agency**: Drag-and-drop to recluster
- **Learning**: Each refinement improves clustering
- **Indicator**: "Bad fit" badges on questionable placements

### Error Handling
- **Philosophy**: Flag, don't guess
- **User Flow**: Failed extractions marked for human review
- **Confidence Scores**: Show when system is uncertain
- **Transparency**: Make limitations visible

## Canvas Interaction Model

### User Experience
- **Editable Canvas**: Users can reorganize content
- **Visual Encoding**:
  - Themes as clusters
  - Color-coding for categories
  - Tags for filtering/grouping
- **Progressive Disclosure**: Start simple, reveal complexity as needed

### TLDraw Integration
- **Strategy**: Use upstream TLDraw, extend via composition
- **Reasoning**: Avoid maintenance burden of fork
- **Customization**: Custom shapes, tools as TLDraw plugins

### Large Document Handling
- **Deferred**: Wait for real-world examples
- **Future**: Layers, hierarchical views, filtering
- **Philosophy**: Let material guide design

## Development Approach

### Phase 0: Foundation (Current)
- [x] Infrastructure setup (starter kit)
- [x] Specialized agent creation
- [ ] Architecture documentation (this document)
- [ ] ADRs for key decisions
- [ ] Phase 1 task breakdown

### Phase 1: Core Pipeline (Next)
- [ ] Stage 1: Basic PDF extraction
- [ ] Stage 2: Structure analysis
- [ ] Minimal canvas rendering
- [ ] End-to-end smoke test

### Phase 2: Quality & Intelligence
- [ ] Stage 3: Thematic clustering
- [ ] Stage 4: Citation linking
- [ ] Stage 5: Image extraction
- [ ] Agent-based quality review

### Phase 3: Polish & UX
- [ ] Canvas interactions
- [ ] Visual design
- [ ] Feedback mechanisms
- [ ] User testing

### Future Phases
- [ ] Large document support
- [ ] Advanced clustering
- [ ] Collaboration features
- [ ] Export/sharing

## Key Architectural Decisions

### ADR-0002: Python Backend + TypeScript Frontend
**Decision**: Separate Python API for processing, TypeScript/React for UI
**Reasoning**: Python strength in PDF/ML, TypeScript/React for modern UI, clear separation of concerns

### ADR-0003: JSON + File System for Initial Storage
**Decision**: Store intermediate stages as JSON files on disk
**Reasoning**: Easy to inspect, debug, review; defer database complexity; agent-friendly format

### ADR-0004: Claude Vision with Local Model Hooks
**Decision**: Use Claude Code with vision initially, maintain hooks for local alternatives
**Reasoning**: Best quality out of gate, flexibility for privacy/offline use

### ADR-0005: TLDraw Composition over Fork
**Decision**: Extend TLDraw via composition/plugins, not forking
**Reasoning**: Avoid maintenance burden, stay current with upstream

### ADR-0006: Band-Based Quality Metrics
**Decision**: "X% of content extracted within Y% accuracy" per document
**Reasoning**: Accounts for variable PDF quality, realistic expectations

### ADR-0007: User-Driven Theme Refinement
**Decision**: Users can drag content between themes, provide "bad fit" feedback
**Reasoning**: No algorithm is perfect; user agency + learning loop

### ADR-0008: Preserve Intermediate Stages Initially
**Decision**: Keep all processing stages for review and debugging
**Reasoning**: Enable agent review, learning loops; can disable later

## Success Criteria

### Minimum Viable Product (MVP)
- [ ] Accepts PDF input (2-50 pages)
- [ ] Extracts text with >90% accuracy
- [ ] Identifies basic structure (sections)
- [ ] Renders canvas with text nodes
- [ ] User can view and navigate canvas

### Version 1.0
- [ ] All 6 pipeline stages functional
- [ ] Thematic clustering with user refinement
- [ ] Citation linking working
- [ ] Image extraction with context
- [ ] Editable, color-coded canvas
- [ ] 95%+ extraction accuracy band

### Future Vision
- [ ] Multi-document canvases
- [ ] Collaboration features
- [ ] Advanced theme detection
- [ ] Export to various formats
- [ ] Large document layers/filtering

## Risks & Mitigations

### Risk: PDF Format Variability
**Mitigation**: OCR/CV fallbacks, quality validation, human review flags

### Risk: Thematic Clustering Accuracy
**Mitigation**: User refinement, feedback loops, "bad fit" indicators, learning from corrections

### Risk: TLDraw Upstream Changes
**Mitigation**: Composition over fork, version pinning, update strategy

### Risk: Performance with Large Documents
**Mitigation**: Defer optimization until real examples, progressive loading

### Risk: Local Model Quality
**Mitigation**: Start with Claude vision, refine before switching to local

## Next Steps

1. **Complete ADRs** for each key decision
2. **Define API contracts** between pipeline stages
3. **Create Phase 1 task breakdown** with acceptance criteria
4. **Set up project structure** (Python package, TypeScript app)
5. **Implement Stage 1 + 6 (minimal)** for end-to-end proof of concept

---

**Document Owner**: rem (coordinator)
**Last Updated**: 2025-11-27
**Next Review**: After Phase 1 completion
