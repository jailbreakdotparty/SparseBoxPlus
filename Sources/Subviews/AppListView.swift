import SwiftUI
import PartyUI

struct AppItemView: View {
    let appDetails: [String : Any]
    let bundleID: String
    var body: some View {
        Form {
            if doubleSystemVersion() <= 18.1 || doubleSystemVersion() >= 26.0 {
                NavigationLink {
                    List {
                        ForEach(Array(appDetails.keys), id: \.self) { k in
                            let v = appDetails[k] as? String
                            VStack(alignment: .leading) {
                                Text(k)
                                Text(v ?? "(not a String)")
                                    .font(Font.footnote)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .navigationTitle((appDetails["CFBundleName"] as? String) ?? bundleID)
                } label: {
                    Text("View App Details")
                }
                Section(header: HeaderLabel(text: "Arbitrary Read Exploit", icon: "paperclip"), footer: Text("After the path gets copied, open Settings, paste the link into the search bar, select all the text, and tap \"Share\". For this exploit, folders can only be shared via AirDrop.\n\nIf you're sharing App Store apps, please note that it will still remain encrypted.")) {
                    VStack(spacing: 12) {
                        if let bundlePath = appDetails["Path"] {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                UIPasteboard.general.string = "file://a\(bundlePath)"
                                Alertinator.shared.alert(title: "Link Copied!", body: "Copied \(UIPasteboard.general.string ?? "") to clipboard.", actionLabel: "Open Settings", action: {
                                    LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.Preferences")
                                })
                            }) {
                                ButtonLabel(text: "Copy App Bundle Folder", icon: "shippingbox")
                            }
                            .buttonStyle(TranslucentButtonStyle())
                        }
                        if let containerPath = appDetails["Container"] {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                UIPasteboard.general.string = "file://a\(containerPath)"
                                Alertinator.shared.alert(title: "Link Copied!", body: "Copied \(UIPasteboard.general.string ?? "") to clipboard.", actionLabel: "Open Settings", action: {
                                    LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.Preferences")
                                })
                            }) {
                                ButtonLabel(text: "Copy App Data Folder", icon: "externaldrive")
                            }
                            .buttonStyle(TranslucentButtonStyle())
                        }
                    }
                }
            } else {
                List {
                    ForEach(Array(appDetails.keys), id: \.self) { k in
                        let v = appDetails[k] as? String
                        VStack(alignment: .leading) {
                            Text(k)
                            Text(v ?? "(not a String)")
                                .font(Font.footnote)
                                .textSelection(.enabled)
                        }
                    }
                }
                .navigationTitle((appDetails["CFBundleName"] as? String) ?? bundleID)
            }
        }
        .navigationTitle((appDetails["CFBundleName"] as? String) ?? bundleID)
    }

    init(bundleID: String) {
        self.bundleID = bundleID
        self.appDetails = ["Loading": AnyCodable("...")]
    }

    init(appDetails: [String: Any]) {
        self.appDetails = appDetails
        self.bundleID = (appDetails["CFBundleIdentifier"] as? String) ?? ""
    }
}

func appIconCornerRadius() -> CGFloat {
    if #available(iOS 26.0, *) {
        return 14
    } else {
        return 10
    }
}

struct AppListView: View {
    @State var apps: [String : [String : Any]] = [:]
    @State var appIcons: [String : UIImage] = [:]
    @State var searchString: String = ""
    @EnvironmentObject var appData: AppData
    
    var results: [String] {
        let filtered: [String]
        if searchString.isEmpty {
            filtered = Array(apps.keys)
        } else {
            filtered = apps.compactMap { key, appDetails in
                let appName = appDetails["CFBundleName"] as? String
                let appPath = appDetails["Path"] as? String
                return (appName!.contains(searchString) ||
                        appPath!.contains(searchString)) ? key : nil
            }
        }
        return filtered.sorted { a, b in
            let nameA = apps[a]!["CFBundleName"] as! String
            let nameB = apps[b]!["CFBundleName"] as! String
            return nameA < nameB
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(results, id: \.self) { bundleID in
                    let appDetails = apps[bundleID]
                    let appName = (appDetails?["CFBundleName"] as? String) ?? "Loading..."
                    let appBundleID = (appDetails?["CFBundleIdentifier"] as? String) ?? ""
                    NavigationLink {
                        if let details = appDetails {
                            AppItemView(appDetails: details)
                        } else {
                            AppItemView(bundleID: bundleID)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(uiImage: appIcons[bundleID] ?? UIImage())
                                .resizable()
                                .frame(width: 50, height: 50)
                                .task(id: bundleID) {
                                    guard appIcons[bundleID] == nil else { return }
                                    await MainActor.run {
                                        appIcons[bundleID] = UIImage()
                                    }
                                    let icon = await Task.detached(priority: .background) {
                                        try? JITEnableContext.shared.getAppIcon(withBundleId: bundleID)
                                    }.value
                                    await MainActor.run {
                                        if let icon { appIcons[bundleID] = icon }
                                    }
                                }
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(appName)
                                    Spacer()
                                    if appBundleID.isEmpty {
                                        ProgressView()
                                    }
                                }
                                if !appBundleID.isEmpty {
                                    Text(appBundleID).font(Font.footnote)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        apps = try JITEnableContext.shared.getAllAppsInfo() as! [String : [String : Any]]
                    } catch {
                        apps = ["Failed to get app list: \(error)": [:]]
                    }
                }
            }
            .searchable(text: $searchString)
            .navigationTitle("Listed Applications")
        }
        .modifier(PrimaryViewModifier())
    }
    
    init() {
        apps = ["Loading": [:]]
    }

}
