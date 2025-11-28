# AL2-0004: JSON Storage Infrastructure

**Status**: Todo
**Priority**: High (Phase 1 foundation)
**Assigned To**: feature-developer
**Estimated Effort**: 3-4 hours
**Created**: 2025-11-28
**Project**: Agentive Lotion 2
**Phase**: 1.0 (Storage Foundation)
**Related ADR**: ADR-0003-json-filesystem-storage.md

## Overview

Implement the JSON + file system storage infrastructure for the 6-stage PDF processing pipeline. This creates a clean, inspectable, agent-friendly directory structure that preserves intermediate stages for debugging, quality improvement, and review.

**Why this matters**: Simple file-based storage enables rapid development, easy debugging, and agent review without database complexity. Every processing stage is human-readable and independently testable.

**Context**: Based on ADR-0003, we're using JSON files on disk instead of a database. Each document gets its own directory with subdirectories for the 6 processing stages. This approach prioritizes simplicity, inspectability, and development velocity.

## Requirements

### Must Have

- [ ] **Storage Service**: Create `StorageService` class for managing document storage
- [ ] **Directory Structure**: Implement automatic creation of stage directories (1-6)
- [ ] **JSON Writers**: Helper functions to write structured data atomically
- [ ] **JSON Readers**: Helper functions to read stage data with validation
- [ ] **Manifest Tracking**: Create/update `manifest.json` for each document
- [ ] **Image Management**: Helper functions to save/load extracted images
- [ ] **Atomic Writes**: Use temp files + move to prevent partial writes
- [ ] **Path Resolution**: Helper to get paths for document stages
- [ ] **Unit Tests**: Test storage operations, concurrent writes, error handling

### Should Have

- [ ] **JSON Schema Validation**: Validate JSON structure when reading/writing
- [ ] **Compression**: Optional gzip compression for JSON files
- [ ] **Cleanup Utility**: Function to delete intermediate stages after completion
- [ ] **Storage Stats**: Function to calculate disk usage per document
- [ ] **Error Recovery**: Handle corrupted JSON files gracefully

### Nice to Have

- [ ] **Migration Script**: Convert old structure to new structure (for future changes)
- [ ] **Storage Inspector**: CLI tool to browse processing output
- [ ] **JSON Pretty Print**: Configurable indentation for readability

## Technical Design

### Directory Structure (Per Document)

```
processing_output/
├── {document_id}/
│   ├── manifest.json              # Processing metadata
│   ├── original.pdf               # Uploaded PDF
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
│   └── stage_6_canvas/
│       └── tldraw_state.json      # Final canvas state
```

### Storage Service Implementation

