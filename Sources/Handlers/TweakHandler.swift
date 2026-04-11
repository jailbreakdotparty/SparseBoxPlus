//
//  TweakHandler.swift
//  SparseBoxPlus
//
//  Created by Main on 1/8/26.
//

import SwiftUI
import PartyUI

@MainActor
final class AppData: ObservableObject {
    static let shared = AppData()
    
    @Published var mobileGestalt: NSMutableDictionary
    @Published var originalMobileGestalt: NSMutableDictionary
    @Published var featureFlagsData = Data()
    @Published var eligibilityData = Data()
    @Published var productType = machineName()
    @Published var deviceSubtype: Int = 2436
    @Published var deviceModelName: String = "iPhone xx"
    
    @Published var taskRunning = false
    @Published var initError: String?
    @Published var isSparseBoxReady = false
    
    @Published var applicationIcon: String = "showMeProgressPlease"
    @Published var applicationIconColor: Color = .primary
    @Published var applicationStatus: String = "Waiting for heartbeat..."
    
    @Published var ddiMounted: Bool = false
    @Published var heartbeatReady: Bool = false
    @Published var isAppReady: Bool = false
    
    let origMGURL, modMGURL, featFlagsURL: URL
    
    init() {
        let documentsDirectory = URL.documentsDirectory
        featFlagsURL = documentsDirectory.appendingPathComponent("FeatureFlags.plist", conformingTo: .data)
        origMGURL = documentsDirectory.appendingPathComponent("OriginalMobileGestalt.plist", conformingTo: .data)
        modMGURL = documentsDirectory.appendingPathComponent("ModifiedMobileGestalt.plist", conformingTo: .data)
        
        do {
            if !FileManager.default.fileExists(atPath: origMGURL.path) {
                let url = URL(filePath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")
                try FileManager.default.copyItem(at: url, to: origMGURL)
            }
            chmod(origMGURL.path, 0o644)
            
            if !FileManager.default.fileExists(atPath: modMGURL.path) {
                try FileManager.default.copyItem(at: origMGURL, to: modMGURL)
            }
            chmod(modMGURL.path, 0o644)
            
            self.mobileGestalt = try NSMutableDictionary(contentsOf: modMGURL, error: ())
            self.originalMobileGestalt = try NSMutableDictionary(contentsOf: origMGURL, error: ())
        } catch {
            self.mobileGestalt = [:]
            self.originalMobileGestalt = [:]
            self.initError = "Failed to copy MobileGestalt: \(error)"
            taskRunning = true
        }
    }
}

@MainActor
func performApplyMobileGestalt(appData: AppData) async throws {
    @AppStorage("BookassetdContainerUUID") var bookassetdUUID: String?
    @AppStorage("shouldRespring") var shouldRespring: Bool = true
    
    appData.applicationIcon = "showMeProgressPlease"
    appData.applicationStatus = "Applying Tweaks..."
    
    let context = JITEnableContext.shared
    var line: String
    
    // get bookassetd container uuid
    if bookassetdUUID == nil {
        appData.applicationStatus = "Getting bookassestd UUID..."
        Alertinator.shared.alert(title: "Books UUID Required", body: "SparseBox+ needs to get the UUID of bookassestd. Click \"Continue\" and download a book.", showCancel: false, actionLabel: "Continue", action: {
            LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
        })
        
        print("Finding bookassetd container UUID...")
        print("Please open the Books app and download a book to continue.")
        line = try await waitForSyslogLine(matches: { $0.contains("bookassetd") && $0.contains("/Documents/BLDownloads/") })
        
        // Return to SparseBox
        LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: Bundle.main.bundleIdentifier!)
        
        bookassetdUUID = line.components(separatedBy: "/var/containers/Shared/SystemGroup/")[1]
            .components(separatedBy: "/Documents/BLDownloads")[0]
        if bookassetdUUID == nil {
            appData.applicationIcon = "xmark.circle"
            appData.applicationStatus = "Failed to get bookassetd UUID!"
            appData.applicationIconColor = .red
            
            Alertinator.shared.alert(title: "Error!", body: "Failed to get bookassetd container UUID from syslog.")
            return
        }
    }
    
