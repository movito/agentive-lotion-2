# Phase 1: Core Pipeline - Task Breakdown

**Date**: 2025-11-27
**Version**: 0.1.0
**Status**: Planning
**Target**: Minimal Viable Pipeline (Stage 1 + Stage 6)

## Phase 1 Goal

Build an end-to-end proof of concept that:
1. Accepts a PDF upload
2. Extracts text content
3. Validates extraction quality
4. Renders content on a basic TLDraw canvas
5. Demonstrates the pipeline works

**NOT in Phase 1**: Stages 2-5 (structure analysis, themat clustering, citations, images). These come in Phase 2+.

## Phase 1 Scope

### Included
- ✅ PDF file upload (frontend + backend)
- ✅ Stage 1: Basic text extraction with PyMuPDF
- ✅ Stage 1: Quality validation with Claude vision
- ✅ Stage 6: Simple canvas rendering (text blocks as nodes)
- ✅ Basic API (upload, process, status, canvas)
- ✅ Minimal UI (upload panel, canvas display, quality report)
- ✅ End-to-end smoke test with sample academic paper

### Excluded (Future Phases)
- ❌ Document structure analysis (Stage 2)
- ❌ Thematic clustering (Stage 3)
- ❌ Citation linking (Stage 4)
- ❌ Image extraction (Stage 5)
- ❌ User refinement / learning loop
- ❌ Auto-layout algorithms (manual grid layout OK)
- ❌ Electron/Tauri packaging

## Success Criteria

Phase 1 is complete when:
1. User can upload a 10-page academic PDF
2. System extracts text with quality report ("good" band or better)
3. Canvas displays extracted text as nodes
4. User can pan/zoom canvas to view content
5. Quality metrics displayed to user
6. Processing completes in < 1 minute for 10-page PDF
7. All tests passing (unit + integration)

## Task List

### Task Group A: Project Setup

#### AL2-0001: Backend Project Structure
**Assignee**: feature-developer
**Estimated Time**: 2 hours

**Description**: Create Python backend package structure

**Acceptance Criteria**:
- [ ] Create `backend/` directory with package structure
- [ ] Set up `pyproject.toml` with dependencies (FastAPI, PyMuPDF, anthropic, etc.)
- [ ] Create virtual environment and install dependencies
- [ ] Add `backend/api/main.py` with FastAPI skeleton
- [ ] Add basic health check endpoint (`GET /health`)
- [ ] Document setup in `backend/README.md`

**Dependencies**: FastAPI, PyMuPDF, pdfplumber, anthropic, uvicorn, pydantic

---

#### AL2-0002: Frontend Project Structure
**Assignee**: feature-developer
**Estimated Time**: 2 hours

**Description**: Create React/TypeScript frontend structure

**Acceptance Criteria**:
- [ ] Create `frontend/` directory with Vite/CRA setup
- [ ] Set up TypeScript configuration
- [ ] Add TLDraw as dependency
- [ ] Create basic app structure (`src/` layout)
- [ ] Add API client stub (`src/api/client.ts`)
- [ ] Run dev server successfully
- [ ] Document setup in `frontend/README.md`

**Dependencies**: React, TLDraw, TypeScript, Vite

---

#### AL2-0003: Development Environment Configuration
**Assignee**: feature-developer
**Estimated Time**: 1 hour

**Description**: Configure local development environment

**Acceptance Criteria**:
- [ ] Add `.env.template` with required environment variables
- [ ] Document how to get Claude API key
- [ ] Configure backend to serve on localhost:8000
- [ ] Configure frontend to proxy API calls to backend
- [ ] Test both servers run concurrently
- [ ] Add npm/yarn script to start both servers
- [ ] Update main project README with setup instructions

---

### Task Group B: Backend - Stage 1 (PDF Extraction)

#### AL2-0004: Text Extraction with PyMuPDF
**Assignee**: pdf-processor
**Estimated Time**: 4 hours

**Description**: Implement basic text extraction from PDF

