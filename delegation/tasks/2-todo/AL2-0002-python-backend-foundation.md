# AL2-0002: Python Backend Foundation

**Status**: Todo
**Priority**: Critical (Phase 1 foundation)
**Assigned To**: feature-developer
**Estimated Effort**: 4-6 hours
**Created**: 2025-11-28
**Project**: Agentive Lotion 2
**Phase**: 1.0 (Backend Foundation)
**Related ADR**: ADR-0002-python-backend-typescript-frontend.md

## Overview

Establish the Python backend foundation for Agentive Lotion 2's PDF processing pipeline. This creates the FastAPI-based REST API that will handle document uploads, orchestrate the 6-stage processing pipeline, and serve results to the TypeScript frontend.

**Why this matters**: The backend is the brain of the system - it coordinates PDF extraction, AI analysis, and data transformation. Getting the architecture right now prevents refactoring pain later.

**Context**: Based on ADR-0002, we're building a Python backend separate from the TypeScript/React canvas UI. The backend handles computationally intensive tasks (PDF parsing, OCR, NLP) while the frontend focuses on visualization.

## Requirements

### Must Have

- [ ] **Project Structure**: Create `backend/` package with proper Python package layout
- [ ] **FastAPI Application**: Set up FastAPI app with CORS, error handling, basic health check
- [ ] **API Endpoints Scaffold**: Create endpoint placeholders for document upload, processing status, results retrieval
- [ ] **Pydantic Models**: Define data models for requests/responses (DocumentUpload, ProcessingStatus, CanvasState)
- [ ] **File Upload Handler**: Implement PDF file upload with validation (size limits, file type checking)
- [ ] **Processing Directory**: Create `processing_output/{document_id}/` structure
- [ ] **Async Processing**: Set up background task handling for long-running PDF processing
- [ ] **Dependency Injection**: Configure FastAPI dependencies for services and configuration
- [ ] **Environment Config**: Load settings from `.env` (API keys, file paths, limits)
- [ ] **Unit Tests**: Test endpoints with mocked processing pipeline

### Should Have

- [ ] **API Documentation**: Auto-generated OpenAPI/Swagger docs at `/docs`
- [ ] **Request Validation**: Comprehensive input validation with helpful error messages
- [ ] **Logging Setup**: Structured logging with request IDs for debugging
- [ ] **Error Responses**: Consistent error response format with status codes
- [ ] **Progress Tracking**: WebSocket or SSE for real-time processing status updates

### Nice to Have

- [ ] **Rate Limiting**: Basic rate limiting for API endpoints
- [ ] **Request Tracing**: Correlation IDs across requests for debugging
- [ ] **Metrics Endpoint**: Prometheus-compatible `/metrics` endpoint
- [ ] **API Versioning**: `/api/v1/` prefix for future compatibility

## Technical Design

### Project Structure

```
backend/
├── __init__.py
├── main.py                 # FastAPI app entry point
├── config.py               # Settings from environment
├── api/
│   ├── __init__.py
│   ├── endpoints/
│   │   ├── __init__.py
│   │   ├── documents.py    # POST /documents, GET /documents/{id}
│   │   ├── processing.py   # GET /processing/{job_id}/status
│   │   └── health.py       # GET /health
│   └── dependencies.py     # FastAPI dependencies
├── models/
│   ├── __init__.py
│   ├── requests.py         # Pydantic request models
│   ├── responses.py        # Pydantic response models
│   └── domain.py           # Domain models (Document, ProcessingJob)
├── services/
│   ├── __init__.py
│   ├── document_service.py # Document CRUD operations
│   └── processing_service.py # Orchestrates 6-stage pipeline
├── processors/             # (Placeholder for AL2-0004)
│   ├── __init__.py
│   └── README.md           # "Processing stages will go here"
└── tests/
    ├── __init__.py
    ├── test_api/
    │   ├── test_documents.py
    │   ├── test_processing.py
    │   └── test_health.py
    └── test_services/
        └── test_document_service.py
```

### Core API Endpoints

#### 1. Document Upload
```python
POST /api/v1/documents
Content-Type: multipart/form-data

Request:
- file: PDF file (max 50MB)
- options: JSON { "quality_band": "high" | "medium" | "low" }

Response: 201 Created
{
  "document_id": "uuid",
  "filename": "paper.pdf",
  "size_bytes": 1024000,
  "processing_job_id": "uuid",
  "status": "queued"
}
```

#### 2. Processing Status
```python
GET /api/v1/processing/{job_id}/status

Response: 200 OK
{
  "job_id": "uuid",
  "document_id": "uuid",
  "status": "processing" | "completed" | "failed",
  "current_stage": 3,
  "total_stages": 6,
  "progress_percent": 50,
  "stages": [
    {
      "stage": 1,
      "name": "extraction",
      "status": "completed",
      "duration_ms": 1234
    },
    {
      "stage": 2,
      "name": "structure",
      "status": "completed",
      "duration_ms": 567
    },
    {
      "stage": 3,
      "name": "themes",
      "status": "in_progress",
      "duration_ms": null
    }
  ],
  "error": null
}
```

