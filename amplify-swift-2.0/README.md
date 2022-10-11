# Introducing the AWS Amplify Library for Swift

The Amplify iOS team is announcing the release of version 2.0.0 of the Amplify Library for Swift. Please use this [GitHub](https://github.com/aws-amplify/amplify-ios) repo to inform the Amplify iOS team about features or issues, or visit the Amplify Discord server under the #ios-help channel.

## Highlights
Below is a high-level breakdown of the features we are announcing with Amplify Library for Swift version 2.0.0

### New Name
The Amplify Library for Swift is the new and improved version of Amplify iOS. This name change comes with the major improvements to the library, with the new support for macOS being a major deciding factor for the library no longer being referred to as Amplify iOS .

### Full Swift Integration 
The Amplify Library for Swift is now exclusively using Swift and provides developers the ability to add cloud-based Analytics, Auth, Data, Geo, Storage, and APIs to their apps. With this version, Swift developers will be able to debug and contribute to the underlying open-source codebase completely in Swift.

### Structured Concurrency
Since the Amplify Library for Swift is now fully written in Swift, one of its most popular features has made its way into the Amplify APIs. Most of the APIs for the supported categories now have the ability to use the recently release concurrency feature, async/await. Before structured concurrency, You might have written your API calls with your logic in a callback like this:
```swift
func signIn(username: String, password: String) {
    Amplify.Auth.signIn(username: username, password: password) { result in
        switch result {
        case .success:
            print("Sign in succeeded")
        case .failure(let error):
            print("Sign in failed \(error)")
        }
    }
}
```

Now you're able to write your Amplify calls like the code snippet below:
```swift
func signIn(username: String, password: String) async {
    do {
        _ = try await Amplify.Auth.signIn(username: username, password: password)
        print("Sign in succeeded")
    } catch {
        print("Sign in failed \(error)")
    }
}
```

### Beta macOS Support
The iOS development community made it very clear that macOS support was the most important [issue](https://github.com/aws-amplify/amplify-ios/issues/1124) to address with Amplify. We listened! The Amplify Library for Swift now supports a beta version of [Analytics](https://docs.amplify.aws/lib/analytics/getting-started/q/platform/ios/), [API](https://docs.amplify.aws/lib/graphqlapi/getting-started/q/platform/ios/), [Auth](https://docs.amplify.aws/lib/auth/getting-started/q/platform/ios/), [DataStore](https://docs.amplify.aws/lib/datastore/getting-started/q/platform/ios/), [Geo](https://docs.amplify.aws/lib/geo/getting-started/q/platform/ios/), and [Storage](https://docs.amplify.aws/lib/storage/getting-started/q/platform/ios/) for macOS development. You'll also be able to take advantage of the structured concurrency features on macOS as well.

### Other Notable Improvements
- Improved ability to debug Auth (sign-up/sign-in) and Storage (file upload/download)
- Removed calls to deprecated Apple APIs
- Built on top of the new AWS SDK for Swift

## In conclusion
We would love to have your feedback on this release and understand how we can help accelerate your productivity. Reach out on the [GitHub](https://github.com/aws-amplify/amplify-ios) repository, or through the Amplify Discord server under the #ios-help channel to help us prioritize features and enhancements.


To get started building iOS and/or macOS apps with Amplify, please visit the [Amplify Swift documentation]().