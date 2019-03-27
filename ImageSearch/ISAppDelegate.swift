//
//  ISAppDelegate.swift
//  ImageSearch
//
//  Created by Edward Smith on 3/22/19.
//  Copyright © 2019 Edward Smith. All rights reserved.
//

import UIKit

@UIApplicationMain
class ISAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
        BNCLogSetDisplayLevel(.none)
        return true
    }
}
