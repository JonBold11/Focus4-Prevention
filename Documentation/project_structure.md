# Project Structure

## Cross-References

### Implementation References
- Component Architecture: Refer to `architecture.md`
- Data Management: Refer to `data_management.md`
- Implementation Order: Refer to `master_dev_guide.md`
- Review Process: Refer to `review_process.md`
- Scope Boundaries: Refer to `scope_boundaries.md`

### Document Relationships
- This document defines the physical structure
- Architecture defines component organization
- Data Management defines data flow
- Implementation Order defines development sequence
- Review Process defines quality checks

## Directory Structure

### Core Application
```
Focus4/
├── iOS/                    # iOS app code
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   └── App.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Task.swift
│   │   │   ├── User.swift
│   │   │   └── Event.swift
│   │   ├── Services/
│   │   │   ├── TaskService.swift
│   │   │   ├── UserService.swift
│   │   │   └── EventService.swift
│   │   └── ViewModels/
│   │       ├── TaskViewModel.swift
│   │       ├── UserViewModel.swift
│   │       └── EventViewModel.swift
│   ├── Views/
│   │   ├── Components/
│   │   │   ├── Buttons/
│   │   │   ├── Inputs/
│   │   │   ├── Cards/
│   │   │   └── Navigation/
│   │   ├── Focus/
│   │   │   ├── TaskList/
│   │   │   ├── Timer/
│   │   │   └── Friction/
│   │   ├── Meetup/
│   │   │   ├── EventList/
│   │   │   ├── EventDetail/
│   │   │   └── RSVP/
│   │   └── Settings/
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── Localization/
│   └── Utils/
│       ├── Extensions/
│       └── Helpers/
│
├── Watch/                   # Watch app code
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── App.swift
│   ├── Core/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── ViewModels/
│   ├── Views/
│   │   ├── Components/
│   │   └── Friction/
│   └── Utils/
│       ├── Extensions/
│       └── Helpers/
│
├── CloudFunctions/         # Cloud function code
│   ├── auth/
│   │   ├── phoneVerification/
│   │   ├── sessionManagement/
│   │   └── securityRules/
│   ├── events/
│   │   ├── validation/
│   │   ├── cleanup/
│   │   └── analytics/
│   ├── users/
│   │   ├── management/
│   │   ├── reputation/
│   │   └── blocking/
│   └── notifications/
│       ├── scheduling/
│       ├── delivery/
│       └── preferences/
│
└── Shared/                 # Shared code/types
    ├── Models/
    │   ├── User.swift
    │   ├── Event.swift
    │   └── Notification.swift
    └── Utils/
        ├── Constants.swift
        └── Helpers.swift
```

## Module Organization

### Core Modules
1. Authentication
   - Phone verification
   - Session management
   - Security rules

2. Task Management
   - Task creation
   - Task editing
   - Task organization
   - Task persistence

3. Timer System
   - Timer interface
   - Timer controls
   - Timer notifications
   - Timer persistence

4. Friction Engine
   - Friction types
   - Friction triggers
   - Friction UI
   - Friction analytics

### Feature Modules
1. Meetup System
   - Event management
   - User profiles
   - RSVP system
   - Notifications

2. Watch Integration
   - Device sync
   - Haptic feedback
   - State management
   - Connection handling

### Shared Modules
1. UI Components
   - Buttons
   - Input fields
   - Cards
   - Navigation elements

2. Utility Components
   - Date formatters
   - Image loaders
   - Network indicators
   - Error handlers

### Testing Modules
1. Unit Tests
   - Component tests
   - Service tests
   - Utility tests
   - State management tests

2. Integration Tests
   - Feature integration
   - Service integration
   - Data flow testing
   - State synchronization

3. UI Tests
   - Component rendering
   - User interactions
   - State changes
   - Error states

## Resource Management

### Storage Structure
1. Local Storage
   - Core Data
   - UserDefaults
   - File System
   - Cache

2. Remote Storage
   - Firebase
   - CloudKit
   - Push Notifications
   - Analytics

### Cache Organization
1. Image Cache
   - Profile images
   - Event images
   - UI assets
   - Temporary files

2. Data Cache
   - Task data
   - Event data
   - User data
   - Settings

### Asset Management
1. UI Assets
   - Icons
   - Images
   - Colors
   - Typography

2. Resource Files
   - Localization
   - Configuration
   - Documentation
   - Help content

### Build Resources
1. Development
   - Debug configurations
   - Test resources
   - Development assets
   - Local settings

2. Production
   - Release configurations
   - Production assets
   - Distribution settings
   - Analytics keys

## Build Configuration

### Development
1. Debug
   - Debug symbols
   - Test configurations
   - Development assets
   - Local settings

2. Staging
   - Staging environment
   - Test data
   - Staging assets
   - Staging settings

### Production
1. Release
   - Release optimizations
   - Production assets
   - Distribution settings
   - Analytics keys

2. Distribution
   - App Store assets
   - Distribution profiles
   - Release notes
   - Marketing materials

Note: For detailed implementation guidelines, refer to `master_dev_guide.md` for overall architecture and `data_management.md` for data handling specifics.

## Backend Structure (Firebase)

### Firebase Services
1. **Authentication**
   - User profiles
   - Authentication state
   - Social sign-in

2. **Firestore Database**
   - Meetup events
   - Bulletin board posts
   - User profiles
   - Host rankings
   - Event participants

3. **Storage**
   - Profile pictures
   - Event images
   - Media attachments

4. **GeoFirestore**
   - Geo-fenced events
   - Location-based queries
   - Event discovery

## Directory Purposes

### iOS/
- Core application setup
- App lifecycle management
- Entry points
- Firebase configuration
- No business logic

### CloudFunctions/
- Server-side logic
- Data processing
- Security rules
- Analytics processing
- Background tasks

### Shared/
- Common data models
- Shared utilities
- Type definitions
- Constants
- Helper functions

### Core/
- Core business logic
- Data models (Local & Remote)
- Service interfaces
- View model logic
- Firebase integration

### Views/
- All UI components
- Screen layouts
- Reusable components
- No business logic

### Resources/
- Assets
- Localization files
- Configuration files
- Firebase config
- No code files

### Utils/
- Shared extensions
- Helper functions
- Common utilities
- No business logic

## Structure Rules

### 1. Directory Creation
- New directories require explicit approval
- Must fit within approved structure
- Must serve core functionality
- Must be properly documented

### 2. File Placement
- Files must go in appropriate directories
- No orphaned files
- Clear organization
- Logical grouping

### 3. Naming Conventions
- Directories: PascalCase
- Files: PascalCase.swift
- Clear, descriptive names
- No abbreviations

### 4. Feature Mapping
- Each feature maps to specific directories
- No cross-cutting features
- Clear boundaries
- Minimal overlap

## Change Process

### 1. Directory Addition
1. Submit request for new directory
2. Explain purpose and necessity
3. Show proposed location
4. Get explicit approval
5. Document change

### 2. Structure Modification
1. Document current structure
2. Propose changes
3. Explain impact
4. Get approval
5. Implement changes
6. Update documentation

### 3. File Organization
1. Follow approved structure
2. Maintain clean organization
3. Regular structure review
4. Document any issues
5. Propose improvements

## Maintenance

### 1. Regular Review
- Monthly structure review
- Clean up unused directories
- Verify organization
- Update documentation

### 2. Documentation
- Keep structure document updated
- Document any exceptions
- Clear change history
- Version control

### 3. Enforcement
- Regular structure checks
- Clear violation process
- Immediate correction
- Prevention measures 