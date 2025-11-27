# ADR-0006: Band-Based Quality Metrics

**Status**: Accepted

**Date**: 2025-11-27

**Deciders**: rem (coordinator), user

## Context

### Problem Statement

PDF extraction quality varies dramatically based on:
- Source document quality (native PDF vs scanned)
- Layout complexity (single column vs multi-column)
- Font rendering (standard fonts vs embedded custom fonts)
- Special content (equations, tables, figures)
- PDF generation method (LaTeX, Word, InDesign, scanned)

Traditional single-threshold metrics (e.g., "99% accuracy") are:
- Too optimistic for poor-quality PDFs (user frustrated by failures)
- Too pessimistic for high-quality PDFs (system undersells capabilities)
- Don't account for variability in academic paper corpus

We need a metric system that:
1. Sets realistic expectations per document type
2. Accounts for inherent PDF quality variation
3. Guides quality improvement efforts
4. Communicates uncertainty honestly

### Forces at Play

**Technical Requirements:**
- Measurable extraction quality
- Actionable feedback for improvements
- User confidence in results
- Debugging support for failures

**Constraints:**
- No ground truth for most documents (can't compare to "perfect" extraction)
- Quality assessment itself requires AI/human review
- Users have different tolerance for errors
- Academic papers vary widely in formatting

**Assumptions:**
- Some PDFs are inherently harder to process than others
- Users understand that scanned PDFs are lower quality
- Band-based communication is clearer than single numbers
- Transparency about limitations builds trust

## Decision

**Use band-based quality metrics: "X% of content extracted within Y% accuracy" per document.**

### Core Principles

1. **Realistic Expectations**: Don't promise perfect extraction for all PDFs
2. **Transparent Uncertainty**: Communicate confidence bands, not false precision
3. **Document-Specific**: Report quality per document, not system-wide average
4. **Actionable**: Bands guide where to focus quality improvements

### Implementation Details

**Quality Bands:**

```python
# backend/quality/metrics.py
from enum import Enum
from dataclasses import dataclass

class QualityBand(Enum):
    EXCELLENT = "excellent"    # 98-100% content, 99-100% accuracy
    GOOD = "good"              # 95-98% content, 95-99% accuracy
    ACCEPTABLE = "acceptable"  # 90-95% content, 90-95% accuracy
    POOR = "poor"              # 80-90% content, 80-90% accuracy
    FAILED = "failed"          # <80% content or <80% accuracy

@dataclass
class ExtractionQuality:
    """Quality metrics for a single document."""
    document_id: str
    content_coverage: float  # % of document content extracted
    accuracy_estimate: float  # % of extracted content that's correct
    quality_band: QualityBand
    confidence: float  # How confident we are in these estimates
    issues: list[str]  # Specific problems detected
```

**Measurement Approach:**

1. **Content Coverage** (% of document extracted):
   - Compare page count before/after
   - Detect large gaps in text flow
   - Check for missing sections from ToC
   - Estimate via Claude vision: "What % of text is visible in this extraction?"

2. **Accuracy Estimate** (% of extracted content that's correct):
   - Sample random paragraphs, compare to Claude vision reading
   - Check for obvious errors (page numbers in body, garbled text)
   - Validate table structure makes sense
   - Cross-reference citations with reference list

3. **Confidence** (how certain we are):
   - High: Native PDF with standard fonts, simple layout
   - Medium: Multi-column or complex layout
   - Low: Scanned PDF or poor OCR results

**User Communication:**

```typescript
// Display in UI
interface QualityReport {
  band: 'excellent' | 'good' | 'acceptable' | 'poor' | 'failed'
  message: string
  details: {
    contentCoverage: string  // "95-98%"
    accuracy: string         // "95-99%"
    confidence: string       // "High" | "Medium" | "Low"
  }
  issues: string[]
  recommendation: string
}

// Example
{
  band: 'good',
  message: '95-98% of content extracted with 95-99% accuracy',
  details: {
    contentCoverage: '97%',
    accuracy: '96%',
    confidence: 'High'
  },
  issues: [
    'Page 5: Complex table structure simplified',
    'Page 12: Equation rendered as text'
  ],
  recommendation: 'Quality sufficient for thematic analysis. Review flagged sections.'
}
```

**Quality Improvement Workflow:**

1. **Track** which bands each document falls into
2. **Analyze** common issues in lower bands
3. **Prioritize** improvements based on frequency
4. **Validate** that changes move documents to higher bands

## Consequences

### Positive

- ✅ **Honest Communication**: Users know what to expect per document
- ✅ **Realistic Expectations**: Don't promise 100% for challenging PDFs
- ✅ **Actionable**: Bands guide quality improvement priorities
- ✅ **Flexible**: Can adjust band definitions as system improves
- ✅ **Builds Trust**: Transparency about limitations vs hidden failures

### Negative

- ⚠️ **Complexity**: More complex than single accuracy number
- ⚠️ **Measurement Cost**: Quality assessment requires AI/human review
- ⚠️ **Subjective Bands**: Where to draw band boundaries is somewhat arbitrary
- ⚠️ **User Confusion**: Some users may not understand bands concept

### Neutral

- 📊 **Evolving Standards**: Band thresholds will adjust as system improves
- 📊 **Competitive Comparison**: Harder to compare with competitors' single metrics
- 📊 **Marketing**: "95-98%" less catchy than "99%" but more honest

## Alternatives Considered

### Alternative 1: Single Accuracy Percentage

**Description**: Report single accuracy number per document (e.g., "96% accurate").

**Rejected because**:
- ❌ False precision (can't measure that accurately)
- ❌ Doesn't communicate uncertainty
- ❌ Oversimplifies multi-dimensional quality
- ❌ Sets unrealistic expectations for poor PDFs

### Alternative 2: Pass/Fail Binary

**Description**: Simple "extraction succeeded" or "extraction failed".

**Rejected because**:
- ❌ Too coarse-grained (loses quality nuance)
- ❌ Doesn't guide improvements
- ❌ User can't make informed decisions about using results
- ❌ Hides partial successes

### Alternative 3: Detailed Error Catalog

**Description**: Enumerate every error found during extraction.

**Rejected because**:
- ❌ Overwhelming for users
- ❌ Doesn't provide overall quality summary
- ❌ Many "errors" are acceptable approximations
- 💡 **Will provide** as optional detailed view for power users

## Real-World Results

[To be filled after processing 50+ documents]

**Metrics to track:**
- Distribution of documents across quality bands
- Correlation between band and user satisfaction
- Accuracy of band predictions vs human review
- Impact of quality improvements on band distribution

## Related Decisions

- ADR-0004: Claude Vision with Local Model Hooks (vision helps measure quality)
- ADR-0007: User-Driven Theme Refinement (users validate quality through usage)

## References

- [Information Retrieval Metrics](https://en.wikipedia.org/wiki/Evaluation_measures_(information_retrieval))
- [Confidence Intervals in ML](https://arxiv.org/abs/1906.xxxxx)
- [User Trust in Imperfect Systems](https://research.google/pubs/pub48401/)

## Revision History

- 2025-11-27: Initial decision (Accepted)
- [Future]: Update band thresholds based on real-world data

---

**Template Version**: 1.1.0
**Project**: Agentive Lotion 2
**Naming Convention**: ADR-####-description.md
