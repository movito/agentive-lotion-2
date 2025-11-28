# AL2-0005: Vision Service Abstraction Layer

**Status**: Todo
**Priority**: High (Phase 1 AI foundation)
**Assigned To**: feature-developer
**Estimated Effort**: 4-5 hours
**Created**: 2025-11-28
**Project**: Agentive Lotion 2
**Phase**: 1.0 (AI Services Foundation)
**Related ADR**: ADR-0004-claude-vision-local-hooks.md

## Overview

Create an abstraction layer for AI vision services that allows seamless switching between Claude Vision API (primary) and local models (future). This enables high-quality PDF analysis now while maintaining flexibility to add offline/local alternatives later without refactoring.

**Why this matters**: The vision service is critical for quality PDF extraction - it validates extraction accuracy, performs OCR, and understands document structure. Getting the abstraction right now prevents vendor lock-in and makes local model integration easy when they mature.

**Context**: Based on ADR-0004, we're using Claude Vision as our primary AI service for quality, with architectural hooks for local models (Tesseract, LayoutParser) later. The abstraction layer makes the processing pipeline agnostic to which vision service is used.

## Requirements

### Must Have

- [ ] **Abstract Base Class**: Define `VisionService` interface with core methods
- [ ] **Claude Implementation**: Implement `ClaudeVisionService` using Anthropic SDK
- [ ] **Service Configuration**: Load AI service settings from `.env`
- [ ] **PDF Page Analysis**: Analyze PDF page images for structure and content
- [ ] **Extraction Validation**: Compare extracted text against visual content
- [ ] **OCR Capability**: Extract text from scanned/low-quality PDF pages
- [ ] **Error Handling**: Graceful handling of API failures and rate limits
- [ ] **Cost Tracking**: Track API usage and estimated costs
- [ ] **Unit Tests**: Test Claude service with mocked API responses
- [ ] **Local Stub**: Placeholder for local vision service (returns mock data)

### Should Have

- [ ] **Retry Logic**: Exponential backoff for transient API failures
- [ ] **Response Caching**: Cache vision responses per document to avoid re-processing
- [ ] **Usage Limits**: Configurable budget limits for API calls
- [ ] **Quality Metrics**: Track confidence scores from vision analysis
- [ ] **Structured Output**: Parse vision responses into structured data

### Nice to Have

- [ ] **Cost Estimator**: Estimate cost before processing document
- [ ] **Multi-provider Support**: Framework for OpenAI Vision, Google Vision
- [ ] **Local Model Evaluation**: Compare local vs Claude quality metrics
- [ ] **Streaming Responses**: Handle long vision API responses efficiently

## Technical Design

### Vision Service Interface

```python
# backend/ai/vision_service.py
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from dataclasses import dataclass
from enum import Enum

class ExtractionQuality(Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    FAILED = "failed"

@dataclass
class PageAnalysis:
    """Result of analyzing a PDF page image."""
    page_number: int
    layout_detected: bool
    column_count: int
    has_tables: bool
    has_images: bool
    has_equations: bool
    quality_score: float  # 0.0 - 1.0
    confidence: float     # 0.0 - 1.0

@dataclass
class ValidationResult:
    """Result of validating extraction quality."""
    is_valid: bool
    quality: ExtractionQuality
    issues: list[str]
    confidence: float
    suggested_action: str  # "accept", "retry_with_ocr", "manual_review"

@dataclass
class OCRResult:
    """Result of OCR on a page image."""
    text: str
    confidence: float
    bounding_boxes: list[Dict[str, Any]]

class VisionService(ABC):
    """Abstract base class for AI vision services."""

    @abstractmethod
    async def analyze_page(
        self, image_data: bytes, page_number: int
    ) -> PageAnalysis:
        """
        Analyze a PDF page image for structure and content.

        Args:
            image_data: PNG image of PDF page
            page_number: Page number in document

        Returns:
            PageAnalysis with detected structure
        """
        pass

    @abstractmethod
    async def validate_extraction(
        self, extracted_text: str, page_image: bytes
    ) -> ValidationResult:
        """
        Validate that extracted text matches visual content.

        Args:
            extracted_text: Text extracted by PyMuPDF/pdfplumber
            page_image: PNG image of the page

        Returns:
            ValidationResult with quality assessment
        """
        pass

    @abstractmethod
    async def perform_ocr(
        self, page_image: bytes
    ) -> OCRResult:
        """
        Perform OCR on a scanned or low-quality page.

        Args:
            page_image: PNG image of page

        Returns:
            OCRResult with extracted text
        """
        pass

    @abstractmethod
    def get_usage_stats(self) -> Dict[str, Any]:
        """
        Get API usage statistics.

        Returns:
            Dict with tokens used, cost, requests made
        """
        pass
```

