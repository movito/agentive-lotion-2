# AL2-0003: TypeScript Frontend Foundation

**Status**: Todo
**Priority**: Critical (Phase 1 foundation)
**Assigned To**: feature-developer
**Estimated Effort**: 5-7 hours
**Created**: 2025-11-28
**Project**: Agentive Lotion 2
**Phase**: 1.0 (Frontend Foundation)
**Related ADR**: ADR-0002-python-backend-typescript-frontend.md, ADR-0005-tldraw-composition-over-fork.md

## Overview

Establish the TypeScript/React frontend foundation for Agentive Lotion 2's interactive canvas visualization. This creates a modern React application with TLDraw integration, API client for backend communication, and the scaffolding for custom shape rendering.

**Why this matters**: The frontend is the user's window into the processed document - it must be responsive, intuitive, and extensible. Getting the TLDraw integration architecture right now prevents refactoring when we add custom shapes later.

**Context**: Based on ADR-0002 and ADR-0005, we're building a TypeScript/React frontend that uses TLDraw as a library (composition, not fork). The frontend communicates with the Python backend via REST API and renders processed PDF content as an interactive canvas.

## Requirements

### Must Have

- [ ] **Vite + React Setup**: Initialize Vite project with React + TypeScript template
- [ ] **TLDraw Integration**: Install TLDraw library and create basic canvas component
- [ ] **API Client**: Create TypeScript API client for backend communication
- [ ] **File Upload UI**: Build PDF upload interface with drag-and-drop
- [ ] **Processing Status UI**: Create component to show processing progress
- [ ] **Canvas View**: Display TLDraw canvas with placeholder shapes
- [ ] **Type Definitions**: Define TypeScript types matching backend Pydantic models
- [ ] **Error Handling**: User-friendly error messages for API failures
- [ ] **Routing**: Basic React Router setup (Upload, Processing, Canvas views)
- [ ] **Unit Tests**: Vitest tests for components and API client

### Should Have

- [ ] **Loading States**: Skeleton screens and spinners during operations
- [ ] **Responsive Design**: Works on laptop screens (1280x720 minimum)
- [ ] **Dark Mode Ready**: CSS variables for theme switching (later)
- [ ] **Toast Notifications**: User feedback for success/error states
- [ ] **Progress Visualization**: Visual progress bar for 6-stage processing

### Nice to Have

- [ ] **File Preview**: Thumbnail preview of uploaded PDF
- [ ] **Recent Documents**: List of previously processed documents
- [ ] **Keyboard Shortcuts**: Common operations (Cmd+O for upload, etc.)
- [ ] **Accessibility**: ARIA labels and keyboard navigation

## Technical Design

### Project Structure

```
frontend/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── index.html
├── src/
│   ├── main.tsx              # App entry point
│   ├── App.tsx               # Root component with routing
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   └── Layout.tsx
│   │   ├── upload/
│   │   │   ├── FileUpload.tsx
│   │   │   └── UploadZone.tsx
│   │   ├── processing/
│   │   │   ├── ProcessingStatus.tsx
│   │   │   └── StageProgress.tsx
│   │   └── canvas/
│   │       ├── CanvasView.tsx
│   │       └── TLDrawCanvas.tsx
│   ├── api/
│   │   ├── client.ts         # API client configuration
│   │   ├── documents.ts      # Document upload/retrieval
│   │   └── processing.ts     # Processing status polling
│   ├── types/
│   │   ├── api.ts            # API request/response types
│   │   ├── canvas.ts         # Canvas-specific types
│   │   └── processing.ts     # Processing status types
│   ├── hooks/
│   │   ├── useDocumentUpload.ts
│   │   ├── useProcessingStatus.ts
│   │   └── useCanvas.ts
│   ├── pages/
│   │   ├── Upload.tsx
│   │   ├── Processing.tsx
│   │   └── Canvas.tsx
│   └── styles/
│       ├── global.css
│       └── variables.css
└── tests/
    ├── components/
    └── api/
```

