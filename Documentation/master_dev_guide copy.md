# Focus4 Integrated Development Guide

## Executive Summary

### Project Overview
Focus4 is a productivity app that combines focus management with social meetup features. The app uses an adaptive friction engine to help users maintain focus while providing social features for community engagement.

### Core Purpose
- Help users maintain focus through intelligent friction
- Enable community meetups and social interaction
- Provide seamless Apple Watch integration
- Ensure privacy and data security

### Key Features
1. **Adaptive Friction Engine**
   - Per-app usage tracking
   - Tiered friction tasks
   - Apple Watch haptic nudges
   - Progressive intervention system

2. **Meetup System**
   - Geo-fenced event creation
   - QR code check-in
   - External chat links
   - Host ranking system

3. **Apple Watch Integration**
   - QR code display for hosts
   - Real-time feedback
   - Haptic notifications
   - Simple watch UI

### 🎯 Scope Management
All development MUST adhere to the boundaries defined in `scope_boundaries.md`. This document:
- Explicitly defines what is in and out of scope
- Lists core features vs. non-essential features
- Provides a protocol for feature addition
- Documents any legacy features

Before implementing any new feature or enhancement:
1. Verify it aligns with scope boundaries
2. Ensure it serves core functionality
3. Get explicit approval for anything not clearly in scope
4. Document any approved exceptions

### 🎯 Implementation Safeguards
Before implementing any feature, the following questions MUST be answered:

1. **Core Purpose Verification**
   - Does it serve the core focus management purpose?
   - Is it explicitly requested?
   - Could it be simplified further?

2. **Dependency Check**
   - Does it depend on anything not yet approved?
   - Are all dependencies clearly identified?
   - Is the implementation order correct?

3. **Implementation Boundaries**
   - No "while we're at it" additions
   - No speculative functionality
   - No premature optimization
   - One feature at a time

4. **Project Structure**
   - Must fit within approved folder structure
   - No new directories without explicit approval
   - Clear mapping to approved features

5. **Review Process**
   - Regular scope verification
   - Feature completion checks
   - Technical debt assessment
   - Scope drift detection

For detailed guidelines on any of these areas, refer to:
- `project_structure.md` for folder/file organization
- `review_process.md` for review procedures
- `scope_boundaries.md` for feature boundaries

### 🎯 Logical Progression and Downstream Impact
When implementing new features or components:
- Always proceed with the most logical next step based on existing architecture
- Consider dependencies and potential downstream impact
- Present only the optimal path forward, not multiple options
- Ensure new implementations maintain compatibility with existing components
- Build in a way that minimizes potential issues for future development

### Technical Stack
- SwiftUI for UI
- Firebase for backend
- Core Data for local storage
- CloudKit for sync
- WatchKit for Apple Watch

## Development Philosophy

### 🎯 Start Simple, Add Complexity Only When Needed
Our primary development principle is to begin with the simplest possible implementation that meets the core requirements. This approach:
- Reduces initial complexity and potential points of failure
- Makes components easier to test and maintain
- Allows for faster iteration and feedback
- Provides a solid foundation for future enhancements

Complexity should only be added when:
1. There is a clear, demonstrated need
2. The benefits outweigh the maintenance costs
3. The feature is essential to the core functionality
4. The complexity can be properly tested and documented

### 🎯 Core Features
The app focuses on three main pillars:

1. **Adaptive Friction Engine**
   - Per-app usage tracking
   - Tiered friction tasks
   - Apple Watch haptic nudges
   - Progressive intervention system

2. **Meetup System**
   - Geo-fenced event creation
   - QR code check-in
   - External chat links (WhatsApp, Signal)
   - Host ranking system

3. **Apple Watch Integration**
   - QR code display for hosts
   - Real-time feedback
   - Haptic notifications
   - Simple watch UI

## Component Terminology Guide

### Core Component Definitions

#### Friction Timing System
- **Purpose**: Manages timing for friction engine operations
- **Key Functions**:
  - App usage duration tracking
  - Friction trigger timing
  - Haptic feedback coordination
  - Watch-phone sync timing
- **Previous References**: "Timer System", "Timing Component", "Friction Timing"
- **Usage Context**: Integral part of the Friction Engine

