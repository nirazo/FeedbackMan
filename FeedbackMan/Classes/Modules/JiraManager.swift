//
//  JiraManager.swift
//  FeedbackMan
//
//  Created by Kenzo on 12/15/17.
//

import Foundation

public final class JiraManager {
    public struct JiraConstants {
        public static var host = ""
        public static var projectID = ""
        public static var mail = ""
        public static var pass = ""
    }

    public static let shared: JiraManager = {
        let instance = JiraManager()
        return instance
    }()

    private init() {
        // Intentionally unimplemented
    }
}