### Claude Vision Implementation

```python
# backend/ai/claude_vision_service.py
from anthropic import AsyncAnthropic
import base64
from backend.ai.vision_service import (
    VisionService,
    PageAnalysis,
    ValidationResult,
    OCRResult,
    ExtractionQuality
)
from backend.config import settings

class ClaudeVisionService(VisionService):
    """Vision service using Claude API."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or settings.anthropic_api_key
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY not set")

        self.client = AsyncAnthropic(api_key=self.api_key)

        # Usage tracking
        self.tokens_used = 0
        self.requests_made = 0
        self.estimated_cost_usd = 0.0

    async def analyze_page(
        self, image_data: bytes, page_number: int
    ) -> PageAnalysis:
        """Analyze PDF page structure using Claude vision."""

        # Encode image to base64
        image_base64 = base64.b64encode(image_data).decode('utf-8')

        # Create vision prompt
        message = await self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/png",
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": """Analyze this PDF page and provide:
1. Layout type (single-column, two-column, multi-column)
2. Number of columns detected
3. Presence of tables (yes/no)
4. Presence of images/figures (yes/no)
5. Presence of mathematical equations (yes/no)
6. Overall quality score (0.0-1.0, where 1.0 is perfect)

Format your response as JSON with keys: layout, column_count, has_tables, has_images, has_equations, quality_score.
""",
                        },
                    ],
                }
            ],
        )

        # Track usage
        self.tokens_used += message.usage.input_tokens + message.usage.output_tokens
        self.requests_made += 1
        self._update_cost_estimate()

        # Parse response
        response_text = message.content[0].text

        # Extract JSON from response (simplified - should use proper JSON parsing)
        import json
        try:
            analysis = json.loads(response_text)
        except json.JSONDecodeError:
            # Fallback if response not JSON
            analysis = {
                "layout": "unknown",
                "column_count": 1,
                "has_tables": False,
                "has_images": False,
                "has_equations": False,
                "quality_score": 0.5
            }

        return PageAnalysis(
            page_number=page_number,
            layout_detected=analysis["layout"] != "unknown",
            column_count=analysis.get("column_count", 1),
            has_tables=analysis.get("has_tables", False),
            has_images=analysis.get("has_images", False),
            has_equations=analysis.get("has_equations", False),
            quality_score=analysis.get("quality_score", 0.5),
            confidence=0.9  # Claude is generally high confidence
        )

    async def validate_extraction(
        self, extracted_text: str, page_image: bytes
    ) -> ValidationResult:
        """Validate extraction quality by comparing text to image."""

        image_base64 = base64.b64encode(page_image).decode('utf-8')

        message = await self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=512,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/png",
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": f"""Compare this extracted text to the image:

EXTRACTED TEXT:
{extracted_text[:1000]}  # Truncate for token limits

Does the extracted text accurately match the visual content?
Respond with JSON: {{"is_valid": true/false, "quality": "high/medium/low/failed", "issues": ["list of issues"], "suggested_action": "accept/retry_with_ocr/manual_review"}}
""",
                        },
                    ],
                }
            ],
        )

        self.tokens_used += message.usage.input_tokens + message.usage.output_tokens
        self.requests_made += 1
        self._update_cost_estimate()

        # Parse response
        import json
        try:
            result = json.loads(message.content[0].text)
        except json.JSONDecodeError:
            # Fallback
            result = {
                "is_valid": True,
                "quality": "medium",
                "issues": [],
                "suggested_action": "accept"
            }

        return ValidationResult(
            is_valid=result["is_valid"],
            quality=ExtractionQuality(result["quality"]),
            issues=result.get("issues", []),
            confidence=0.85,
            suggested_action=result.get("suggested_action", "accept")
        )

    async def perform_ocr(self, page_image: bytes) -> OCRResult:
        """Perform OCR using Claude vision."""

        image_base64 = base64.b64encode(page_image).decode('utf-8')

        message = await self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=4096,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/png",
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": "Extract ALL text from this image. Preserve layout and structure as much as possible.",
                        },
                    ],
                }
            ],
        )

        self.tokens_used += message.usage.input_tokens + message.usage.output_tokens
        self.requests_made += 1
        self._update_cost_estimate()

        extracted_text = message.content[0].text

        return OCRResult(
            text=extracted_text,
            confidence=0.9,
            bounding_boxes=[]  # Claude doesn't provide bounding boxes
        )

    def get_usage_stats(self) -> Dict[str, Any]:
        """Get API usage statistics."""
        return {
            "provider": "claude",
            "tokens_used": self.tokens_used,
            "requests_made": self.requests_made,
            "estimated_cost_usd": self.estimated_cost_usd,
        }

    def _update_cost_estimate(self):
        """Update cost estimate based on token usage."""
        # Claude Sonnet 4 pricing (example - verify current rates)
        # Input: $3 per million tokens
        # Output: $15 per million tokens
        # Simplified: assume 50/50 split -> average $9 per million
        cost_per_million_tokens = 9.0
        self.estimated_cost_usd = (self.tokens_used / 1_000_000) * cost_per_million_tokens
```

