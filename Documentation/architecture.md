# Architecture

## System Architecture

### Core Components
1. Authentication System
   - Phone Authentication (Primary)
   - Email Recovery (Secondary)
   - User Profile Management
   - Session Management
   - Cross-Device Authentication

2. Focus App
   - Task Management
   - Timer System
   - Friction Engine
   - Analytics Dashboard

3. Meetup System
   - Event Management
   - User Profiles
   - RSVP System
   - Notifications

### Shared Components
1. UI Components
   - Buttons
   - Input fields
   - Cards
   - Navigation elements
   - Loading indicators
   - Error states

2. Navigation Components
   - Tab bar
   - Navigation stack
   - Modal presentations
   - State management for navigation

3. Utility Components
   - Date formatters
   - Image loaders
   - Network indicators
   - Error handlers

## Authentication Architecture

### Authentication Flow
1. Primary Authentication Flow (Phone)
   ```
   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
   │  Phone Number   │────▶│  SMS Code       │────▶│  Verification   │────▶│  Profile        │
   │  Entry          │     │  Delivery       │     │  Completion     │     │  Creation       │
   └─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
                                                                                  │
                                                                                  ▼
                                                                           ┌─────────────────┐
                                                                           │  Recovery Email │
                                                                           │  Option         │
                                                                           └─────────────────┘
   ```

2. Recovery Authentication Flow (Email)
   ```
   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
   │  Recovery       │────▶│  Email          │────▶│  Password       │────▶│  Account        │
   │  Request        │     │  Verification   │     │  Creation       │     │  Access         │
   └─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
                                                                                  │
                                                                                  ▼
                                                                           ┌─────────────────┐
                                                                           │  Phone Number   │
                                                                           │  Update         │
                                                                           └─────────────────┘
   ```

3. Authentication Method Relationship
   ```
   ┌──────────────────────┐                         ┌──────────────────────┐
   │                      │                         │                      │
   │  Phone Auth (Primary)│                         │  Email (Recovery)    │
   │                      │◀────Links to─────────▶ │                      │
   └──────────────────────┘                         └──────────────────────┘
         │        ▲                                         ▲        │
         │        │                                         │        │
         │        │           ┌─────────────┐              │        │
         │        │           │             │              │        │
         ▼        │           │  User       │              │        ▼
    ┌──────────┐  │           │  Account    │             │   ┌──────────┐
    │ Sign-in  │  │           │             │             │   │ Account  │
    │ Process  │──┘           └─────────────┘             └───│ Recovery │
    └──────────┘                                              └──────────┘
   ```

### Authentication Components
1. Phone Authentication Components
   - PhoneNumberValidator
   - SMSCodeManager
   - VerificationHandler
   - PhoneAuthViewModel
   - InternationalPhoneFormatter
   - VerificationTimerService

2. Email Recovery Components
   - EmailValidator
   - PasswordManager
   - RecoveryRequestHandler
   - EmailRecoveryViewModel
   - SecurityQuestionHandler
   - AccountRestoreService

3. Shared Authentication Components
   - TokenManager
   - SessionController
   - AuthStateObserver
   - BiometricAuthHelper
   - WatchAuthStateSync
   - SecurityAuditLogger

### Authentication-User Relationship
- Each user account has exactly one primary authentication method (phone)
- Each user account may have zero or one recovery method (email)
- Authentication methods are linked by internal account identifiers
- Authentication state is synchronized across devices
- Recovery method cannot be used for primary sign-in
- Changes to either method require verification

## Data Flow

### Authentication Data Flow
1. Phone Authentication Flow
   - Phone Entry → Validation → SMS Delivery → Code Verification → Account Access → Profile Creation
   - Authentication token stored in secure storage
   - User ID linked to phone number in Firebase
   - Session state propagated to all app components

2. Email Recovery Flow
   - Recovery Request → Email Delivery → Link Verification → Password Creation → Limited Account Access
   - Temporary recovery token with expiration
   - Recovery state allows only specific account operations
   - Full authentication restored after phone verification

3. Cross-Device Authentication
   - Authentication state synchronized via CloudKit
   - Watch receives delegated authentication from phone
   - Session tokens refreshed based on device-specific timeouts
   - Authentication events logged for security monitoring

