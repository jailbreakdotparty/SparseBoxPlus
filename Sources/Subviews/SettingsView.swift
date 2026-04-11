//
//  SettingsView.swift
//  SparseBoxPlus
//
//  Created by Main on 1/7/26.
//

import SwiftUI
import PartyUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @EnvironmentObject var appData: AppData
    
    @AppStorage("shouldRespring") var shouldRespring: Bool = true
    @AppStorage("showCustomKeys") var showCustomKeys: Bool = false
    @AppStorage("BookassetdContainerUUID") var bookassetdUUID: String?
    
    @AppStorage("showFilesystemPage") var showFilesystemPage: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "About", icon: "info.circle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        AppInfoCell()
                        Button(action: {
                            Haptic.shared.play(.soft)
                            openURL(URL(string: "https://jailbreak.party")!)
                        }) {
                            ButtonLabel(text: "Website", icon: "globe")
                        }
                        .buttonStyle(TranslucentButtonStyle(color: .blue))
                        HStack {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                openURL(URL(string: "https://jailbreak.party/discord")!)
                            }) {
                                ButtonLabel(text: "Discord", icon: "discord", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .discord))
                            Button(action: {
                                Haptic.shared.play(.soft)
                                openURL(URL(string: "https://github.com/jailbreakdotparty/SparseBoxPlus")!)
                            }) {
                                ButtonLabel(text: "GitHub", icon: "github", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .gitHub))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if appData.ddiMounted || weOnADebugBuild {
                    Section(header: HeaderLabel(text: "Applying", icon: "checkmark.seal")) {
                        HStack {
                            TextField("bookassetd UUID", text: Binding(get: { bookassetdUUID ?? "" }, set: { bookassetdUUID = $0.isEmpty ? nil : $0 }))
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                Alertinator.shared.alert(title: "Are you sure?", body: "You'll have to get a new one when applying. Only reset your UUID if you've had to re-install the Books app.", action: {
                                    bookassetdUUID = nil
                                })
                            }) {
                                Image(systemName: "xmark")
                                    .frame(width: 24)
                            }
                            .buttonStyle(.plain)
                        }
                        Toggle("Respring After Finish Restoring", isOn: $shouldRespring)
                    }
                    .modifier(ConditionalListModifiers())
                    
                    Section(header: HeaderLabel(text: "Features", icon: "wrench.and.screwdriver")) {
                        Toggle(isOn: $showCustomKeys) {
                            Text("Enable Custom Gestalt Keys")
                            Text("This feature could brick your device! Don't use it unless you know what you're doing.")
                        }
                        .disabled(!appData.isSparseBoxReady)
                        Toggle("Show Filesystem Tools (experimental)", isOn: $showFilesystemPage)
                    }
                }
                Section {
                    NavigationLink("Customize", destination: CustomizeView(colorOptions: [
                        ColorOption(label: "Default", color: Color.accent),
                        ColorOption(label: "Blue", color: Color.blue),
                        ColorOption(label: "Purple", color: Color.purple),
                        ColorOption(label: "Pink", color: Color.pink),
                        ColorOption(label: "Red", color: Color.red),
                        ColorOption(label: "Orange", color: Color.orange),
                        ColorOption(label: "Yellow", color: Color.yellow),
                        ColorOption(label: "Green", color: Color.green)
                    ]))
                }
                Section(header: HeaderLabel(text: "Credits", icon: "star")) {
                    LinkCreditCell(image: Image("duyTran"), name: "Duy Tran (@khanhduytran0)", description: "Original project creator", url: "https://github.com/khanhduytran0")
                    LinkCreditCell(image: Image("lunginspector"), name: "lunginspector (jbdotparty)", description: "All improvements for SparseBox+", url: "https://github.com/lunginspector")
                    LinkCreditCell(image: Image("sidestore"), name: "SideStore Team", description: "idevice, C bindings from StikDebug", url: "https://github.com/sidestore")
                    LinkCreditCell(image: Image("jjtech"), name: "JJTech", description: "SparseRestore and backup exploit", url: "https://github.com/JJTech0130")
                    LinkCreditCell(image: Image("hanakim3945"), name: "hanakim3945", description: "BookRestore exploit files and writeup", url: "https://github.com/hanakim3945")
                    LinkCreditCell(image: Image("poomsmart"), name: "PoomSmart", description: "MobileGestalt keys dump", url: "https://github.com/poomsmart")
                    LinkCreditCell(image: Image("lakr233"), name: "Lakr233", description: "BBackup", url: "https://github.com/Lakr233")
                    LinkCreditCell(image: Image("libimobiledevice"), name: "libimobileDevice", description: "libimobiledevice", url: "https://github.com/libimobiledevice")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                    .modifier(SolariumButtonTint())
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