```python
# backend/services/storage_service.py
from pathlib import Path
from typing import Any, Dict, List, Optional
import json
import uuid
import shutil
from datetime import datetime
import aiofiles
import aiofiles.os

class StorageService:
    """Manages document storage using JSON + file system."""

    STAGE_NAMES = {
        1: "stage_1_extraction",
        2: "stage_2_structure",
        3: "stage_3_themes",
        4: "stage_4_citations",
        5: "stage_5_visual",
        6: "stage_6_canvas",
    }

    def __init__(self, base_dir: str = "processing_output"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(exist_ok=True)

    def get_document_dir(self, document_id: str) -> Path:
        """Get the directory path for a document."""
        return self.base_dir / document_id

    def get_stage_dir(self, document_id: str, stage: int) -> Path:
        """Get the directory path for a specific processing stage."""
        stage_name = self.STAGE_NAMES.get(stage)
        if not stage_name:
            raise ValueError(f"Invalid stage number: {stage}")
        return self.get_document_dir(document_id) / stage_name

    async def initialize_document(
        self, document_id: str, filename: str, file_size: int
    ) -> None:
        """Create directory structure and manifest for a new document."""
        doc_dir = self.get_document_dir(document_id)
        doc_dir.mkdir(exist_ok=True)

        # Create stage directories
        for stage in range(1, 7):
            stage_dir = self.get_stage_dir(document_id, stage)
            stage_dir.mkdir(exist_ok=True)

            # Create images subdirectory for stages that need it
            if stage in [1, 5]:
                (stage_dir / "images").mkdir(exist_ok=True)

        # Create manifest
        manifest = {
            "document_id": document_id,
            "original_filename": filename,
            "file_size_bytes": file_size,
            "processing_started": datetime.utcnow().isoformat(),
            "processing_completed": None,
            "stages_completed": [],
            "quality_metrics": {},
        }

        await self.write_manifest(document_id, manifest)

    async def write_json(
        self, document_id: str, stage: int, filename: str, data: Dict[str, Any]
    ) -> None:
        """Write JSON data to a stage directory atomically."""
        stage_dir = self.get_stage_dir(document_id, stage)
        target_path = stage_dir / filename

        # Atomic write: write to temp file, then move
        temp_path = target_path.with_suffix(".tmp")

        async with aiofiles.open(temp_path, "w") as f:
            await f.write(json.dumps(data, indent=2))

        # Atomic move
        await aiofiles.os.rename(temp_path, target_path)

    async def read_json(
        self, document_id: str, stage: int, filename: str
    ) -> Optional[Dict[str, Any]]:
        """Read JSON data from a stage directory."""
        stage_dir = self.get_stage_dir(document_id, stage)
        file_path = stage_dir / filename

        if not file_path.exists():
            return None

        async with aiofiles.open(file_path, "r") as f:
            content = await f.read()
            return json.loads(content)

    async def write_manifest(
        self, document_id: str, manifest: Dict[str, Any]
    ) -> None:
        """Update the document manifest."""
        doc_dir = self.get_document_dir(document_id)
        manifest_path = doc_dir / "manifest.json"

        # Atomic write
        temp_path = manifest_path.with_suffix(".tmp")

        async with aiofiles.open(temp_path, "w") as f:
            await f.write(json.dumps(manifest, indent=2))

        await aiofiles.os.rename(temp_path, manifest_path)

    async def read_manifest(self, document_id: str) -> Optional[Dict[str, Any]]:
        """Read the document manifest."""
        doc_dir = self.get_document_dir(document_id)
        manifest_path = doc_dir / "manifest.json"

        if not manifest_path.exists():
            return None

        async with aiofiles.open(manifest_path, "r") as f:
            content = await f.read()
            return json.loads(content)

    async def mark_stage_complete(
        self, document_id: str, stage: int, duration_ms: int
    ) -> None:
        """Mark a processing stage as completed in the manifest."""
        manifest = await self.read_manifest(document_id)
        if not manifest:
            raise ValueError(f"Manifest not found for document {document_id}")

        if stage not in manifest["stages_completed"]:
            manifest["stages_completed"].append(stage)

        # Update quality metrics with stage timing
        if "stage_timings" not in manifest["quality_metrics"]:
            manifest["quality_metrics"]["stage_timings"] = {}

        manifest["quality_metrics"]["stage_timings"][f"stage_{stage}"] = duration_ms

        await self.write_manifest(document_id, manifest)

    async def save_image(
        self, document_id: str, stage: int, image_name: str, image_data: bytes
    ) -> Path:
        """Save an image file to a stage's images directory."""
        stage_dir = self.get_stage_dir(document_id, stage)
        images_dir = stage_dir / "images"
        images_dir.mkdir(exist_ok=True)

        image_path = images_dir / image_name

        async with aiofiles.open(image_path, "wb") as f:
            await f.write(image_data)

        return image_path

    async def list_images(self, document_id: str, stage: int) -> List[str]:
        """List all images in a stage's images directory."""
        stage_dir = self.get_stage_dir(document_id, stage)
        images_dir = stage_dir / "images"

        if not images_dir.exists():
            return []

        return [p.name for p in images_dir.iterdir() if p.is_file()]

    def get_storage_stats(self, document_id: str) -> Dict[str, Any]:
        """Calculate storage statistics for a document."""
        doc_dir = self.get_document_dir(document_id)

        if not doc_dir.exists():
            return {"error": "Document not found"}

        total_size = sum(f.stat().st_size for f in doc_dir.rglob("*") if f.is_file())
        file_count = len(list(doc_dir.rglob("*")))

        return {
            "document_id": document_id,
            "total_size_bytes": total_size,
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "file_count": file_count,
        }
```

