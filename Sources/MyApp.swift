import FlyingFox
import SQLite3
import SwiftUI
import UniformTypeIdentifiers
import DeviceKit
import PartyUI

var weOnADebugBuild: Bool = false

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

@main
struct MyApp: App {
    @StateObject private var appData = AppData.shared
    
    init() {
        //setenv("RUST_LOG", "trace", 1)
        //set_debug(true)
        Task.detached {
            Utils.port = try Utils.reservePort()
            
            let server = HTTPServer(port: Utils.port)
            await server.appendRoute("GET /*", to: DirectoryHTTPHandler(root: URL.documentsDirectory))
            try await server.run()
        }
        
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
        #if DEBUG
        weOnADebugBuild = true
        #else
        weOnADebugBuild = false
        #endif
    }
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appData)
        }
    }
}

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

// thanks leminlimez for this method (skidded from Nugget Mobile)
@MainActor
func isOSVersionPatched() -> Bool {
    if doubleSystemVersion() < 17.4 {
        return true
    } else if doubleSystemVersion() > 26.1 {
        var osVersionString = [CChar](repeating: 0, count: 16)
        var osVersionStringLen = size_t(osVersionString.count - 1)

        let result = sysctlbyname("kern.osversion", &osVersionString, &osVersionStringLen, nil, 0)
        if result == 0 {
            if let build = String(validatingUTF8: osVersionString) {
                if build == "23C5027f" {
                    return false
                }
            } else {
                print("Failed to convert build number to String")
            }
        } else {
            print("sysctlbyname failed with error: \(String(cString: strerror(errno)))")
        }
        return true
    } else {
        return false
    }
}