    print("bookassetd container UUID: \(bookassetdUUID!)")
    
    // copy files from bundle to Documents folder
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let d28LocalPath = documentsDirectory.appendingPathComponent("downloads.28.sqlitedb").path
    let bldLocalPath = documentsDirectory.appendingPathComponent("BLDatabaseManager.sqlite").path
    let bundle = Bundle.main
    if !FileManager.default.fileExists(atPath: d28LocalPath),
       let resourcePath = bundle.path(forResource: "downloads.28", ofType: "sqlitedb") {
        try? FileManager.default.copyItem(atPath: resourcePath, toPath: d28LocalPath)
    }
    if !FileManager.default.fileExists(atPath: bldLocalPath),
       let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite") {
        try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath)
    }
    if !FileManager.default.fileExists(atPath: bldLocalPath + "-shm"),
        let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-shm") {
        try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath + "-shm")
    }
    if !FileManager.default.fileExists(atPath: bldLocalPath + "-wal"),
        let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-wal") {
        try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath + "-wal")
    }
    
    appData.applicationStatus = "Patching BLDatabaseManager.sqlite..."
    print("Patching BLDatabaseManager.sqlite...")
    try Databases.patchDatabase(dbPath: d28LocalPath, uuid: bookassetdUUID!, ip: "localhost", port: Utils.port)
    
    // Kill bookassetd and Books processes to stop them from updating BLDatabaseManager.sqlite
    var processes: [Int32 : String?] = try getRunningProcesses()
    var pid_bookassetd = processes.first { $0.value?.hasSuffix("/bookassetd") == true }?.key
    var pid_Books = processes.first { $0.value?.hasSuffix("/Books") == true }?.key
    if let pid_bookassetd {
        appData.applicationStatus = "topping bookassetd (pid \(pid_bookassetd))..."
        print("Stopping bookassetd (pid \(pid_bookassetd))...")
        try context?.killProcess(withPID: pid_bookassetd, signal: SIGSTOP)
    }
    if let pid_Books {
        appData.applicationStatus = "Killing Books (pid \(pid_Books))..."
        print("Killing Books (pid \(pid_Books))...")
        try context?.killProcess(withPID: pid_Books, signal: SIGKILL)
    }
    
    // Upload com.apple.MobileGestalt.plist
    appData.applicationStatus = "Uploading MobileGestalt..."
    print("Uploading com.apple.MobileGestalt.plist")
    try context?.afcPushFile(appData.modMGURL.path(), toPath: "com.apple.MobileGestalt.plist")
    
    // Upload downloads.28.sqlitedb
    appData.applicationStatus = "Uploading Database..."
    print("Uploading downloads.28.sqlitedb")
    try context?.afcPushFile(d28LocalPath, toPath: "Downloads/downloads.28.sqlitedb")
    try context?.afcPushFile(d28LocalPath + "-shm", toPath: "Downloads/downloads.28.sqlitedb-shm")
    try context?.afcPushFile(d28LocalPath + "-wal", toPath: "Downloads/downloads.28.sqlitedb-wal")
    // conn.close()
    
    // Kill itunesstored to trigger BLDataBaseManager.sqlite overwrite
    processes = try getRunningProcesses()
    let pid_itunesstored = processes.first { $0.value?.hasSuffix("/itunesstored") == true }?.key
    if let pid_itunesstored {
        appData.applicationStatus = "Killing itunesstored (pid \(pid_itunesstored))..."
        print("Killing itunesstored (pid \(pid_itunesstored))...")
        try context?.killProcess(withPID: pid_itunesstored, signal: SIGKILL)
    }
    
    // Wait for itunesstored to finish download and raise an error
    appData.applicationStatus = "Waiting for itunesstored to finish download..."
    print("Waiting for itunesstored to finish download...")
    // FIXME: syslog not working
    _ = try await waitForSyslogLine(matches: { $0.contains("Install complete for download: 6936249076851270152 result: Failed") }, timeout: 2)
    
    // Kill bookassetd and Books processes to trigger MobileGestalt overwrite
    pid_bookassetd = processes.first { $0.value?.hasSuffix("/bookassetd") == true }?.key
    pid_Books = processes.first { $0.value?.hasSuffix("/Books") == true }?.key
    if let pid_bookassetd {
        appData.applicationStatus = "Killing bookassetd (pid \(pid_bookassetd))..."
        print("Killing bookassetd (pid \(pid_bookassetd))...")
        try context?.killProcess(withPID: pid_bookassetd, signal: SIGKILL)
    }
    if let pid_Books {
        appData.applicationStatus = "Killing Books (pid \(pid_Books))..."
        print("Killing Books (pid \(pid_Books))...")
        try context?.killProcess(withPID: pid_Books, signal: SIGKILL)
    }
    
    // Re-open Books app
    LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
    LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: Bundle.main.bundleIdentifier!)
    
    appData.applicationStatus = "Waiting for overwrite to complete..."
    print("Waiting for MobileGestalt overwrite to complete...")
    appData.applicationStatus = "Tweaks Applied Successfully!"
    appData.applicationIcon = "checkmark.circle.fill"
    appData.applicationIconColor = .green
    let success_message = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist) [Install-Mgr]: Marking download as [finished]"
    // FIXME: syslog not working
    _ = try await waitForSyslogLine(matches: { $0.contains(success_message) }, timeout: 3)
    
    if shouldRespring {
        print("Respringing...")
        let pid_backboardd = processes.first { $0.value?.hasSuffix("/backboardd") == true }?.key
        if let pid_backboardd {
            try context?.killProcess(withPID: pid_backboardd, signal: SIGKILL)
        }
    }
}

