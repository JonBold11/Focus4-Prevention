import Foundation
import CoreData
import Combine

/// A service for managing focus sessions
public class FocusSessionService {
    // MARK: - Properties
    
    /// The shared singleton instance
    public static let shared = FocusSessionService()
    
    /// The Core Data manager
    private let coreDataManager = CoreDataManager.shared
    
    /// The user profile service
    private let userProfileService = UserProfileService.shared
    
    /// The data synchronization service
    private let syncService = DataSynchronizationService.shared
    
    /// Timer for session tracking
    private var sessionTimer: Timer?
    
    /// Current session publisher
    private let currentSessionSubject = CurrentValueSubject<FocusSession?, Never>(nil)
    public var currentSession: AnyPublisher<FocusSession?, Never> {
        return currentSessionSubject.eraseToAnyPublisher()
    }
    
    /// Session state publisher
    private let sessionStateSubject = CurrentValueSubject<SessionState, Never>(.idle)
    public var sessionState: AnyPublisher<SessionState, Never> {
        return sessionStateSubject.eraseToAnyPublisher()
    }
    
    /// Remaining time publisher (in seconds)
    private let remainingTimeSubject = CurrentValueSubject<Int, Never>(0)
    public var remainingTime: AnyPublisher<Int, Never> {
        return remainingTimeSubject.eraseToAnyPublisher()
    }
    
    /// Cancellables bag
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Starts a new focus session
    /// - Parameters:
    ///   - taskID: Optional ID of the task to associate with the session
    ///   - title: Optional session title
    ///   - duration: Duration in seconds, defaults to user's settings
    ///   - completion: Callback with the created session or error
    public func startSession(
        taskID: UUID? = nil,
        title: String? = nil,
        duration: Int32? = nil,
        completion: @escaping (Result<FocusSession, Error>) -> Void
    ) {
        // Check if there's already an active session
        if let currentSession = currentSessionSubject.value, currentSession.isActive {
            completion(.failure(SessionError.sessionAlreadyActive))
            return
        }
        
        userProfileService.currentUser
            .first()
            .sink { user in
                guard let user = user else {
                    completion(.failure(SessionError.userNotAuthenticated))
                    return
                }
                
                // If duration is nil, use user's default session duration
                let sessionDuration = duration ?? user.settings?.defaultSessionDuration ?? 1500
                
                // If taskID is provided, fetch the task
                var task: Task?
                if let taskID = taskID {
                    let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
                    
                    do {
                        let results = try self.coreDataManager.viewContext.fetch(fetchRequest)
                        task = results.first
                    } catch {
                        print("Error fetching task: \(error)")
                    }
                }
                
                // Create the session
                let session = self.coreDataManager.createFocusSession(
                    user: user,
                    task: task,
                    title: title ?? task?.title,
                    targetDuration: sessionDuration
                )
                
                // Start tracking the session
                self.startSessionTracking(session)
                
                // Notify observers
                self.currentSessionSubject.send(session)
                self.sessionStateSubject.send(.running)
                self.remainingTimeSubject.send(Int(sessionDuration))
                
                // Trigger sync
                self.syncService.syncSessions()
                
                completion(.success(session))
            }
            .store(in: &cancellables)
    }
    
