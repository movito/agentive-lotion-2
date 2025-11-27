# ADR-0002: Python Backend + TypeScript Frontend

**Status**: Accepted

**Date**: 2025-11-27

**Deciders**: rem (coordinator), user

## Context

### Problem Statement

Agentive Lotion 2 requires two distinct technical domains:
1. **Document Processing**: PDF parsing, OCR, NLP, thematic analysis
2. **Interactive Canvas**: Real-time visual interface with TLDraw

We need to choose a technology stack that optimizes for both domains while maintaining clean separation of concerns.

### Forces at Play

**Technical Requirements:**
- High-quality PDF extraction and analysis
- Advanced NLP for thematic clustering
- OCR/computer vision for poorly formatted PDFs
- Modern, responsive canvas interface
- Real-time user interactions
- Maintainable codebase

**Constraints:**
- Single-user desktop application (local deployment)
- Team expertise in Python and TypeScript
- Need to integrate existing libraries (PyMuPDF, pdfplumber, TLDraw)
- Performance requirements for 2-50 page documents

**Assumptions:**
- Processing can be asynchronous (not real-time during extraction)
- Canvas rendering happens after processing completes
- User tolerates seconds-to-minutes processing time

## Decision

**Separate Python API for document processing, TypeScript/React frontend for canvas UI.**

### Core Principles

1. **Use the Right Tool for the Job**: Python excels at data science/ML tasks; TypeScript/React excels at interactive UIs
2. **Clear Separation**: Processing logic completely independent of presentation
3. **API-First Design**: Well-defined contract between backend and frontend

### Implementation Details

**Backend (Python):**
- FastAPI or Flask for REST API
- PDF processing libraries (PyMuPDF, pdfplumber)
- Claude Code vision API integration
- NLP libraries for thematic analysis
- File-based storage for intermediate stages

**Frontend (TypeScript/React):**
- React for UI framework
- TLDraw for canvas rendering
- State management (TBD: Redux, Zustand, or Context)
- API client for backend communication

**Communication:**
- RESTful API or WebSocket for processing status
- JSON payloads for data exchange
- File uploads for PDF input
- JSON download for canvas state

**Project Structure:**
```
agentive-lotion-2/
├── backend/               # Python package
│   ├── api/              # FastAPI endpoints
│   ├── processors/       # PDF processing stages
│   ├── models/           # Data models
│   └── tests/            # Backend tests
├── frontend/             # TypeScript/React app
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── canvas/      # TLDraw integration
│   │   ├── api/         # Backend client
│   │   └── types/       # TypeScript types
│   └── tests/           # Frontend tests
└── shared/              # Shared types/schemas
```

## Consequences

### Positive

- ✅ **Language Strengths**: Python's rich PDF/ML ecosystem + TypeScript's UI capabilities
- ✅ **Independent Development**: Backend and frontend can be developed/tested separately
- ✅ **Clear Contracts**: API-first design forces well-defined interfaces
- ✅ **Scalability Path**: Easy to scale backend independently if needed
- ✅ **Testability**: Each layer can be unit tested in isolation
- ✅ **Technology Flexibility**: Can swap implementations without rewriting entire stack

### Negative

- ⚠️ **Additional Complexity**: Two languages, two build systems, API versioning
- ⚠️ **Type Synchronization**: Need to keep TypeScript types in sync with Python models
- ⚠️ **Development Setup**: More complex local development environment
- ⚠️ **Deployment**: Need to package both backend and frontend for distribution

### Neutral

- 📊 **Learning Curve**: Team already knows both languages
- 📊 **Tooling**: Standard tooling available for both stacks
- 📊 **Community Support**: Both ecosystems well-supported

## Alternatives Considered

### Alternative 1: Full Python Stack (e.g., Dash, Streamlit)

**Description**: Use Python for both processing and UI via frameworks like Dash or Streamlit.

**Rejected because**:
- ❌ Limited UI flexibility compared to React
- ❌ TLDraw is a JavaScript library, difficult to integrate with Python UI
- ❌ Python UI frameworks not optimized for complex interactive canvases
- ❌ Would require custom WebGL/canvas integration

### Alternative 2: Full JavaScript/TypeScript Stack

**Description**: Use Node.js for backend with JavaScript PDF libraries.

**Rejected because**:
- ❌ JavaScript PDF libraries less mature than Python alternatives
- ❌ Limited NLP/ML ecosystem compared to Python
- ❌ OCR/computer vision tools better in Python ecosystem
- ❌ Would lose access to PyMuPDF, pdfplumber quality

### Alternative 3: Monorepo with Python + Electron

**Description**: Embed Python backend in Electron app with TypeScript frontend.

**Rejected because**:
- ❌ Electron adds significant complexity and bundle size
- ❌ Distribution becomes more complex (shipping Python runtime)
- ❌ Doesn't provide benefits for single-user desktop app
- ❌ Can reconsider for later packaging/distribution phase

## Real-World Results

[To be filled after Phase 1 implementation]

**Before this decision:**
- N/A (greenfield project)

**After this decision:**
- [Metrics to track: development velocity, test coverage, bug rate]

## Related Decisions

- ADR-0003: JSON + File System for Initial Storage (storage format)
- ADR-0004: Claude Vision with Local Model Hooks (backend AI integration)
- ADR-0005: TLDraw Composition over Fork (frontend canvas strategy)

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PyMuPDF (fitz) Documentation](https://pymupdf.readthedocs.io/)
- [TLDraw Documentation](https://tldraw.dev/)
- [React Documentation](https://react.dev/)

## Revision History

- 2025-11-27: Initial decision (Accepted)

---

**Template Version**: 1.1.0
**Project**: Agentive Lotion 2
**Naming Convention**: ADR-####-description.md
