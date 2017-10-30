import Foundation
final class ModalPresenter {
    
    var uiScreenImage: UIImage?
    var fbdata = FeedbackData()
    
    init() {
        self.uiScreenImage = ScreenCapture.takeScreenshot()
    }
    
    func setFeedbackData() -> FeedbackData {
        fbdata.appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
        fbdata.deviceName = UIDevice.current.modelName
        fbdata.osVersion = UIDevice.current.systemVersion
        fbdata.appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        return fbdata
    }
    
    func postFeedbackData(_ fbdata: FeedbackData, completion: @escaping (Result<Bool, APIError>) -> Void) {
        let slackApi = SlackAPI.fileUpload(fbdata: fbdata)
        
        APIClient.multipartPost(api: slackApi, completion:
            { data, response, error in
                if let data = data, let response = response {
                    print(response)
                    self.jsonSerialize(data: data, completion: completion)
                } else {
                    print("Post Failed")
                    completion(.failure(.other))
                }
            }
        )
    }
    
    func createJiraIssue(image: UIImage?, completion: @escaping (Result<Bool, APIError>) -> Void) {
        APIClient.createJiraIssue(api: JiraAPI.createIssue(), completion: { [weak self] data, response, error in
            if let data = data, let response = response {
                print("Jira response: \(response)")
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                    if let json = json, let key = json["key"] as? String, let image = image {
                        print("id: \(key)")
                        self?.attachImageToIssue(issueKey: key, image: image) { result in
                            UIApplication.shared.endIgnoringInteractionEvents()
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    print("success to post image to issue!!")
                                    completion(.success(true))
                                case .failure:
                                    completion(.failure(.other))
                                }
                            }
                        }
                    }
                } catch {
                    print("Wrong Response")
                    completion(.failure(.other))
                }
                completion(.success(true))
            } else {
                print("Post Failed")
                completion(.failure(.other))
            }
        })
    }
    
    func attachImageToIssue(issueKey: String, image: UIImage, completion: @escaping (Result<Bool, APIError>) -> Void) {
        let jiraApi = JiraAPI.attachFile(issueKey: issueKey, image: image)
        
        APIClient.multipartPost(api: jiraApi, completion:
            { data, response, error in
                if let _ = data, let response = response {
                    print("response: \(response)")
                    completion(.success(true))
                } else {
                    print("Post Failed")
                    completion(.failure(.other))
                }
        }
        )
    }
    
    func jsonSerialize(data: Data, completion: @escaping (Result<Bool, APIError>) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
            
            let isPostSucceeded = json?["ok"] as? Bool ?? false
            if isPostSucceeded == true {
                print("Post Success")
                completion(.success(true))
            } else {
                print("Wrong Response")
                completion(.failure(.other))
            }
            
        } catch {
            print("Serialize Error")
            completion(.failure(.other))
        }
    }
}