### Core Dependencies

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "@tldraw/tldraw": "^2.0.0",
    "axios": "^1.6.0",
    "zustand": "^4.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vitest": "^1.0.0",
    "@testing-library/react": "^14.1.0",
    "@testing-library/user-event": "^14.5.0"
  }
}
```

### API Client Implementation

```typescript
// src/api/client.ts
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request/response interceptors for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);
```

```typescript
// src/api/documents.ts
import { apiClient } from './client';
import type { DocumentUploadResponse, CanvasState } from '../types/api';

export const documentsApi = {
  async upload(file: File): Promise<DocumentUploadResponse> {
    const formData = new FormData();
    formData.append('file', file);

    const response = await apiClient.post<DocumentUploadResponse>(
      '/api/v1/documents',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );

    return response.data;
  },

  async getCanvas(documentId: string): Promise<CanvasState> {
    const response = await apiClient.get<CanvasState>(
      `/api/v1/documents/${documentId}/canvas`
    );
    return response.data;
  },
};
```

### TypeScript Types

```typescript
// src/types/api.ts
export interface DocumentUploadResponse {
  document_id: string;
  filename: string;
  size_bytes: number;
  processing_job_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
}

export interface ProcessingStatus {
  job_id: string;
  document_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  current_stage: number;
  total_stages: number;
  progress_percent: number;
  stages: StageStatus[];
  error: string | null;
}

export interface StageStatus {
  stage: number;
  name: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  duration_ms: number | null;
}

export interface CanvasState {
  document_id: string;
  canvas_state: any; // TLDraw state - will be typed in AL2-0006
  metadata: {
    processing_completed: string;
    quality_metrics: Record<string, any>;
  };
}
```

### TLDraw Integration

```typescript
// src/components/canvas/TLDrawCanvas.tsx
import { Tldraw } from '@tldraw/tldraw';
import '@tldraw/tldraw/tldraw.css';

interface TLDrawCanvasProps {
  canvasState?: any; // Will be properly typed in AL2-0006
  onStateChange?: (state: any) => void;
}

export function TLDrawCanvas({ canvasState, onStateChange }: TLDrawCanvasProps) {
  return (
    <div style={{ position: 'fixed', inset: 0 }}>
      <Tldraw
        // Initial state will be loaded from backend
        snapshot={canvasState}
        onMount={(editor) => {
          console.log('TLDraw editor mounted:', editor);
        }}
      />
    </div>
  );
}
```

### File Upload Component

```typescript
// src/components/upload/FileUpload.tsx
import { useState, useCallback } from 'react';
import { documentsApi } from '../../api/documents';
import type { DocumentUploadResponse } from '../../types/api';

export function FileUpload() {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFileChange = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.name.endsWith('.pdf')) {
      setError('Please select a PDF file');
      return;
    }

    if (file.size > 50 * 1024 * 1024) {
      setError('File size must be less than 50MB');
      return;
    }

    setUploading(true);
    setError(null);

    try {
      const result = await documentsApi.upload(file);
      console.log('Upload successful:', result);
      // Navigate to processing view
      window.location.href = `/processing/${result.processing_job_id}`;
    } catch (err) {
      setError('Upload failed. Please try again.');
      console.error('Upload error:', err);
    } finally {
      setUploading(false);
    }
  }, []);

  return (
    <div className="file-upload">
      <input
        type="file"
        accept=".pdf"
        onChange={handleFileChange}
        disabled={uploading}
      />
      {uploading && <p>Uploading...</p>}
      {error && <p className="error">{error}</p>}
    </div>
  );
}
```

## Implementation Steps

### Step 1: Initialize Vite Project

```bash
# Create frontend directory
npm create vite@latest frontend -- --template react-ts

# Navigate and install dependencies
cd frontend
npm install

# Install additional dependencies
npm install @tldraw/tldraw react-router-dom axios zustand
npm install -D vitest @testing-library/react @testing-library/user-event
```

### Step 2: Configure Vite

Update `vite.config.ts`:

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './tests/setup.ts',
  },
});
```

