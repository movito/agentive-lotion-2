# ADR-0007: User-Driven Theme Refinement

**Status**: Accepted

**Date**: 2025-11-27

**Deciders**: rem (coordinator), user

## Context

### Problem Statement

Thematic clustering is an inherently subjective task:
- Different users may organize the same content differently
- No single "correct" way to group concepts
- Context and prior knowledge affect categorization
- User's research goals influence what themes are meaningful

Traditional approaches:
- **Fully Automated**: System decides clusters, user stuck with them
- **Fully Manual**: User organizes from scratch, no AI assistance

We need a hybrid approach that:
1. Provides intelligent initial clustering (saves time)
2. Respects user's domain expertise (acknowledges subjectivity)
3. Learns from corrections (improves over time)
4. Makes disagreements visible and actionable

### Forces at Play

**Technical Requirements:**
- Initial clustering algorithm (ML-based)
- User interface for reorganization
- Feedback capture mechanism
- Learning loop to improve clustering
- Conflict resolution (when system disagrees with user)

**Constraints:**
- Canvas-based interaction (drag-and-drop)
- No separate "editing mode" for clustering
- Learning happens locally (no central model training)
- Users won't provide explicit labels or training data

**Assumptions:**
- Users will naturally reorganize content if clustering is wrong
- Drag-and-drop more intuitive than explicit feedback forms
- "Bad fit" indicators less intrusive than error dialogs
- Implicit feedback sufficient for learning

## Decision

**Users can drag content between themes, provide "bad fit" feedback. System learns from reorganizations to improve future clustering.**

### Core Principles

1. **User Agency**: Users are experts in their domain, system is helpful assistant
2. **Implicit Feedback**: Learn from actions (drag-and-drop) not forms
3. **Transparent Disagreement**: Show where system is uncertain
4. **Continuous Learning**: Each refinement improves next document

### Implementation Details

**Canvas Interactions:**

```typescript
// frontend/src/canvas/interactions/ThemeRefinement.ts

interface ThemeRefinementAction {
  type: 'drag-to-theme' | 'mark-bad-fit' | 'create-theme' | 'merge-themes'
  contentId: string
  originalTheme?: string
  newTheme?: string
  timestamp: Date
  confidence: number  // System's confidence in original placement
}

// User can:
// 1. Drag content from one theme cluster to another
// 2. Click "bad fit" indicator on poorly placed content
// 3. Create new theme and drag content to it
// 4. Merge two similar themes
```

**"Bad Fit" Indicator:**

```typescript
// Show on content nodes where system has low confidence
interface ContentNode {
  id: string
  themeId: string
  confidence: number  // 0-1
  showBadFitIndicator: boolean  // if confidence < 0.6
}

// Visual: Small amber icon on node corner
// Tooltip: "We're unsure about this placement. Feel free to reorganize."
```

**Feedback Capture:**

```python
# backend/learning/feedback_collector.py

@dataclass
class ThemeRefinementFeedback:
    """Captures user's theme reorganization."""
    document_id: str
    content_id: str
    original_theme: str
    new_theme: str
    system_confidence: float  # How confident we were originally
    user_action: str  # 'drag', 'bad_fit_then_drag', 'create_new_theme'
    context: dict  # Surrounding themes, tags, etc.

# Stored in: processing_output/{doc_id}/user_feedback/theme_refinements.json
```

**Learning Loop:**

```python
# backend/learning/theme_clustering_improver.py

class ThemeClusteringImprover:
    """Learns from user corrections to improve future clustering."""

    def learn_from_feedback(self, feedback: list[ThemeRefinementFeedback]):
        """
        Analyze patterns in user corrections:
        - Which types of content often misclassified?
        - Which themes get confused with each other?
        - What features predict correct placement?
        """
        # Updates local clustering model weights
        # No central training server needed

    def adjust_confidence_thresholds(self):
        """
        If users frequently correct high-confidence placements,
        lower confidence threshold for "bad fit" indicator.
        """
        pass
```

**Conflict Resolution:**

When system and user disagree consistently:
1. **First Time**: System notes disagreement, adjusts weights
2. **Second Time**: System lowers confidence, shows "bad fit" indicator earlier
3. **Third+ Times**: System defers to user preference for similar content

