//
//  DerDieDas_Watch_AppApp.swift
//  DerDieDas Watch App Watch App
//
//  Created by Nicolas Lehmann on 18/06/26.
//

import SwiftUI

@main
struct DerDieDas_Watch_App_Watch_AppApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            WatchSearchView()
                .environmentObject(store)
        }
    }
}