**Acceptance Criteria**:
- [ ] Create `backend/processors/stage_1_extraction/text_extractor.py`
- [ ] Implement PDF loading with PyMuPDF (fitz)
- [ ] Extract text page-by-page with bounding boxes
- [ ] Handle multi-column layouts (best effort)
- [ ] Preserve paragraph structure where possible
- [ ] Save output as JSON (text blocks with positions)
- [ ] Unit tests with sample PDF (10 pages)
- [ ] Handle errors gracefully (corrupted PDFs, etc.)

**Output Format**:
```json
{
  "pages": [
    {
      "page_num": 1,
      "blocks": [
        {
          "id": "block-001",
          "text": "...",
          "bbox": [x, y, w, h],
          "page_num": 1
        }
      ]
    }
  ]
}
```

---

#### AL2-0005: PDF Metadata Extraction
**Assignee**: pdf-processor
**Estimated Time**: 2 hours

**Description**: Extract PDF metadata (title, author, page count, etc.)

**Acceptance Criteria**:
- [ ] Create `backend/processors/stage_1_extraction/metadata_extractor.py`
- [ ] Extract PDF metadata (title, author, creation date)
- [ ] Count total pages
- [ ] Detect if PDF is scanned (image-only pages)
- [ ] Calculate file size and document hash
- [ ] Save output as JSON
- [ ] Unit tests

**Output Format**:
```json
{
  "title": "Paper Title",
  "author": "Author Name",
  "page_count": 25,
  "creation_date": "2024-01-15",
  "file_size_bytes": 1234567,
  "is_scanned": false
}
```

---

#### AL2-0006: Quality Validation with Claude Vision
**Assignee**: pdf-processor
**Estimated Time**: 6 hours

**Description**: Validate extraction quality using Claude vision API

**Acceptance Criteria**:
- [ ] Create `backend/processors/stage_1_extraction/quality_checker.py`
- [ ] Implement Claude vision API client wrapper
- [ ] Convert PDF pages to images (for vision analysis)
- [ ] Sample 3-5 pages from document
- [ ] Send to Claude vision: "Does this extracted text match the image?"
- [ ] Parse Claude response for quality assessment
- [ ] Calculate coverage and accuracy estimates
- [ ] Assign quality band (excellent/good/acceptable/poor/failed)
- [ ] Detect common issues (page numbers in body, missing text)
- [ ] Save quality report as JSON
- [ ] Unit tests (with mocked Claude API)
- [ ] Integration test (with real Claude API)

**Output Format**:
```json
{
  "band": "good",
  "coverage_estimate": 0.97,
  "accuracy_estimate": 0.96,
  "confidence": "high",
  "issues": [
    "Page 5: Complex table simplified"
  ],
  "sampled_pages": [1, 3, 7]
}
```

---

#### AL2-0007: Stage 1 Orchestrator
**Assignee**: pdf-processor
**Estimated Time**: 3 hours

**Description**: Orchestrate Stage 1 extraction pipeline

**Acceptance Criteria**:
- [ ] Create `backend/processors/stage_1_extraction/extractor.py`
- [ ] Orchestrate: metadata → text → quality check
- [ ] Save all outputs to `processing_output/{doc_id}/stage_1_extraction/`
- [ ] Create `manifest.json` with processing metadata
- [ ] Handle partial failures (continue with warnings)
- [ ] Log progress and errors
- [ ] Emit status updates for frontend polling
- [ ] Integration test: end-to-end Stage 1 processing

---

### Task Group C: Backend - Stage 6 (Canvas Builder)

#### AL2-0008: Simple Canvas Layout
**Assignee**: canvas-architect
**Estimated Time**: 4 hours

**Description**: Create basic grid layout for text blocks

**Acceptance Criteria**:
- [ ] Create `backend/processors/stage_6_canvas/layout_engine.py`
- [ ] Implement simple grid layout algorithm
  - Position text blocks in reading order
  - Grid spacing: 20px horizontal, 40px vertical
  - Max width: 800px before wrapping to next row
- [ ] Calculate positions for all text blocks from Stage 1
- [ ] Return positions as dict: `{block_id: {x, y}}`
- [ ] Unit tests with sample text blocks

---

#### AL2-0009: TLDraw State Generation
**Assignee**: canvas-architect
**Estimated Time**: 6 hours

**Description**: Generate TLDraw JSON state from extracted text