#### 3. Retrieve Results
```python
GET /api/v1/documents/{document_id}/canvas

Response: 200 OK
{
  "document_id": "uuid",
  "canvas_state": {
    // TLDraw JSON state from stage_6_canvas/tldraw_state.json
  },
  "metadata": {
    "processing_completed": "2025-11-28T12:00:00Z",
    "quality_metrics": {...}
  }
}
```

#### 4. Health Check
```python
GET /health

Response: 200 OK
{
  "status": "healthy",
  "version": "0.1.0",
  "dependencies": {
    "storage": "ok",
    "python_version": "3.9.18"
  }
}
```

### Pydantic Models Example

```python
# backend/models/requests.py
from pydantic import BaseModel, Field
from typing import Literal

class DocumentUploadOptions(BaseModel):
    quality_band: Literal["high", "medium", "low"] = "medium"
    preserve_intermediate_stages: bool = True

class DocumentUploadResponse(BaseModel):
    document_id: str
    filename: str
    size_bytes: int
    processing_job_id: str
    status: Literal["queued", "processing", "completed", "failed"]

class ProcessingStatus(BaseModel):
    job_id: str
    document_id: str
    status: Literal["queued", "processing", "completed", "failed"]
    current_stage: int
    total_stages: int = 6
    progress_percent: float
    error: str | None = None
```

### Configuration

```python
# backend/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # API Configuration
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    cors_origins: list[str] = ["http://localhost:5173"]  # Vite default

    # File Upload
    max_file_size_mb: int = 50
    allowed_extensions: list[str] = [".pdf"]

    # Processing
    processing_output_dir: str = "processing_output"
    cleanup_intermediate_stages: bool = False

    # AI Services (for future use)
    anthropic_api_key: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
```

## Implementation Steps

### Step 1: Create Backend Package Structure

```bash
# Create directory structure
mkdir -p backend/{api/endpoints,models,services,processors,tests/{test_api,test_services}}
touch backend/__init__.py
touch backend/{main.py,config.py}
touch backend/api/{__init__.py,dependencies.py}
touch backend/api/endpoints/{__init__.py,documents.py,processing.py,health.py}
touch backend/models/{__init__.py,requests.py,responses.py,domain.py}
touch backend/services/{__init__.py,document_service.py,processing_service.py}
touch backend/processors/{__init__.py,README.md}
touch backend/tests/__init__.py
```

### Step 2: Install Backend Dependencies

Add to `pyproject.toml`:

```toml
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
    "python-multipart>=0.0.6",  # For file uploads
    "aiofiles>=23.0.0",         # Async file operations
]
```

Install:
```bash
source venv/bin/activate
pip install -e ".[dev]"
```

### Step 3: Implement FastAPI Application

Create `backend/main.py`:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.config import settings
from backend.api.endpoints import documents, processing, health

app = FastAPI(
    title="Agentive Lotion 2 API",
    description="PDF to Interactive Canvas Processing Pipeline",
    version="0.1.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, tags=["health"])
app.include_router(documents.router, prefix="/api/v1", tags=["documents"])
app.include_router(processing.router, prefix="/api/v1", tags=["processing"])

@app.get("/")
async def root():
    return {
        "message": "Agentive Lotion 2 API",
        "docs": "/docs",
        "health": "/health"
    }
```

### Step 4: Implement Health Check Endpoint

Create `backend/api/endpoints/health.py`:

```python
from fastapi import APIRouter
from backend.config import settings
import sys

router = APIRouter()

@router.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "0.1.0",
        "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
        "environment": "development"
    }
```

### Step 5: Implement Document Upload Endpoint

Create `backend/api/endpoints/documents.py`:

```python
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from backend.models.requests import DocumentUploadResponse
from backend.services.document_service import DocumentService
from backend.api.dependencies import get_document_service
import uuid

router = APIRouter()

@router.post("/documents", response_model=DocumentUploadResponse, status_code=201)
async def upload_document(
    file: UploadFile = File(...),
    document_service: DocumentService = Depends(get_document_service)
):
    """Upload a PDF document for processing."""

    # Validate file type
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are supported")

    # Validate file size
    contents = await file.read()
    if len(contents) > 50 * 1024 * 1024:  # 50MB limit
        raise HTTPException(status_code=413, detail="File size exceeds 50MB limit")

    # Create document
    document_id = str(uuid.uuid4())
    processing_job_id = str(uuid.uuid4())

    # Save uploaded file
    await document_service.save_uploaded_file(document_id, file.filename, contents)

    # Queue processing (placeholder - will be implemented in next task)
    # await processing_service.queue_processing(document_id, processing_job_id)

    return DocumentUploadResponse(
        document_id=document_id,
        filename=file.filename,
        size_bytes=len(contents),
        processing_job_id=processing_job_id,
        status="queued"
    )

