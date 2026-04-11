//
//  FilesystemView.swift
//  SparseBoxPlus
//
//  Created by Main on 1/14/26.
//

import SwiftUI
import PartyUI

struct FilesystemView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "Tools", icon: "wrench.and.screwdriver")) {
                    NavigationLink("List Installed Apps", destination: AppListView())
                        .disabled(!appData.isSparseBoxReady && !weOnADebugBuild)
                    NavigationLink("Browse AFC (Media)", destination: BrowseFSView())
                        .disabled(!appData.isSparseBoxReady)
                    NavigationLink("View MobileGestalt Data", destination: GestaltDataView())
                }
            }
            .navigationTitle("Filesystem")
        }
    }
}
