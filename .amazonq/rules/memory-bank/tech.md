# Proxmox VE Helper-Scripts - Technology Stack

## Programming Languages

### Bash (Primary)
- **Version**: Bash 4.0+ (POSIX-compliant where possible)
- **Usage**: All container/VM scripts, installation scripts, management tools
- **Shell Compatibility**: 
  - Standard scripts use bash
  - Alpine containers may use ash (BusyBox)
  - OpenWRT uses ash shell
- **Key Features**: Process substitution, arrays, functions, error handling

### TypeScript/JavaScript
- **Version**: TypeScript 5.8.2, ES2022+
- **Usage**: Frontend website (helper-scripts.com)
- **Runtime**: Node.js via Next.js framework
- **Type Safety**: Strict TypeScript configuration

### Go
- **Version**: Go 1.23.2
- **Usage**: Backend API server
- **Module**: `proxmox-api`

## Frontend Stack

### Framework & Runtime
- **Next.js**: 15.5.2 (App Router)
- **React**: 19.0.0
- **Node.js**: Compatible with Next.js 15

### UI Libraries
- **Radix UI**: Accessible component primitives
  - Accordion, Dialog, Dropdown, Select, Tabs, Tooltip, etc.
- **Lucide React**: Icon library (0.542.0)
- **Framer Motion**: Animation library (11.18.2)
- **Motion**: Advanced animations (12.23.12)

### Styling
- **Tailwind CSS**: 3.4.17
- **PostCSS**: 8.5.3
- **Plugins**: 
  - tailwindcss-animate
  - tailwindcss-animated
  - prettier-plugin-tailwindcss

### State & Data
- **TanStack Query**: 5.71.1 (data fetching/caching)
- **nuqs**: 2.4.1 (URL state management)
- **Zod**: 3.24.2 (schema validation)
- **Fuse.js**: 7.1.0 (fuzzy search)

### Utilities
- **clsx**: Class name utilities
- **class-variance-authority**: Component variants
- **tailwind-merge**: Tailwind class merging
- **date-fns**: Date manipulation (4.1.0)
- **sharp**: Image optimization (0.33.5)

### Development Tools
- **ESLint**: 9.23.0 with custom config
- **Prettier**: 3.5.3
- **TypeScript**: 5.8.2
- **Bun**: Package manager (lock file present)

## Backend Stack

### API Server (Go)
- **Router**: Gorilla Mux 1.8.1
- **Database**: MongoDB driver 1.17.2
- **CORS**: rs/cors 1.11.1
- **Environment**: godotenv 1.5.1

### Dependencies
- Compression: klauspost/compress
- Cryptography: golang.org/x/crypto
- Text processing: golang.org/x/text

## Build System (Bash)

### Core Functions
- **build.func**: Main orchestration
- **install.func**: Debian/Ubuntu package management
- **alpine-install.func**: Alpine package management
- **tools.func**: System utilities
- **core.func**: Helper functions

### External Tools
- **curl**: HTTP requests and script sourcing
- **whiptail**: Interactive TUI dialogs
- **pct**: Proxmox container management
- **pvesm**: Proxmox storage management
- **pvesh**: Proxmox API shell

### Container Technologies
- **LXC**: Linux Containers
- **Proxmox VE**: 8.4.x or 9.0.x
- **systemd**: Service management
- **Docker**: Optional containerization within LXC

## Development Commands

### Frontend
```bash
# Development server with Turbopack
npm run dev

# Production build
npm run build

# Start production server
npm run start

# Linting
npm run lint

# Type checking
npm run typecheck
```

### API
```bash
# Run API server
go run main.go

# Build binary
go build -o api main.go

# Install dependencies
go mod download

# Update dependencies
go mod tidy
```

### Scripts
```bash
# Test script locally
bash ct/homeassistant.sh

# Test with custom repo
REPO="username/fork" bash ct/homeassistant.sh

# Test install script
bash install/homeassistant-install.sh

# Run management tool
bash tools/pve/update-lxcs.sh
```

## Configuration Files

### Frontend
- `next.config.mjs` - Next.js configuration
- `tailwind.config.ts` - Tailwind CSS configuration
- `tsconfig.json` - TypeScript configuration
- `eslint.config.mjs` - ESLint configuration
- `postcss.config.mjs` - PostCSS configuration
- `.prettierrc` - Prettier configuration
- `components.json` - Shadcn UI configuration

### API
- `go.mod` - Go module definition
- `go.sum` - Dependency checksums
- `.env.example` - Environment variable template

### Repository
- `.editorconfig` - Editor configuration
- `.gitignore` - Git ignore rules
- `.gitattributes` - Git attributes

## CI/CD Workflows

### GitHub Actions
- **frontend-cicd.yml**: Frontend build and deployment
- **script-test.yml**: Script validation and testing
- **script_format.yml**: Script formatting checks
- **validate-filenames.yml**: Filename convention validation
- **auto-update-app-headers.yml**: Header synchronization
- **changelog-pr.yml**: Automated changelog generation
- **github-release.yml**: Release automation
- **crawl-versions.yaml**: Version tracking

## Dependencies Management

### Frontend Package Manager
- **Bun**: Primary package manager (bun.lock present)
- **npm/yarn**: Alternative package managers supported

### Version Overrides
- React 19.0.0 (RC types)
- date-fns 4.1.0

### Go Modules
- Automatic dependency resolution via go.mod
- Vendor directory not used (direct module imports)

## Testing

### Frontend
- **Vitest**: Testing framework (vitest.config.mjs)
- **jsdom**: DOM testing environment (25.0.1)

### Scripts
- Manual testing on Proxmox VE hosts
- GitHub Actions validation
- Community testing and feedback

## Environment Requirements

### Proxmox Host
- Proxmox VE 8.4.x or 9.0.x
- Debian-based system
- Internet connectivity
- Sufficient storage for templates

### Development
- Bash 4.0+ for script development
- Node.js 18+ for frontend development
- Go 1.23+ for API development
- Git for version control
