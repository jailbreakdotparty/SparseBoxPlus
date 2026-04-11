//
//  GestaltDataView.swift
//  SparseBoxPlus
//
//  Created by Main on 1/9/26.
//

import SwiftUI
import PartyUI

struct GestaltDataView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        MobileGestaltViewer() {
            Section(header: HeaderLabel(text: "Actions", icon: "wrench.and.screwdriver.fill")) {
                VStack(spacing: 8) {
                    if appData.isSparseBoxReady {
                        Button(action: {
                            saveProductType(appData: AppData.shared)
                            try! appData.mobileGestalt.write(to: appData.modMGURL)
                            presentShareSheet(with: appData.modMGURL)
                        }) {
                            ButtonLabel(text: "Export Modified MobileGestalt", icon: "doc.badge.gearshape")
                        }
                        .buttonStyle(TranslucentButtonStyle())
                    }
                    Button(action: {
                        presentShareSheet(with: appData.origMGURL)
                    }) {
                        ButtonLabel(text: "Export Original MobileGestalt", icon: "arrow.up.doc")
                    }
                    .buttonStyle(TranslucentButtonStyle())
                }
            }
        }
    }
}

// i am so sorry for doing this, but it fixed the weird ui issues so womp womp
struct MobileGestaltViewer<Content: View>: View {
    let pathToGestalt = URL(fileURLWithPath: "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")
    
    @State var gestaltData: [String: Any] = [:]
    @State var topLevelCache: [String: Any] = [:]
    @State var searchRequest: String = ""
    @ViewBuilder var content: Content
    
    var body: some View {
        NavigationStack {
            List {
                content
                Section(header: HeaderLabel(text: "MobileGestalt Data", icon: "doc")) {
                    DictionaryView(dictionary: topLevelCache, searchRequest: searchRequest)
                }
            }
            .navigationTitle("MobileGestalt Data")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchRequest, prompt: "Search Keys")
            .onAppear {
                gestaltData = loadGestaltData() as? [String: Any] ?? [:]
                topLevelCache = gestaltData["CacheExtra"] as? [String: Any] ?? [:]
            }
        }
    }

    func loadGestaltData() -> Any? {
        do {
            // this gets the data of the file
            let rawGestaltData = try Data(contentsOf: pathToGestalt)
            // this returns it as a property list
            return try PropertyListSerialization.propertyList(from: rawGestaltData, options: [], format: nil)
        } catch {
            // this comes up if something goes wrong
            Alertinator.shared.alert(title: "Error!", body: "\(error)")
            return nil
        }
    }
}

struct DictionaryView: View {
    var dictionary: [String: Any]
    var searchRequest: String = ""
    
    var body: some View {
        ForEach(searchRequest.isEmpty ? Array(dictionary.keys.sorted()) : Array(dictionary.keys.sorted()).filter { $0.localizedStandardContains(searchRequest) }, id: \.self) { key in
            let rawValue = dictionary[key] ?? "N/A"
            let value = String(describing: rawValue)
            VStack(alignment: .leading, spacing: 14) {
                if value.contains("""
                    {
                    
                    """) {
                    let nestedDictionary = rawValue as? [String: Any] ?? [:]
                    DisclosureGroup {
                        DictionaryView(dictionary: nestedDictionary)
                            .padding(.leading, 20)
                    } label: {
                        Text(key)
                    }
                } else {
                    LabeledContent(key) {
                        Text(value)
                    }
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = key
                        }) {
                            Image(systemName: "key")
                            Text("Copy Key")
                        }
                        Button(action: {
                            UIPasteboard.general.string = value
                        }) {
                            Image(systemName: "link")
                            Text("Copy Value")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    GestaltDataView()
}
