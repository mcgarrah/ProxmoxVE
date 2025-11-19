# Development Guidelines

## Code Quality Standards

### File Headers and Licensing
- **Consistent Copyright Headers**: All files include standardized copyright notices with MIT license reference
- **Author Attribution**: Clear author identification in file headers (e.g., `// Author: Michel Roegl-Brunner (michelroegl-brunner)`)
- **License Reference**: Direct link to LICENSE file in repository (`https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE`)

### Code Formatting and Structure
- **Consistent Indentation**: 2-space indentation for TypeScript/JavaScript, standard Go formatting
- **Line Length**: Reasonable line lengths with proper wrapping for readability
- **Import Organization**: Grouped imports with clear separation between external and internal modules
- **Function Spacing**: Consistent spacing between functions and logical code blocks

### Naming Conventions
- **TypeScript/React**: PascalCase for components, camelCase for variables and functions
- **Go**: Standard Go conventions with exported functions in PascalCase
- **Database Fields**: Snake_case for MongoDB field names (e.g., `ct_type`, `disk_size`)
- **File Names**: Kebab-case for component files, descriptive names for utilities

### Error Handling Patterns
- **Graceful Degradation**: Non-critical errors don't break application flow
- **Comprehensive Logging**: Detailed error messages with context information
- **User-Friendly Messages**: Clear error communication to end users
- **Timeout Management**: Consistent timeout patterns (10 seconds for database operations)

## TypeScript/React Development Standards

### Component Architecture
- **Functional Components**: Exclusive use of React functional components with hooks
- **Type Safety**: Comprehensive TypeScript typing with strict type checking
- **Props Interface**: Clear prop type definitions with optional/required indicators
- **Component Composition**: Modular component design with single responsibility principle

### State Management Patterns
- **React Hooks**: useState, useEffect, useCallback, useMemo for local state
- **Custom Hooks**: Reusable logic extraction (e.g., `useIsInView`, `useMeasure`)
- **State Updates**: Immutable state updates with proper dependency arrays
- **Performance Optimization**: Memoization for expensive calculations and callbacks

### Event Handling
- **Callback Patterns**: Consistent use of useCallback for event handlers
- **Form Handling**: Controlled components with proper validation
- **User Interaction**: Responsive feedback for user actions (loading states, success messages)
- **Accessibility**: Proper ARIA attributes and semantic HTML structure

### Animation and UI Patterns
- **Framer Motion**: Consistent animation library usage with spring configurations
- **Performance Considerations**: Efficient animation patterns with proper cleanup
- **Responsive Design**: Mobile-first approach with flexible layouts
- **Theme Integration**: Dark/light theme support with CSS custom properties

## Go Backend Development Standards

### API Design Patterns
- **RESTful Endpoints**: Clear, resource-based URL structure
- **HTTP Methods**: Proper use of GET, POST methods for appropriate operations
- **Response Format**: Consistent JSON response structure with proper status codes
- **Error Responses**: Standardized error response format with meaningful messages

### Database Integration
- **MongoDB Patterns**: Consistent use of MongoDB driver with proper context handling
- **Connection Management**: Centralized database connection with proper initialization
- **Query Optimization**: Efficient aggregation pipelines and indexed queries
- **Data Validation**: Input validation before database operations

### Middleware and CORS
- **CORS Configuration**: Proper cross-origin resource sharing setup
- **Request Logging**: Comprehensive request/response logging for debugging
- **Environment Configuration**: Secure environment variable handling with .env files
- **Graceful Shutdown**: Proper resource cleanup and connection closing

### Concurrency and Performance
- **Context Usage**: Proper context.Context usage for request lifecycle management
- **Timeout Handling**: Consistent timeout patterns across all operations
- **Resource Management**: Proper cleanup of database cursors and connections
- **Error Propagation**: Clear error handling and propagation up the call stack

## Shell Scripting Standards

### Script Structure (Based on Active File Analysis)
- **Shebang Lines**: Proper shell specification (`#!/bin/ash` for Alpine, `#!/bin/bash` for others)
- **Error Handling**: Set -e for exit on error, proper error checking
- **Function Organization**: Modular functions with clear responsibilities
- **Variable Naming**: Uppercase for environment variables, lowercase for local variables

### Configuration Management
- **UCI Integration**: Proper OpenWrt UCI configuration management
- **Service Management**: Systemd/OpenRC service file creation and management
- **Network Configuration**: Automated network interface setup and validation
- **Package Management**: Distribution-specific package manager usage (opkg, apt, apk)

### Security Practices
- **Input Validation**: Sanitization of user inputs and parameters
- **Privilege Management**: Minimal required permissions for operations
- **Secure Defaults**: Conservative security configurations out-of-the-box
- **Credential Handling**: Secure generation and storage of passwords and keys

## Testing and Validation Patterns

### Frontend Testing
- **Component Testing**: Comprehensive component behavior validation
- **Type Checking**: Strict TypeScript compilation with no errors
- **Schema Validation**: Zod schema validation for data structures
- **User Interaction Testing**: Event handling and state management validation

### Backend Testing
- **API Endpoint Testing**: Comprehensive endpoint behavior validation
- **Database Integration Testing**: MongoDB operation validation
- **Error Scenario Testing**: Proper error handling verification
- **Performance Testing**: Response time and resource usage validation

### Integration Testing
- **End-to-End Workflows**: Complete user journey validation
- **Cross-Browser Compatibility**: Multi-browser testing for web interface
- **Mobile Responsiveness**: Touch interface and responsive design validation
- **Accessibility Testing**: Screen reader and keyboard navigation support

## Documentation Standards

### Code Documentation
- **Inline Comments**: Clear explanations for complex logic and business rules
- **Function Documentation**: Purpose, parameters, and return value descriptions
- **API Documentation**: Comprehensive endpoint documentation with examples
- **Configuration Documentation**: Clear setup and configuration instructions

### User Documentation
- **Installation Guides**: Step-by-step setup instructions
- **Usage Examples**: Practical examples for common use cases
- **Troubleshooting Guides**: Common issues and resolution steps
- **FAQ Documentation**: Frequently asked questions and answers

### Contribution Guidelines
- **Code Style Guidelines**: Consistent formatting and naming conventions
- **Pull Request Templates**: Standardized PR descriptions and checklists
- **Issue Templates**: Structured bug reports and feature requests
- **Review Process**: Clear code review criteria and approval process

## Performance and Optimization

### Frontend Performance
- **Bundle Optimization**: Code splitting and lazy loading for large components
- **Image Optimization**: Proper image formats and compression
- **Caching Strategies**: Effective browser caching and CDN usage
- **Runtime Performance**: Efficient React rendering and state updates

### Backend Performance
- **Database Optimization**: Efficient queries and proper indexing
- **Connection Pooling**: Optimal database connection management
- **Response Caching**: Strategic caching for frequently accessed data
- **Resource Management**: Efficient memory and CPU usage patterns

### Network Optimization
- **API Efficiency**: Minimal data transfer with proper pagination
- **Compression**: Gzip compression for text-based responses
- **CDN Integration**: Content delivery network usage for static assets
- **Request Batching**: Efficient API call patterns to reduce network overhead

These guidelines ensure consistency, maintainability, and quality across the entire codebase while supporting the project's goal of providing reliable automation tools for Proxmox VE environments.