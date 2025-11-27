# System Components and Data Flow

**Date**: 2025-11-27
**Version**: 0.1.0
**Status**: Initial Design

## Overview

This document defines the technical architecture, component boundaries, and data flow for Agentive Lotion 2. It translates the architectural vision and ADRs into concrete system design.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              TLDraw Canvas (TypeScript/React)            │   │
│  │  • Theme Clusters  • Content Nodes  • Connections        │   │
│  │  • Drag-and-drop   • Color coding   • "Bad fit" badges   │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Control Panel                         │   │
│  │  • PDF Upload  • Quality Report  • Settings              │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  │ REST API / WebSocket
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend API (Python)                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   API Endpoints                          │   │
│  │  /upload  /process  /status  /canvas  /feedback         │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Processing Pipeline                           │
│                                                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐ │
│  │  Stage 1   │  │  Stage 2   │  │  Stage 3   │  │  Stage 6 │ │
│  │   PDF      │→ │  Document  │→ │  Thematic  │→ │  Canvas  │ │
│  │Disassembly │  │ Structure  │  │  Parsing   │  │ Builder  │ │
│  └────────────┘  └────────────┘  └────────────┘  └──────────┘ │
│       ↓               ↓                ↓               ↓       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐ │
│  │  Quality   │  │ Structure  │  │  Clusters  │  │  TLDraw  │ │
│  │  Checker   │  │  Analyzer  │  │ & Connects │  │  State   │ │
│  └────────────┘  └────────────┘  └────────────┘  └──────────┘ │
│                                                                 │
│  [Stages 4 & 5 omitted from Phase 1, added later]              │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    External Services                            │
│  ┌──────────────────┐  ┌──────────────────────────────────┐    │
│  │  Claude Vision   │  │     File Storage                 │    │
│  │  API (Anthropic) │  │  processing_output/{doc_id}/     │    │
│  └──────────────────┘  └──────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### Frontend Components (TypeScript/React)

#### 1. Canvas Renderer
**Purpose**: Render TLDraw canvas with custom shapes

**Technologies**:
- React 18+
- TLDraw 2.x
- TypeScript 5.x

**Key Files**:
```
frontend/src/canvas/
├── CanvasApp.tsx              # Main canvas component
├── shapes/
│   ├── ThemeClusterShape.tsx  # Theme cluster custom shape
│   ├── ContentNodeShape.tsx   # Text/image content nodes
│   └── CitationLinkShape.tsx  # Citation connection arrows
├── tools/
│   ├── ThemeConnectorTool.ts  # Custom tool for linking themes
│   └── BadFitIndicator.ts     # "Bad fit" marking tool
└── layout/
    ├── ThematicLayout.ts      # Auto-layout algorithms
    └── ForceDirectedLayout.ts # Force-directed positioning
```

**Responsibilities**:
- Render canvas from TLDraw state JSON
- Handle user interactions (drag, zoom, pan)
- Trigger feedback events (drag to new theme)
- Display quality indicators

**Data In**: TLDraw state JSON from backend
**Data Out**: User refinement actions (drag events, feedback)

#### 2. Control Panel
**Purpose**: PDF upload, settings, quality reporting

**Key Files**:
```
frontend/src/components/
├── UploadPanel.tsx     # PDF drag-and-drop upload
├── QualityReport.tsx   # Display extraction quality bands
├── SettingsPanel.tsx   # User preferences
└── ProcessingStatus.tsx # Real-time progress indicator
```

**Responsibilities**:
- File upload to backend
- Display processing status
- Show quality metrics and issues
- Configure application settings

**Data In**: Processing status, quality metrics from backend
**Data Out**: PDF files, settings changes

#### 3. API Client
**Purpose**: Communication with Python backend

**Key Files**:
```
frontend/src/api/
├── client.ts           # REST API client
├── types.ts            # TypeScript types for API
└── websocket.ts        # WebSocket for status updates
```

**Endpoints**:
- `POST /api/upload` - Upload PDF file
- `POST /api/process/{doc_id}` - Start processing
- `GET /api/status/{doc_id}` - Get processing status
- `GET /api/canvas/{doc_id}` - Get canvas state
- `POST /api/feedback/{doc_id}` - Submit user refinements

### Backend Components (Python)

#### 4. API Server
**Purpose**: REST API for frontend communication

**Technologies**:
- FastAPI (async framework)
- Pydantic (data validation)
- Uvicorn (ASGI server)