### Local Vision Service Stub

```python
# backend/ai/local_vision_service.py
from backend.ai.vision_service import (
    VisionService,
    PageAnalysis,
    ValidationResult,
    OCRResult,
    ExtractionQuality
)

class LocalVisionService(VisionService):
    """Stub for local vision models (Tesseract, LayoutParser)."""

    async def analyze_page(self, image_data: bytes, page_number: int) -> PageAnalysis:
        """Stub - returns mock data."""
        return PageAnalysis(
            page_number=page_number,
            layout_detected=True,
            column_count=1,
            has_tables=False,
            has_images=False,
            has_equations=False,
            quality_score=0.7,
            confidence=0.6
        )

    async def validate_extraction(
        self, extracted_text: str, page_image: bytes
    ) -> ValidationResult:
        """Stub - always validates as medium quality."""
        return ValidationResult(
            is_valid=True,
            quality=ExtractionQuality.MEDIUM,
            issues=[],
            confidence=0.6,
            suggested_action="accept"
        )

    async def perform_ocr(self, page_image: bytes) -> OCRResult:
        """Stub - returns placeholder text."""
        return OCRResult(
            text="[Local OCR not yet implemented]",
            confidence=0.5,
            bounding_boxes=[]
        )

    def get_usage_stats(self) -> Dict[str, Any]:
        """Local service has no API costs."""
        return {
            "provider": "local",
            "tokens_used": 0,
            "requests_made": 0,
            "estimated_cost_usd": 0.0,
        }
```

### Service Factory

```python
# backend/ai/factory.py
from backend.ai.vision_service import VisionService
from backend.ai.claude_vision_service import ClaudeVisionService
from backend.ai.local_vision_service import LocalVisionService
from backend.config import settings

def create_vision_service() -> VisionService:
    """Create vision service based on configuration."""
    provider = settings.vision_provider

    if provider == "claude":
        return ClaudeVisionService(api_key=settings.anthropic_api_key)
    elif provider == "local":
        return LocalVisionService()
    else:
        raise ValueError(f"Unknown vision provider: {provider}")
```

### Configuration

```python
# backend/config.py
class Settings(BaseSettings):
    # ... existing settings ...

    # AI Services
    vision_provider: Literal["claude", "local"] = "claude"
    anthropic_api_key: str = ""

    # Vision API Configuration
    max_vision_tokens_per_document: int = 100000  # Budget limit
    enable_vision_caching: bool = True

    class Config:
        env_file = ".env"
```

Add to `.env`:
```bash
# AI Services Configuration
VISION_PROVIDER=claude
ANTHROPIC_API_KEY=sk-ant-your-key-here

# Optional: Budget limits
MAX_VISION_TOKENS_PER_DOCUMENT=100000
ENABLE_VISION_CACHING=true
```

## Implementation Steps

### Step 1: Create Vision Service Interface

1. Create `backend/ai/` directory
2. Create `vision_service.py` with abstract base class
3. Define data classes (`PageAnalysis`, `ValidationResult`, `OCRResult`)

### Step 2: Implement Claude Vision Service

1. Create `claude_vision_service.py`
2. Implement all abstract methods
3. Add usage tracking and cost estimation
4. Handle API errors gracefully

### Step 3: Create Local Vision Stub

1. Create `local_vision_service.py`
2. Implement stub methods returning mock data
3. Add TODO comments for future Tesseract/LayoutParser integration

### Step 4: Add Service Factory

1. Create `factory.py`
2. Implement `create_vision_service()` based on config
3. Handle invalid provider gracefully

### Step 5: Add Dependencies

Update `pyproject.toml`:

```toml
dependencies = [
    # ... existing ...
    "anthropic>=0.18.0",
]
```

### Step 6: Write Unit Tests

Create `backend/tests/test_ai/test_claude_vision_service.py`:

```python
import pytest
from unittest.mock import Mock, AsyncMock, patch
from backend.ai.claude_vision_service import ClaudeVisionService
from backend.ai.vision_service import ExtractionQuality

@pytest.fixture
def mock_anthropic():
    """Mock Anthropic client."""
    with patch('backend.ai.claude_vision_service.AsyncAnthropic') as mock:
        yield mock

@pytest.mark.asyncio
async def test_analyze_page(mock_anthropic):
    """Test page analysis with mocked API response."""
    # Mock API response
    mock_message = Mock()
    mock_message.content = [Mock(text='{"layout": "two-column", "column_count": 2, "has_tables": true, "has_images": false, "has_equations": true, "quality_score": 0.95}')]
    mock_message.usage = Mock(input_tokens=100, output_tokens=50)

    mock_client = AsyncMock()
    mock_client.messages.create.return_value = mock_message
    mock_anthropic.return_value = mock_client

    # Test
    service = ClaudeVisionService(api_key="test-key")
    result = await service.analyze_page(b"fake image data", page_number=1)

    assert result.page_number == 1
    assert result.column_count == 2
    assert result.has_tables == True
    assert result.has_equations == True
    assert result.quality_score == 0.95

@pytest.mark.asyncio
async def test_validate_extraction(mock_anthropic):
    """Test extraction validation."""
    mock_message = Mock()
    mock_message.content = [Mock(text='{"is_valid": true, "quality": "high", "issues": [], "suggested_action": "accept"}')]
    mock_message.usage = Mock(input_tokens=200, output_tokens=30)

    mock_client = AsyncMock()
    mock_client.messages.create.return_value = mock_message
    mock_anthropic.return_value = mock_client

    service = ClaudeVisionService(api_key="test-key")
    result = await service.validate_extraction("test text", b"fake image")

    assert result.is_valid == True
    assert result.quality == ExtractionQuality.HIGH
    assert result.suggested_action == "accept"

def test_usage_stats(mock_anthropic):
    """Test usage statistics tracking."""
    service = ClaudeVisionService(api_key="test-key")
    service.tokens_used = 1000
    service.requests_made = 5

    stats = service.get_usage_stats()

    assert stats["provider"] == "claude"
    assert stats["tokens_used"] == 1000
    assert stats["requests_made"] == 5
    assert stats["estimated_cost_usd"] > 0
```

### Step 7: Integration Test

Create example usage script:

```python
# scripts/test_vision_service.py
import asyncio
from pathlib import Path
from backend.ai.factory import create_vision_service

async def main():
    # Create vision service
    service = create_vision_service()

    # Test with a sample image (you'll need to provide one)
    image_path = Path("tests/fixtures/sample_page.png")
    if not image_path.exists():
        print("❌ Sample image not found")
        return

    image_data = image_path.read_bytes()

    # Test page analysis
    print("📸 Analyzing page...")
    analysis = await service.analyze_page(image_data, page_number=1)
    print(f"✅ Analysis: {analysis}")

    # Test validation
    print("\n✅ Validating extraction...")
    test_text = "This is a test document with two columns."
    validation = await service.validate_extraction(test_text, image_data)
    print(f"✅ Validation: {validation}")

    # Check usage
    print("\n📊 Usage stats:")
    print(service.get_usage_stats())

if __name__ == "__main__":
    asyncio.run(main())
```

## Testing Checklist

- [ ] All unit tests pass (`pytest backend/tests/test_ai/`)
- [ ] Claude vision service successfully analyzes sample page
- [ ] Extraction validation works with test image
- [ ] OCR extracts text from scanned page sample
- [ ] Usage tracking accurately counts tokens and costs
- [ ] Local vision service returns mock data without errors
- [ ] Service factory creates correct service based on config
- [ ] Error handling works for invalid API keys
- [ ] Retry logic handles transient failures

## Success Criteria

✅ **Vision Service Layer Complete When:**
1. Abstract `VisionService` interface defined and documented
2. `ClaudeVisionService` fully implemented and tested
3. `LocalVisionService` stub created (returns mock data)
4. Service factory pattern implemented
5. All unit tests pass (100% coverage for service layer)
6. Can switch between Claude and Local via config
7. Usage tracking works (tokens, cost, requests)
8. Integration test successfully calls Claude API

## Dependencies

**Blocks**:
- AL2-0006: PDF Extraction Stage 1 (uses vision for validation)
- AL2-0007+: Subsequent stages may use vision for specific tasks

**Blocked By**:
- AL2-0001: CI/CD setup (DONE ✅)
- AL2-0002: Python Backend Foundation (vision service integrates with backend)

**Related**:
- ADR-0004: Claude Vision with Local Model Hooks (architecture guidance)
- ADR-0006: Band-Based Quality Metrics (vision helps achieve targets)

## Notes

- Start with Claude Vision for quality, add local models in Phase 2
- Vision API costs ~$0.01-0.10 per document (track actual usage)
- Cache vision responses to avoid re-processing same pages
- Consider adding Tesseract/LayoutParser in AL2-0010+ when local models mature
- Claude Vision has 200K context window - can handle large documents
- Image format: PNG recommended for best quality
- Consider adding image preprocessing (resize, contrast enhancement) for better results

---

**Related ADR**: ADR-0004-claude-vision-local-hooks.md
**Created By**: rem (coordinator)
**Last Updated**: 2025-11-28
