import Foundation
import ArgumentParser

struct SearchResult {
    let filePath: String
    let lineNumber: Int
    let lineContent: String
    let searchString: String
}

struct PrivacyManifestScanner {
    let excludeDirs: [String]
    let rootDirectory: URL
    let privacyAPIs: [String] = [
        ".creationDate",
        ".creationDateKey",
        ".modificationDate",
        ".fileModificationDate",
        ".contentModificationDateKey", 
        ".creationDateKey",
        "getattrlist(", 
        "getattrlistbulk(", 
        "fgetattrlist(", 
        "stat.st_", 
        "fstat(",
        "fstatat(",
        "lstat(",
        "getattrlistat(",
        "systemUptime",
        "mach_absolute_time()",
        "volumeAvailableCapacityKey",
        "volumeAvailableCapacityForImportantUsageKey",
        "volumeAvailableCapacityForOpportunisticUsageKey",
        "volumeTotalCapacityKey",
        "systemFreeSize",
        "systemSize",
        "statfs(",
        "statvfs(",
        "fstatfs(",
        "fstatvfs(",
        "getattrlist(",
        "fgetattrlist(",
        "getattrlistat(",
        "activeInputModes",
        "UserDefaults",
        "NSUserDefaults",
        "NSFileCreationDate",
        "NSFileModificationDate",
        "NSFileSystemFreeSize",
        "NSFileSystemSize",
        "NSURLContentModificationDateKey",
        "NSURLCreationDateKey",
        "NSURLVolumeAvailableCapacityForImportantUsageKey",
        "NSURLVolumeAvailableCapacityForOpportunisticUsageKey",
        "NSURLVolumeAvailableCapacityKey",
        "NSURLVolumeTotalCapacityKey",
        "AppStorage"
    ]

    var results: [SearchResult] = []

    init(excludeDirs: [String], rootDirectory: URL) {
        self.excludeDirs = excludeDirs
        self.rootDirectory = rootDirectory
    }

    mutating func startScan() {
        let totalFiles = calculateTotalFiles(in: rootDirectory)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        if let formattedNumber = formatter.string(from: NSNumber(value: totalFiles)) {
            print("📁 Total files to process: \(formattedNumber)") // 📁 Total files to process: 1,234,567
        } else {
            print("📁 Total files to process: \(totalFiles)") // 포맷 실패 시 fallback
        }

        print("🚀 Starting scan please wait...")
        
        let scanStartTime = Date()
        traverse(directory: rootDirectory, excludeDirs: excludeDirs)
        if results.isEmpty {
            print("🤷 No results found.")
            return
        }
        
        generateHTMLReport(scanStartTime: scanStartTime, rootDirectoryPath: rootDirectory.path)
    }

    mutating private func calculateTotalFiles(in directory: URL) -> Int {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil) else { return 0 }
        
        var count = 0
        for case let fileURL as URL in enumerator {
            let dirName = fileURL.deletingLastPathComponent().lastPathComponent
            if !excludeDirs.contains(dirName) {
                count += 1
            }
        }
        return count
    }


    mutating private func traverse(directory: URL, excludeDirs: [String]) {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else { return }
        
        for case let fileURL as URL in enumerator {
            let dirName = fileURL.deletingLastPathComponent().lastPathComponent
            if excludeDirs.contains(dirName) {
                enumerator.skipDescendants()
                continue
            }
            
            if fileURL.pathExtension == "swift" || fileURL.pathExtension == "m" || fileURL.pathExtension == "h" {
                searchInFile(fileURL)
            }
        }
    }

    mutating private func searchInFile(_ fileURL: URL) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        let lines = content.split(separator: "\n")

        for (index, line) in lines.enumerated() {
            for searchString in privacyAPIs {
                if line.contains(searchString) {
                    let result = SearchResult(filePath: fileURL.path, lineNumber: index + 1, lineContent: String(line), searchString: String(searchString))
                    self.results.append(result)
                }
            }
        }
    }

    private func generateHTMLReport(scanStartTime: Date, rootDirectoryPath: String) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let fileDateFormatter = DateFormatter()
        fileDateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let currentDate = dateFormatter.string(from: Date())
        let currentDateForFile = fileDateFormatter.string(from: Date())
        let scanDuration = Date().timeIntervalSince(scanStartTime)
        let fileName = "\(Config.appName)_\(rootDirectory.lastPathComponent)_\(currentDateForFile).html"
        let filePath = rootDirectory.appendingPathComponent(fileName)
        
        let htmlContent = HTMLTemplate.generateHTML(currentDate: currentDate,
                                                    rootDirectoryPath: rootDirectoryPath,
                                                    scanDuration: String(format: "%.2f", scanDuration),
                                                    with: results)
        
        do {
            try htmlContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("📄 Report generated at: \(filePath)")
        } catch {
            print("😭 Failed to save results: \(error)")
        }
    }
}

struct SearchTool: ParsableCommand {
     @Option(name: .customLong("exclude_dir"), help: "Directories to exclude from the search.")
    var excludeDir: [String] = []

    @Option(name: .customLong("path"), 
            help: "The root directory to start searching from. Defaults to the current directory.")
    var path: String?

    func run() throws {
        let rootDirectoryPath = path ?? FileManager.default.currentDirectoryPath
        let rootDirectory = URL(fileURLWithPath: rootDirectoryPath)
        var scanner = PrivacyManifestScanner(excludeDirs: excludeDir, rootDirectory: rootDirectory)
        
        print("🚫 Excluded Directories: \(excludeDir)")
        print("🔍 Searching in: \(rootDirectoryPath)")

        scanner.startScan()        
    }
}

SearchTool.main()
