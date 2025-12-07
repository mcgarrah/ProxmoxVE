# Proxmox VE Helper-Scripts - Development Guidelines

## Code Quality Standards

### Copyright and Licensing
Every source file MUST include a copyright header:
```bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: [Author Name]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
```

For Go files:
```go
// Copyright (c) 2021-2025 community-scripts ORG
// Author: [Author Name]
// License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
```

### Bash Script Standards

#### Shebang and Directives
```bash
#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
```
- Use `#!/usr/bin/env bash` for portability
- Disable shellcheck warnings for dynamic sourcing (SC1090, SC1091)

#### Variable Naming
- **Global variables**: UPPERCASE with underscores (e.g., `BASE_URL`, `CT_TYPE`)
- **Local variables**: lowercase with underscores (e.g., `template_name`, `var_cpu`)
- **Script variables**: Prefix with `var_` (e.g., `var_ram`, `var_disk`, `var_os`)
- **Function parameters**: lowercase descriptive names

#### Error Handling
- Always check command exit codes for critical operations
- Use `set -e` equivalent through `catch_errors` function
- Redirect errors to stderr with `>&2`
- Provide meaningful error messages

Example:
```bash
if ! pct create "$CTID" "$template"; then
  msg_error "Container creation failed"
  exit 1
fi
```

#### Shell Compatibility
- Standard scripts use bash features (arrays, process substitution)
- Alpine containers use ash (BusyBox) - avoid bash-specific syntax
- OpenWRT uses ash - use simple echo instead of complex functions
- Test shell compatibility when targeting non-bash environments

### TypeScript/React Standards

#### File Organization
- Use `"use client"` directive for client components
- Import types separately: `import type { Type } from "module"`
- Group imports: external libraries, then internal modules
- Use named exports for components

#### Type Safety
- Always define explicit types for props and state
- Use TypeScript strict mode
- Prefer interfaces for object shapes, types for unions
- Use Zod for runtime validation

Example:
```typescript
type ComponentProps = {
  value: number;
  onChange: (value: number) => void;
  className?: string;
};
```

#### React Patterns
- Use functional components exclusively
- Prefer hooks over class components
- Use `useCallback` for event handlers passed to children
- Use `useMemo` for expensive computations
- Use `useEffect` with proper dependency arrays

#### Component Structure
```typescript
"use client";

import type { Props } from "./types";
import { useState, useCallback } from "react";

export default function Component({ prop1, prop2 }: Props) {
  const [state, setState] = useState(initialValue);
  
  const handler = useCallback(() => {
    // logic
  }, [dependencies]);
  
  return (
    <div>
      {/* JSX */}
    </div>
  );
}
```

### Go Standards

#### Package Structure
- Use descriptive package names (e.g., `main`)
- Group imports: standard library, then external packages
- Define types before functions

#### Error Handling
```go
if err != nil {
  log.Fatal("Error message", err)
}
```
- Always check errors
- Use `log.Fatal` for critical errors
- Use `http.Error` for API errors with appropriate status codes

#### API Patterns
- Use gorilla/mux for routing
- Enable CORS for frontend access
- Set proper Content-Type headers
- Use context with timeouts for database operations

Example:
```go
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
```

## Structural Conventions

### Bash Script Structure

#### Standard Container Script Pattern
```bash
#!/usr/bin/env bash
source <(curl -fsSL ${BASE_URL}/misc/build.func)

# Variable definitions
APP="Application Name"
var_tags="${var_tags:-category;tags}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="debian"
var_version="12"

# Initialize build system
header_info "$APP"
variables
color
catch_errors

# Set base settings
base_settings

# Custom functions (if needed)
function update_script() {
  # Update logic
}

# Start build system
start
```

#### Function Definitions
- Define functions before they are called
- Use `function` keyword for clarity
- Keep functions focused and single-purpose
- Document complex logic with comments

### Frontend Structure

#### Component Organization
```
components/
├── ui/              # Reusable UI primitives
├── animate-ui/      # Animation components
└── [feature]/       # Feature-specific components
```

