# ADR-0004: Claude Vision with Local Model Hooks

**Status**: Accepted

**Date**: 2025-11-27

**Deciders**: rem (coordinator), user

## Context

### Problem Statement

Academic PDFs often have complex layouts that challenge traditional PDF parsing:
- Multi-column layouts with irregular text flow
- Equations and scientific notation embedded in text
- Tables with complex structures
- Figures with captions that may be misplaced
- Scanned pages requiring OCR
- Mixed content (text + handwritten annotations)

We need AI/ML capabilities to:
1. Validate extraction quality (detect page numbers in body text)
2. Perform OCR on scanned or low-quality PDFs
3. Understand document structure visually
4. Extract semantic relationships

We must balance quality, cost, privacy, and offline capabilities.

### Forces at Play

**Technical Requirements:**
- High-quality vision/OCR for poorly formatted PDFs
- Document understanding (not just text extraction)
- Semantic analysis for thematic clustering
- Quality validation of extraction results

**Constraints:**
- Single-user desktop app (privacy important)
- Cost sensitivity (academic users, frequent processing)
- Potential offline usage requirements
- API rate limits and availability

**Assumptions:**
- Claude vision quality superior to local models initially
- Local models improving over time (can switch later)
- Users willing to use API keys for better quality
- Privacy concerns vary by user

## Decision

**Use Claude Code with vision API as primary AI service, with architectural hooks for local model alternatives.**

### Core Principles

1. **Quality First**: Start with best-in-class models for proof of concept
2. **Flexibility**: Design for swappable AI backends
3. **Progressive Enhancement**: Offer local models as privacy/offline option
4. **Cost Awareness**: Make API usage transparent and controllable

### Implementation Details

**AI Service Abstraction Layer:**

```python
# backend/ai/vision_service.py
from abc import ABC, abstractmethod

class VisionService(ABC):
    @abstractmethod
    def analyze_pdf_page(self, image_data: bytes) -> PageAnalysis:
        """Analyze a single PDF page image."""
        pass

    @abstractmethod
    def validate_extraction(self, extracted_text: str, image: bytes) -> ValidationResult:
        """Validate that extraction matches visual content."""
        pass

    @abstractmethod
    def detect_structure(self, image: bytes) -> StructureAnalysis:
        """Detect visual structure (columns, sections, etc.)."""
        pass

class ClaudeVisionService(VisionService):
    """Implementation using Claude API with vision."""
    # Uses Anthropic SDK

class LocalVisionService(VisionService):
    """Implementation using local models (Tesseract, LayoutParser, etc.)."""
    # Uses local libraries
```

**Configuration:**

```yaml
# config/ai_services.yml
vision:
  provider: "claude"  # or "local"
  claude:
    api_key: "${ANTHROPIC_API_KEY}"
    model: "claude-sonnet-4-20250514"
    max_tokens: 4096
  local:
    ocr_engine: "tesseract"
    layout_model: "layoutparser"
    device: "cpu"  # or "cuda"
```

**Usage Strategy:**

1. **Stage 1 (Extraction)**: Claude vision for quality validation
2. **Stage 1 (OCR)**: Claude vision for scanned pages, with Tesseract fallback
3. **Stage 2 (Structure)**: Claude vision for layout understanding
4. **Stage 3 (Themes)**: Text-based analysis (no vision needed)
5. **Stage 4 (Citations)**: Claude vision for complex citation formats

**Cost Management:**
- Cache results per document to avoid re-processing
- Only use vision when traditional extraction fails/uncertain
- Provide cost estimates before processing
- Allow users to set budget limits

**Local Model Hooks (Future):**
- Tesseract for basic OCR
- LayoutParser for document layout analysis
- Local LLaMA/Mistral for text analysis
- Evaluation framework to compare quality

## Consequences

### Positive

- ✅ **Quality**: Best-in-class vision and understanding from day one
- ✅ **Flexibility**: Can switch to local models without architectural changes
- ✅ **Time to Market**: Don't need to train/fine-tune local models initially
- ✅ **Progressive Enhancement**: Can offer local as privacy option later
- ✅ **Validation**: Can compare Claude vs local models to measure quality gap

### Negative

- ⚠️ **Cost**: API calls add per-document expense (~$0.01-0.10 per document estimated)
- ⚠️ **Dependency**: Requires internet connection and API availability
- ⚠️ **Privacy**: Sending PDF content to third-party API
- ⚠️ **Rate Limits**: Subject to Anthropic's rate limiting
- ⚠️ **Vendor Lock-in Risk**: Abstraction layer mitigates but doesn't eliminate

### Neutral

- 📊 **API Evolution**: Claude models will improve over time
- 📊 **Local Model Maturity**: Local alternatives improving rapidly
- 📊 **User Choice**: Some users prefer API, others prefer local

## Alternatives Considered

### Alternative 1: Local-Only Models (Tesseract + LayoutParser)

**Description**: Use only open-source local models from day one.

**Rejected because**:
- ❌ Significantly lower quality for complex layouts
- ❌ Requires fine-tuning for academic paper domain
- ❌ More development time to achieve acceptable results
- ❌ Still need fallback for very poor quality PDFs
- 💡 **Will reconsider** when local models reach comparable quality

### Alternative 2: OpenAI Vision API

**Description**: Use GPT-4 Vision instead of Claude.

**Rejected because**:
- ❌ Team already using Claude Code for development
- ❌ Claude vision quality meets requirements
- ❌ Prefer consistency in AI provider
- ❌ Claude's longer context window beneficial for documents
- 💡 **Could support** as alternative provider via abstraction layer

### Alternative 3: Hybrid (Local First, Cloud Fallback)

**Description**: Try local models first, only use Claude for failures.

**Rejected because**:
- ❌ Adds complexity of dual implementation upfront
- ❌ Local models not reliable enough yet to be primary
- ❌ Would spend time debugging local failures instead of building features
- 💡 **Will adopt** once local models mature enough

## Real-World Results

[To be filled after processing first 10-20 documents]

**Metrics to track:**
- API cost per document (target: <$0.10)
- Accuracy improvement over traditional extraction
- Processing time impact
- User satisfaction with quality vs local alternatives

## Related Decisions

- ADR-0002: Python Backend + TypeScript Frontend (abstraction layer in Python)
- ADR-0006: Band-Based Quality Metrics (vision helps achieve accuracy targets)

## References

- [Claude Vision Capabilities](https://docs.anthropic.com/claude/docs/vision)
- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract)
- [LayoutParser](https://layout-parser.github.io/)
- [Vision Model Comparison (2024)](https://arxiv.org/abs/2401.xxxxx)

## Revision History

- 2025-11-27: Initial decision (Accepted)
- [Future]: Add local model migration plan when quality gap closes

---

**Template Version**: 1.1.0
**Project**: Agentive Lotion 2
**Naming Convention**: ADR-####-description.md