#### Friction Analytics System
- **Purpose**: Tracks and analyzes friction effectiveness
- **Key Functions**:
  - Friction trigger effectiveness
  - User engagement metrics
  - Feature usage tracking
  - Behavior analysis
- **Previous References**: "Analytics Dashboard", "Analytics System", "Usage Analytics"
- **Usage Context**: Essential for Friction Engine optimization

#### Friction Task System
- **Purpose**: Manages friction-based behavioral interventions
- **Key Functions**:
  - Friction task creation
  - Task trigger management
  - Task completion tracking
  - Behavioral intervention delivery
- **Previous References**: "Task Management", "Friction Tasks", "Task System"
- **Usage Context**: Core component of the Friction Engine

### Component Relationships
- Friction Timing System → Friction Engine
- Friction Analytics System → Friction Engine
- Friction Task System → Friction Engine

### Implementation Context
- These components are integral parts of the Friction Engine
- They are not standalone features
- They work together to deliver the core friction functionality
- They support the Meetup System and Watch Integration

### Note on Documentation
- While other documents may use different terminology
- This guide serves as the canonical reference
- All components should be understood in their Friction Engine context
- No functional changes are required, only terminology clarification

## Core Development Guidelines

### Code Organization
1. File Structure
   - Feature-based organization
   - Clear separation of concerns
   - Shared resources management
   - Watch-specific components
   - Platform-specific implementations
   - Common utilities

2. Naming Conventions
   - Clear and descriptive names
   - Consistent terminology
   - Platform-specific prefixes
   - Feature-based namespacing
   - Watch component identifiers
   - Shared component naming

3. Documentation Standards
   - Inline documentation
   - API documentation
   - Implementation notes
   - Watch integration notes
   - Dependencies documentation
   - Version history

### Implementation Standards
1. SwiftUI Best Practices
   - State management
   - View composition
   - Performance optimization
   - Watch UI optimization
   - Accessibility support
   - Cross-platform compatibility

2. Architecture Patterns
   - MVVM implementation
   - Dependency injection
   - Protocol-oriented design
   - Watch connectivity
   - State synchronization
   - Error handling

3. Testing Requirements
   - Unit test coverage
   - UI test automation
   - Watch app testing
   - Integration testing
   - Performance testing
   - Security testing

### Error Handling
1. User-Facing Errors
   - Clear error messages
   - Recovery options
   - Offline handling
   - Watch error display
   - Error logging
   - Error analytics

2. System Errors
   - Graceful degradation
   - Recovery procedures
   - Data consistency
   - Watch sync errors
   - Network errors
   - Storage errors

3. Development Errors
   - Debug logging
   - Error tracking
   - Crash reporting
   - Watch debugging
   - Performance profiling
   - Memory leaks

### Performance Standards
1. Launch Time
   - Cold start < 2s
   - Warm start < 1s
   - Watch app launch < 1s
   - Background refresh
   - State restoration
   - Cache warming

2. Runtime Performance
   - 60 FPS animations
   - Smooth scrolling
   - Responsive UI
   - Watch responsiveness
   - Background tasks
   - Memory usage

3. Network Performance
   - Request timeout < 5s
   - Retry logic
   - Offline support
   - Watch connectivity
   - Background sync
   - Data optimization

## Quality Assurance Guidelines

### Testing Standards
1. Unit Testing
   - Component isolation
   - Mock dependencies
   - Edge cases
   - Error conditions
   - Watch components
   - Shared logic

2. Integration Testing
   - Component interaction
   - Data flow
   - State management
   - Error handling
   - Watch integration
   - Cross-platform sync

3. UI Testing
   - User flows
   - Accessibility
   - Responsiveness
   - Platform specifics
   - Watch UI
   - Cross-device UI

### Testing Requirements
1. Coverage Requirements
   - Core logic: 90%
   - UI components: 80%
   - Watch components: 85%
   - Shared code: 95%
   - Error handling: 100%
   - Critical paths: 100%

2. Performance Testing
   - Load testing
   - Stress testing
   - Memory leaks
   - Battery impact
   - Watch performance
   - Sync performance

3. Security Testing
   - Authentication
   - Data protection
   - Network security
   - Input validation
   - Watch security
   - Cross-device security