**Acceptance Criteria**:
- [ ] Create `backend/processors/stage_6_canvas/canvas_builder.py`
- [ ] Define TLDraw shape schema for text nodes (Python dict/Pydantic)
- [ ] Convert text blocks to TLDraw text shapes
- [ ] Apply positions from layout engine
- [ ] Set basic styling (font, size, background)
- [ ] Generate complete TLDraw state JSON
- [ ] Save to `processing_output/{doc_id}/stage_6_canvas/tldraw_state.json`
- [ ] Validate output against TLDraw schema
- [ ] Unit tests
- [ ] Integration test: Stage 1 output → Stage 6 canvas

**Output**: Valid TLDraw 2.x JSON state

---

### Task Group D: Backend - API Endpoints

#### AL2-0010: File Upload Endpoint
**Assignee**: feature-developer
**Estimated Time**: 3 hours

**Description**: Implement PDF upload API

**Acceptance Criteria**:
- [ ] Create `backend/api/routes/upload.py`
- [ ] Implement `POST /api/upload` endpoint
- [ ] Accept multipart/form-data with PDF file
- [ ] Validate file is PDF (magic bytes)
- [ ] Enforce size limit (max 100MB)
- [ ] Generate unique document ID (UUID)
- [ ] Save PDF to `processing_output/{doc_id}/original.pdf`
- [ ] Return document ID and metadata
- [ ] Error handling (invalid file, too large, etc.)
- [ ] Unit tests with sample PDFs

---

#### AL2-0011: Processing Trigger Endpoint
**Assignee**: feature-developer
**Estimated Time**: 4 hours

**Description**: Implement processing trigger and status endpoints

**Acceptance Criteria**:
- [ ] Create `backend/api/routes/processing.py`
- [ ] Implement `POST /api/process/{doc_id}` endpoint
  - Trigger async processing (Stage 1 + Stage 6)
  - Return immediate response with "processing" status
- [ ] Implement `GET /api/status/{doc_id}` endpoint
  - Return current processing status
  - Include progress percentage
  - Return quality report when complete
- [ ] Use async task queue or threading for processing
- [ ] Update status file during processing
- [ ] Error handling (document not found, processing failed)
- [ ] Unit tests

---

#### AL2-0012: Canvas Retrieval Endpoint
**Assignee**: feature-developer
**Estimated Time**: 2 hours

**Description**: Implement canvas state retrieval API

**Acceptance Criteria**:
- [ ] Create `backend/api/routes/canvas.py`
- [ ] Implement `GET /api/canvas/{doc_id}` endpoint
- [ ] Load TLDraw state from Stage 6 output
- [ ] Include quality report in response
- [ ] Handle document not found / not yet processed
- [ ] Unit tests

---

### Task Group E: Frontend - Upload & Display

#### AL2-0013: PDF Upload Component
**Assignee**: feature-developer
**Estimated Time**: 4 hours

**Description**: Create drag-and-drop PDF upload UI

**Acceptance Criteria**:
- [ ] Create `frontend/src/components/UploadPanel.tsx`
- [ ] Implement drag-and-drop zone for PDF files
- [ ] Add file selector button as fallback
- [ ] Validate file type client-side
- [ ] Display file name and size before upload
- [ ] Show upload progress bar
- [ ] Call `POST /api/upload` with FormData
- [ ] Handle upload success (save document ID)
- [ ] Handle upload errors (display to user)
- [ ] Unit tests (with mocked API)

---

#### AL2-0014: Processing Status Component
**Assignee**: feature-developer
**Estimated Time**: 3 hours

**Description**: Display processing progress and quality report

**Acceptance Criteria**:
- [ ] Create `frontend/src/components/ProcessingStatus.tsx`
- [ ] Poll `GET /api/status/{doc_id}` every 2 seconds
- [ ] Display current stage and progress percentage
- [ ] Show spinner/progress indicator
- [ ] When complete, display quality report:
  - Quality band (with color coding)
  - Coverage and accuracy percentages
  - List of issues
- [ ] Handle processing errors (display error message)
- [ ] Stop polling when complete or failed
- [ ] Unit tests

---

#### AL2-0015: Basic Canvas Display
**Assignee**: canvas-architect
**Estimated Time**: 6 hours

