---
description: Spec Driven Development - Generate modular specs by responsibility with a main spec as guide
argument-hint: [feature_file_or_prompt]
model: opus
---

# Spec Driven Development (SDD) Process

You are an expert software architect following **Spec Driven Development** methodology. Your goal is to create **modular, actionable specifications** organized by responsibility before any code is written.

## Available Specs (Generate ONLY what applies)

**IMPORTANT**: Not every feature needs ALL specs. Only generate the specs that are relevant to the feature being specified.

```
docs/specs/{feature-name}/
├── 00-main.spec.md           # ALWAYS required - Index and navigation guide
├── 01-use-cases.spec.md      # If there are user interactions/flows
├── 02-architecture.spec.md   # If there are system design decisions
├── 03-data-model.spec.md     # If there are database changes
├── 04-api-contracts.spec.md  # If there are API endpoints
├── 05-ui-components.spec.md  # If there are frontend components
└── 06-tasks.spec.md          # ALWAYS required - Implementation breakdown
```

### When to include each spec:

| Spec | Include when... |
|------|-----------------|
| 00-main | Always |
| 01-use-cases | Feature has user-facing flows or interactions |
| 02-architecture | New components, services, or significant design decisions |
| 03-data-model | New tables, columns, or schema changes |
| 04-api-contracts | New or modified API endpoints |
| 05-ui-components | New or modified frontend components |
| 06-tasks | Always |

---

## Input Analysis

Read and analyze the input: `$1`

If it's a file path, read the file. If it's a prompt, use it as the feature description.

---

## Phase 1: Discovery Interview

Conduct a thorough discovery interview using `AskUserQuestionTool`. Structure your questions around:

### 1. Business Context
- What problem does this solve?
- Who are the users (primary/secondary)?
- Success metrics?

### 2. Technical Context
- Integration with existing systems?
- Performance requirements?
- Security/privacy considerations?

### 3. Scope Definition
- What's must-have vs nice-to-have?
- What areas are affected? (Backend only? Frontend only? Both?)
- Does this need new database tables/columns?
- Does this need new API endpoints?

### 4. Edge Cases
- What can go wrong?
- How should errors be handled?

**Continue interviewing until you have clarity. Do not assume - ASK.**

During the interview, determine which specs are needed based on the answers.

---

## Phase 2: Generate Modular Specs

After the interview, generate ONLY the relevant spec files:

---

### 00-main.spec.md (ALWAYS REQUIRED)

This is the **entry point** and navigation guide:

```markdown
# {Feature Name} - Main Spec

## Overview
[2-3 sentence summary of the feature]

## Specs Index

| Spec | Description | Status |
|------|-------------|--------|
| [01-use-cases](./01-use-cases.spec.md) | User flows and scenarios | Draft |
| [02-architecture](./02-architecture.spec.md) | System design | Draft |
| ... | (only list specs that exist) | ... |

## Reading Order
1. Start with **use-cases** to understand what we're building
2. Review **architecture** for system design decisions
3. (adjust based on which specs exist)
4. Use **tasks** for implementation order

## Key Decisions
- Decision 1: [rationale]
- Decision 2: [rationale]

## Open Questions
- [ ] Question 1
- [ ] Question 2

## Change Log
| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Initial spec | Claude |
```

---

### 01-use-cases.spec.md (If user interactions exist)

```markdown
# Use Cases Spec

## UC-001: {Use Case Name}

**Actor**: {Who performs this}
**Priority**: {Must-have | Should-have | Nice-to-have}
**Preconditions**:
- Condition 1
- Condition 2

**Trigger**: {What initiates this flow}

**Main Flow**:
1. User does X
2. System responds with Y
3. User confirms Z

**Alternative Flows**:
- **ALT-1**: If condition A, then...

**Exception Flows**:
- **EXC-1**: If error X occurs, system shows message Y

**Postconditions**:
- State change 1

**Business Rules**:
- BR-001: Rule description

---

## UC-002: {Next Use Case}
...
```

---

### 02-architecture.spec.md (If system design decisions needed)

```markdown
# Architecture Spec

## High-Level Overview

```
[ASCII diagram or description of component relationships]
```

## Components

### Component: {Name}
**Responsibility**: Single sentence
**Technology**: Framework/library
**Dependencies**: Other components it uses
**Exposes**: APIs/interfaces it provides

## Data Flow

1. Request enters at...
2. Passes through...
3. Persisted in...
4. Response returns via...

## Integration Points

| External System | Protocol | Purpose |
|-----------------|----------|---------|
| System A | REST | Description |

## Technology Decisions

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| X | Y | Z | W |

## Security Considerations
- Authentication: How handled
- Authorization: Permission model
- Data protection: Encryption, PII handling
```