**Key Files**:
```
backend/api/
├── main.py              # FastAPI app
├── routes/
│   ├── upload.py        # File upload endpoint
│   ├── processing.py    # Processing control
│   ├── canvas.py        # Canvas state retrieval
│   └── feedback.py      # User feedback ingestion
└── models/
    ├── requests.py      # Pydantic request models
    └── responses.py     # Pydantic response models
```

**Responsibilities**:
- Accept PDF uploads
- Trigger processing pipeline
- Return processing status
- Serve canvas state
- Collect user feedback

#### 5. Stage 1: PDF Disassembly
**Purpose**: Extract raw content from PDF with quality validation

**Key Files**:
```
backend/processors/stage_1_extraction/
├── __init__.py
├── extractor.py         # Main extraction orchestrator
├── text_extractor.py    # PyMuPDF/pdfplumber text extraction
├── table_extractor.py   # Table structure extraction
├── image_extractor.py   # Image extraction
├── metadata_extractor.py # PDF metadata
└── quality_checker.py   # Claude vision validation
```

**Dependencies**:
- PyMuPDF (fitz) - Primary PDF library
- pdfplumber - Table extraction
- Pillow - Image processing
- anthropic - Claude API client

**Process**:
1. Load PDF with PyMuPDF
2. Extract text page-by-page with position data
3. Extract tables using pdfplumber
4. Extract embedded images
5. **Quality Check**: Sample pages, validate with Claude vision
   - "Does this extracted text match the visual page?"
   - "Are there page numbers embedded in paragraphs?"
   - "Is any text missing?"
6. Generate quality metrics (coverage, accuracy estimate)

**Output**:
```json
{
  "text": {
    "pages": [
      {
        "page_num": 1,
        "blocks": [
          {"text": "...", "bbox": [x, y, w, h], "confidence": 0.95}
        ]
      }
    ]
  },
  "tables": [...],
  "images": [...],
  "metadata": {...},
  "quality": {
    "band": "good",
    "coverage": 0.97,
    "accuracy": 0.96,
    "issues": ["Page 5: Complex table simplified"]
  }
}
```

#### 6. Stage 2: Document Structure Analysis
**Purpose**: Understand document hierarchy and sections

**Key Files**:
```
backend/processors/stage_2_structure/
├── __init__.py
├── structure_analyzer.py    # Main orchestrator
├── toc_extractor.py         # Table of contents extraction
├── section_detector.py      # Section boundary detection
└── hierarchy_builder.py     # Build document tree
```

**Dependencies**:
- spaCy or NLTK - Text analysis
- anthropic - Claude for structure understanding

**Process**:
1. Extract ToC from PDF (if exists)
2. Detect section headings (font size, formatting)
3. Identify standard sections (Abstract, Intro, Methods, Results, Discussion, Conclusion)
4. **Claude Analysis**: "What is the structure of this paper?"
5. Build hierarchical outline

**Output**:
```json
{
  "outline": {
    "title": "Paper Title",
    "sections": [
      {
        "id": "sec-1",
        "title": "Introduction",
        "level": 1,
        "page_range": [1, 3],
        "subsections": [...]
      }
    ]
  },
  "hierarchy": {
    "root": "document",
    "children": ["abstract", "introduction", ...]
  }
}
```

#### 7. Stage 3: Thematic Parsing
**Purpose**: Cluster content into themes and detect connections

**Key Files**:
```
backend/processors/stage_3_themes/
├── __init__.py
├── theme_clusterer.py       # Main clustering logic
├── semantic_analyzer.py     # Extract concepts/themes
├── connection_detector.py   # Find relationships between themes
└── tag_generator.py         # Generate tags for themes
```

**Dependencies**:
- sentence-transformers - Semantic embeddings
- scikit-learn - Clustering algorithms
- anthropic - Claude for theme naming

**Process**:
1. Generate embeddings for text blocks
2. Cluster embeddings (HDBSCAN or K-means)
3. **Claude Analysis**: "Name these theme clusters" + "Find connections"
4. Generate tags for each theme
5. Assign confidence scores

**Output**:
```json
{
  "clusters": [
    {
      "id": "cluster-001",
      "theme": "Machine Learning Methods",
      "tags": ["ML", "neural networks", "training"],
      "content_ids": ["text-001", "text-045"],
      "confidence": 0.89,
      "color": "#4A90E2"
    }
  ],
  "connections": [
    {
      "from_cluster": "cluster-001",
      "to_cluster": "cluster-003",
      "relationship": "method-result",
      "strength": 0.75
    }
  ]
}
```

