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
    @EnvironmentObject var theme: AppTheme
    
    @State public var selectedTab: SelectableTab = .apply
    
    @AppStorage("showFilesystemPage") var showFilesystemPage: Bool = false
    
    let device = Device.current
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                ApplyView()
                    .navigationSplitViewColumnWidth(385)
            } detail: {
                TabView(selection: $selectedTab) {
                    GestaltTweaksView()
                        .tabItem { Label("Tweaks", systemImage: "wrench.and.screwdriver") }
                        .tag(SelectableTab.tweaks)
                    FilesystemView()
                        .tabItem { Label("Filesystem", systemImage: "folder") }
                        .tag(SelectableTab.filesystem)
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .onAppear {
                if isOSVersionPatched() && !weOnADebugBuild {
                    Alertinator.shared.alert(title: "Unsupported Device Detected!", body: "This device (\(device.description), \(device.systemName!) \(device.systemVersion!)) does not support SparseBox+ and never will. Apologies for any inconviences.", showCancel: false, action: {
                        exitinator()
                    })
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                ApplyView()
                    .tabItem { Label("Apply", systemImage: "gear.badge.checkmark") }
                    .tag(SelectableTab.apply)
                GestaltTweaksView()
                    .tabItem { Label("Tweaks", systemImage: "wrench.and.screwdriver") }
                    .tag(SelectableTab.tweaks)
                if !showFilesystemPage {
                    GestaltDataView()
                        .tabItem { Label("Gestalt", systemImage: "doc.text") }
                        .tag(SelectableTab.filesystem)
                } else {
                    FilesystemView()
                        .tabItem { Label("Filesystem", systemImage: "folder") }
                        .tag(SelectableTab.filesystem)
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
            .onAppear {
                if isOSVersionPatched() && !weOnADebugBuild {
                    Alertinator.shared.alert(title: "Unsupported Device Detected!", body: "This device (\(device.description) \(device.systemName!) \(device.systemVersion!)) does not support SparseBox+ and never will. Apologies for any inconviences.", showCancel: false, action: {
                        exitinator()
                    })
                }
            }
            .onChange(of: selectedTab) {
                Haptic.shared.play(.soft, intensity: 0.6)
            }
        }
    }
}

struct PrimaryViewModifier: ViewModifier {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .disabled(!weOnADebugBuild && !appData.isSparseBoxReady)
            .tint(!weOnADebugBuild && !appData.isSparseBoxReady ? .gray : theme.accentColor)
    }
}

#Preview {
    MainView()
        .environmentObject(AppData())
}