### Quality Metrics
1. Code Quality
   - Complexity metrics
   - Code duplication
   - Documentation coverage
   - Watch code quality
   - Shared code quality
   - Platform-specific code

2. Performance Metrics
   - Response times
   - Resource usage
   - Battery efficiency
   - Network efficiency
   - Watch efficiency
   - Sync efficiency

3. User Experience
   - Usability testing
   - Accessibility compliance
   - Error handling
   - Recovery procedures
   - Watch experience
   - Cross-device experience

### Review Process
1. Code Review
   - Architecture review
   - Implementation review
   - Security review
   - Performance review
   - Watch review
   - Cross-platform review

2. Testing Review
   - Test coverage
   - Test quality
   - Test automation
   - Watch testing
   - Platform testing
   - Integration testing

3. Documentation Review
   - Technical docs
   - API docs
   - User guides
   - Watch docs
   - Platform docs
   - Integration docs

## Monetization Strategy

### Core Philosophy
Focus4 follows a freemium model that prioritizes user experience while ensuring sustainable revenue. The core focus management features remain completely free, while social features are gated behind a premium subscription.

### Free Tier
- Complete friction engine functionality
  - App usage tracking
  - Friction tasks
  - Haptic feedback
  - Apple Watch integration
- Limited social features (3-month trial period):
  - 25 event views per month
  - 2 event attendances per month
  - Basic host ranking
  - Standard notifications
- Time-limited access:
  - Full free tier features available for 3 months
  - After 3 months, social features are restricted
  - Core focus features remain free indefinitely

### Premium Tier
- Pricing:
  - Monthly: $3.87
  - Yearly: $36.19 (22% savings)
- All friction features remain free
- Full social features:
  - Unlimited event viewing
  - Unlimited event attendance
  - Create unlimited events
  - Advanced host ranking
  - Priority notifications
  - Enhanced QR code features
  - Advanced Apple Watch features
  - Ad-free experience

### Upgrade Triggers
1. Primary Triggers:
   - When user hits attendance limit (2 events)
   - When trying to create an event
   - When accessing advanced social features
   - When approaching 3-month trial end

2. Secondary Triggers:
   - When approaching view limit (e.g., at 20 views)
   - When viewing premium features
   - When engaging with community features

3. Soft Triggers:
   - Highlighting premium features in event details
   - Showing premium benefits in host profiles
   - Displaying premium features in event creation flow

### Implementation Guidelines
1. User Experience
   - Clear upgrade path
   - Non-intrusive upgrade prompts
   - Easy subscription management
   - Clear feature differentiation

2. Technical Requirements
   - Subscription management
   - Usage tracking
   - Time limit enforcement
   - Feature flagging system

3. Analytics Requirements
   - Conversion tracking
   - Usage patterns
   - Upgrade triggers effectiveness
   - Retention metrics

4. Security Requirements
   - Secure payment processing
   - Subscription validation
   - Usage limit enforcement
   - Data protection

## Pre-Release Documentation Requirements

Before submitting to the App Store, ensure the following views contain accurate, up-to-date information:

### Legal and Informational Views
- `PrivacyPolicyView`: Must reflect actual data collection, usage, and sharing practices
- `TermsView`: Must contain current terms of service and usage conditions
- `AcknowledgmentsView`: Must list:
  - All actual third-party libraries used in the project
  - Correct versions of each library
  - Accurate license information
  - Real contributors and credits
  - Current team information
- `AboutView`: Must include:
  - Current app version
  - Accurate contact information
  - Valid links to website, support, and social media
  - Up-to-date feature descriptions
  - Current copyright information

### Verification Checklist
- [ ] All legal text has been reviewed by legal counsel
- [ ] Privacy policy matches actual app behavior
- [ ] Terms of service are current and applicable
- [ ] All third-party libraries are properly credited
- [ ] All links are valid and accessible
- [ ] Contact information is current
- [ ] Version numbers are accurate
- [ ] Copyright year is current
- [ ] Feature descriptions match actual functionality

## New Data Model Documentation

### Users
- phoneNumber (unique identifier)
- displayName
- profileImage
- hostRating
- blockedUsers (array)
- deletedAt
- accountStatus
- canceledEvents (array of {eventId, cancelDate})
- blocksReceived (array of {hostId, blockDate})
- accountWarnings (array of {warningType, date})
- lastCanceledEventDate (for 60-day reset)

