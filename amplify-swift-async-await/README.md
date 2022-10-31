# Using Async/Await with AWS Amplify Libraries for Swift

With the [release of the AWS Amplify Libraries for Swift](https://aws.amazon.com/blogs/mobile/introducing-the-aws-amplify-library-for-swift/), one of the most anticipated features is now generally available to iOS and macOS developers, async/await. Async/await is part of structured concurrency which allows developers to write asyncronous code in an easy-to-read manner by reducing the amount of callback blocks or chained operations with reactive frameworks liked Apple's Combine.

This article will show you how to use async/await with the Amplify Libraries for Swift and will demonstrate how efficiently you can write asynchronous code with this new release.

## Chaining Operations

One of the most common operations in most modern apps is to authenticate a user and keep that user signed in for subsequent launches of the app. This functionality can be implemented by using Amplify Auth's  Before the latest release of the Amplify Libraries for Swift, one solution would be to use Combine to chain operations using `flatMap` like the snippet below:

```swift
func autoSignIn() {
    Amplify.Auth.fetchAuthSession()
        .resultPublisher
        .map(\.isSignedIn)
        .filter { $0 }
        .flatMap { _ in
            Amplify.Auth.getCurrentUser()
                .publisher
        }
        .receive(on: DispatchQueue.main)
        .sink { completion in
            if case .failure(let error) = completion {
                print(error)
            }
        } receiveValue: { user in
            self.username = user.username
        }
        .store(in: &tokens)
}
```

This code is still legible and can be implemented in a similar way using Combine with some minor modifications, but the real improvement comes when async/await is used instead. The snippet below achieves the same as the snippet above, which uses Combine, but does so by taking advantage of the structured concurrency features directly supported by the Swift language:

```swift
func autoSignIn() async {
    do {
        let session = try await Amplify.Auth.fetchAuthSession()
        if session.isSignedIn {
            let user = try await Amplify.Auth.getCurrentUser()
            DispatchQueue.main.async {
                self.username = user.username
            }
        }
    } catch {
        print(error)
    }
}
```

Using async/await for a scenario like auto sign-in makes the code more concise and reduces the amount of knowledge that is needed of a reactive framework like Combine. It also helps prevent issues like memory leaks since there is no need to terminate subscriptions to any streams.

## Working with Publishers

Async/await is great for scenarios where only a single asynchronous value is needed to complete an operation. However, there are still many instances where publishers are very useful and it still makes sense to use Combine.

In an app that needs to be updated with the latest clients and their location, which will be displayed on a map, observing the stream of values in real-time is essential. With the new APIs, you can create a publisher that will observe new clients and update the map:

```swift
func observeClientsOnMap() {
    Amplify.Publisher.create(
        Amplify.DataStore.observe(Client.self)
    )
    .tryMap { try $0.decodeModel(as: Client.self) }
    .flatMap { client -> Future<[Geo.Place], Error> in
        Future { promise in
            Task {
                if let places = try? await Amplify.Geo.search(for: client.coordinates) {
                    promise(.success(places))
                }
            }
        }
    }
    .receive(on: DispatchQueue.main)
    .sink(
        receiveCompletion: { print($0) },
        receiveValue: { self.mapState.features.append($0) }
    )
    .store(in: &tokens)
}
```

The snippet above takes advantage of another new API offered by the Amplify Libraries, `Amplify.Publisher.create`. You can now create a Publisher from the `DataStore.observe` method which will send the latest version of the created, updated, or deleted model down the stream. As values are passed over time, different operations can be performed on those values. The snippet above observes the Client values and uses the async/await API provided from Amplify Geo to do a search on the coordinates.

This examples demonstrates that Combine and async/await can work together, giving the developer the option to choose the best tool for the job.

## Awaiting Values Over Time

Observing the progress of a file upload is a good use-case for when Combine may come in handy, but it's not the only way that progress can be observed. To allow developers to keep a consistent and consise codebase when working with the Amplify Libraries, the upload and download APIs for Amplify Storage offer a solution to monitor progress as the file transfer is executing.

In previous versions of the Amplify Libraries, observing progress would look like the following snippet:

```swift
func uploadVideo() {
    let key = "video.mp4"
    let uploadTask = Amplify.Storage.uploadData(
        key: key, 
        data: videoData
    )
    uploadTask.progressPublisher
        .receive(on: DispatchQueue.main)
        .sink { progress in
            self.uploadProgress = progress.fractionCompleted
        }
        .store(in: &tokens)
    uploadTask.resultPublisher
        .sink(
            receiveCompletion: { print($0) },
            receiveValue: { print("Uploaded video with key: \($0)") }
        )
        .store(in: &tokens)
}
```

While there's nothing wrong with the snippet above, it requires that two publishers are managed properly. If these publishers aren't handled properly, there's an opportunity for a memory leak or having the sinks removed from memory earlier than desired.

The following snippet shows how to observe progress by only using async/await:

```swift
func uploadVideo() async {
    do {
        let key = "video.mp4"
        let uploadTask = try await Amplify.Storage.uploadData(
            key: key,
            data: videoData
        )
        Task {
            for await progress in await uploadTask.progress {
                DispatchQueue.main.async {
                    self.uploadProgress = progress.fractionCompleted
                }
            }
        }
        let uploadedKey = try await uploadTask.value
        print("Uploaded video with key: \(uploadedKey)")
    } catch {
        print(error)
    }
}
```

Using async/await to monitor progress allows the developer to stick with the Swift language native features and removes the risk of improperly managing streams. It also keeps the code simple if the developer needs to chain other operations after the upload is complete.

## Conclusion

With the latest release of the AWS Amplify Libraries for Swift, developers are given the opportunity to use one of the Swift programming language's most popular new features, async/await. Reach out on the [GitHub](https://github.com/aws-amplify/amplify-ios) repository, or through the Amplify Discord server under the [#swift-help](http://discord.gg/invite/amplify) channel if you run into issues or need help.

To get started building iOS and/or macOS apps with Amplify, please visit the [Amplify Library for Swift documentation](https://docs.amplify.aws/start/q/integration/ios/).