**Description**: Render TLDraw canvas with extracted text

**Acceptance Criteria**:
- [ ] Create `frontend/src/canvas/CanvasApp.tsx`
- [ ] Initialize TLDraw editor component
- [ ] Fetch canvas state from `GET /api/canvas/{doc_id}`
- [ ] Load TLDraw state into editor
- [ ] Enable basic interactions (pan, zoom, select)
- [ ] Disable editing for Phase 1 (read-only)
- [ ] Handle loading states
- [ ] Handle errors (failed to load canvas)
- [ ] Unit tests
- [ ] E2E test: Full flow from upload to canvas display

---

#### AL2-0016: Main Application Layout
**Assignee**: feature-developer
**Estimated Time**: 3 hours

**Description**: Assemble components into main application

**Acceptance Criteria**:
- [ ] Create `frontend/src/App.tsx` main layout
- [ ] Left panel: Upload + Processing Status
- [ ] Right panel: Canvas Display (when ready)
- [ ] Handle application state (uploaded, processing, complete)
- [ ] Responsive layout (desktop only for Phase 1)
- [ ] Add basic styling (minimal CSS)
- [ ] Integration test: Full user flow

---

### Task Group F: Testing & Documentation

#### AL2-0017: Integration Testing
**Assignee**: test-runner
**Estimated Time**: 6 hours

**Description**: End-to-end integration tests

**Acceptance Criteria**:
- [ ] Create integration test suite
- [ ] Test: Upload sample PDF → Extract → Display canvas
- [ ] Test: Quality validation for good PDF
- [ ] Test: Quality validation for poor PDF
- [ ] Test: Error handling (corrupted PDF)
- [ ] Test: API error responses
- [ ] Test: Frontend error handling
- [ ] All tests passing
- [ ] Add tests to CI pipeline (if exists)

**Sample PDFs Needed**:
- Good quality academic paper (10 pages)
- Poor quality scanned paper (5 pages)
- Corrupted PDF file

---

#### AL2-0018: Performance Testing
**Assignee**: test-runner
**Estimated Time**: 4 hours

**Description**: Validate performance targets

**Acceptance Criteria**:
- [ ] Benchmark Stage 1 extraction (10, 25, 50 page PDFs)
- [ ] Benchmark Stage 6 canvas generation
- [ ] Benchmark API response times
- [ ] Benchmark canvas rendering (time to interactive)
- [ ] Verify targets met:
  - 10 pages: < 30 seconds total
  - 25 pages: < 60 seconds total
  - 50 pages: < 120 seconds total
- [ ] Document performance results
- [ ] Identify bottlenecks if targets not met

---

#### AL2-0019: User Documentation
**Assignee**: document-reviewer
**Estimated Time**: 4 hours

**Description**: Create user-facing documentation

**Acceptance Criteria**:
- [ ] Create `docs/user-guide/QUICK-START.md`
  - How to set up development environment
  - How to get Claude API key
  - How to upload and process a PDF
  - How to navigate the canvas
- [ ] Create `docs/user-guide/TROUBLESHOOTING.md`
  - Common errors and solutions
  - How to interpret quality reports
  - Performance tips
- [ ] Add screenshots/diagrams where helpful
- [ ] Review for clarity and completeness

---

#### AL2-0020: Developer Documentation
**Assignee**: document-reviewer
**Estimated Time**: 4 hours

**Description**: Document codebase for developers

**Acceptance Criteria**:
- [ ] Update main `README.md` with:
  - Architecture overview
  - Tech stack
  - Setup instructions
  - How to run tests
- [ ] Add `backend/DEVELOPMENT.md`:
  - Backend architecture
  - How to add new processors
  - API design patterns
- [ ] Add `frontend/DEVELOPMENT.md`:
  - Frontend architecture
  - How to extend canvas
  - Component patterns
- [ ] Add inline code comments for complex logic
- [ ] Review ADRs for accuracy

---

## Task Dependencies (Critical Path)

