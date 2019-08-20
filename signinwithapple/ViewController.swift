//
//  ViewController.swift
//  signinwithapple
//
//  Created by Martin Walsh on 10/07/2019.
//  Copyright © 2019 Martin Walsh. All rights reserved.
//

import UIKit
import AuthenticationServices

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

class ViewController: UIViewController {
    
    @IBOutlet weak var loginProviderStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupProviderLoginView()
    }
    
    func setupProviderLoginView() {
        // Create Button
        let authorizationButton = ASAuthorizationAppleIDButton()
        
        // Add Callback on Touch
        authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        
        //Add button to the UIStackView
        self.loginProviderStackView.addArrangedSubview(authorizationButton)
    }
    
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        // Create the authorization request
        let request = ASAuthorizationAppleIDProvider().createRequest()
        
        // Set Scopes
        request.requestedScopes = [.email, .fullName, .init("access_token")]

        // Setup a controller to display the authorization flow
        let controller = ASAuthorizationController(authorizationRequests: [request])

        // Set delegate to handle the flow response.
        controller.delegate = self
        controller.presentationContextProvider = self
        
        // Action
        controller.performRequests()
    }
}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

extension ViewController: ASAuthorizationControllerDelegate {
    
    // Handle authorization success
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            print("\n\n\n\n------------ RESPONSE FROM APPLE ----------------\n\n\n\n")

            print("User Identifier: \(appleIDCredential.user)")
            print("Full Name: \(appleIDCredential.fullName?.givenName ?? "No Name")")
            print("Email: \(appleIDCredential.email ?? "No Email Provided")")
            print("Real Person Status: \(appleIDCredential.realUserStatus.rawValue)")
            print("ID Token: \(String(data: appleIDCredential.identityToken!, encoding: .utf8) ?? "No ID Token Returned")")
            print("AuthorizationCode: \(String(data: appleIDCredential.authorizationCode!, encoding: .utf8) ?? "No Authorization Code Returned")")
            
            print("\n\n\n\n------------ RESPONSE FROM AUTH0 ----------------\n\n\n\n")

            let url = URL(string: "https://canary.au.auth0.com/oauth/token")!
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let parameters: [String: Any] = [
                "subject_token": String(data: appleIDCredential.authorizationCode!, encoding: .utf8)!,
                "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
                "client_id": "vN6u2W3sH8Ko5XLtwH3W7wCS0xpaKEeB",
                "audience": "urn:fadydev",
                "scope": "openid profile email offline_access"
            ]

            request.httpBody = parameters.percentEscaped().data(using: .utf8)

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                    let response = response as? HTTPURLResponse,
                    error == nil else {
                    print("error", error ?? "Unknown error")
                    return
                }

                guard (200 ... 299) ~= response.statusCode else {
                    print("statusCode \(response.statusCode)")
                    print("response \(response)")
                    return
                }

                let responseString = String(data: data, encoding: .utf8)
                print(responseString!)
            }
            
            task.resume()
        }
    }
    
    // Handle authorization failure
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
    }
}