    /// Pauses the current session
    /// - Parameter completion: Callback with success result
    public func pauseSession(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let session = currentSessionSubject.value else {
            completion(.failure(SessionError.noActiveSession))
            return
        }
        
        guard session.isActive && !session.isPaused else {
            completion(.failure(SessionError.invalidStateTransition))
            return
        }
        
        // Stop the timer
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        // Update session state
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id! as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let sessionInContext = results.first {
                    self.coreDataManager.updateSession(
                        session: sessionInContext,
                        isPaused: true,
                        timeRemaining: Int32(self.remainingTimeSubject.value),
                        in: context
                    )
                    
                    // Update statistics
                    if let statistics = sessionInContext.statistics {
                        statistics.pauseCount += 1
                    }
                    
                    self.coreDataManager.saveContext(context)
                    
                    // Refresh current session
                    self.refreshCurrentSession()
                    
                    // Update session state
                    self.sessionStateSubject.send(.paused)
                    
                    // Trigger sync
                    self.syncService.syncSessions()
                    
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(SessionError.sessionNotFound))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Resumes the current session
    /// - Parameter completion: Callback with success result
    public func resumeSession(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let session = currentSessionSubject.value else {
            completion(.failure(SessionError.noActiveSession))
            return
        }
        
        guard session.isActive && session.isPaused else {
            completion(.failure(SessionError.invalidStateTransition))
            return
        }
        
        // Update session state
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id! as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let sessionInContext = results.first {
                    self.coreDataManager.updateSession(
                        session: sessionInContext,
                        isPaused: false,
                        in: context
                    )
                    
                    self.coreDataManager.saveContext(context)
                    
                    // Refresh current session
                    self.refreshCurrentSession()
                    
                    // Restart the timer
                    self.startSessionTracking(session)
                    
                    // Update session state
                    self.sessionStateSubject.send(.running)
                    
                    // Trigger sync
                    self.syncService.syncSessions()
                    
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(SessionError.sessionNotFound))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Completes the current session
    /// - Parameter completion: Callback with success result
    public func completeSession(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let session = currentSessionSubject.value else {
            completion(.failure(SessionError.noActiveSession))
            return
        }
        
        guard session.isActive else {
            completion(.failure(SessionError.invalidStateTransition))
            return
        }
        
        // Stop the timer
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        // Update session state
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id! as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let sessionInContext = results.first {
                    self.coreDataManager.updateSession(
                        session: sessionInContext,
                        isActive: false,
                        isPaused: false,
                        isCompleted: true,
                        timeRemaining: 0,
                        in: context
                    )
                    
                    // Update statistics
                    if let statistics = sessionInContext.statistics {
                        statistics.totalFocusTime = sessionInContext.targetDuration
                        statistics.completionRate = 1.0
                    }
                    
                    self.coreDataManager.saveContext(context)
                    
                    // Clear current session
                    self.currentSessionSubject.send(nil)
                    
                    // Update session state
                    self.sessionStateSubject.send(.completed)
                    self.remainingTimeSubject.send(0)
                    
                    // Trigger sync
                    self.syncService.syncSessions()
                    
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(SessionError.sessionNotFound))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Cancels the current session
    /// - Parameter completion: Callback with success result
    public func cancelSession(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let session = currentSessionSubject.value else {
            completion(.failure(SessionError.noActiveSession))
            return
        }
        
        guard session.isActive else {
            completion(.failure(SessionError.invalidStateTransition))
            return
        }
        
        // Stop the timer
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        // Update session state
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", session.id! as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let sessionInContext = results.first {
                    self.coreDataManager.updateSession(
                        session: sessionInContext,
                        isActive: false,
                        isPaused: false,
                        isCompleted: false,
                        in: context
                    )
                    
                    // Update statistics
                    if let statistics = sessionInContext.statistics, let timeRemaining = sessionInContext.timeRemaining {
                        statistics.totalFocusTime = sessionInContext.targetDuration - timeRemaining
                        statistics.completionRate = 0.0
                    }
                    
                    self.coreDataManager.saveContext(context)
                    
                    // Clear current session
                    self.currentSessionSubject.send(nil)
                    
                    // Update session state
                    self.sessionStateSubject.send(.canceled)
                    self.remainingTimeSubject.send(0)
                    
                    // Trigger sync
                    self.syncService.syncSessions()
                    
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(SessionError.sessionNotFound))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Creates a friction event for the current session
    /// - Parameters:
    ///   - frictionLevel: The friction level (1-4)
    ///   - taskType: The type of friction task
    ///   - completion: Callback with the created event or error
    public func createFrictionEvent(
        frictionLevel: Int16,
        taskType: String,
        completion: @escaping (Result<FrictionEvent, Error>) -> Void
    ) {
        guard let session = currentSessionSubject.value else {
            completion(.failure(SessionError.noActiveSession))
            return
        }
        
        // Create the friction event
        let event = coreDataManager.createFrictionEvent(
            session: session,
            frictionLevel: frictionLevel,
            taskType: taskType
        )
        
        // Trigger sync
        syncService.syncSessions()
        
        completion(.success(event))
    }
    
    /// Completes a friction event
    /// - Parameters:
    ///   - eventID: The ID of the event to complete
    ///   - userResponse: The user's response
    ///   - responseTime: The time it took to respond
    ///   - completion: Callback with success result
    public func completeFrictionEvent(
        eventID: UUID,
        userResponse: String?,
        responseTime: Double,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<FrictionEvent> = FrictionEvent.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let event = results.first {
                    self.coreDataManager.completeFrictionEvent(
                        frictionEvent: event,
                        userResponse: userResponse,
                        responseTime: responseTime,
                        in: context
                    )
                    
                    // Trigger sync
                    self.syncService.syncSessions()
                    
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(SessionError.frictionEventNotFound))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Refreshes the current session
    public func refreshCurrentSession() {
        userProfileService.currentUser
            .first()
            .sink { user in
                guard let user = user else {
                    self.currentSessionSubject.send(nil)
                    self.sessionStateSubject.send(.idle)
                    self.remainingTimeSubject.send(0)
                    return
                }
                
                // Look for active session
                if let session = self.coreDataManager.fetchActiveSession(for: user) {
                    self.currentSessionSubject.send(session)
                    
                    if session.isPaused {
                        self.sessionStateSubject.send(.paused)
                    } else {
                        self.sessionStateSubject.send(.running)
                        
                        // Start or resume tracking
                        self.startSessionTracking(session)
                    }
                    
                    // Update remaining time
                    if let timeRemaining = session.timeRemaining {
                        self.remainingTimeSubject.send(Int(timeRemaining))
                    }
                } else {
                    self.currentSessionSubject.send(nil)
                    self.sessionStateSubject.send(.idle)
                    self.remainingTimeSubject.send(0)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Listen for user changes
        userProfileService.currentUser
            .sink { [weak self] _ in
                self?.refreshCurrentSession()
            }
            .store(in: &cancellables)
    }
    
    private func startSessionTracking(_ session: FocusSession) {
        // Stop any existing timer
        sessionTimer?.invalidate()
        
        // Set initial time
        if let timeRemaining = session.timeRemaining {
            remainingTimeSubject.send(Int(timeRemaining))
        } else {
            remainingTimeSubject.send(Int(session.targetDuration))
        }
        
        // Start a new timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Decrement time
            let currentTime = self.remainingTimeSubject.value
            let newTime = max(0, currentTime - 1)
            self.remainingTimeSubject.send(newTime)
            
            // Check if session is complete
            if newTime == 0 {
                self.sessionTimer?.invalidate()
                self.sessionTimer = nil
                
                // Complete the session
                self.completeSession { _ in }
            } else {
                // Periodically update the session in the database
                if newTime % 15 == 0 { // Update every 15 seconds
                    let context = self.coreDataManager.createBackgroundContext()
                    
                    context.perform {
                        let fetchRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", session.id! as CVarArg)
                        
                        do {
                            let results = try context.fetch(fetchRequest)
                            if let sessionInContext = results.first {
                                self.coreDataManager.updateSession(
                                    session: sessionInContext,
                                    timeRemaining: Int32(newTime),
                                    in: context
                                )
                            }
                        } catch {
                            print("Error updating session time: \(error)")
                        }
                    }
                }
            }
        }
        
        // Make sure the timer runs even when scrolling
        RunLoop.current.add(sessionTimer!, forMode: .common)
    }
}

// MARK: - Supporting Types

/// Session state
public enum SessionState {
    case idle
    case running
    case paused
    case completed
    case canceled
}

/// Session-related errors
public enum SessionError: LocalizedError {
    case userNotAuthenticated
    case noActiveSession
    case sessionNotFound
    case sessionAlreadyActive
    case invalidStateTransition
    case frictionEventNotFound
    
    public var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .noActiveSession:
            return "No active session found"
        case .sessionNotFound:
            return "Session not found"
        case .sessionAlreadyActive:
            return "A session is already active"
        case .invalidStateTransition:
            return "Invalid session state transition"
        case .frictionEventNotFound:
            return "Friction event not found"
        }
    }
} 