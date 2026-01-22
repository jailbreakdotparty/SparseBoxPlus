//
//  MainView.swift
//  SparseBoxPlus
//
//  Created by Main on 1/8/26.
//

import SwiftUI
import UIKit
import PartyUI
import DeviceKit

internal enum SelectableTab: Int, CaseIterable {
    case apply, tweaks, filesystem
}

struct MainView: View {
    @EnvironmentObject var appData: AppData
    @State public var selectedTab: SelectableTab = .apply
    let device = Device.current
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                ApplyView()
                    .navigationSplitViewColumnWidth(400)
            } detail: {
                Group {
                    switch selectedTab {
                    case .tweaks:
                        GestaltTweaksView()
                            .modifier(PrimaryViewModifier())
                    case .filesystem:
                        FilesystemView()
                            .modifier(PrimaryViewModifier())
                    default:
                        TweaksView()
                            .modifier(PrimaryViewModifier())
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button(action: {
                            selectedTab = .tweaks
                        }) {
                            Image(systemName: "wrench.and.screwdriver")
                        }
                        Button(action: {
                            selectedTab = .filesystem
                        }) {
                            Image(systemName: "checklist")
                        }
                    }
                }
            }
            .onAppear {
                if isOSVersionPatched() && !weOnADebugBuild {
                    Alertinator.shared.alert(title: "Unsupported Device Detected!", body: "This device (\(device.description) \(device.systemName!) \(device.systemVersion!)) does not support SparseBox+ and never will. Apologies for any inconviences.", showCancel: false, action: {
                        exitinator()
                    })
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                ApplyView()
                    .tabItem { Label("Apply", systemImage: "house") }
                    .tag(SelectableTab.apply)
                GestaltTweaksView()
                    .tabItem { Label("Tweaks", systemImage: "wrench.and.screwdriver")}
                    .tag(SelectableTab.tweaks)
                FilesystemView()
                    .tabItem { Label("Filesystem", systemImage: "folder")}
                    .tag(SelectableTab.filesystem)
            }
            .onAppear {
                if isOSVersionPatched() && !weOnADebugBuild {
                    Alertinator.shared.alert(title: "Unsupported Device Detected!", body: "This device (\(device.description) \(device.systemName!) \(device.systemVersion!)) does not support SparseBox+ and never will. Apologies for any inconviences.", showCancel: false, action: {
                        exitinator()
                    })
                }
            }
            .overlay(alignment: .bottom) {
                if doubleSystemVersion() < 26.0 {
                    let color = Color.accentColor
                    GeometryReader { geometry in
                        let aThird = geometry.size.width / 3
                        VStack {
                            Spacer()
                            Circle()
                                .background(color.blur(radius: 20))
                                .frame(width: aThird, height: 30)
                                .shadow(color: color, radius: 40)
                                .offset(
                                    x: CGFloat(selectedTab.rawValue) * aThird,
                                    y: 30
                                )
                        }
                        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: selectedTab)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct PrimaryViewModifier: ViewModifier {
    @EnvironmentObject var appData: AppData
    
    func body(content: Content) -> some View {
        content
            .disabled(!weOnADebugBuild && !appData.isSparseBoxReady)
            .tint(!weOnADebugBuild && !appData.isSparseBoxReady ? .gray : .accent)
    }
}

#Preview {
    MainView()
        .environmentObject(AppData())
}
