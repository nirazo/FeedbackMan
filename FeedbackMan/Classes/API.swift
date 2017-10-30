import Foundation

protocol API {
    var buildURL: String { get }
    var baseURL: String { get }
    var path: String { get }
    var parameters: [String: Any] { get }
    var body: Data { get }
}

public struct FeedbackData {
    var userName: String = ""
    var title: String = ""
    var description: String = ""
    var appName: String = ""
    var viewControllerName: String = ""
    var deviceName: String = ""
    var osVersion: String = ""
    var appVersion: String = ""
    var image: UIImage?

    func createFormattedText() -> String {
        var formattedText = String()
        formattedText += "[Name]\r\n\(userName)\r\n"
        formattedText += "[Description]\r\n\(description)\r\n"
        formattedText += "[App Name]\r\n\(appName)\r\n"
        formattedText += "[App Version]\r\n\(appVersion)\r\n"
        formattedText += "[Device Name]\r\n\(deviceName)\r\n"
        formattedText += "[OS Version]\r\n\(osVersion)\r\n"
        formattedText += "[Current ViewController]\r\n\(viewControllerName)\r\n"
        return formattedText
    }
    
    init() {
        // Intentionally unimplemented
    }
}

enum SlackAPI: API {
    case chatPostMessage(fbdata: FeedbackData)
    case fileUpload(fbdata: FeedbackData)
    
    static let token = FeedbackManManager.APIConstants.token
    static let channel = FeedbackManManager.APIConstants.channel
    var buildURL: String {
        return "\(baseURL)\(path)"
    }
    
    var baseURL: String {
        return "https:" + "//" + "slack.com" + "/" + "api"
    }
    
    var path: String {
        switch self {
        case .chatPostMessage(fbdata: _): return "/" + "chat.postMessage"
        case .fileUpload(fbdata: _): return "/" + "files.upload"
        }
    }
    
    var parameters: [String: Any] {
        var params: [String: Any] = ["token": SlackAPI.token]
        switch self {
        case .chatPostMessage(fbdata: let fbdata):
            params["text"] = fbdata.createFormattedText()
            params["channel"] = SlackAPI.channel
            return params
        case .fileUpload(fbdata: let fbdata):
            params["file"] = fbdata.image!
            params["title"] = fbdata.title
            params["channels"] = SlackAPI.channel
            params["initial_comment"] = fbdata.createFormattedText()
            return params
        }
    }
    
    var body: Data {
        return Data()
    }
}

enum JiraAPI: API {
    
    case createIssue()
    case attachFile(issueKey: String, image: UIImage)
    
    static let host = JiraManager.JiraConstants.host
    static let projectID = JiraManager.JiraConstants.projectID
    var buildURL: String {
        return "\(baseURL)\(path)"
    }
    
    var baseURL: String {
        return "https://\(JiraAPI.host)"
    }
    
    var path: String {
        switch self {
        case .createIssue(): return "/rest/api/2/issue"
        case .attachFile(issueKey: let issueKey, _): return "/rest/api/2/issue/\(issueKey)/attachments"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .createIssue(): return [:]
        case .attachFile(_, image: let image):
            let params: [String: Any] = ["file": image]
            return params
        }
    }
    
    var body: Data {
        var project = [String: String]()
        project["id"] = JiraAPI.projectID
        var issueType = [String: String]()
        issueType["id"] = "10004"
        
        var body = [String: Any]()
        body["project"] = project
        body["summary"] = "Sample bug"
        body["description"] = "バグが発生しました！"
        body["issuetype"] = issueType
        
        var fields = [String: Any]()
        fields["fields"] = body
        
        let jsonData = try! JSONSerialization.data(withJSONObject: fields, options: [])
        return jsonData
    }
}