#### 8. Stage 6: Canvas Builder
**Purpose**: Generate TLDraw canvas state from processed data

**Key Files**:
```
backend/processors/stage_6_canvas/
├── __init__.py
├── canvas_builder.py        # Main builder
├── node_factory.py          # Create TLDraw shapes
├── layout_engine.py         # Position nodes spatially
└── style_generator.py       # Color-coding, visual style
```

**Dependencies**:
- TLDraw shape schemas (TypeScript definitions → Python)

**Process**:
1. Load Stage 3 thematic clusters
2. Create TLDraw shape for each theme cluster
3. Create content nodes within clusters
4. Create connection edges
5. Run layout algorithm (force-directed or hierarchical)
6. Apply color-coding based on themes
7. Generate final TLDraw state JSON

**Output**:
```json
{
  "tldrawVersion": "2.x",
  "shapes": [
    {
      "id": "shape-cluster-001",
      "type": "theme-cluster",
      "props": {
        "themeId": "cluster-001",
        "themeName": "Machine Learning Methods",
        "color": "#4A90E2",
        "tags": ["ML", "neural networks"],
        "x": 100,
        "y": 200
      }
    },
    {
      "id": "shape-content-001",
      "type": "text-node",
      "parentId": "shape-cluster-001",
      "props": {
        "text": "...",
        "confidence": 0.89
      }
    }
  ],
  "bindings": [...]
}
```

#### 9. Quality Metrics Engine
**Purpose**: Calculate and report quality bands

**Key Files**:
```
backend/quality/
├── __init__.py
├── metrics.py               # Quality calculation
├── band_classifier.py       # Assign quality bands
└── report_generator.py      # Generate user-facing reports
```

**Responsibilities**:
- Aggregate quality signals from all stages
- Classify into quality bands (excellent/good/acceptable/poor/failed)
- Generate actionable quality reports
- Track quality over time

#### 10. Learning & Feedback System
**Purpose**: Capture user refinements and improve clustering

**Key Files**:
```
backend/learning/
├── __init__.py
├── feedback_collector.py    # Capture user actions
├── clustering_improver.py   # Learn from corrections
└── local_storage.py         # Store learning data locally
```

**Responsibilities**:
- Collect drag-and-drop events from frontend
- Analyze patterns in user corrections
- Adjust clustering weights/thresholds
- Update "bad fit" confidence thresholds

## Data Flow

### Primary Flow: PDF to Canvas

```
1. User drops PDF file on frontend
   ↓
2. Frontend uploads to POST /api/upload
   ↓
3. Backend saves PDF, returns document_id
   ↓
4. Frontend calls POST /api/process/{doc_id}
   ↓
5. Backend triggers async processing pipeline:
   ├─ Stage 1: Extract content + validate quality
   ├─ Stage 2: Analyze structure
   ├─ Stage 3: Cluster themes
   └─ Stage 6: Build canvas
   ↓
6. Frontend polls GET /api/status/{doc_id}
   (or receives WebSocket updates)
   ↓
7. When complete, frontend fetches GET /api/canvas/{doc_id}
   ↓
8. Frontend renders TLDraw canvas with custom shapes
   ↓
9. User views and interacts with canvas
```

### Secondary Flow: User Refinement & Learning

```
1. User drags content from theme A to theme B
   ↓
2. Frontend captures drag event with context
   ↓
3. Frontend sends POST /api/feedback/{doc_id}
   ↓
4. Backend stores refinement in feedback.json
   ↓
5. Backend learning system analyzes pattern
   ↓
6. Backend updates clustering weights for future docs
   ↓
7. Next document processed with improved clustering
```

### Data Storage Structure

```
processing_output/
├── {doc_id_1}/
│   ├── manifest.json                    # Processing metadata
│   ├── original.pdf                     # Uploaded PDF
│   ├── stage_1_extraction/
│   │   ├── text.json
│   │   ├── tables.json
│   │   ├── metadata.json
│   │   └── images/
│   │       ├── img_001.png
│   │       └── img_002.png
│   ├── stage_2_structure/
│   │   ├── outline.json
│   │   ├── sections.json
│   │   └── hierarchy.json
│   ├── stage_3_themes/
│   │   ├── clusters.json
│   │   ├── connections.json
│   │   └── tags.json
│   ├── stage_6_canvas/
│   │   └── tldraw_state.json
│   └── user_feedback/
│       └── theme_refinements.json
└── {doc_id_2}/
    └── ...
```