```
AL2-0001 (Backend Setup) → AL2-0004, AL2-0005, AL2-0006, AL2-0007
                         → AL2-0010, AL2-0011, AL2-0012

AL2-0002 (Frontend Setup) → AL2-0013, AL2-0014, AL2-0015, AL2-0016

AL2-0004, AL2-0005, AL2-0006 → AL2-0007 (Stage 1 Orchestrator)

AL2-0007 → AL2-0008, AL2-0009 (Stage 6)

AL2-0007, AL2-0009 → AL2-0011 (Processing Endpoint)

AL2-0011 → AL2-0014 (Status Component)

AL2-0012 → AL2-0015 (Canvas Display)

All implementation tasks → AL2-0017, AL2-0018 (Testing)

AL2-0017 passing → AL2-0019, AL2-0020 (Documentation)
```

## Resource Allocation

### Agents & Time Estimates

| Agent | Tasks | Estimated Hours | Priority |
|-------|-------|----------------|----------|
| feature-developer | AL2-0001, 0002, 0003, 0010, 0011, 0012, 0013, 0014, 0016 | 28 hours | High |
| pdf-processor | AL2-0004, 0005, 0006, 0007 | 15 hours | High |
| canvas-architect | AL2-0008, 0009, 0015 | 16 hours | High |
| test-runner | AL2-0017, 0018 | 10 hours | High |
| document-reviewer | AL2-0019, 0020 | 8 hours | Medium |

**Total Estimated Time**: 77 hours (~2 weeks with 1 full-time developer equivalent)

### Recommended Sequence

**Week 1: Core Infrastructure**
1. Day 1-2: AL2-0001, 0002, 0003 (Setup)
2. Day 2-4: AL2-0004, 0005 (Basic extraction)
3. Day 4-5: AL2-0006, 0007 (Quality validation + orchestration)

**Week 2: Canvas & Integration**
1. Day 1-2: AL2-0008, 0009 (Canvas builder)
2. Day 2-3: AL2-0010, 0011, 0012 (API endpoints)
3. Day 3-4: AL2-0013, 0014, 0015, 0016 (Frontend)
4. Day 4-5: AL2-0017, 0018 (Testing)
5. Day 5: AL2-0019, 0020 (Documentation)

## Risks & Mitigations

### Risk: Claude Vision API Costs Higher Than Expected
**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- Implement caching of vision results per document
- Only sample 3-5 pages instead of full document
- Add budget limit in configuration

### Risk: TLDraw State Generation More Complex Than Anticipated
**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- Start with simplest possible shapes (basic text boxes)
- Defer advanced styling to Phase 2
- Test with TLDraw examples early

### Risk: PDF Extraction Quality Poor for Multi-Column Layouts
**Probability**: High
**Impact**: Medium
**Mitigation**:
- Document limitations in quality report
- Set expectations with "acceptable" or "poor" band
- Add layout detection to backlog for Phase 2

### Risk: Performance Targets Not Met
**Probability**: Low
**Impact**: High
**Mitigation**:
- Profile early to identify bottlenecks
- Optimize most expensive operations first
- Consider parallel processing for page extraction

## Success Metrics (Phase 1)

At end of Phase 1, we should have:

**Functional Metrics**:
- [x] 100% of core tasks completed (AL2-0001 through AL2-0020)
- [x] All tests passing (unit + integration)
- [x] Processing 3+ sample PDFs successfully
- [x] Quality band "good" or better for high-quality PDFs

**Technical Metrics**:
- [x] Processing time < 1 minute for 10-page PDF
- [x] Test coverage > 70% for backend
- [x] Test coverage > 60% for frontend
- [x] Zero critical bugs

**Quality Metrics**:
- [x] User documentation complete and reviewable
- [x] Developer documentation complete
- [x] All ADRs reviewed and accurate
- [x] Code passes linting and type checking

## Next Steps After Phase 1

Upon Phase 1 completion:
1. **User Testing**: Have 2-3 users try the system with their own PDFs
2. **Feedback Collection**: Gather impressions and pain points
3. **Phase 2 Planning**: Define tasks for Stages 2-5 based on learnings
4. **Evaluation**: Run adversarial evaluation on Phase 2 plan
5. **Iteration**: Refine architecture based on Phase 1 experience

---

**Document Owner**: rem (coordinator)
**Last Updated**: 2025-11-27
**Status**: Ready for Task Creation
