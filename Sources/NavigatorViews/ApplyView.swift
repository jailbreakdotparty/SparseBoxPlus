import SwiftUI
import UniformTypeIdentifiers
import PartyUI
import DeviceKit

func backgroundCornerRadius() -> CGFloat {
    if #available(iOS 26.0, *) {
        return 26
    } else {
        return 18
    }
}

func smallPlatterCornerRadius() -> CGFloat {
    if #available(iOS 26.0, *) {
        return 16
    } else {
        return 12
    }
}

struct ApplyView: View {
    @Environment(\.scenePhase) var scenePhase
    @State var pairingFile: String?
    @State var mbdb: Backup?
    @State var heartbeatReady = false
    @State var ddiMounted = false
    @State var showPairingFileImporter = false
    @State var taskRunning = false
    @State private var showSettingsView: Bool = false
    @State private var showLogs: Bool = true
    @State private var hasShownWelcome: Bool = false
    
    @EnvironmentObject var appData: AppData
    @AppStorage("shouldRespring") var shouldRespring: Bool = true
    @AppStorage("showCustomKeys") var showCustomKeys: Bool = false
    @AppStorage("BookassetdContainerUUID") var bookassetdUUID: String?
    
    let device = Device.current
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "Version \(UIApplication.appVersion!) (\(weOnADebugBuild ? "Debug" : "Release"))", icon: "info.circle")) {
                    VStack(alignment: .leading) {
                        HStack {
                            if appData.applicationIcon == "showMeProgressPlease" {
                                ProgressView()
                                    .offset(y: 1)
                            } else {
                                Image(systemName: appData.applicationIcon)
                                    .foregroundStyle(appData.applicationIconColor)
                            }
                            Text(appData.applicationStatus)
                                .fontWeight(.semibold)
                        }
                        Text("HTTP Server Port: \(String(Utils.port))")
                        if showLogs {
                            TerminalContainer(content: VStack {
                                LogView()
                            })
                        }
                        HStack {
                            HStack {
                                Image(systemName: heartbeatReady ? "checkmark.circle" : "xmark.circle")
                                Text(heartbeatReady ? "Ready" : "Not Ready")
                            }
                            .foregroundStyle(heartbeatReady ? .green : .red)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .modifier(DynamicGlassEffect(color: secondaryBackgroundColor(), shape: AnyShape(.rect(cornerRadius: smallPlatterCornerRadius()))))
                            
                            HStack {
                                Image(systemName: ddiMounted ? "checkmark.circle" : "xmark.circle")
                                Text(ddiMounted ? "Mounted" : "Not Mounted")
                            }
                            .foregroundStyle(ddiMounted ? .green : .red)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .modifier(DynamicGlassEffect(color: secondaryBackgroundColor(), shape: AnyShape(.rect(cornerRadius: smallPlatterCornerRadius()))))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .modifier(DynamicGlassEffect(shape: AnyShape(.rect(cornerRadius: backgroundCornerRadius())), useBackground: false))
                    .listRowBackground(Color.clear)
                    .listRowInsets(.zeroInsets)
                }
                
                if ddiMounted || weOnADebugBuild {
                    Section(header: HeaderLabel(text: "Actions", icon: "wrench.and.screwdriver")) {
                        VStack {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                saveProductType(appData: AppData.shared)
                                try! appData.mobileGestalt.write(to: appData.modMGURL)
                                DispatchQueue.global(qos: .background).async {
                                    Task {
                                        do {
                                            try await performApplyMobileGestalt(appData: AppData.shared)
                                        } catch {
                                            await MainActor.run {
                                                Alertinator.shared.alert(title: "Failed to Apply!", body: "Error: \(error)")
                                            }
                                        }
                                    }
                                }
                            }) {
                                ButtonLabel(text: "Apply Tweaks", icon: "checkmark")
                            }
                            .buttonStyle(GlassyButtonStyle(color: .green))
                            
                            HStack {
                                Button(action: {
                                    Haptic.shared.play(.soft)
                                    try! FileManager.default.removeItem(at: appData.modMGURL)
                                    try! FileManager.default.copyItem(at: appData.origMGURL, to: appData.modMGURL)
                                    appData.mobileGestalt = try! NSMutableDictionary(contentsOf: appData.modMGURL, error: ())
                                    DispatchQueue.global(qos: .background).async {
                                        Task {
                                            do {
                                                try await performApplyMobileGestalt(appData: AppData.shared)
                                            } catch {
                                                await MainActor.run {
                                                    Alertinator.shared.alert(title: "Failed to Revert!", body: "Error: \(error)")
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    ButtonLabel(text: "Revert", icon: "xmark")
                                }
                                .buttonStyle(GlassyButtonStyle(color: .red))
                                Button(action: {
                                    Haptic.shared.play(.heavy)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        respringDevice()
                                    }
                                }) {
                                    ButtonLabel(text: "Respring", icon: "gobackward")
                                }
                                .buttonStyle(GlassyButtonStyle(color: .orange))
                            }
                        }
                    }
                }
                
                if ddiMounted || weOnADebugBuild {
                    Section(header: HeaderLabel(text: "Application Settings", icon: "gear"), footer: Text("**WARNING:** Enabling the custom gestalt keys feature is super dangerous, and if not used properly, will brick your device! Please do not use this feature unless you know what you are doing.")) {
                        HStack {
                            TextField("bookassetsd UUID", text: Binding(
                                get: { bookassetdUUID ?? "" },
                                set: { bookassetdUUID = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(GlassyTextFieldStyle(isDisabled: bookassetdUUID == nil))
                            Button(action: {
                                bookassetdUUID = nil
                            }) {
                                Image(systemName: "xmark")
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(GlassyButtonStyle(isDisabled: bookassetdUUID == nil, color: .red, useFullWidth: false))
                        }
                        .disabled(bookassetdUUID == nil)
                        Toggle("Respring After Finish Restoring", isOn: $shouldRespring)
                        Toggle("Enable Custom Gestalt Keys", isOn: $showCustomKeys)
                    }
                }
                
                Section(header: HeaderLabel(text: "Device Pairing", icon: "doc"), footer: Text(ddiMounted ? "If you've already imported a pairing file, and the things above aren't green, then make sure that you actually enabled LocalDevVPN. Also ensure that your pairing file has not expired." : heartbeatReady ? "The Developer Disk Image is not mounted." : "Select or drag and drop a pairing file to continue. If you do not have one, click [here](https://docs.sidestore.io/docs/getting-started/pairing-file) to learn how to generate one.")) {
                    VStack(spacing: 14) {
                        Button(action: {
                            if pairingFile == nil {
                                showPairingFileImporter.toggle()
                            } else {
                                pairingFile = nil
                                heartbeatReady = false
                                ddiMounted = false
                                appData.isSparseBoxReady = false
                                appData.applicationStatus = "Please import a pairing file!"
                                appData.applicationIcon = "exclamationmark.triangle.fill"
                                appData.applicationIconColor = .yellow
                                try? FileManager.default.removeItem(
                                    at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist")
                                )
                            }
                        }) {
                            ButtonLabel(text: pairingFile == nil ? "Import Pairing File" : "Remove Pairing File", icon: pairingFile == nil ? "arrow.down.doc" : "xmark")
                        }
                        .buttonStyle(GlassyButtonStyle(color: pairingFile == nil ? .green : .red))
                        .dropDestination(for: Data.self) { items, location in
                            guard let item = items.first else { return false }
                            pairingFile = String(decoding: item, as: UTF8.self)
                            guard pairingFile?.contains("DeviceCertificate") ?? false else {
                                Alertinator.shared.alert(title: "That's not a pairing file!", body: "Please drop a vaild pairing file and try again.")
                                pairingFile = nil
                                return false
                            }
                            savePairingFile()
                            startHeartbeat()
                            return true
                        }
                        if !ddiMounted {
                            Button(action: {
                                LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.jkcoxson.LocalDevVPN")
                            }) {
                                ButtonLabel(text: "Open LocalDevVPN", icon: "link")
                            }
                            .buttonStyle(GlassyButtonStyle())
                        }
                    }
                }
                /*
                Section(header: HeaderLabel(text: "Tweaks", icon: "wrench.and.screwdriver"), footer: Text(Restore.supportedExploitLevel() != .unsupported ? "Hide free developer apps from installd, so you could install more than 3 apps. You need to apply this for each 3 apps you install or update. **This feature is currently unavailable as of right now.**" : "")) {
                    let tempUnavailable = true
                    NavigationLink("List Installed Apps") {
                        AppListView()
                    }
                    .disabled(!ddiMounted)
                    NavigationLink("MobileGestalt Tweaks") {
                        MobileGestaltView()
                    }
                    .disabled(!ddiMounted)
                    if Restore.supportedExploitLevel() != .unsupported {
                        Button("Bypass 3-App Limit") {
                            testBypassAppLimit()
                        }
                        .disabled(tempUnavailable || Restore.supportedExploitLevel() != .dotAndSlashes || !heartbeatReady || taskRunning)
                    }
                }
                 */
            }
            .navigationTitle("SparseBox+")
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showSettingsView = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showLogs.toggle()
                    }) {
                        Image(systemName: "terminal")
                    }
                }
            }
            .onAppear {
                if !hasShownWelcome {
                    print("[*] Welcome to SparseBox+!\n[*] Running on \(device.systemName!) \(device.systemVersion!), \(device.description)\n[!] WARNING: This tool has the potential to break or bootloop your device! It's highly recommended to create a backup before usage.")
                    hasShownWelcome = true
                }
            }
            .fileImporter(isPresented: $showPairingFileImporter, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList], onCompletion: { result in
                switch result {
                case .success(let url):
                    pairingFile = try! String(contentsOf: url)
                    savePairingFile()
                    startHeartbeat()
                case .failure(let error):
                    Alertinator.shared.alert(title: "Error!", body: "\(error.localizedDescription)")
                }
            })
            .navigationDestination(for: String.self) { view in
                if view == "Apply3AppLimitBypass" {
                    Text("TODO")
                } else {
                    Text("Unknown view: \(view)")
                }
            }
        }
        .onAppear {
            if appData.initError != nil {
                Alertinator.shared.alert(title: "Failed to initalize!", body: "\(appData.initError ?? "something just happened. and i'm not sure what it was. 💀")")
                return
            }
            
            if pairingFile == nil {
                appData.applicationStatus = "Please import a pairing file!"
                appData.applicationIcon = "exclamationmark.triangle.fill"
                appData.applicationIconColor = .yellow
                pairingFile = try? String(contentsOf: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
            }
            
            if let altPairingFile = Bundle.main.object(forInfoDictionaryKey: "ALTPairingFile") as? String, altPairingFile.count > 5000, pairingFile == nil {
                pairingFile = altPairingFile
                savePairingFile()
            }
            
            if pairingFile != nil {
                if !ddiMounted {
                    appData.applicationStatus = "Waiting for heartbeat..."
                    appData.applicationIcon = "showMeProgressPlease"
                    appData.applicationIconColor = .primary
                }
                startHeartbeat()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // keep HTTP server alive in the background for a while
            if scenePhase == .inactive {
                Utils.bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                    // This executes when time is about to run out
                    UIApplication.shared.endBackgroundTask(Utils.bgTask)
                    Utils.bgTask = .invalid
                })
                if Utils.bgTask == .invalid {
                    print("Failed to start background task")
                    return
                }
            } else if scenePhase == .active {
                if Utils.bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(Utils.bgTask)
                    Utils.bgTask = .invalid
                }
            }
        }
    }
    func savePairingFile() {
        try? pairingFile?.write(to: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"), atomically: true, encoding: .utf8)
        appData.applicationStatus = "Waiting for heartbeat..."
        appData.applicationIcon = "showMeProgressPlease"
        appData.applicationIconColor = .primary
    }

    func testBypassAppLimit() {
        guard Restore.supportedExploitLevel() == .dotAndSlashes else {
            return
        }
        Task {
            taskRunning = true
            mbdb = Restore.createBypassAppLimit()
            //path.append("Apply3AppLimitBypass")
            taskRunning = false
        }
    }
    
    func startHeartbeat() {
        guard pairingFile != nil else {
            return
        }
        //let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteString
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try JITEnableContext.shared.startHeartbeat()
                heartbeatReady = true
                print("Heartbeat started successfully")
                
                // quick way to check if DDI is mounted
                let ddiPath: String
                if #available(iOS 17.0, *) {
                    ddiPath = "/System/Developer/Library"
                } else {
                    ddiPath = "/Developer/Library"
                }
                ddiMounted = FileManager.default.fileExists(atPath: ddiPath)
                
                if ddiMounted {
                    Task { @MainActor in
                        appData.applicationStatus = "Ready to Apply"
                        appData.applicationIcon = "checkmark.circle.fill"
                        appData.applicationIconColor = .primary
                        appData.isSparseBoxReady = true
                    }
                }
                // TODO: mount DDI
//                DispatchQueue.main.async {
//                    let trustcachePath = URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg.trustcache").path
//                    guard FileManager.default.fileExists(atPath: trustcachePath),
//                          !MountingProgress.shared.coolisMounted,
//                          MountingProgress.shared.mountingThread == nil else { return }
//                    MountingProgress.shared.pubMount()
//                }
            } catch {
                let err2 = error as NSError
                let code = err2.code
                print("Error: \(error.localizedDescription) (Code: \(code))")
                DispatchQueue.main.async {
                    if code == -9 {
                        do {
                            try FileManager.default.removeItem(at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                            print("Removed invalid pairing file")
                        } catch {
                            print("Error removing invalid pairing file: \(error)")
                        }
                        
                        Alertinator.shared.alert(title: "Invaild Pairing File!", body: "The pairing file you imported has expired or is invaild. Please generate a new pairing file!")
                    } else {
                        Alertinator.shared.alert(title: "Failed to connect to heartbeat! (\(code))", body: "Make sure WiFi and LocalDevVPN are connected and that the device is reachable. Launch the app at least once while online before trying again.")
                    }
                }
            }
        }
    }
    
    func performApply3AppLimitBypass() {
        /*
        let deviceList = MobileDevice.deviceList()
        guard deviceList.count == 1 else {
            print("Invalid device count: \(deviceList.count)")
            return
        }
        Utils.udid = deviceList.first!
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(Utils.udid, conformingTo: .data)
        try? FileManager.default.removeItem(at: folder)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            try mbdb!.writeTo(directory: folder)
            // Restore now
            let restoreArgs = [
                "idevicebackup2",
                "-n", "restore", "--no-reboot", "--system",
                documentsDirectory.path(percentEncoded: false)
            ]
            print("Executing args: \(restoreArgs)")
            var argv = restoreArgs.map{ strdup($0) }
            let result = 0 //idevicebackup2_main(Int32(restoreArgs.count), &argv)
            print("idevicebackup2 exited with code \(result)")
            
            print()
            let log = GLOBAL_LOG.text
            if log.contains("Domain name cannot contain a slash") {
                print("Result: this iOS version is not supported.")
            } else if log.contains("crash_on_purpose") || result == 0 {
                print("Result: restore successful.")
                if reboot {
                    //MobileDevice.rebootDevice(udid: Utils.udid)
                }
            }
            
            logPipe.fileHandleForReading.readabilityHandler = nil
        } catch {
            print(error.localizedDescription)
            return
        }
         */
    }
    
    func ready() -> Bool {
        heartbeatReady
    }
}

#Preview {
    ApplyView()
}