## Technology Stack Summary

### Backend (Python)
- **Framework**: FastAPI
- **PDF Libraries**: PyMuPDF (fitz), pdfplumber
- **ML/NLP**: sentence-transformers, scikit-learn
- **AI**: anthropic (Claude API)
- **Data**: Pydantic, JSON, Pillow

### Frontend (TypeScript/React)
- **Framework**: React 18+
- **Canvas**: TLDraw 2.x
- **HTTP**: fetch API or axios
- **WebSocket**: native WebSocket
- **Build**: Vite or Create React App

### Development Tools
- **Testing**: pytest (backend), Jest/Vitest (frontend)
- **Linting**: ruff (Python), ESLint (TypeScript)
- **Formatting**: black (Python), Prettier (TypeScript)
- **Type Checking**: mypy (Python), TypeScript compiler

## API Contract (Phase 1)

### POST /api/upload
**Request**: Multipart form data with PDF file
**Response**:
```json
{
  "document_id": "uuid-here",
  "filename": "paper.pdf",
  "size_bytes": 1234567,
  "page_count": 25
}
```

### POST /api/process/{doc_id}
**Request**: Empty body or processing options
**Response**:
```json
{
  "status": "processing",
  "started_at": "2025-11-27T10:00:00Z",
  "estimated_completion": "2025-11-27T10:02:30Z"
}
```

### GET /api/status/{doc_id}
**Response**:
```json
{
  "status": "completed",  // or "processing", "failed"
  "progress": {
    "stage_1": "completed",
    "stage_2": "completed",
    "stage_3": "in_progress",
    "stage_6": "pending"
  },
  "current_stage": "stage_3",
  "percentage": 75
}
```

### GET /api/canvas/{doc_id}
**Response**:
```json
{
  "document_id": "uuid-here",
  "tldraw_state": {
    "shapes": [...],
    "bindings": [...]
  },
  "quality_report": {
    "band": "good",
    "details": {...}
  }
}
```

### POST /api/feedback/{doc_id}
**Request**:
```json
{
  "action": "drag-to-theme",
  "content_id": "text-045",
  "from_theme": "cluster-001",
  "to_theme": "cluster-003",
  "timestamp": "2025-11-27T10:05:00Z"
}
```
**Response**:
```json
{
  "acknowledged": true,
  "learning_updated": true
}
```

## Deployment Architecture (Phase 1)

For Phase 1 (single-user desktop app):

```
User's Computer
├── Backend (Python FastAPI)
│   ├── Runs on localhost:8000
│   ├── Accesses Claude API over internet
│   └── Writes to local file system
└── Frontend (React dev server)
    └── Runs on localhost:3000
    └── Proxies API calls to :8000
```

**Later**: Package as Electron app or Tauri for distribution.

## Performance Targets (Phase 1)

- **PDF Upload**: < 5 seconds for 50MB file
- **Stage 1 Extraction**: < 30 seconds for 50-page document
- **Stage 2 Structure**: < 10 seconds
- **Stage 3 Themes**: < 20 seconds
- **Stage 6 Canvas**: < 5 seconds
- **Total Processing**: < 2 minutes for typical paper

- **Canvas Rendering**: < 1 second initial load, 60fps interactions
- **Drag-and-drop**: < 100ms response time

## Security Considerations

- **File Upload**: Validate PDF magic bytes, size limits (max 100MB)
- **API Keys**: Store Claude API key in environment variables, never in code
- **Path Traversal**: Sanitize document IDs, use UUIDs
- **DoS**: Rate limit API endpoints
- **Privacy**: Process locally, option to disable cloud AI services

## Error Handling Strategy

- **Stage Failures**: Continue to next stage with degraded quality
- **Quality Thresholds**: Warn user if quality < "acceptable"
- **User Feedback**: Always acknowledge, never silently fail
- **Logging**: Structured logs for debugging, PII-free

## Testing Strategy

- **Unit Tests**: Each processor component independently testable
- **Integration Tests**: Full pipeline with sample PDFs
- **Quality Tests**: Validate extraction accuracy against known-good outputs
- **E2E Tests**: Frontend → Backend → Canvas rendering
- **Performance Tests**: Benchmark processing times

---

**Document Owner**: rem (coordinator)
**Last Updated**: 2025-11-27
**Next Review**: After Phase 1 implementation begins