### Events
- eventId
- hostId
- title
- summary
- description
- category
- tags
- location
- startTime
- endTime
- maxAttendees
- currentAttendees
- status
- createdAt
- expiresAt
- isHumanVerified (boolean)
- reportedContent (array of {userId, reason, date})
- blockedUsers (array of userIds)

### Categories
- categoryId
- name
- description
- isActive
- createdAt
- submittedBy (userId)
- submissionStatus (pending/approved/rejected)
- submissionDate

## Storage & Caching

### Storage Limits
- Total app storage: 150MB
  - Focus app: ~50MB (task data, settings, analytics)
  - Meetup data: ~100MB (event details, images, user data)
- Local cache: Minimal, optimized for performance
  - Focus app: Task data, settings, recent analytics
  - Meetup: 15 most recent events with optimized details

### Caching Strategy
1. Focus App Cache
   - Active tasks and settings
   - Recent analytics data
   - User preferences
   - Sync state

2. Meetup Cache
   - Recent events (15 most recent)
   - User profile data
   - Event images (optimized)
   - Search results

3. Watch Cache
   - Current timer state
   - Active tasks
   - Complications data
   - Sync state

### Cache Management
1. Cache Invalidation
   - Time-based expiration
   - Event-based invalidation
   - Storage pressure triggers
   - User action triggers

2. Cache Optimization
   - Size limits per category
   - Compression for images
   - Prioritized retention
   - Background cleanup

### Storage Management
1. Local Storage
   - Core Data: 30MB
   - UserDefaults: 1MB
   - File System: 19MB
   - Cache: 20MB

2. Remote Storage
   - Firebase: 100MB
   - CloudKit: 50MB
   - Push Notifications: 1MB
   - Analytics: 1MB

### Sync Strategy
1. Background Sync
   - Every 15 minutes
   - On app launch
   - After significant changes
   - When network available

2. Manual Sync
   - Pull to refresh
   - Settings trigger
   - User request
   - Error recovery

## Analytics Implementation

### Data Collection
1. Event Tracking
   - User actions
   - Feature usage
   - Error events
   - Performance metrics
   - Watch interactions

2. Performance Metrics
   - App launch time
   - Screen load time
   - Network latency
   - Memory usage
   - Battery impact
   - Watch sync time

3. User Behavior
   - Session duration
   - Feature adoption
   - Drop-off points
   - Usage patterns
   - Watch usage patterns

4. Error Tracking
   - Crash reports
   - Error logs
   - Stack traces
   - User context
   - Recovery attempts

### Data Processing
1. Local Processing
   - Data aggregation
   - Metric calculation
   - Pattern detection
   - Anomaly detection
   - Watch data processing

2. Cloud Processing
   - Data normalization
   - Trend analysis
   - User segmentation
   - Cohort analysis
   - Cross-platform analysis

3. Data Aggregation
   - Daily summaries
   - Weekly reports
   - Monthly analysis
   - Quarterly reviews
   - Annual trends

### Reporting
1. Daily Reports
   - Active users
   - Feature usage
   - Error rates
   - Performance metrics
   - Watch engagement

2. Weekly Summaries
   - Usage trends
   - Feature adoption
   - Error patterns
   - Performance trends
   - User feedback

3. Monthly Analysis
   - Growth metrics
   - Retention rates
   - Revenue analysis
   - User satisfaction
   - Platform comparison

### Analytics Requirements
1. Data Privacy
   - GDPR compliance
   - CCPA compliance
   - Data minimization
   - User consent
   - Data retention

2. Performance Impact
   - Minimal battery drain
   - Low network usage
   - Efficient storage
   - Background processing
   - Watch optimization

3. Implementation Guidelines
   - Consistent tracking
   - Error handling
   - Offline support
   - Data validation
   - Watch sync

## Monitoring Systems

### Performance Monitoring
1. App Performance
   - Launch time tracking
   - Screen load times
   - Memory usage
   - CPU utilization
   - Battery impact
   - Watch performance

2. Network Performance
   - Request latency
   - Response times
   - Bandwidth usage
   - Connection quality
   - Sync performance
   - Watch connectivity