### Local Data Layer
1. Core Data
   - Task entities
   - User settings
   - Analytics data
   - Sync state

2. File System
   - Cached images
   - Logs
   - Temporary files
   - Backup data

### Remote Data Layer
1. Firebase
   - User authentication
   - User profiles
   - Event data
   - Analytics
   - Push notifications

2. CloudKit
   - Device sync
   - Settings sync
   - Backup data
   - Shared data

## Component Architecture

### Focus App Components
1. Task Management
   - Task list
   - Task creation
   - Task editing
   - Task organization

2. Timer System
   - Timer interface
   - Timer controls
   - Timer notifications
   - Timer persistence

3. Friction Engine
   - Friction types
   - Friction triggers
   - Friction UI
   - Friction analytics

4. Analytics Dashboard
   - Usage statistics
   - Performance metrics
   - User feedback
   - Error tracking

### Meetup Components
1. Event Management
   - Event list
   - Event details
   - Event search
   - Event filtering

2. User Interaction
   - RSVP interface
   - Event sharing
   - User profiles
   - Notifications

3. Group Management
   - Group creation
   - Member management
   - Group settings
   - Group analytics

## Security Implementation

### Authentication Security
1. User Identity
   - Phone number verification
   - Email verification
   - Account linking protection
   - Cross-verification requirements
   - Recovery limitations

2. Session Security
   - Short-lived authentication tokens
   - Secure storage in Keychain
   - Background session expiration
   - Token refresh mechanisms
   - Watch delegated authentication

### Local Security
1. Storage
   - File encryption
   - Keychain access
   - Secure containers
   - Access control

2. Cache
   - Basic encryption
   - Secure deletion
   - Access limits
   - Size control

### Network Security
1. Transmission
   - HTTPS
   - Certificate pinning
   - Request signing
   - Response validation

2. Authentication
   - Token management
   - Session control
   - Access levels
   - Rate limiting

## State Management

### Authentication State
1. Unauthenticated State
   - Initial app launch
   - Signed out
   - Session expired
   - Recovery in progress

2. Authenticated State
   - Fully authenticated (phone)
   - Recovery authentication (email)
   - Temporary access (recovery in progress)
   - Watch delegated authentication

### App State
1. User State
   - Authentication state
   - User preferences
   - Session data
   - Feature flags

2. Feature State
   - Task state
   - Timer state
   - Event state
   - Sync state

### UI State
1. Navigation State
   - Current screen
   - Navigation stack
   - Modal state
   - Tab selection

2. Component State
   - Loading states
   - Error states
   - Success states
   - Empty states

## Error Handling

### Authentication Errors
1. Phone Authentication Errors
   - Invalid phone number format
   - SMS delivery failure
   - Verification code expiration
   - Too many verification attempts
   - Network timeout during verification

2. Recovery Authentication Errors
   - Invalid email format
   - Email delivery failure
   - Recovery link expiration
   - Password complexity requirements
   - Rate limiting of recovery attempts

3. Recovery Procedures
   - Automated retry mechanisms
   - Alternative verification options
   - Fallback verification channels
   - Support-assisted recovery

### Component Errors
1. UI Errors
   - Input validation
   - State errors
   - Navigation errors
   - Display errors

2. Data Errors
   - Sync errors
   - Storage errors
   - Network errors
   - Cache errors

### Recovery Procedures
1. Automatic Recovery
   - State restoration
   - Data revalidation
   - Cache management
   - Network recovery

2. Manual Recovery
   - User intervention
   - Data recovery
   - Cache clearing
   - State reset

## Performance Optimization

### Component Optimization
1. UI Performance
   - View recycling
   - Lazy loading
   - Image optimization
   - Animation efficiency

2. Data Performance
   - Efficient queries
   - Batch operations
   - Cache management
   - Background processing

### Resource Management
1. Memory Management
   - Memory limits
   - Resource cleanup
   - Cache size control
   - Background task limits

2. Storage Management
   - Storage limits
   - Cache cleanup
   - Temporary file management
   - Backup management

Note: For detailed implementation guidelines, refer to `master_dev_guide.md` for overall architecture and `data_management.md` for data handling specifics. 