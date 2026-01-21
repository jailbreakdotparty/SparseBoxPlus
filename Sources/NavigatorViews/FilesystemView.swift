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
                    NavigationLink(destination: AppListView()) {
                        ButtonLabel(text: "List Installed Apps", icon: "app")
                    }
                    .disabled(!appData.isSparseBoxReady)
                    NavigationLink(destination: BrowseFSView()) {
                        ButtonLabel(text: "Browse AFC (Media)", icon: "photo")
                    }
                    .disabled(!appData.isSparseBoxReady)
                    NavigationLink(destination: GestaltDataView()) {
                        ButtonLabel(text: "View MobileGestalt Data", icon: "doc")
                    }
                    .disabled(!appData.isSparseBoxReady)
                }
            }
            .navigationTitle("Filesystem")
        }
    }
}