3. Storage Performance
   - Storage usage
   - Cache efficiency
   - Database performance
   - File system operations
   - Watch storage

### Error Monitoring
1. Crash Reporting
   - Crash logs
   - Stack traces
   - Device information
   - User context
   - Recovery attempts
   - Watch crashes

2. Error Tracking
   - Error types
   - Error frequency
   - Error patterns
   - User impact
   - Resolution status
   - Watch errors

3. Recovery Monitoring
   - Recovery success rate
   - Recovery time
   - User intervention
   - Automatic recovery
   - Watch recovery

### User Analytics
1. Engagement Metrics
   - Active users
   - Session duration
   - Feature usage
   - Drop-off points
   - Watch engagement
   - Cross-platform usage

2. Behavior Analysis
   - Usage patterns
   - Feature adoption
   - User flows
   - Pain points
   - Watch behavior
   - Platform preferences

3. Feedback Collection
   - User ratings
   - App Store reviews
   - In-app feedback
   - Support tickets
   - Watch feedback
   - Feature requests

### System Health
1. Resource Usage
   - Memory consumption
   - CPU usage
   - Battery drain
   - Storage usage
   - Network bandwidth
   - Watch resources

2. Service Health
   - API availability
   - Response times
   - Error rates
   - Sync status
   - Watch sync
   - Background tasks

3. Platform Health
   - iOS version distribution
   - WatchOS version distribution
   - Device types
   - Network conditions
   - Regional usage
   - Platform-specific issues

### Alert System
1. Critical Alerts
   - Service outages
   - High error rates
   - Performance degradation
   - Security incidents
   - Watch issues
   - Sync failures

2. Warning Alerts
   - Performance trends
   - Error patterns
   - Resource usage
   - User feedback
   - Watch warnings
   - Sync delays

3. Informational Alerts
   - Feature adoption
   - Usage trends
   - Platform updates
   - Watch updates
   - System changes
   - Maintenance windows

## User Experience Guidelines

### Design Principles
1. Simplicity
   - Clean, uncluttered interfaces
   - Intuitive navigation
   - Clear visual hierarchy
   - Minimal cognitive load
   - Watch-optimized layouts
   - Consistent patterns

### User Interface Standards
1. Navigation
   - Tab-based primary navigation
   - Hierarchical drill-down
   - Clear back navigation
   - Gesture support
   - Watch crown integration
   - Cross-device consistency

2. Typography
   - System fonts
   - Dynamic type support
   - Clear hierarchy
   - Consistent sizing
   - Watch legibility
   - Accessibility compliance

3. Color System
   - Brand colors
   - Semantic colors
   - Dark mode support
   - Accessibility contrast
   - Watch complications
   - Color blindness support

### Interaction Patterns
1. Touch Interactions
   - Tap targets
   - Swipe actions
   - Long press
   - Pinch to zoom
   - Watch gestures
   - Force touch (where applicable)

2. Feedback
   - Visual feedback
   - Haptic feedback
   - Audio feedback
   - Progress indicators
   - Error states
   - Success states

3. Animations
   - Natural transitions
   - Meaningful motion
   - Performance optimization
   - Reduced motion support
   - Watch animations
   - Loading states

### Accessibility
1. VoiceOver
   - Screen reader support
   - Meaningful labels
   - Action descriptions
   - Navigation flow
   - Watch VoiceOver
   - Dynamic updates

2. Dynamic Type
   - Text scaling
   - Layout adaptation
   - Minimum text size
   - Maximum text size
   - Watch text scaling
   - UI adjustments

3. Additional Support
   - Reduced motion
   - Color contrast
   - Bold text
   - Button shapes
   - On/off labels
   - Haptic alerts

### Cross-Platform Consistency
1. Shared Elements
   - Visual language
   - Interaction patterns
   - Navigation flows
   - Data presentation
   - Error handling
   - Success states

2. Platform-Specific
   - iOS optimizations
   - Watch optimizations
   - Screen size adaptations
   - Input methods
   - Hardware features
   - Platform capabilities

### Performance Guidelines
1. Response Times
   - Immediate feedback
   - Loading indicators
   - Progress updates
   - Background tasks
   - Watch responsiveness
   - Sync status

