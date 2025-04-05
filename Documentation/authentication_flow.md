# Authentication Flow

## Cross-References
- For overall architecture, see `architecture.md`
- For implementation guidelines, see `master_dev_guide.md`
- For known issues and limitations, see `known_issues.md`
- For data handling details, see `data_management.md`

## Overview

The Focus4 authentication system uses a dual-method approach:
- **Primary Authentication**: Phone number with SMS verification (required)
- **Secondary Authentication**: Email/password for account recovery only (optional)

This document provides comprehensive details on the authentication flow, recovery procedures, security considerations, and handling of edge cases.

## User Onboarding Flow

### 1. Initial Launch & Phone Verification

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Welcome Screen │────▶│  Phone Number   │────▶│  SMS Code       │────▶│  Verification   │
│                 │     │  Entry          │     │  Entry          │     │  Processing     │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
                                                                               │
                                                                               ▼
                                                                        ┌─────────────────┐
                                                                        │  Verified       │
                                                                        │  Successfully   │
                                                                        └─────────────────┘
```

#### Welcome Screen
- Minimalistic design introducing Focus4 briefly
- Single call-to-action: "Get Started"
- Privacy policy and terms links (small, bottom of screen)

#### Phone Number Entry
- Country code selector with default based on locale
- Phone number input with formatting
- Clear error states for invalid formats
- "Next" button to request verification code
- Error handling for unsupported regions

#### SMS Verification
- Auto-detection of SMS code when possible
- Manual entry field with appropriate keyboard
- Countdown timer for code expiration
- Resend option (available after 30 seconds)
- "Didn't receive a code?" help text

#### Verification Success
- Success animation
- Automatic transition to profile creation

### 2. Profile Creation & Recovery Setup

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Basic Profile  │────▶│  Recovery Email │────▶│  Email          │────▶│  Onboarding     │
│  Form           │     │  Option         │     │  Verification   │     │  Completion     │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
```

#### Basic Profile Form
- Username field (required)
- Profile picture upload option (optional)
- Other minimal information relevant to app focus

#### Recovery Email Option
- Prominent section explaining benefits of recovery email
- Email input with validation
- Password creation with strength requirements
- "Skip for now" option (less prominent)
- Clear indication this is for recovery only

#### Email Verification (Optional)
- Email sent for verification if email provided
- Can proceed without immediate verification
- Reminder in app to verify email later
- Email contains verification link

#### Onboarding Completion
- Success screen
- Brief feature orientation
- Entry to main app interface

## Recovery Procedures

### 1. Standard Account Recovery

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Recovery       │────▶│  Email          │────▶│  Password-Based │────▶│  Account        │
│  Request        │     │  Verification   │     │  Authentication │     │  Access         │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
                                                                               │
                                                                               ▼
                                                                        ┌─────────────────┐
                                                                        │  Phone          │
                                                                        │  Re-verification│
                                                                        └─────────────────┘
```

#### Recovery Initiation
- "Can't access your account?" option on sign-in screen
- Input for recovery email address
- Verification that email exists in system
- Rate limiting to prevent abuse

#### Recovery Email
- Password reset link sent to recovery email
- Link expiration after 24 hours
- One-time-use link validation
- IP address and device logging for security

#### Limited Account Access
- Initial access is limited to profile and settings
- Option to send new verification to updated phone number
- Access to essential account functions only
- Security notifications on sign-in

#### Phone Re-verification
- Once new phone is verified, full account access restored
- Security notification to recovery email
- Session tokens refreshed
- Activity logging for security audit

### 2. Emergency Recovery Procedures

#### Support-Assisted Recovery
- For cases where both phone and email are inaccessible
- Requires identity verification through alternative means
- Limited to exceptional circumstances
- Detailed logging of all actions
- Security review before account access granted

#### Device-Based Recovery
- Option for previously authorized devices
- Additional security questions
- Biometric authentication if previously enabled
- Strict rate limiting
- Security notifications to all contact methods

## Security Considerations

### 1. Authentication Security Measures

#### Token Management
- Short-lived access tokens (1 hour)
- Longer refresh tokens (7 days)
- Secure token storage in Keychain
- Token rotation on security events
- Automatic invalidation after extended inactivity

#### Verification Limitations
- Maximum 5 SMS attempts per phone number in 24 hours
- Maximum 3 failed verification attempts before temporary lockout
- Maximum 5 email recovery attempts in 24 hours
- Progressive timeout for repeated failures
- Security notifications for unusual patterns

#### Cross-Device Authentication
- Primary device issues delegation to watches/extensions
- Cross-device verification for sensitive operations
- Session synchronization via encrypted channel
- Device registration and authorization flow
- Remote session termination capability

### 2. Security Event Handling

#### Suspicious Activity Detection
- Multiple failed authentication attempts
- Authentication from new locations/devices
- Unusual usage patterns
- Rapid changes to profile or authentication methods
- Multiple recovery attempts

#### Security Event Response
- Account lockdown procedures
- Notification via all available channels
- Step-up authentication requirements
- Activity logging for security audit
- Recovery verification requirement

## Edge Cases Handling

### 1. Technical Issues

#### SMS Delivery Failures
- Alternative verification channels
- Carrier-specific SMS troubleshooting
- WhatsApp verification fallback (where allowed)
- Delayed SMS handling
- Support contact option after multiple failures

#### Email Delivery Issues
- Spam filter recommendations
- Alternative email option
- Delivery success validation
- Instructions for checking spam folders
- Email client-specific troubleshooting

#### Network Connectivity Issues
- Offline authentication support
- Session extension during intermittent connectivity
- Retry logic with exponential backoff
- State recovery after reconnection
- Cached credentials for known devices

### 2. User Behavior Edge Cases

#### Multiple Device Management
- Clear device list in settings
- Remote logout capabilities
- Per-device permissions
- Primary device designation
- Inactive device cleanup

#### International User Support
- Region-specific phone format handling
- International SMS reliability considerations
- Language support for verification messages
- Region-restricted feature handling
- Time zone considerations for expirations

#### Account Sharing Prevention
- Session limitation policies
- Concurrent login detection
- Location-based suspicious activity
- Device fingerprinting
- Behavioral analysis

## Implementation Guidelines

### 1. Error Message Guidelines

#### Phone Authentication Errors
- Invalid format: "Please enter a valid phone number with country code"
- SMS failure: "We couldn't deliver the code. Please verify your number or try again in a few minutes"
- Code expired: "This code has expired. We've sent a new one to your phone"
- Too many attempts: "Too many incorrect attempts. Please wait 30 minutes before trying again"

#### Email Recovery Errors
- Invalid email: "Please enter a valid email address"
- Unrecognized email: "This email isn't associated with an account"
- Password requirements: "Password must be at least 8 characters with a number and special character"
- Rate limiting: "For security reasons, please wait before requesting another recovery"

### 2. User Experience Guidelines

#### Authentication Progress Indication
- Clear progress steps (1/4, 2/4, etc.)
- Persistent indicator during async operations
- Error state visualization
- Success confirmation animations
- Timeout indicators for time-sensitive operations

#### Accessibility Considerations
- VoiceOver support for all authentication screens
- Additional verification time allowances when needed
- Alternative text input methods
- High contrast mode support
- Screen reader optimized instructions

### 3. Testing Scenarios

#### Required Test Cases
- Successful phone verification
- Invalid phone formats
- SMS timeout handling
- Recovery email verification
- Password recovery
- Cross-device authentication
- Session timeout handling
- Multiple failed attempts
- Network interruption
- International phone formats

## Version History
- 2024-04-03: Initial documentation created 