**Privacy-Preserving Learning:**

```python
# Learning happens locally, not sent to cloud
# Each user's refinements improve their own experience
# Optional: Aggregate anonymous feedback for system-wide improvements

class LocalLearningStore:
    """Stores user's refinement patterns locally."""
    path: Path = Path.home() / '.agentive-lotion-2' / 'learning_data'

    def update_user_preferences(self, feedback):
        # Store in local SQLite or JSON
        pass
```

## Consequences

### Positive

- ✅ **User Empowerment**: Users control final organization
- ✅ **No Training Data Burden**: Users don't fill out forms, just work naturally
- ✅ **Continuous Improvement**: Every document processed improves next one
- ✅ **Transparent Uncertainty**: "Bad fit" indicators set expectations
- ✅ **Respects Expertise**: Acknowledges users know their domain better than AI
- ✅ **Privacy-Friendly**: Learning happens locally

### Negative

- ⚠️ **Initial Clustering May Be Wrong**: First documents may need significant reorganization
- ⚠️ **Learning Speed**: May take 10-20 documents before clustering improves noticeably
- ⚠️ **Inconsistent Improvements**: Different users have different preferences (no central model)
- ⚠️ **UI Complexity**: Need to design intuitive drag-and-drop + feedback indicators

### Neutral

- 📊 **Personalization**: Each user's system learns their preferences (pro and con)
- 📊 **No Ground Truth**: Can't measure "accuracy" objectively, only user satisfaction
- 📊 **Feature Complexity**: More complex than static clustering, but more useful

## Alternatives Considered

### Alternative 1: Fully Automated Clustering (No User Refinement)

**Description**: System decides clusters, users can't change them.

**Rejected because**:
- ❌ Ignores user expertise and preferences
- ❌ Frustrating when clustering is wrong
- ❌ No learning loop to improve
- ❌ Contradicts "editable canvas" design goal

### Alternative 2: Fully Manual (No Initial Clustering)

**Description**: Users organize all content from scratch, no AI assistance.

**Rejected because**:
- ❌ Tedious for large documents (50+ themes)
- ❌ Wastes AI capabilities
- ❌ Slower workflow than AI-assisted
- ❌ Users may miss non-obvious connections

### Alternative 3: Explicit Feedback Forms

**Description**: Pop up dialog asking "Is this clustering correct?" with thumbs up/down.

**Rejected because**:
- ❌ Interrupts workflow
- ❌ Users won't provide feedback consistently
- ❌ More clicks/effort than drag-and-drop
- ❌ Annoying notification fatigue
- 💡 **May add** as optional power-user feature later

### Alternative 4: Central Model Training

**Description**: Upload all user corrections to cloud, train shared model.

**Rejected because**:
- ❌ Privacy concerns (uploading academic content)
- ❌ Requires server infrastructure
- ❌ Different users have different preferences (averaging may worsen experience)
- ❌ Regulatory complexity (data collection, GDPR)
- 💡 **Could offer** as opt-in anonymous telemetry later

## Real-World Results

[To be filled after 20+ users process 10+ documents each]

**Metrics to track:**
- % of content reorganized by users (target: <20% after learning)
- Time spent reorganizing (target: <2 minutes per document)
- User satisfaction ratings before and after reorganization
- Clustering confidence improvement over time
- "Bad fit" indicator accuracy (does user actually reorganize flagged content?)

## Related Decisions

- ADR-0005: TLDraw Composition over Fork (drag-and-drop implemented via TLDraw)
- ADR-0006: Band-Based Quality Metrics (user refinement is another quality signal)

## References

- [Interactive Machine Learning](https://en.wikipedia.org/wiki/Interactive_machine_learning)
- [Implicit Feedback in Information Retrieval](https://dl.acm.org/doi/10.1145/3130348.3130372)
- [User Agency in AI Systems](https://research.google/pubs/pub49922/)
- [Heptabase: User-Driven Knowledge Organization](https://heptabase.com/)

## Revision History

- 2025-11-27: Initial decision (Accepted)
- [Future]: Add metrics on learning effectiveness

---

**Template Version**: 1.1.0
**Project**: Agentive Lotion 2
**Naming Convention**: ADR-####-description.md