2. Resource Usage
   - Memory efficiency
   - Battery optimization
   - Network usage
   - Storage management
   - Watch battery life
   - Background refresh

## Distribution Guidelines

### App Store Preparation
1. Metadata Requirements
   - App name and subtitle optimization
   - Compelling app description
   - Keywords optimization
   - Screenshots for iOS and Watch
   - App preview videos
   - Privacy policy URL
   - Support URL

2. Asset Requirements
   - App icon (all sizes)
   - Watch app icon
   - Marketing screenshots
   - Preview videos
   - Promotional artwork
   - Brand assets

3. Technical Requirements
   - Build optimization
   - Size optimization
   - Battery usage optimization
   - Network usage optimization
   - Watch app optimization
   - TestFlight distribution

### Release Management
1. Version Control
   - Semantic versioning
   - Build numbering
   - Release notes
   - Change logs
   - Watch app versioning
   - App Store versioning

2. Phased Release
   - TestFlight beta testing
   - Staged rollout
   - Version monitoring
   - Crash monitoring
   - Analytics monitoring
   - Rollback strategy

3. Post-Release
   - Performance monitoring
   - User feedback tracking
   - Bug tracking
   - Support response
   - Watch app monitoring
   - Analytics review

### Compliance
1. App Store Guidelines
   - Content guidelines
   - Privacy requirements
   - Data collection
   - In-app purchases
   - Watch app guidelines
   - Subscription rules

2. Legal Requirements
   - Terms of service
   - Privacy policy
   - Data protection
   - User agreements
   - Age restrictions
   - Regional compliance

3. Technical Compliance
   - iOS requirements
   - WatchOS requirements
   - Network security
   - Data encryption
   - API compliance
   - SDK requirements

## Compliance and Release Guidelines

### Privacy Compliance
1. Data Collection
   - User consent management
   - Data minimization practices
   - Purpose specification
   - Retention policies
   - Watch data handling
   - Cross-device sync privacy

2. GDPR Requirements
   - Right to access
   - Right to be forgotten
   - Data portability
   - Consent management
   - Data processing records
   - International transfers

3. CCPA Compliance
   - Privacy notices
   - Opt-out mechanisms
   - Data sale provisions
   - Minor protection
   - Service provider requirements
   - Verification processes

### Security Standards
1. Authentication Security
   - Phone number verification
   - Session management
   - Token handling
   - Watch authentication
   - Biometric security
   - Multi-device security

2. Data Protection
   - Encryption at rest
   - Encryption in transit
   - Key management
   - Secure storage
   - Watch data protection
   - Backup security

3. Network Security
   - API security
   - Certificate pinning
   - Request signing
   - Rate limiting
   - Watch connectivity
   - Sync security

### Release Process
1. Pre-Release Checklist
   - Code freeze
   - Feature verification
   - Performance testing
   - Security audit
   - Watch app testing
   - Documentation review

2. Release Phases
   - Internal testing
   - TestFlight beta
   - Staged rollout
   - Full release
   - Watch app release
   - Marketing coordination

3. Post-Release Monitoring
   - Performance metrics
   - Error tracking
   - User feedback
   - Analytics review
   - Watch metrics
   - Support readiness

### Maintenance Plan
1. Regular Updates
   - Security patches
   - Bug fixes
   - Performance improvements
   - Feature updates
   - Watch updates
   - Documentation updates

2. Emergency Procedures
   - Critical bug protocol
   - Security incident response
   - Service disruption plan
   - Data breach response
   - Watch emergency fixes
   - Communication plan

3. Version Support
   - iOS version support
   - WatchOS version support
   - Deprecation policy
   - Migration support
   - Legacy feature support
   - End-of-life planning

## Integrated Implementation Order

### Phase 1: Foundation & Shared Infrastructure
1. Project Setup
   - Create Xcode project with iOS and Watch targets
   - Set up shared framework
   - Configure Firebase
   - Set up CoreData with Watch support
   - Create unified folder structure

2. Data Layer & Models (Shared)
   - UserProfile model
   - FocusSession model
   - UserPreferences model
   - Firebase service layer (iOS)
   - Local caching service (shared)
   - Data synchronization (shared)
   - Watch complications data source

