import Foundation
import Sentry
import CocoaLumberjack

/// A class that provides support for logging crashes. Not compatible with Objective-C.
public class CrashLogging {

    /// A singleton is maintained, but the host application needn't be aware of its existence.
    internal static let sharedInstance = CrashLogging()

    private var dataProvider: CrashLoggingDataProvider?
    private var eventLogging: EventLogging?

    /// Thread-safe single initialization
    fileprivate static let threadSafeDispatchQueue = DispatchQueue(label: Bundle.main.bundleIdentifier ?? "tracks" + "-crash-logging-queue")
    fileprivate static var _isStarted = false
    internal static var isStarted: Bool {
        get {
            return threadSafeDispatchQueue.sync { _isStarted }
        }
        set {
            threadSafeDispatchQueue.sync { _isStarted = newValue }
        }
    }

    /**
     Initializes the crash logging system.

     - Parameters:
     - dataProvider: An object that will provide any required data to the crash logging system.

     - SeeAlso: CrashLoggingDataProvider
     */
    public static func start(withDataProvider dataProvider: CrashLoggingDataProvider, eventLogging: EventLogging? = nil) {

        // Only allow initializing this system once
        guard !isStarted else { return }
        isStarted = true

        // Store the data provider and event logging subsystem for future use
        sharedInstance.dataProvider = dataProvider
        sharedInstance.eventLogging = eventLogging

        // Create a Sentry client and start crash handler
        do {
            Client.shared = try Client(dsn: dataProvider.sentryDSN)
            try Client.shared?.startCrashHandler()

            // Store lots of breadcrumbs to trace errors
            Client.shared?.breadcrumbs.maxBreadcrumbs = 500

            // Automatically track screen transitions
            Client.shared?.enableAutomaticBreadcrumbTracking()

            // Override event serialization to append the logs, if needed
            Client.shared?.beforeSerializeEvent = sharedInstance.beforeSerializeEvent
            Client.shared?.shouldSendEvent = sharedInstance.shouldSendEvent

            // Add additional data
            Client.shared?.releaseName = dataProvider.releaseName
            Client.shared?.environment = dataProvider.buildType

            // Refresh data from the data provider
            setNeedsDataRefresh()

        } catch let error {
            logError(error)
        }
    }

    /// A Sentry hook used to attach any additional data to the event.
    private func beforeSerializeEvent(_ event: Event) {
        // event.tags is always not null so we don't care that much about it here.
        event.tags?["locale"] = NSLocale.current.languageCode

        if let appState = ApplicationFacade().applicationState {
            event.tags?["app.state"] = appState
        }
    }

    /// A Sentry hook that controls whether or not the event should be sent.
    private func shouldSendEvent(_ event: Event?) -> Bool {

        DDLogDebug("📜 Firing `shouldSendEvent`")

        #if DEBUG
        DDLogDebug("📜 This is a debug build")
        let shouldSendEvent = UserDefaults.standard.bool(forKey: "force-crash-logging") ?? false
        #else
        let shouldSendEvent = !CrashLogging.userHasOptedOut
        #endif

        shouldSendEventCallback?(event, shouldSendEvent)

        guard let eventLogging = self.eventLogging else {
            DDLogDebug("📜 Cancelling log file attachment – Event Logging is not initialized")
            return shouldSendEvent
        }

        guard let event = event else {
            DDLogDebug("📜 Cancelling log file attachment – event is nil")
            return shouldSendEvent
        }

        guard shouldSendEvent else {
            DDLogDebug("📜 Cancelling log file attachment – should not send event")
            return shouldSendEvent
        }

        eventLogging.attachLogToEventIfNeeded(event: event)

        return shouldSendEvent
    }

    /// The current state of the user's choice to opt out of data collection. Provided by the data source.
    private static var userHasOptedOut: Bool {
        /// If we can't say for sure, assume the user has opted out
        guard let dataProvider = sharedInstance.dataProvider else { return true }
        return dataProvider.userHasOptedOut
    }

    /// Immediately crashes the application and generates a crash report.
    public static func crash() {
        Client.shared?.crash()
    }

    public static var eventLogging: EventLogging? {
        return sharedInstance.eventLogging
    }
}

// Manual Error Logging
public extension CrashLogging {

    /**
     Writes the error to the Crash Logging system, and includes a stack trace.

     - Parameters:
     - error: The error object
     - userInfo: A dictionary containing additional data about this error.
     - level: The level of severity to report in Sentry (`.error` by default)
    */
    static func logError(_ error: Error, userInfo: [String: Any]? = nil, level: SentrySeverity = .error) {
        let event = Event(level: .error)
        event.message = error.localizedDescription
        event.extra = userInfo ?? (error as NSError).userInfo

        Client.shared?.snapshotStacktrace {
            Client.shared?.appendStacktrace(to: event)
        }

        Client.shared?.send(event: event)
        sharedInstance.dataProvider?.didLogErrorCallback?(event)
    }

    /**
     Writes a message to the Crash Logging system, and includes a stack trace.
     - Parameters:
     - message: The message
     - properties: A dictionary containing additional information about this error
     - level: The level of severity to report in Sentry (`.error` by default)
    */
    static func logMessage(_ message: String, properties: [String: Any]? = nil, level: SentrySeverity = .info) {

        let event = Event(level: level)
        event.message = message
        event.extra = properties

        Client.shared?.snapshotStacktrace {
            Client.shared?.appendStacktrace(to: event)
        }

        Client.shared?.send(event: event)
        sharedInstance.dataProvider?.didLogMessageCallback?(event)
    }
}

// User Tracking
extension CrashLogging {

    internal var currentUser: Sentry.User {

        let anonymousUser = TracksUser(userID: nil, email: nil, username: nil).sentryUser

        /// Don't continue unless `start` has been called on the crash logger
        guard let dataProvider = self.dataProvider else { return anonymousUser }

        /// Don't continue if the data source doesn't yet have a user
        guard let user = dataProvider.currentUser else { return anonymousUser }
        let data = dataProvider.additionalUserData

        return user.sentryUser(withData: data)
    }

    /// Causes the Crash Logging System to refresh its knowledge about the current state of the system.
    ///
    /// This is required in situations like login / logout, when the system otherwise might not
    /// know a change has occured.
    ///
    /// Calling this method in these situations prevents
    public static func setNeedsDataRefresh() {
        Client.shared?.user = sharedInstance.currentUser
    }
}

// Event Logging
extension Event {

    private static let logIDKey = "logID"

    var logID: String? {
        get {
            return self.extra?[Event.logIDKey] as? String
        }
        set {
            self.extra?[Event.logIDKey] = newValue
        }
    }
}
