import SwiftUI
import UniformTypeIdentifiers
import PartyUI

struct GestaltTweaksView: View {
    @State private var mbdb: Backup?
    @State private var viewShouldUpdate = false
    @State private var customGestaltKey: String = ""
    @State private var customGestaltValue: String = ""
    @State private var customDeviceName: String = ""
    @State private var hasCustomDeviceNameBeenSet: Bool = false
    
    @State private var originalSubtype: Int = 2436
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var appData: AppData
    
    @AppStorage("BookassetdContainerUUID") var bookassetdUUID: String?
    @AppStorage("customGestaltKeys") var customGestaltKeys: [String : String] = [:]
    @AppStorage("showCustomKeys") var showCustomKeys: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "Device Artwork", icon: "paintbrush.pointed")) {
                    HStack(spacing: 10) {
                        PrimaryTextFieldButton(titleKey: "Custom Device Name", text: $customDeviceName, button: {
                            Button(action: {
                                withAnimation {
                                    if hasCustomDeviceNameBeenSet {
                                        Haptic.shared.play(.soft)
                                        hasCustomDeviceNameBeenSet = false
                                    } else {
                                        Haptic.shared.play(.soft)
                                        setDeviceModelName()
                                    }
                                }
                            }) {
                                Image(systemName: hasCustomDeviceNameBeenSet ? "xmark" : "checkmark")
                                    .modifier(UpdatedIconAnimation(isOn: hasCustomDeviceNameBeenSet))
                            }
                        })
                        .disabled(hasCustomDeviceNameBeenSet)
                    }
                    HStack {
                        Picker(selection: $appData.deviceSubtype) {
                            Text("Default (\(originalSubtype))").tag(originalSubtype)
                            if isDeviceNotBroke() {
                                Text("Disable Dynamic Island").tag(2436)
                            }
                            Text("iPhone 14 Pro").tag(2436)
                            Text("iPhone 14 Pro Max").tag(2796)
                            Text("iPhone 15 Pro Max").tag(2976)
                            if doubleSystemVersion() >= 18.0 {
                                Text("iPhone 16 Pro").tag(2622)
                                Text("iPhone 16 Pro Max").tag(2868)
                            }
                            if doubleSystemVersion() >= 26.0 {
                                Text("iPhone Air").tag(2736)
                            }
                            if UIDevice._hasHomeButton() {
                                Text("iPhone X Gestures").tag(2436)
                            }
                        } label: {
                            ButtonLabel(text: "Subtype", icon: "iphone")
                        }
                        .frame(height: 22)
                        .modifier(ListTogglePlatter())
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                
                Section(header: HeaderLabel(text: "Software-Oriented Features", icon: "gearshape")) {
                    PlatterToggle(text: "Dynamic Island", icon: "platter.filled.top.iphone", minSupportedVersion: 19.0, isOn: bindingForMGKeys(["YlEtTtHlNesRBMal1CqRaA"]))
                    PlatterToggle(text: "Always On Display", icon: "sun.max", minSupportedVersion: 18.0, isOn: bindingForMGKeys(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    PlatterToggle(text: "AOD Vibrancy", icon: "rays", minSupportedVersion: 18.0, isOn: bindingForMGKeys(["ykpu7qyhqFweVMKtxNylWA"]))
                    PlatterToggle(text: "Charge Limit", icon: "battery.100.bolt", minSupportedVersion: 17.0, isOn: bindingForMGKeys(["37NVydb//GP/GrhuTN+exg"]))
                    PlatterToggle(text: "Boot Chime", icon: "speaker.wave.3", isOn: bindingForMGKeys(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    PlatterToggle(text: "Liquid Glass LPM", icon: "app.background.dotted", minSupportedVersion: 19.0, isOn: bindingForMGKeys(["SAGvsp6O6kAQ4fEfDJpC4Q"]))
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                
                Section(header: HeaderLabel(text: "Hardware-Oriented Features", icon: "iphone")) {
                    PlatterToggle(text: "Camera Control", icon: "camera.shutter.button", minSupportedVersion: 18.0, isOn: bindingForMGKeys(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    PlatterToggle(text: "Action Button", icon: "button.vertical.left.press", minSupportedVersion: 17.0, isOn: bindingForMGKeys(["cT44WE1EohiwRzhsZ8xEsw"]))
                    PlatterToggle(text: "Crash Detection", icon: "car", isOn: bindingForMGKeys(["HCzWusHQwZDea6nNhaKndw"]))
                    if UIDevice._hasHomeButton() {
                        PlatterToggle(text: "Enable Tap to Wake", icon: "hand.tap", isOn: bindingForMGKeys(["yZf3GTRMGTuwSV/lD7Cagw"]))
                    }
                    PlatterToggle(text: "Pulse Width Modulation", icon: "eye", minSupportedVersion: 19.0, isOn: bindingForMGKeys(["6IejgN+1Fmu5/QrZFOIeNw"]))
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                
                Section(header: HeaderLabel(text: "Eligibility", icon: "checklist")) {
                    PlatterToggle(text: "Security Research Device UI", icon: "terminal", minSupportedVersion: 26.0, isOn: bindingForMGKeys(["XYlJKKkj2hztRP1NWWnhlw"]))
                    PlatterToggle(text: "Disable Region Restrictions", icon: "globe", isOn: bindingForRegionRestriction())
                    PlatterToggle(text: "Apple Intelligence", icon: "apple.intelligence", minSupportedVersion: 18.1, isOn: bindingForAppleIntelligence())
                    HStack(spacing: 10) {
                        Picker("Spoofing", selection:$appData.productType) {
                            Text("Default").tag(machineName())
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                if doubleSystemVersion() >= 17.4 {
                                    Text("iPad Pro 11-inch (M4)").tag("iPad16,3")
                                    Text("iPad Pro 11-inch (M4, Cellular)").tag("iPad16,4")
                                }
                                Text("iPad Pro 11-inch (4th Gen)").tag("iPad14,3")
                                Text("iPad Pro 11-inch (4th Gen, Cellular)").tag("iPad14,4")
                            } else {
                                Text("iPhone 15 Pro").tag("iPhone16,1")
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                if doubleSystemVersion() >= 18.0 {
                                    Text("iPhone 16").tag("iPhone17,3")
                                    Text("iPhone 16 Plus").tag("iPhone17,4")
                                    Text("iPhone 16 Pro").tag("iPhone17,1")
                                    Text("iPhone 16 Pro Max").tag("iPhone17,2")
                                }
                                if doubleSystemVersion() >= 19.0 {
                                    Text("iPhone 17").tag("iPhone18,3")
                                    Text("iPhone 17 Pro").tag("iPhone18,1")
                                    Text("iPhone 17 Pro Max").tag("iPhone18,2")
                                    Text("iPhone Air").tag("iPhone18,4")
                                }
                            }
                        }
                        .frame(height: 22)
                        .modifier(ListTogglePlatter())
                        Button(action: {
                            Alertinator.shared.alert(title: "Device Spoofing Info", body: "Only spoof your device model if you want to download Apple Intelligence. This may break Face ID. If you decide to unspoof and want to keep Apple Intelligence, do NOT re-enter the Apple Intelligence & Siri menu in Settings.")
                        }) {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(TranslucentButtonStyle(useFullWidth: false))
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                
                Section(header: HeaderLabel(text: "iPadOS Features", icon: "ipad")) {
                    let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary
                    
                    PlatterToggle(text: "Allow Installing iPadOS Apps", icon: "plus.app", isOn: bindingForMGKeys(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, defaultValue: [1], enableValue: [1, 2]))
                    PlatterToggle(text: "Apple Pencil Settings", icon: "pencil", isOn: bindingForMGKeys(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        PlatterToggle(text: "Stage Manager", icon: "squares.leading.rectangle", isOn: bindingForMGKeys(["qeaj75wk3HF4DwQ8qbIi7g"]))
                    }
                    HStack(spacing: 10) {
                        PlatterToggle(text: "iPadOS UI", icon: "ipad", isOn: bindingForTrollPad())
                            .disabled(cacheExtra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                        Button(action: {
                            Alertinator.shared.alert(title: "Warning!", body: "This changes the UI idiom to iPadOS, giving you multitasking features and other iPadOS UI elements. Gives the same capbilities as TrollPad, but may cause issues.\n\nWARNING: Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape. Also, do NOT use this tweak with an alphanumeric passcode!")
                        }) {
                            Image(systemName: "exclamationmark.triangle")
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .red, useFullWidth: false))
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                
                Section(header: HeaderLabel(text: "Internal", icon: "ant")) {
                    PlatterToggle(text: "Internal Storage", icon: "externaldrive", isOn: bindingForMGKeys(["LBJfwOEzExRxzlAnSuI7eg"]))
                    PlatterToggle(text: "Internal Features", icon: "gearshape", isOn: bindingForInternalStuff())
                    PlatterToggle(text: "Metal HUD in All Apps", icon: "terminal", isOn: bindingForMGKeys(["EqrsVvjcYDdxHBiQmGhAWw"]))
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.dropdownRowInsets)
                if showCustomKeys {
                    Section(header: HeaderLabel(text: "Custom Gestalt Keys", icon: "paintpalette")) {
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Gestalt Key", text: $customGestaltKey)
                                    .modifier(PrimaryTextFieldStyle())
                                Button(action: {
                                    customGestaltKey = UIPasteboard.general.string ?? ""
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(TranslucentButtonStyle(useFullWidth: false))
                            }
                            TextField("Gestalt Value (string)", text: $customGestaltValue)
                                .modifier(PrimaryTextFieldStyle())
                            Button(action: {
                                customGestaltKeys[customGestaltKey] = customGestaltValue
                                customGestaltKey = ""
                                customGestaltValue = ""
                            }) {
                                ButtonLabel(text: "Add Key", icon: "plus")
                            }
                            .buttonStyle(TranslucentButtonStyle())
                            .disabled(customGestaltKey.isEmpty || customGestaltValue.isEmpty)
                        }
                        .modifier(SectionPlatter(backgroundType: .systemBackground))
                        
                        ForEach(customGestaltKeys.keys.sorted(), id: \.self) { key in
                            if let value = customGestaltKeys[key] {
                                PlatterToggle(text: key, icon: "key", isOn: bindingForCustomGestaltKey(key: key, value: value))
                                    .contextMenu {
                                        Button(action: {
                                            Alertinator.shared.alert(title: "Custom Key Info", body: "Key: \(key)\nValue: \(value)")
                                        }) {
                                            Label("Get Info", systemImage: "info.circle")
                                        }
                                        Button(action: {
                                            // set the binding to false
                                            bindingForCustomGestaltKey(key: key, value: value).wrappedValue = false
                                            customGestaltKeys.removeValue(forKey: key)
                                            customGestaltKeys[key] = nil
                                        }) {
                                            Label("Remove Key", systemImage: "key")
                                        }
                                    }
                                    .tint(.primary)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.dropdownRowInsets)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Tweaks")
            .onAppear {
                if appData.initError != nil {
                    Alertinator.shared.alert(title: "Error!", body: "\(appData.initError ?? "something just happened. and i'm not sure what it was. 💀")")
                    return
                }
                
                if let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary {
                    appData.productType = cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] as! String
                }
                
                
                if let originalCacheExtra = appData.originalMobileGestalt["CacheExtra"] as? NSMutableDictionary {
                    if let artworkDetails = originalCacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary {
                        appData.deviceSubtype = artworkDetails["ArtworkDeviceSubType"] as? Int ?? 2436
                        originalSubtype = artworkDetails["ArtworkDeviceSubType"] as? Int ?? 2436
                        appData.deviceModelName = artworkDetails["ArtworkDeviceProductDescription"] as? String ?? "iPhone xx"
                    }
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
        .modifier(PrimaryViewModifier())
    }
    
    func bindingForAppleIntelligence() -> Binding<Bool> {
        guard let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        let key = "A62OafQ85EJAiiqKn4agtg"
        return Binding(
            get: {
                _ = viewShouldUpdate
                if let value = cacheExtra[key] as? Int? {
                    return value == 1
                }
                return false
            },
            set: { enabled in
                if enabled {
                    appData.eligibilityData = try! Data(contentsOf: Bundle.main.url(forResource: "eligibility", withExtension: "plist")!)
                    appData.featureFlagsData = try! Data(contentsOf: Bundle.main.url(forResource: "FeatureFlags_Global", withExtension: "plist")!)
                    cacheExtra[key] = 1
                } else {
                    appData.featureFlagsData = try! PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
                    appData.eligibilityData = appData.featureFlagsData
                    // just remove the key as it will be pulled from device tree if missing
                    cacheExtra.removeObject(forKey: key)
                }
                DispatchQueue.main.async {
                    viewShouldUpdate.toggle()
                    Haptic.shared.play(.soft)
                }
            }
        )
    }

    func bindingForRegionRestriction() -> Binding<Bool> {
        guard let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        return Binding<Bool>(
            get: {
                _ = viewShouldUpdate
                return cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] as? String == "US" &&
                    cacheExtra["zHeENZu+wbg7PUprwNwBWg"] as? String == "LL/A"
            },
            set: { enabled in
                if enabled {
                    cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] = "US"
                    cacheExtra["zHeENZu+wbg7PUprwNwBWg"] = "LL/A"
                } else {
                    cacheExtra.removeObject(forKey: "h63QSdBCiT/z0WU6rdQv6Q")
                    cacheExtra.removeObject(forKey: "zHeENZu+wbg7PUprwNwBWg")
                }
                DispatchQueue.main.async {
                    viewShouldUpdate.toggle()
                    Haptic.shared.play(.soft)
                }
            }
        )
    }
    
    func bindingForInternalStuff() -> Binding<Bool> {
        // we need to do it via CacheData
        guard let cacheData = appData.mobileGestalt["CacheData"] as? NSMutableData else {
            return State(initialValue: false).projectedValue
        }
        let off_appleInternalInstall = FindCacheDataOffset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_HasInternalSettingsBundle = FindCacheDataOffset("Oji6HRoPi7rH7HPdWVakuw")
        let off_InternalBuild = FindCacheDataOffset("LBJfwOEzExRxzlAnSuI7eg")
        //print("Read value from \(cacheData.mutableBytes.load(fromByteOffset: valueOffset, as: Int.self))")
        
        return Binding(
            get: {
                _ = viewShouldUpdate
                return cacheData.bytes.load(fromByteOffset: off_appleInternalInstall, as: Int.self) == 1
            },
            set: { enabled in
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_appleInternalInstall, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_HasInternalSettingsBundle, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_InternalBuild, as: Int.self)
                DispatchQueue.main.async {
                    viewShouldUpdate.toggle()
                    Haptic.shared.play(.soft)
                }
            }
        )
    }
    
    func bindingForCustomGestaltKey(key: String, value: String) -> Binding<Bool> {
        guard let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        
        return Binding<Bool>(
            get: {
                _ = viewShouldUpdate
                return cacheExtra[key] as? String == value
            },
            set: { enabled in
                if enabled {
                    cacheExtra[key] = value
                } else {
                    cacheExtra.removeObject(forKey: key)
                }
                DispatchQueue.main.async {
                    viewShouldUpdate.toggle()
                    Haptic.shared.play(.soft)
                }
            }
        )
    }
    
    /*
    func bindingForDeviceModelName(value: String) -> Binding<Bool> {
        guard let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary, let artworkDetails = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        
        return Binding<Bool>(
            get: {
                _ = viewShouldUpdate
                return artworkDetails[value] as? String == value
            },
            set: { enabled in
                if enabled {
                    artworkDetails["ArtworkDeviceProductDescription"] = value
                } else {
                    artworkDetails["ArtworkDeviceProductDescription"] = appData.deviceModelName
                }
            }
        )
    }
    */
    
    func bindingForTrollPad() -> Binding<Bool> {
        // We're going to overwrite DeviceClassNumber but we can't do it via CacheExtra, so we need to do it via CacheData instead
        guard let cacheData = appData.mobileGestalt["CacheData"] as? NSMutableData,
              let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        let valueOffset = FindCacheDataOffset("mtrAoWJ3gsq+I90ZnQ0vQw")
        //print("Read value from \(cacheData.mutableBytes.load(fromByteOffset: valueOffset, as: Int.self))")
        
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability,
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        return Binding(
            get: {
                _ = viewShouldUpdate
                if let value = cacheExtra[keys.first!] as? Int? {
                    return value == 1
                }
                return false
            },
            set: { enabled in
                cacheData.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: valueOffset, as: Int.self)
                for key in keys {
                    if enabled {
                        cacheExtra[key] = 1
                    } else {
                        // just remove the key as it will be pulled from device tree if missing
                        cacheExtra.removeObject(forKey: key)
                    }
                }
                DispatchQueue.main.async {
                    viewShouldUpdate.toggle()
                    Haptic.shared.play(.soft)
                }
            }
        )
    }
    
    func bindingForMGKeys<T: Equatable>(_ keys: [String], type: T.Type = Int.self, defaultValue: T? = 0, enableValue: T? = 1) -> Binding<Bool> {
        guard let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary else {
            return State(initialValue: false).projectedValue
        }
        return Binding(
            get: {
                _ = viewShouldUpdate
                if let value = cacheExtra[keys.first!] as? T?, let enableValue {
                    return value == enableValue
                }
                return false
            },
            set: { enabled in
                for key in keys {
                    if enabled {
                        cacheExtra[key] = enableValue
                    } else {
                        // just remove the key as it will be pulled from device tree if missing
                        cacheExtra.removeObject(forKey: key)
                    }
                }
                DispatchQueue.main.async {
                    viewShouldUpdate.toggle()
                    Haptic.shared.play(.soft)
                }
            }
        )
    }
    
    func generateFilesToRestore() -> [FileToRestore] {
        return [
            FileToRestore(from: appData.modMGURL, to: URL(filePath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"), owner: 501, group: 501),
            FileToRestore(contents: appData.eligibilityData, to: URL(filePath: "/var/db/eligibilityd/eligibility.plist")),
            FileToRestore(contents: appData.featureFlagsData, to: URL(filePath: "/var/preferences/FeatureFlags/Global.plist")),
        ]
    }
    
    func setDeviceModelName() {
        if let cacheExtra = appData.mobileGestalt["CacheExtra"] as? NSMutableDictionary {
            if let artworkDetails = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary {
                if !customDeviceName.isEmpty {
                    artworkDetails["ArtworkDeviceProductDescription"] = customDeviceName
                    hasCustomDeviceNameBeenSet = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GestaltTweaksView()
            .environmentObject(AppData())
    }
}