### Step 3: Create API Client

1. Create `src/api/client.ts` (as shown above)
2. Create `src/api/documents.ts` (as shown above)
3. Create `src/api/processing.ts`:

```typescript
import { apiClient } from './client';
import type { ProcessingStatus } from '../types/api';

export const processingApi = {
  async getStatus(jobId: string): Promise<ProcessingStatus> {
    const response = await apiClient.get<ProcessingStatus>(
      `/api/v1/processing/${jobId}/status`
    );
    return response.data;
  },
};
```

### Step 4: Create Type Definitions

Create `src/types/api.ts` with all TypeScript interfaces (as shown above).

### Step 5: Build Core Components

1. **FileUpload.tsx** - PDF upload with validation
2. **ProcessingStatus.tsx** - Show processing progress
3. **TLDrawCanvas.tsx** - TLDraw integration
4. **Layout.tsx** - App layout with header/footer

### Step 6: Set Up Routing

Create `src/App.tsx`:

```typescript
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Upload } from './pages/Upload';
import { Processing } from './pages/Processing';
import { Canvas } from './pages/Canvas';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Upload />} />
        <Route path="/processing/:jobId" element={<Processing />} />
        <Route path="/canvas/:documentId" element={<Canvas />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
```

### Step 7: Write Unit Tests

Create `tests/components/FileUpload.test.tsx`:

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { FileUpload } from '../../src/components/upload/FileUpload';

describe('FileUpload', () => {
  it('renders file input', () => {
    render(<FileUpload />);
    expect(screen.getByRole('input')).toBeInTheDocument();
  });

  it('shows error for non-PDF files', async () => {
    render(<FileUpload />);
    const input = screen.getByRole('input');

    const file = new File(['content'], 'test.txt', { type: 'text/plain' });
    fireEvent.change(input, { target: { files: [file] } });

    expect(screen.getByText(/Please select a PDF file/i)).toBeInTheDocument();
  });
});
```

### Step 8: Run and Test Frontend

```bash
# Start development server
npm run dev

# Run tests
npm run test

# Build for production
npm run build
```

## Testing Checklist

- [ ] `npm run test` passes all tests
- [ ] Frontend starts without errors on port 5173
- [ ] Can upload PDF file through UI
- [ ] API client successfully calls backend `/health` endpoint
- [ ] TLDraw canvas renders empty canvas
- [ ] React Router navigation works (/, /processing, /canvas)
- [ ] TypeScript compilation succeeds (`npm run build`)
- [ ] No console errors in browser

## Success Criteria

✅ **Frontend Foundation Complete When:**
1. Vite development server runs and serves React app
2. File upload UI accepts PDFs and calls backend API
3. TLDraw canvas component renders successfully
4. All unit tests pass (`npm run test` returns 100% pass rate)
5. TypeScript types defined for all backend API responses
6. Can navigate between Upload, Processing, and Canvas views
7. Code follows TypeScript best practices (no `any` types except TLDraw)
8. Can be built for production: `npm run build` succeeds

## Dependencies

**Blocks**: AL2-0006 (Custom TLDraw shapes need this foundation)
**Blocked By**:
- AL2-0001: CI/CD setup (DONE ✅)
- AL2-0002: Python Backend Foundation (needs API to communicate with)

**Related**:
- ADR-0005: TLDraw Composition over Fork (architecture guidance)
- AL2-0006: Custom TLDraw shapes (will extend this foundation)

## Notes

- This task creates the **skeleton** of the frontend - custom shapes come later
- Focus on API integration and TLDraw setup, not visual design
- Use TLDraw's default shapes initially - custom shapes in AL2-0006
- Frontend should work with mocked backend if API not ready
- Consider adding Storybook for component development (nice-to-have)
- TLDraw v2.x has breaking changes from v1.x - ensure using latest docs

---

**Related ADRs**:
- ADR-0002-python-backend-typescript-frontend.md
- ADR-0005-tldraw-composition-over-fork.md

**Created By**: rem (coordinator)
**Last Updated**: 2025-11-28