#### Page Structure (App Router)
```typescript
// app/[route]/page.tsx
export default function Page() {
  // Page component
}

// app/[route]/_components/  # Private components
// app/[route]/_schemas/      # Validation schemas
```

### API Structure

#### Handler Pattern
```go
func HandlerName(w http.ResponseWriter, r *http.Request) {
  // Parse input
  var input Model
  if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
    http.Error(w, err.Error(), http.StatusBadRequest)
    return
  }
  
  // Process
  // ...
  
  // Respond
  w.Header().Set("Content-Type", "application/json")
  json.NewEncoder(w).Encode(response)
}
```

## Textual Standards

### Naming Conventions

#### Files
- **Bash scripts**: lowercase with hyphens (e.g., `home-assistant.sh`)
- **Install scripts**: `{app-name}-install.sh`
- **Headers**: lowercase matching script name (e.g., `homeassistant`)
- **TypeScript**: kebab-case for files (e.g., `sliding-number.tsx`)
- **React components**: PascalCase in code, kebab-case for files

#### Variables and Functions
- **Bash functions**: snake_case (e.g., `build_container`, `update_script`)
- **TypeScript functions**: camelCase (e.g., `handleClick`, `fetchData`)
- **React components**: PascalCase (e.g., `SlidingNumber`, `Particles`)
- **Constants**: UPPERCASE (e.g., `BASE_URL`, `API_ENDPOINT`)

### Documentation

#### Comments
- Use `#` for bash comments
- Use `//` for TypeScript single-line comments
- Document complex logic and non-obvious behavior
- Avoid obvious comments that restate code

#### Function Documentation
Bash:
```bash
# Creates OpenWRT template if it doesn't exist
# Returns: template filename
create_openwrt_template() {
  # implementation
}
```

TypeScript:
```typescript
/**
 * Formats a number with optional decimal places and separators
 * @param num - The number to format
 * @param decimalPlaces - Number of decimal places
 * @returns Formatted number string
 */
```

## Semantic Patterns

### Common Implementation Patterns

#### 1. Build System Integration
All container scripts follow this pattern:
```bash
# Source build system
source <(curl -fsSL ${BASE_URL}/misc/build.func)

# Define variables
APP="Name"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"

# Initialize
header_info "$APP"
variables
color
catch_errors
base_settings

# Start
start
```

#### 2. Template Management
```bash
create_template() {
  local template_name="app-version.tar.gz"
  local template_path="/var/lib/vz/template/cache/$template_name"
  
  if [ ! -f "$template_path" ]; then
    # Create template
  fi
  
  echo "$template_name"
}
```

#### 3. React State Management
```typescript
const [state, setState] = useState(initialValue);

const updateState = useCallback((key, value) => {
  setState(prev => ({ ...prev, [key]: value }));
}, []);
```

#### 4. API Database Operations
```go
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

cursor, err := collection.Find(ctx, filter)
if err != nil {
  http.Error(w, err.Error(), http.StatusInternalServerError)
  return
}
defer cursor.Close(ctx)

for cursor.Next(ctx) {
  var record Model
  cursor.Decode(&record)
  records = append(records, record)
}
```

### Architectural Approaches

#### 1. Separation of Concerns
- Container creation scripts in `/ct/`
- Installation logic in `/install/`
- Shared functions in `/misc/`
- Frontend separate from backend

#### 2. Configuration Over Code
- Use variables for customization (`var_cpu`, `var_ram`)
- External header files for branding
- JSON metadata for script information
- Environment variables for API configuration

#### 3. Progressive Enhancement
- Default settings for quick deployment
- Advanced options for power users
- Interactive prompts with sensible defaults
- Validation before execution

#### 4. Error Recovery
- Check prerequisites before execution
- Validate inputs and configurations
- Provide clear error messages
- Clean up on failure

### Design Patterns

#### 1. Factory Pattern (Script Generation)
Scripts dynamically generate containers based on configuration:
```bash
function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
}
```

#### 2. Template Method Pattern (Build System)
Build system defines skeleton, scripts customize:
```bash
# Framework provides: header_info, variables, start
# Scripts provide: APP, var_*, update_script
```

#### 3. Observer Pattern (React State)
```typescript
useEffect(() => {
  // React to state changes
}, [dependencies]);
```

