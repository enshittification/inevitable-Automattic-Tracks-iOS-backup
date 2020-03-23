import Foundation

open class EventLoggingUploadQueue {

    private let fileManager = FileManager.default

    /// The log file on top of the queue
    var first: LogFile? {

        guard let url = try? fileManager.contentsOfDirectory(at: storageDirectory).first else {
            return nil
        }

        return LogFile(url: url, uuid: url.lastPathComponent)
    }

    func add(_ log: LogFile) throws {
        try ensureStorageDirectoryExists()
        try fileManager.copyItem(at: log.url, to: storageURL(forLog: log))
    }

    func remove(_ log: LogFile) throws {
        let url = storageURL(forLog: log)
        if fileManager.fileExistsAtURL(url) {
            try fileManager.removeItem(at: storageURL(forLog: log))
        }
    }

    var storageDirectory: URL {
        return fileManager.documentsDirectory.appendingPathComponent("log-upload-queue")
    }

    func storageURL(forLog log: LogFile) -> URL {
        let newURL = storageDirectory.appendingPathComponent(log.uuid)
        return newURL
    }

    func ensureStorageDirectoryExists() throws {
        if !fileManager.directoryExistsAtURL(storageDirectory) {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
}