func getRunningProcesses() throws -> [Int32 : String?] {
    Dictionary(
        uniqueKeysWithValues: (try JITEnableContext.shared?.fetchProcessList() as! [[String: Any]])
            .compactMap { item in
                guard let pid = item["pid"] as? Int32 else { return nil }
                let path = item["path"] as? String
                return (pid, path)
            }
    )
}

func waitForSyslogLine(matches predicate: @escaping (String) -> Bool, timeout: TimeInterval? = nil) async throws -> String {
    let result = try await withCheckedThrowingContinuation { continuation in
        var resumed = false
        JITEnableContext.shared.startSyslogRelay { line in
            if predicate(line!) {
                resumed = true
                continuation.resume(returning: line!)
            }
        } onError: { error in
            resumed = true
            continuation.resume(throwing: error!)
        }
        
        if let timeout {
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if resumed { return }
                continuation.resume(returning: "Timed out waiting for syslog line.")
            }
        }
    }
    JITEnableContext.shared.stopSyslogRelay()
    return result
}

func respringDevice() {
    let context = JITEnableContext.shared
    var processes: [Int32 : String?] = try! getRunningProcesses()
    
    print("Respringing...")
    let pid_backboardd = processes.first { $0.value?.hasSuffix("/backboardd") == true }?.key
    if let pid_backboardd {
        try! context?.killProcess(withPID: pid_backboardd, signal: SIGKILL)
    }
}

// https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
// read device model from kernel
func machineName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    return machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
}

@MainActor
func saveProductType(appData: AppData) {
    let cacheExtra = appData.mobileGestalt["CacheExtra"] as! NSMutableDictionary
    cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] = appData.productType
    
    if let artworkDetails = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary {
        artworkDetails["ArtworkDeviceSubType"] = appData.deviceSubtype
    }
}