#### 4. Repository Pattern (API)
```go
// Database operations abstracted through collection
collection.Find(ctx, filter)
collection.InsertOne(ctx, document)
collection.UpdateOne(ctx, filter, update)
```

### Internal API Usage

#### Build System Functions
```bash
# Messaging
msg_info "Message"    # Blue info message
msg_ok "Message"      # Green success message
msg_error "Message"   # Red error message

# Container operations
start                 # Launch build system
build_container       # Create container (can be overridden)
description          # Show completion message

# Configuration
header_info "$APP"    # Load and display header
variables            # Process script variables
base_settings        # Set default container settings
```

#### Storage Selection
```bash
source <(curl -fsSL ${BASE_URL}/misc/tools.func)

select_storage() {
  local CLASS=$1  # 'template' or 'container'
  # Returns: STORAGE_RESULT
}
```

#### React Hooks
```typescript
// Custom hooks
import { useIsInView } from "@/hooks/use-is-in-view";

const { ref, isInView } = useIsInView(ref, {
  inView: false,
  inViewOnce: true,
  inViewMargin: "0px",
});
```

#### Utility Functions
```typescript
// Class name utilities
import { cn } from "@/lib/utils";

<div className={cn("base-class", condition && "conditional-class")} />
```

### Code Idioms

#### Bash Idioms
```bash
# Variable with default
var_cpu="${var_cpu:-2}"

# Command substitution
var_template=$(create_template)

# Process substitution
source <(curl -fsSL $URL)

# Conditional execution
[ -f "$file" ] && echo "exists"

# Error handling
if ! command; then
  echo "Error" >&2
  exit 1
fi
```

#### TypeScript Idioms
```typescript
// Optional chaining
const value = obj?.prop?.nested;

// Nullish coalescing
const result = value ?? defaultValue;

// Destructuring with defaults
const { prop = defaultValue } = object;

// Spread operator
const updated = { ...prev, [key]: value };

// Template literals
const message = `Value: ${variable}`;
```

#### React Idioms
```typescript
// Conditional rendering
{condition && <Component />}
{condition ? <A /> : <B />}

// List rendering
{items.map(item => <Item key={item.id} {...item} />)}

// Event handlers
onClick={e => handler(e)}
onChange={e => setValue(e.target.value)}

// Refs
const ref = useRef<HTMLElement>(null);
```

### Popular Annotations

#### TypeScript
```typescript
// Type annotations
const value: string = "text";
function fn(param: Type): ReturnType {}

// Generic types
const items: Array<Item> = [];
const map: Map<string, number> = new Map();

// Union types
type Status = "pending" | "success" | "error";

// Optional properties
type Props = {
  required: string;
  optional?: number;
};
```

#### JSDoc (when needed)
```typescript
/**
 * @param {string} name - Parameter description
 * @returns {Promise<void>} Return description
 * @throws {Error} Error description
 */
```

#### Bash
```bash
# shellcheck disable=SC2086  # Intentional word splitting
# shellcheck disable=SC1090  # Dynamic source

# TODO: Future improvement
# FIXME: Known issue
# NOTE: Important information
```

## Best Practices Summary

### Bash Scripts
1. Always source build.func for container scripts
2. Use external headers in `/ct/headers/`
3. Implement `update_script()` function
4. Check command exit codes
5. Redirect errors to stderr
6. Use meaningful variable names
7. Test on actual Proxmox hosts

### TypeScript/React
1. Use "use client" for client components
2. Define explicit types for all props
3. Use hooks appropriately (useState, useEffect, useCallback, useMemo)
4. Implement proper error boundaries
5. Optimize re-renders with memoization
6. Use Zod for validation
7. Follow accessibility best practices

### Go API
1. Always check errors
2. Use context with timeouts
3. Set proper HTTP headers
4. Enable CORS for frontend
5. Use structured logging
6. Close resources with defer
7. Validate input data

### General
1. Include copyright headers
2. Write self-documenting code
3. Comment complex logic
4. Follow naming conventions
5. Test thoroughly
6. Handle errors gracefully
7. Maintain backward compatibility