### JSON Schema Examples

```json
// manifest.json
{
  "document_id": "a1b2c3d4-5678-90ab-cdef-123456789012",
  "original_filename": "research_paper.pdf",
  "file_size_bytes": 2048000,
  "processing_started": "2025-11-28T10:00:00Z",
  "processing_completed": "2025-11-28T10:05:23Z",
  "stages_completed": [1, 2, 3, 4, 5, 6],
  "quality_metrics": {
    "extraction_accuracy": 95,
    "stage_timings": {
      "stage_1": 1234,
      "stage_2": 567,
      "stage_3": 2345,
      "stage_4": 890,
      "stage_5": 1200,
      "stage_6": 450
    }
  }
}
```

```json
// stage_1_extraction/text.json
{
  "blocks": [
    {
      "block_id": "block-001",
      "page": 1,
      "text": "Introduction\n\nThis paper presents...",
      "bbox": [72, 100, 523, 300],
      "font_size": 12,
      "font_family": "Times New Roman"
    }
  ],
  "total_blocks": 45,
  "extraction_method": "pymupdf"
}
```

```json
// stage_3_themes/clusters.json
{
  "clusters": [
    {
      "id": "cluster-001",
      "theme": "Machine Learning Methods",
      "tags": ["ML", "neural networks", "training"],
      "content_block_ids": ["block-001", "block-045", "block-078"],
      "confidence": 0.89,
      "color": "#FF5733"
    },
    {
      "id": "cluster-002",
      "theme": "Experimental Results",
      "tags": ["results", "evaluation", "metrics"],
      "content_block_ids": ["block-023", "block-067"],
      "confidence": 0.92,
      "color": "#33FF57"
    }
  ]
}
```

## Implementation Steps

### Step 1: Create Storage Service

1. Create `backend/services/storage_service.py`
2. Implement `StorageService` class (as shown above)
3. Add async file operations with `aiofiles`

### Step 2: Add Dependencies

Update `pyproject.toml`:

```toml
dependencies = [
    # ... existing ...
    "aiofiles>=23.0.0",
]
```

### Step 3: Integrate with Document Service

Update `backend/services/document_service.py`:

```python
from backend.services.storage_service import StorageService

class DocumentService:
    def __init__(self):
        self.storage = StorageService()

    async def create_document(self, document_id: str, filename: str, contents: bytes):
        """Create document and initialize storage structure."""
        # Initialize storage
        await self.storage.initialize_document(
            document_id, filename, len(contents)
        )

        # Save original PDF
        doc_dir = self.storage.get_document_dir(document_id)
        pdf_path = doc_dir / "original.pdf"

        async with aiofiles.open(pdf_path, 'wb') as f:
            await f.write(contents)

        return pdf_path
```

### Step 4: Write Unit Tests

Create `backend/tests/test_services/test_storage_service.py`:

