# Friction Logic Implementation Details

## Unified State Management Framework

### Core State Model
- **Central State Manager**: `FrictionStateManager`
  - Maintains single source of truth for friction states
  - Coordinates state transitions across components
  - Manages state persistence and recovery
  - Handles cross-device state synchronization

### State Events
- **Event Types**:
  - `FrictionTriggered`: Initial intervention request
  - `FrictionLevelChanged`: Escalation/de-escalation
  - `FrictionTaskCompleted`: User response received
  - `FrictionStateReset`: Return to baseline
  - `FrictionError`: System or user error occurred

### Component Integration

#### Timer Display
- **State Subscriptions**:
  - Listens for `FrictionTriggered` events
  - Responds to `FrictionLevelChanged` with visual updates
  - Handles `FrictionStateReset` to restore normal operation
- **State Effects**:
  - Pauses timer during friction tasks
  - Shows friction level indicator
  - Updates visual feedback based on level
  - Manages haptic feedback coordination

#### Settings Toggle
- **State Subscriptions**:
  - Monitors `FrictionLevelChanged` events
  - Responds to `FrictionStateReset` events
- **State Effects**:
  - Updates toggle state based on friction level
  - Manages accessibility settings
  - Controls haptic feedback intensity
  - Handles user preference updates

#### Focus Session Card
- **State Subscriptions**:
  - Listens for `FrictionTriggered` events
  - Monitors `FrictionTaskCompleted` events
- **State Effects**:
  - Updates session status display
  - Shows friction task progress
  - Manages session statistics
  - Handles user interaction states

### State Transitions

#### Timer Display States
```
Idle → Running → Paused → Completed
```
- **Purpose**: Manage visual and timing aspects of tasks
- **Key Functions**:
  - Display countdown progress
  - Show task status
  - Handle timing-related UI updates
  - Manage background state

#### Friction Override States
```
Active → Level 1 → Level 2 → Level 3 → Level 4
```
- **Purpose**: Manage behavioral intervention and escalation
- **Key Functions**:
  - Track override attempts
  - Determine intervention level
  - Manage escalation logic
  - Handle user responses

### State Interaction
- Timer Display listens for override events
- Friction logic can trigger timer state changes
- Clear interface between systems:
  - Timer → Friction: Time completion events
  - Friction → Timer: Pause/reset signals
  - Shared: State update notifications

### Recovery Flow
```
Override → Cooling Period → Idle
```

## Core Systems Integration

### Timing System
- **Purpose**: Manages intervention timing and escalation
- **Key Functions**:
  - Tracks time between overrides
  - Manages cooling periods
  - Controls intervention duration
  - Coordinates haptic feedback timing

### Analytics System
- **Purpose**: Tracks and analyzes user behavior
- **Key Functions**:
  - Records override patterns
  - Tracks task abandonment rates
  - Monitors intervention effectiveness
  - Generates usage statistics

### Task System
- **Purpose**: Manages intervention tasks and escalation
- **Key Functions**:
  - Creates and manages friction tasks
  - Handles task progression
  - Controls intervention levels
  - Manages user responses

## Intervention Tiers

### Level 1 – Gentle Reminder
- **Trigger**: Initial threshold or first minor override
- **Intervention Behavior**:
  - Phone: Single, soft vibration (gentle tap)
  - Apple Watch: No haptic feedback at this level (phone-only reminder)
- **Prompt**: "Is this the best use of your time right now?" (or similar)
- **Purpose**: Encourage a moment of mindfulness with minimal interruption

### Level 2 – Moderate Intervention
- **Trigger**: Increased usage or second override
- **Intervention Behavior**:
  - Phone: Two quick vibration pulses
  - Apple Watch: One gentle haptic tap (0.5s delay after phone)
- **Purpose**: Create a noticeable pause that makes the user reflect before proceeding

### Level 3 – Strong Intervention
- **Trigger**: Persistent usage or multiple overrides indicating pattern
- **Intervention Behavior**:
  - Phone: Three distinct pulses
  - Apple Watch: Two stronger haptic taps (partially overlapping with phone)
- **Purpose**: Significantly disrupt impulsive behavior and force deliberate reflection

### Level 4 – Extreme Intervention
- **Trigger**: Chronic misuse with repeated overrides
- **Intervention Behavior**:
  - Phone: Sustained "rumble" vibration
  - Apple Watch: Series of rapid, strong haptic pulses (intentionally out-of-sync)
- **Purpose**: Force deep, conscious reassessment of behavior

## Friction Tasks

### Level 2 Tasks
1. **Quick Reflection Prompt**
   - One-sentence input: "Why do you need to continue right now?"

2. **Simple Choice**
   - Binary options:
     - "Focus on your goal"
     - "Continue"
     - "Abandon this task"
   - Requires deliberate choice

### Level 3 Tasks
1. **Simple Cognitive Puzzle**
   - Basic math problem
   - Pattern recognition query
   - 10-15 second timer delay

2. **Short Reflection Exercise**
   - Text box prompt: "What distraction are you avoiding, and why does it matter?"

3. **Multiple-Choice Quiz**
   - Reflective questions about priorities
   - 10-15 second timer delay

### Level 4 Tasks
1. **Mirror Mirror Task**
   - Front-facing camera activation
   - User must write explanation of intended app usage
   - Psychological self-confrontation

2. **Multi-Step Reflective Challenge**
   Sequential prompts:
   - "List three reasons why your current focus matters"
   - "Describe one major distraction and its impact on your goals"
   - "State a personal commitment to regain focus in one actionable step"
   - "Reflect on how improved focus will benefit you today"

3. **Complex Cognitive Task**
   - Logic puzzle or multi-part decision scenario
   - 15-20 second timer delay

## Reflective Questions
(20 pre-defined questions for Level 2, randomly or sequentially selected)

1. "Is this the best use of your time right now?"
2. "What important task are you neglecting by continuing?"
3. "How will spending more time here affect your goals?"
4. "What could you accomplish if you focused on your priorities?"
5. "Is this activity in line with your values?"
6. "What is the one thing you need to achieve today?"
7. "How would you feel if you wasted this time?"
8. "What distraction are you trying to escape, and is it worth it?"
9. "How can you invest this moment more productively?"
10. "What's your primary objective at this moment?"
11. "Will continuing here bring you closer to your long-term goals?"
12. "What is one meaningful activity you could do instead?"
13. "Are you using this app to procrastinate or to focus?"
14. "What's one benefit you'll gain by taking a break from distractions?"
15. "Is this activity really serving your best interests?"
16. "What is the most important task on your agenda right now?"
17. "How can you better utilize your time at this moment?"
18. "What's one positive change you could make if you refocused?"
19. "What is the opportunity cost of staying on this app?"
20. "How will you feel if you shift your attention to something more meaningful?"

## Implementation Details

### Timer Integration
- Seamless timer state management
- Background state preservation
- Watch complication updates
- Integration with Timing System for intervention scheduling

### Data Persistence
- Override history tracking
- User preference storage
- Statistics collection
- Task abandonment tracking
- Analytics data storage

### System Coordination
- Timing System triggers interventions
- Analytics System determines escalation
- Task System executes appropriate level
- Cross-system communication for state management

### Accessibility
- VoiceOver support
- Haptic feedback options
- Visual alternatives

## Version History
- 2024-04-03: Added core systems integration structure
- 2024-04-03: Added task abandonment option to binary choice tasks
- 2024-04-03: Updated intervention tiers with refined behavioral approach
- 2024-04-03: Initial documentation created 