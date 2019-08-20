Quickstart/Investigation: Native Sign In With Apple
==============================

### Requirements 
- [Xcode 11 beta 3 (11M362V)](https://developer.apple.com/news/releases/) (You should be able to use your own Apple ID)
- iOS 13 Simulator _(Running Beta iOS on your device may end in tears)_

### Application basics

For the sake of time, it's presumed you can setup a basic app with a `UIStackView` outlet, if not
download the sample and you can then walk through the code.

**Note: I had problems with this not working with my own bundle identifier, changing it to Apple's seemed to make
everything work in the simulator: `com.example.apple-samplecode.juice`

Add a `UIStackView` to your MainStoryboard and create an outlet in your `ViewController.swift`

```swift
 @IBOutlet weak var loginProviderStackView: UIStackView!
```

Add the `AuthenticationServices` Framework to your `ViewController.swift`

```swift
import AuthenticationServices
```

### Integration overview
* Button
* Authorization
* Verficiation
* Handling Changes

### Adding the Sign In With Apple Button

Adding an Apple Sign In button to your Stack View.

```swift
func setupProviderLoginView() {
  // Create Button
  let authorizationButton = ASAuthorizationAppleIDButton()
  
  // Add Callback on Touch
  authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
  
  //Add button to the UIStackView
  self.loginProviderStackView.addArrangedSubview(authorizationButton) 
}
```

Call this func in `viewDidLoad`

```swift
override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupProviderLoginView()
    }
```

### Authorization

Add a handler function to start a request when the Apple Button is pressed.

```swift
@objc
func handleAuthorizationAppleIDButtonPress() {
    // Create the authorization request
    let request = ASAuthorizationAppleIDProvider().createRequest()
    
    // Set Scopes
    request.requestedScopes = [.email, .fullName]
    
    // Setup a controller to display the authorization flow
    let controller = ASAuthorizationController(authorizationRequests: [request])
    
    // Set delegates to handle the flow response.
    controller.delegate = self
    controller.presentationContextProvider = self
    
    // Action
    controller.performRequests()
}
```

The only supported scopes appear to be email and fullname, although you can technically specify your own.<br />
Example:

```swift
request.requestedScopes = [.email, .fullName, ASAuthorization.Scope("openid")]
```

Reference: [ASAuthorization.scope](https://developer.apple.com/documentation/authenticationservices/asauthorization/scope)

Before moving forward with all the code, let's remove the code errors by providing basics delegate
handlers and adding the Sign In With Apple capability to your app.

#### Adding the `presentationContextProvider` for the `ASAuthorizationController`

Add the following to the end of the `ViewController` file. This enables the Authroization flow UI
to be displayed from our controller.

```swift
extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
```

#### Adding a stub `delegate` for the `ASAuthorizationController`

Add the following to the end of the `ViewController` file. This code will handle the response sent
to the `ASAuthorizationController You will be coming back to this one later.

```swift
extension ViewController: ASAuthorizationControllerDelegate {
}
```
#### Adding the Sign In With Apple Capability

To enable Sign In With Apple in your application, you need to officially enable this functionality. This is done
through setting `entitlements` as follows:

![add-capabilities](https://user-images.githubusercontent.com/928115/60961015-babd4280-a2fa-11e9-8f95-4fa15d55861e.png)

#### Run the app

You should see the following UI Dialog after clicking the Sign In With Apple button, notice that there is no default email option. 
The user must activley decice.

![default-auhtorization-dialog](https://user-images.githubusercontent.com/928115/60961094-ea6c4a80-a2fa-11e9-998c-3445ce015179.png)

If you are on a device, I imagine it will display Touch ID / Face ID.

### Processing Authroization Callback Success/Errors

Add the following to the end of your `ViewController` file.

```swift
extension ViewController: ASAuthorizationControllerDelegate {
    
    // Handle authorization success
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print("User Identifier: \(appleIDCredential.user)")
            print("Full Name: \(appleIDCredential.fullName?.givenName ?? "No Name")")
            print("Email: \(appleIDCredential.email ?? "No Email Provided")")
            print("Real Person Status: \(appleIDCredential.realUserStatus.rawValue)")
            print("ID Token: \(String(data: appleIDCredential.identityToken!, encoding: .utf8) ?? "No ID Token Returned")")
            print("AuthorizationCode: \(String(data: appleIDCredential.authorizationCode!, encoding: .utf8) ?? "No Authorization Code Returned")")
        }
    }
    
    // Handle authorization failure
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
    }
}
```

For more info on the Apple ID Credential object see [ASAuthorizationAppleIDCredential](https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidcredential)

Now **Run the app**

#### What does ther developer receive?
- UUID, team-scoped user ID (Unique to your teams apps?)
- Verification Data
  - ID Token, Authorization Code
- Account Information (Optional)
  - Name, Verified Email Address (Original or relay address)
- Real user indiciator
  - High confidence indicator that the user is legit

Example out from our app:

```text
User Identifier: 000593.4655439c592d4057959973dd4fcdff18.1148
Full Name: Martin
Email: martin.walsh@gmail.com
Real Person Status: 1
ID Token: 
eyJraWQiOiJBSURPUEsxIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoiY29tLmV4YW1wbGUuYXBwbGUtc2FtcGxlY29kZS5qdWljZSIsImV4cCI6MTU2Mjc2MDM5NiwiaWF0IjoxNTYyNzU5Nzk2LCJzdWIiOiIwMDA1OTMuNDY1NTQzOWM1OTJkNDA1Nzk1OTk3M2RkNGZjZGZmMTguMTE0OCJ9.hCmE7H7EyzdJfGdpYvjwVcAUYUlWYjwegIIu8S06Zewhs6tAE78XJuJdNJvWDH1dRNkF4qPtpa9JEmwfhsgSuqIPwZ1NthX2lOVu86uPZkdKSQubBSeqwQQfj6r2_yGDuxts-C9NqkRKB56E3BxIH_-ePfAo2BaK4zkMNYnEV1D4aU31DES6rbbIwXteoOeirYrfEeFiZ1Ki0O7oBJtaiDzBAfO-17NeG9Oz_Xl8jkbMHTvUKoZVJ3HWbAsbJxEVttOxsYaSHzHdsTmdr0H9AJoC0kN8wdw_ToI_96bf6oTOXwY91APB1f5t7E3kYY2pmJPEejM5-KIU1fpu_um5Ug
AuthorizationCode: c62a7b73c505643aea6dcef5e3678abd7.0.nvzt.F20v8uniV-ArymKwrCtY6A
```

**JWT Decoded**
```text
{
  "iss": "https://appleid.apple.com",
  "aud": "com.example.apple-samplecode.juice",
  "exp": 1562760396, 
  "iat": 1562759796,
  "sub": "000593.4655439c592d4057959973dd4fcdff18.1148"
}
```

_Note: ID Token exp appears to be around 10 minutes_

### Next Steps 

Somehow use this information to return an Auth0 authentication object.

### Authorization Change(s)

You also need to be aware of Authorization changes and handle these in the app, such as `Sign out` or
the Apple ID being revoked else where. This is out of scope in this document for now.

### References:
[https://developer.apple.com/videos/play/wwdc2019/706](https://developer.apple.com/videos/play/wwdc2019/706)

### Sign In With Apple Platforms
Available across all Apple platforms - iOS, tvOS, macOS, watchOS, JS (Web)