---

### 03-data-model.spec.md (If database changes needed)

```markdown
# Data Model Spec

## Entities

### Entity: {Name}

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK | Primary key |
| name | VARCHAR(255) | NOT NULL | Display name |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |

**Indexes**:
- `idx_{table}_field` on (field)

**Relationships**:
- Has many: OtherEntity
- Belongs to: ParentEntity

## ER Diagram

```
[ASCII ER diagram]
```

## Migrations Required

### Migration: {name}
```sql
-- Up
CREATE TABLE ...

-- Down
DROP TABLE ...
```
```

---

### 04-api-contracts.spec.md (If API endpoints needed)

```markdown
# API Contracts Spec

## Endpoints Overview

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | /api/v1/resource | Create resource | Required |
| GET | /api/v1/resource/:id | Get resource | Required |

---

## POST /api/v1/resource

**Description**: Creates a new resource

**Request**:
```typescript
interface CreateResourceRequest {
  name: string;        // Required, 1-255 chars
  description?: string; // Optional
}
```

**Response 201**:
```typescript
interface CreateResourceResponse {
  id: string;
  name: string;
  created_at: string;
}
```

**Response 400**:
```typescript
interface ErrorResponse {
  error: string;
  message: string;
  details?: Record<string, string>;
}
```

**Example**:
```bash
curl -X POST /api/v1/resource \
  -H "Authorization: Bearer token" \
  -d '{"name": "Example"}'
```
```

---

### 05-ui-components.spec.md (If frontend components needed)

```markdown
# UI Components Spec

## Component Tree

```
Page
├── Header
├── MainContent
│   ├── ComponentA
│   └── ComponentB
└── Footer
```

## Component: {Name}

**Purpose**: Single sentence
**Location**: `src/components/{path}`

**Props**:
```typescript
interface ComponentProps {
  prop1: string;
  prop2?: number;
  onAction: (id: string) => void;
}
```

**States**:
- Loading: Shows spinner
- Error: Shows error message with retry
- Empty: Shows empty state CTA
- Success: Shows data

**User Interactions**:
- Click X → triggers Y
- Hover Z → shows tooltip

**Implementation Example**:
```tsx
export function Component({ prop1, onAction }: ComponentProps) {
  // Implementation pattern
}
```
```

---

### 06-tasks.spec.md (ALWAYS REQUIRED)

```markdown
# Tasks Spec

## Priority 1: MVP (Must Have)

### Backend
- [ ] **TASK-001**: Create database migration for {entity}
  - File: `migrations/xxx_create_entity.sql`
  - Depends on: Nothing
  - Spec: [03-data-model](./03-data-model.spec.md)

- [ ] **TASK-002**: Implement {endpoint} API
  - File: `app/api/{route}.py`
  - Depends on: TASK-001
  - Spec: [04-api-contracts](./04-api-contracts.spec.md)

### Frontend
- [ ] **TASK-003**: Create {Component} component
  - File: `src/components/{Component}.tsx`
  - Depends on: TASK-002
  - Spec: [05-ui-components](./05-ui-components.spec.md)

## Priority 2: Should Have

- [ ] **TASK-004**: Add {enhancement}
  - Depends on: TASK-003

## Priority 3: Nice to Have

- [ ] **TASK-005**: Implement {optimization}
  - Depends on: TASK-004

## Dependency Graph

```
TASK-001 → TASK-002 → TASK-003 → TASK-004 → TASK-005
```

## Definition of Done

- [ ] Code reviewed
- [ ] No TypeScript errors
- [ ] Build passes
- [ ] Manually verified in browser
```

---

## Phase 3: Write Specs to Files

After generating all specs:

1. Ask user for the feature name (for folder naming, use kebab-case)
2. Create the folder structure: `docs/specs/{feature-name}/`
3. Write ONLY the relevant spec files (not all of them)
4. Summarize what was created

---

## Important Guidelines

- **No assumptions**: If unclear, ASK the user
- **Be specific**: No vague language - define exactly what happens
- **Include code examples**: Every spec should have implementation patterns
- **Reference existing code**: Read the codebase to understand current patterns
- **Cross-link specs**: Use relative links between specs
- **Keep specs focused**: Each file has ONE responsibility
- **Only create necessary specs**: Don't generate empty or irrelevant spec files

---

## How Claude Should Use These Specs

When implementing this feature later:

1. **Read 00-main.spec.md** first for overview and to see which specs exist
2. **Read 06-tasks.spec.md** to see what to implement
3. **For each task**, read the referenced spec (linked in each task)
4. **Follow the patterns** in implementation examples

---

Begin the discovery interview now.