3. Authentication System (iOS)
   - Phone authentication UI
   - Firebase Auth integration
   - User profile creation
   - Authentication state management
   - Onboarding flow

### Phase 2: Core Focus Features (Shared)
1. Task Management
   - Task creation (shared)
   - Task editing (shared)
   - Task organization (shared)
   - Task persistence (shared)
   - Task UI (platform-specific)

2. Timer System
   - Timer interface (platform-specific)
   - Timer logic (shared)
   - Timer controls (shared)
   - Timer notifications (shared)
   - Timer persistence (shared)
   - Watch complications updates

3. Friction Engine
   - Friction types (shared)
   - Friction triggers (shared)
   - Friction UI (platform-specific)
   - Friction analytics (shared)
   - Haptic feedback (shared)

### Phase 3: Meetup System (iOS)
1. Event Management
   - Event listing
   - Event details
   - Event search
   - Event filtering

2. User Interaction
   - RSVP system
   - Event sharing
   - User profiles
   - Notifications

### Phase 4: Enhancement & Optimization
1. Performance
   - Load time optimization
   - Memory management
   - Storage optimization
   - Network efficiency

2. User Experience
   - UI polish
   - Animation refinement
   - Accessibility
   - Localization

## Project Structure

### Directory Structure
```
Focus4/
├── Core/
│   ├── Models/         (Shared models)
│   ├── Services/       (Shared services)
│   └── Extensions/     (Shared extensions)
├── Features/
│   ├── Authentication/ (iOS only)
│   ├── Timer/         (iOS + Watch)
│   ├── Statistics/    (iOS + Watch)
│   └── Settings/      (iOS + Watch)
└── Shared/
    └── (Shared framework code)
```

## Component Architecture

### Core Components
1. Authentication Module
   - AuthenticationService
   - UserProfileService
   - PhoneVerificationManager
   - AuthenticationViewModel
   - AuthenticationViews
   - WatchAuthSync

2. Focus Engine
   - FocusSessionManager
   - TimerService
   - FrictionEngine
   - TaskManager
   - WatchFocusSync
   - FocusViewModel

3. Meetup System
   - EventService
   - LocationManager
   - QRCodeManager
   - EventViewModel
   - MeetupViews
   - WatchEventSync

### Service Layer
1. Data Services
   - FirebaseService
   - CoreDataService
   - CloudKitService
   - LocalCacheService
   - WatchSyncService
   - AnalyticsService

2. Utility Services
   - NetworkManager
   - LoggingService
   - ErrorHandler
   - NotificationService
   - WatchConnectivity
   - SecurityService

3. Business Services
   - UserService
   - EventService
   - StatisticsService
   - SubscriptionService
   - WatchDataService
   - SyncService

### View Layer
1. iOS Views
   - Authentication
   - Focus Timer
   - Event Management
   - User Profile
   - Settings
   - Statistics

2. Watch Views
   - Timer
   - Event Details
   - Quick Actions
   - Complications
   - Settings
   - Notifications

3. Shared Components
   - Loading Views
   - Error Views
   - Empty States
   - Action Sheets
   - Alerts
   - Progress Views

### Data Flow
1. User Data
   - Authentication → Profile
   - Profile → Preferences
   - Preferences → Settings
   - Settings → Watch
   - Watch → Sync
   - Sync → Cloud

2. Focus Data
   - Session → Timer
   - Timer → Tasks
   - Tasks → Progress
   - Progress → Statistics
   - Statistics → Watch
   - Watch → Cloud

3. Event Data
   - Creation → Validation
   - Validation → Storage
   - Storage → Display
   - Display → Watch
   - Watch → Updates
   - Updates → Sync

## Technical Requirements

### Performance Benchmarks
- App size: < 50MB
- Launch time: < 2 seconds
- Screen load time: < 1 second
- Local storage usage: < 150MB total
- Network usage: < 5MB per hour
- Memory usage: < 100MB

### Security Requirements
1. Authentication
   - Phone number verification
   - Two-factor authentication (optional)
   - Session management
   - Token-based authentication

2. Data Protection
   - At rest: AES-256 encryption
   - In transit: TLS 1.3
   - Key management
   - Key rotation

## Testing Framework