@router.get("/documents/{document_id}/canvas")
async def get_document_canvas(
    document_id: str,
    document_service: DocumentService = Depends(get_document_service)
):
    """Retrieve processed canvas state for a document."""
    # Placeholder - will load from processing_output/{document_id}/stage_6_canvas/
    return {"document_id": document_id, "canvas_state": {}, "message": "Canvas retrieval not yet implemented"}
```

### Step 6: Implement Document Service

Create `backend/services/document_service.py`:

```python
from pathlib import Path
import aiofiles
from backend.config import settings

class DocumentService:
    """Manages document storage and retrieval."""

    def __init__(self):
        self.output_dir = Path(settings.processing_output_dir)
        self.output_dir.mkdir(exist_ok=True)

    async def save_uploaded_file(self, document_id: str, filename: str, contents: bytes):
        """Save uploaded PDF to processing directory."""
        doc_dir = self.output_dir / document_id
        doc_dir.mkdir(exist_ok=True)

        # Save original PDF
        pdf_path = doc_dir / "original.pdf"
        async with aiofiles.open(pdf_path, 'wb') as f:
            await f.write(contents)

        # Save metadata
        metadata = {
            "document_id": document_id,
            "original_filename": filename,
            "size_bytes": len(contents)
        }

        import json
        metadata_path = doc_dir / "metadata.json"
        async with aiofiles.open(metadata_path, 'w') as f:
            await f.write(json.dumps(metadata, indent=2))

        return pdf_path
```

### Step 7: Write Unit Tests

Create `backend/tests/test_api/test_health.py`:

```python
import pytest
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)

def test_health_check():
    """Test that health endpoint returns 200 OK."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data
    assert "python_version" in data

def test_root_endpoint():
    """Test that root endpoint returns API info."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "Agentive Lotion 2" in data["message"]
    assert data["docs"] == "/docs"
```

Create `backend/tests/test_api/test_documents.py`:

```python
import pytest
from fastapi.testclient import TestClient
from backend.main import app
from io import BytesIO

client = TestClient(app)

def test_upload_pdf_success():
    """Test successful PDF upload."""
    # Create a fake PDF file
    pdf_content = b"%PDF-1.4\n%fake pdf content"
    files = {"file": ("test.pdf", BytesIO(pdf_content), "application/pdf")}

    response = client.post("/api/v1/documents", files=files)

    assert response.status_code == 201
    data = response.json()
    assert "document_id" in data
    assert data["filename"] == "test.pdf"
    assert data["status"] == "queued"

def test_upload_non_pdf_rejected():
    """Test that non-PDF files are rejected."""
    files = {"file": ("test.txt", BytesIO(b"not a pdf"), "text/plain")}

    response = client.post("/api/v1/documents", files=files)

    assert response.status_code == 400
    assert "Only PDF files" in response.json()["detail"]
```

### Step 8: Run and Test Backend

```bash
# Run backend server
cd backend
uvicorn main:app --reload --port 8000

# Test in another terminal
curl http://localhost:8000/health

# Open API docs
open http://localhost:8000/docs
```

## Testing Checklist

- [ ] `pytest backend/tests/ -v` passes all tests
- [ ] FastAPI server starts without errors
- [ ] `/health` endpoint returns 200 OK
- [ ] OpenAPI docs accessible at `/docs`
- [ ] PDF upload creates `processing_output/{document_id}/` directory
- [ ] PDF upload saves `original.pdf` and `metadata.json`
- [ ] Non-PDF files are rejected with 400 error
- [ ] Files >50MB are rejected with 413 error
- [ ] CORS allows requests from localhost:5173

## Success Criteria

✅ **Backend Foundation Complete When:**
1. FastAPI server runs and serves `/health` endpoint
2. Document upload endpoint accepts PDFs, creates directory structure
3. All unit tests pass (`pytest backend/` returns 100% pass rate)
4. OpenAPI documentation accessible and accurate
5. Code follows Python best practices (black + ruff pass)
6. Can be run from project root: `uvicorn backend.main:app`

## Dependencies

**Blocks**: AL2-0003 (Frontend needs this API to communicate with)
**Blocked By**: AL2-0001 (CI/CD setup - DONE ✅)
**Related**:
- AL2-0004: JSON Storage Infrastructure (will use file structure created here)
- AL2-0005: Vision Service Abstraction Layer (will plug into processing pipeline)

## Notes

- This task creates the **skeleton** of the backend - processing logic comes in later tasks
- Focus on API contract and structure, not processing implementation
- The 6-stage processing pipeline will be filled in incrementally
- Backend should be independently testable without frontend
- Consider adding `make` commands for common operations (`make run-backend`, `make test-backend`)

---

**Related ADR**: ADR-0002-python-backend-typescript-frontend.md
**Created By**: rem (coordinator)
**Last Updated**: 2025-11-28