```python
import pytest
import tempfile
import shutil
from pathlib import Path
from backend.services.storage_service import StorageService

@pytest.fixture
def temp_storage():
    """Create a temporary storage directory for testing."""
    temp_dir = tempfile.mkdtemp()
    storage = StorageService(base_dir=temp_dir)
    yield storage
    shutil.rmtree(temp_dir)

@pytest.mark.asyncio
async def test_initialize_document(temp_storage):
    """Test that document initialization creates correct structure."""
    document_id = "test-doc-001"

    await temp_storage.initialize_document(document_id, "test.pdf", 1024)

    # Verify directory structure
    doc_dir = temp_storage.get_document_dir(document_id)
    assert doc_dir.exists()

    # Verify all stage directories exist
    for stage in range(1, 7):
        stage_dir = temp_storage.get_stage_dir(document_id, stage)
        assert stage_dir.exists()

    # Verify images directories exist
    assert (temp_storage.get_stage_dir(document_id, 1) / "images").exists()
    assert (temp_storage.get_stage_dir(document_id, 5) / "images").exists()

    # Verify manifest created
    manifest = await temp_storage.read_manifest(document_id)
    assert manifest is not None
    assert manifest["document_id"] == document_id
    assert manifest["original_filename"] == "test.pdf"

@pytest.mark.asyncio
async def test_write_and_read_json(temp_storage):
    """Test JSON write and read operations."""
    document_id = "test-doc-002"
    await temp_storage.initialize_document(document_id, "test.pdf", 1024)

    # Write JSON data
    test_data = {"test_key": "test_value", "numbers": [1, 2, 3]}
    await temp_storage.write_json(document_id, 1, "test.json", test_data)

    # Read JSON data
    result = await temp_storage.read_json(document_id, 1, "test.json")

    assert result == test_data

@pytest.mark.asyncio
async def test_mark_stage_complete(temp_storage):
    """Test marking stages as complete."""
    document_id = "test-doc-003"
    await temp_storage.initialize_document(document_id, "test.pdf", 1024)

    # Mark stage 1 complete
    await temp_storage.mark_stage_complete(document_id, 1, 1234)

    # Verify manifest updated
    manifest = await temp_storage.read_manifest(document_id)
    assert 1 in manifest["stages_completed"]
    assert manifest["quality_metrics"]["stage_timings"]["stage_1"] == 1234

@pytest.mark.asyncio
async def test_save_and_list_images(temp_storage):
    """Test image save and list operations."""
    document_id = "test-doc-004"
    await temp_storage.initialize_document(document_id, "test.pdf", 1024)

    # Save test image
    image_data = b"fake image data"
    await temp_storage.save_image(document_id, 1, "test_img.png", image_data)

    # List images
    images = await temp_storage.list_images(document_id, 1)
    assert "test_img.png" in images

def test_get_storage_stats(temp_storage):
    """Test storage statistics calculation."""
    document_id = "test-doc-005"
    # Create a simple document structure
    doc_dir = temp_storage.get_document_dir(document_id)
    doc_dir.mkdir()
    (doc_dir / "test.txt").write_text("test content")

    stats = temp_storage.get_storage_stats(document_id)
    assert stats["document_id"] == document_id
    assert stats["total_size_bytes"] > 0
    assert stats["file_count"] > 0
```

### Step 5: Test Storage Service

```bash
# Run tests
pytest backend/tests/test_services/test_storage_service.py -v

# Test storage stats for a document
python -c "
from backend.services.storage_service import StorageService
storage = StorageService()
print(storage.get_storage_stats('test-doc-001'))
"
```

## Testing Checklist

- [ ] All unit tests pass (`pytest backend/tests/test_services/test_storage_service.py`)
- [ ] Document initialization creates all 6 stage directories
- [ ] JSON write/read operations work correctly
- [ ] Atomic writes prevent partial file corruption
- [ ] Manifest tracks stages completed and timing
- [ ] Image save/load operations work
- [ ] Storage stats calculation accurate
- [ ] Handles concurrent writes safely
- [ ] Error handling for missing files/directories

## Success Criteria

✅ **Storage Infrastructure Complete When:**
1. `StorageService` class fully implemented and tested
2. All 6 stage directories created automatically
3. JSON read/write operations atomic and reliable
4. Manifest tracking works for all processing stages
5. Image management functions operational
6. All unit tests pass (100% coverage for storage service)
7. Can handle multiple concurrent document processing
8. Storage stats accurately calculate disk usage

## Dependencies

**Blocks**:
- AL2-0006: Processing Pipeline Stage 1 (extraction needs to write to storage)
- AL2-0007+: All subsequent processing stages use this storage

**Blocked By**:
- AL2-0001: CI/CD setup (DONE ✅)

**Related**:
- AL2-0002: Python Backend Foundation (storage service integrates with backend)
- ADR-0003: JSON + File System Storage (architecture guidance)

## Notes

- Storage service is **synchronous-safe and async-safe** (using aiofiles)
- Atomic writes prevent partial file corruption during crashes
- JSON pretty-printing (indent=2) makes files agent-reviewable
- Consider adding JSON schema validation in future for robustness
- Image files stored as PNG for universal compatibility
- Cleanup utility (deleting intermediate stages) can be added post-Phase 1
- Storage service is backend-agnostic (could switch to S3/database later)

---

**Related ADR**: ADR-0003-json-filesystem-storage.md
**Created By**: rem (coordinator)
**Last Updated**: 2025-11-28
