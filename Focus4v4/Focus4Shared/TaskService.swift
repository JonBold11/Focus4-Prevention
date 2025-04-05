import Foundation
import CoreData
import Combine

/// A service for managing task operations
public class TaskService {
    // MARK: - Properties
    
    /// The shared singleton instance
    public static let shared = TaskService()
    
    /// The Core Data manager
    private let coreDataManager = CoreDataManager.shared
    
    /// The user profile service
    private let userProfileService = UserProfileService.shared
    
    /// The data synchronization service
    private let syncService = DataSynchronizationService.shared
    
    /// Tasks publisher
    private let tasksSubject = CurrentValueSubject<[Task], Never>([])
    public var tasks: AnyPublisher<[Task], Never> {
        return tasksSubject.eraseToAnyPublisher()
    }
    
    /// Cancellables bag
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new task
    /// - Parameters:
    ///   - title: The task title
    ///   - details: Optional task details
    ///   - category: Optional task category
    ///   - dueDate: Optional due date
    ///   - priority: Optional task priority (0-3)
    ///   - isImportant: Whether the task is marked as important
    ///   - estimatedDuration: Estimated duration in seconds, defaults to 25 minutes
    ///   - completion: Callback with the created task or error
    public func createTask(
        title: String,
        details: String? = nil,
        category: String? = nil,
        dueDate: Date? = nil,
        priority: Int16 = 0,
        isImportant: Bool = false,
        estimatedDuration: Int32 = 1500,
        completion: @escaping (Result<Task, Error>) -> Void
    ) {
        userProfileService.currentUser
            .first()
            .sink { user in
                guard let user = user else {
                    completion(.failure(TaskError.userNotAuthenticated))
                    return
                }
                
                let task = self.coreDataManager.createTask(
                    title: title,
                    details: details,
                    user: user,
                    category: category,
                    dueDate: dueDate,
                    priority: priority,
                    isImportant: isImportant,
                    estimatedDuration: estimatedDuration
                )
                
                // Trigger sync
                self.syncService.syncTasks()
                
                // Refresh tasks
                self.refreshTasks()
                
                completion(.success(task))
            }
            .store(in: &cancellables)
    }
    
    /// Updates an existing task
    /// - Parameters:
    ///   - taskID: The ID of the task to update
    ///   - title: New title
    ///   - details: New details
    ///   - category: New category
    ///   - dueDate: New due date
    ///   - priority: New priority
    ///   - isImportant: New importance flag
    ///   - estimatedDuration: New estimated duration
    ///   - completion: Callback with success result
    public func updateTask(
        taskID: UUID,
        title: String? = nil,
        details: String? = nil,
        category: String? = nil,
        dueDate: Date? = nil,
        priority: Int16? = nil,
        isImportant: Bool? = nil,
        estimatedDuration: Int32? = nil,
        completion: @escaping (Result<Task, Error>) -> Void
    ) {
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                guard let task = results.first else {
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.taskNotFound))
                    }
                    return
                }
                
                if let title = title {
                    task.title = title
                }
                
                if let details = details {
                    task.details = details
                }
                
                if let category = category {
                    task.category = category
                }
                
                if let dueDate = dueDate {
                    task.dueDate = dueDate
                }
                
                if let priority = priority {
                    task.priority = priority
                }
                
                if let isImportant = isImportant {
                    task.isImportant = isImportant
                }
                
                if let estimatedDuration = estimatedDuration {
                    task.estimatedDuration = estimatedDuration
                }
                
                task.updatedAt = Date()
                
                self.coreDataManager.saveContext(context)
                
                // Trigger sync
                self.syncService.syncTasks()
                
                // Refresh tasks
                self.refreshTasks()
                
                DispatchQueue.main.async {
                    // We need to fetch the task in the main context to return it
                    let mainFetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                    mainFetchRequest.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
                    
                    do {
                        let mainResults = try self.coreDataManager.viewContext.fetch(mainFetchRequest)
                        if let mainTask = mainResults.first {
                            completion(.success(mainTask))
                        } else {
                            completion(.failure(TaskError.taskNotFound))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Completes a task
    /// - Parameters:
    ///   - taskID: The ID of the task to complete
    ///   - completion: Callback with success result
    public func completeTask(
        taskID: UUID,
        completion: @escaping (Result<Task, Error>) -> Void
    ) {
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                guard let task = results.first else {
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.taskNotFound))
                    }
                    return
                }
                
                self.coreDataManager.completeTask(task: task, in: context)
                
                // Trigger sync
                self.syncService.syncTasks()
                
                // Refresh tasks
                self.refreshTasks()
                
                DispatchQueue.main.async {
                    // We need to fetch the task in the main context to return it
                    let mainFetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
                    mainFetchRequest.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
                    
                    do {
                        let mainResults = try self.coreDataManager.viewContext.fetch(mainFetchRequest)
                        if let mainTask = mainResults.first {
                            completion(.success(mainTask))
                        } else {
                            completion(.failure(TaskError.taskNotFound))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Deletes a task
    /// - Parameters:
    ///   - taskID: The ID of the task to delete
    ///   - completion: Callback with success result
    public func deleteTask(
        taskID: UUID,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let context = coreDataManager.createBackgroundContext()
        
        context.perform {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                guard let task = results.first else {
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.taskNotFound))
                    }
                    return
                }
                
                context.delete(task)
                self.coreDataManager.saveContext(context)
                
                // Trigger sync
                self.syncService.syncTasks()
                
                // Refresh tasks
                self.refreshTasks()
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Refreshes the task list
    public func refreshTasks() {
        userProfileService.currentUser
            .first()
            .sink { user in
                guard let user = user else {
                    self.tasksSubject.send([])
                    return
                }
                
                // Check if we should include completed tasks
                let includeCompleted = user.settings?.showCompletedTasks ?? false
                
                // Fetch tasks
                let tasks = self.coreDataManager.fetchTasks(for: user, includeCompleted: includeCompleted)
                self.tasksSubject.send(tasks)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Listen for user changes
        userProfileService.currentUser
            .sink { [weak self] _ in
                self?.refreshTasks()
            }
            .store(in: &cancellables)
        
        // Listen for settings changes
        NotificationCenter.default.publisher(for: NSManagedObjectContext.didSaveObjectsNotification)
            .filter { notification in
                // Check if any UserSettings objects were updated
                guard let userInfo = notification.userInfo,
                      let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> else {
                    return false
                }
                
                return updatedObjects.contains { $0 is UserSettings }
            }
            .sink { [weak self] _ in
                self?.refreshTasks()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

/// Task-related errors
public enum TaskError: LocalizedError {
    case userNotAuthenticated
    case taskNotFound
    
    public var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .taskNotFound:
            return "Task not found"
        }
    }
} 