### Component Testing
1. Unit Tests
   - Component logic
   - Service functionality
   - Utility methods
   - State management

2. UI Tests
   - Component rendering
   - User interactions
   - State changes
   - Error states

### Integration Testing
1. Feature Integration
   - Component interaction
   - Data flow
   - State management
   - Error handling

2. Platform Integration
   - iOS-Watch sync
   - Data consistency
   - State synchronization
   - Error recovery

## Documentation Requirements

### Component Documentation
1. Implementation Details
   - Component purpose
   - Dependencies
   - Usage examples
   - Testing requirements

2. API Documentation
   - Public interfaces
   - Method signatures
   - Parameter descriptions
   - Return values

## Review Process

### Phase-Specific Reviews
1. Foundation & Shared Infrastructure
   - Authentication flow review
   - Security implementation review
   - Basic UI component review
   - Data model review
   - Shared framework review

2. Core Focus Features
   - Task management review
   - Timer system review
   - Friction engine review
   - Analytics implementation review
   - Watch integration review

3. Meetup System
   - Event management review
   - User profiles review
   - RSVP system review
   - Notification system review

4. Enhancement & Optimization
   - Performance optimization review
   - Security enhancement review
   - UI/UX improvement review
   - Analytics enhancement review

## Deployment Strategy

### Environment Setup
1. Development
   - Debug configuration
   - Test environment
   - Development assets
   - Local settings

2. Production
   - Release optimization
   - Production assets
   - Distribution settings
   - Analytics integration

### Release Process
1. Pre-release
   - Code review
   - Test verification
   - Performance check
   - Security scan
   - Documentation update

2. Post-release
   - Health check
   - Monitoring
   - Backup verification
   - Performance verification
   - User notification

## Cross-References

### Implementation References
- Component Architecture: Refer to `architecture.md`
- Data Management: Refer to `data_management.md`
- Project Structure: Refer to `project_structure.md`
- Review Process: Refer to `review_process.md`
- Scope Boundaries: Refer to `scope_boundaries.md`

### Document Relationships
- This document defines the integrated development approach
- Architecture defines component structure
- Data Management defines data handling
- Project Structure defines file organization
- Review Process defines quality checks

## Data Retention

### User Data Retention
1. Active User Data
   - Profile information: Until account deletion
   - Authentication data: Until session expiry
   - Preferences: Until account deletion
   - Watch settings: Until account deletion
   - Device tokens: Until device change
   - Session history: 12 months

2. Inactive User Data
   - Profile: 6 months after last activity
   - Session data: 3 months after last activity
   - Analytics: 12 months
   - Watch data: 3 months
   - Device info: 6 months
   - Preferences: 6 months

3. Deleted User Data
   - Immediate deletion: Personal information
   - 30-day retention: Anonymous analytics
   - 90-day retention: Aggregated statistics
   - Watch data: Immediate deletion
   - Event contributions: Anonymized
   - System logs: 30 days

### Event Data Retention
1. Active Events
   - Event details: Until completion + 30 days
   - Participant data: Until completion + 7 days
   - Chat links: Until completion
   - Location data: Until completion
   - Watch data: Until completion
   - Analytics: 90 days

2. Past Events
   - Basic details: 12 months
   - Participant list: 3 months (anonymized)
   - Statistics: 12 months
   - Watch data: 30 days
   - Reviews: 12 months
   - Reports: 24 months

3. Cancelled Events
   - Basic info: 30 days
   - Participant notifications: 7 days
   - System logs: 30 days
   - Watch data: Immediate deletion
   - Analytics: 90 days
   - Reports: 12 months

### System Data Retention
1. Performance Data
   - Error logs: 30 days
   - Performance metrics: 90 days
   - Usage statistics: 12 months
   - Watch metrics: 30 days
   - Crash reports: 90 days
   - Analytics: 12 months

2. Security Data
   - Authentication logs: 90 days
   - Security incidents: 12 months
   - Access logs: 30 days
   - Watch security logs: 30 days
   - System alerts: 90 days
   - Audit trails: 12 months

3. Compliance Data
   - GDPR requests: 36 months
   - CCPA requests: 24 months
   - Legal holds: As required
   - Watch compliance: 12 months
   - Privacy logs: 24 months
   - Consent records: 36 months 