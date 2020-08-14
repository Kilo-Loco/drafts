# AWS Amplify + Swift Combine = ❤️

While there may be a lot of great things that are included in the AWS Amplify 1.1 release for iOS, the thing that I am most excited about is the support for Combine. Combine is a first party reactive framework that makes it easy to deal with asynchronous events in a declarative way.

Using the libraries is very straight forward already since almost all the API work with the `Swift.Result` type, but now code can be even cleaner AND reactive all while avoiding callback hell. Now that's just amazing to me!

One of the most common use cases developers come across when programming an app that performs networking requests is performing one or more tasks, then taking the data from those tasks to perform another task.

Here's what it might look like if you wanted to identify objects in an image and upload the image asynchronously, then create post from the image with callbacks/closures:

```swift
func savePostWithCallbacks() {
    let imageKey = UUID().uuidString + ".jpg"

    // Label objects in image
    dispatchGroup.enter()
    _ = Amplify.Predictions.identify(type: .detectLabels(.labels), image: imageUrl) { result in
        switch result {
        case .success(let identifyResult):
            let labelsResult = identifyResult as! IdentifyLabelsResult
            labels = labelsResult.labels.map(\.name)
            dispatchGroup.leave()

        case .failure(let error):
            print(error)
        }
    }

    // Upload image to storage
    dispatchGroup.enter()
    _ = Amplify.Storage.uploadFile(key: imageKey, local: imageUrl) { result in

        switch result {
        case .success:
            dispatchGroup.leave()

        case .failure(let error):
            print(error)
        }
    }

    // Only save the post once image has been uploaded and object in
    // the image have been identified
    dispatchGroup.notify(queue: .global()) {
        let post = Post(imageKey: imageKey, tags: self.labels)
        _ = Amplify.API.mutate(request: .update(post)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let post):
                    print("Post saved - \(post)")

                case .failure(let error):
                    print(error)
                }

            case .failure(let error):
                print("Event error - \(error)")
            }
        }
    }
}
```

And here's what that same process looks like using Combine:

```swift
@State var token: AnyCancellable?
    func savePostWithCombine() {
        let imageKey = UUID().uuidString + ".jpg"
        
        // Label objects in image
        let getImageTags = Amplify.Predictions.identify(type: .detectLabels(.labels), image: imageUrl)
            .resultPublisher
            .mapError { PostError.failedToGetTags(error: $0) }
            
        // Upload image to storage
        let uploadImage = Amplify.Storage.uploadFile(key: imageKey,local: imageUrl)
            .resultPublisher
            .mapError { PostError.failedToUploadImage(error: $0) }
        
        token = Publishers.CombineLatest(getImageTags, uploadImage)
            
            // Only save the post once image has been uploaded and object in
            // the image have been identified
            .flatMap { identifyResult, _ -> AnyPublisher<Post, PostError> in
                let labelsResult = identifyResult as! IdentifyLabelsResult
                let tags = labelsResult.labels.map(\.name)
                let post = Post(imageKey: imageKey, tags: tags)
                return Amplify.API.mutate(request: .update(post))
                    .resultPublisher
                    .tryMap { try $0.get() }
                    .mapError { PostError.failedToGetTags(error: $0) }
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { print($0) },
                receiveValue: { print("post saved - \($0)") }
            )
    }
```

So you might be able to see what we use the ❤️ when talking about Combine 😊

Let's take a peek at the new Combine APIs that are available by going through an example of what the code might look like for a social media app.

### Sign Up

First things first, we can't have a social media site without users, so let's sign them up.
```swift
// 1
@State var signUpToken: AnyCancellable?
func signUp() {
    // 2
    signUpToken = Amplify.Auth.signUp(username: username, password: password)
        // 3
        .resultPublisher
        // 4
        .receive(on: DispatchQueue.main)
        // 5
        .sink(
            // 6
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Sign in error: \(error)")
                }
            },
            // 7
            receiveValue: { result in
                // 8
                switch result.nextStep {
                case .confirmUser:
                    break

                case .done:
                    break
                }
            }
        )
}
```

1. Since we are working with Combine and Publishers, it is important that we always have a "token" object that will allow the publisher to stay alive even after the function has completed.
2. We can see here that we are assigning a value to the token by starting off with the same function signature that we are already used to when using `Auth.signUp`.
3. This is the publisher itself. In some cases we will have a `resultPublisher` in others, we will see that the original function signature has been overloaded to return a Publisher.
4. Since our Sign Up flow will most-likely involve additional steps like confirmation, which is dealing directly with UI, I want to make sure that I handle the result on the main thread. If I didn't intend to modify UI, omitting this step would be fine.
5. Our sink is where we can observe what is actually going on in regards to the resulting value, errors, or the completion of the stream.
6. Just like any Combine `sink`, we can receive a completion on a stream, stopping it from emitting any more values. Errors also cause streams to complete and this is where we can handle them.
7. The `receivedValue` is the object that we are looking for when the happy path succeeds.
8. The `result` is the same type as it would be if we were using closures/callbacks, meaning that this is an `AuthSignUpResult` which may or may not have a `nextStep` that needs to be handled.

### Sign In

Once we have the user created in our backend, it's time to let them sign into the app.
```swift
@State var signInToken: AnyCancellable?
func signIn() {
    // 1
    signInToken = Amplify.Auth.signIn(username: username, password: password)
        .resultPublisher
        .sink(
            receiveCompletion: {
                // 2
                if case .failure(let error) = $0 {
                    print("Sign in error: \(error)")
                }
            },
            receiveValue: { result in
                // 3
                print("Successful result: \(result)")
            }
        )
}
```

For the most part, the layout of the publishers will be similar to that of the Sign Up code. We do have a few differences though:
1. We are using a seperate "token" to hang on to the reference of the `Auth.signIn` `sink`.
2. Instead of passing in `completion` to the closure, I've decided to use the short hand to check if `$0` is an error.
3. Here we are simply printing out the result, but you would most likely want to do any additional work here while you still have access to the `username` and `password` of the user. In my case, I plan on using `HUB` to handle state change.

### Observe Session Status

If you like to keep things easier to maintain like I do, then we should use `HUB` to listen to the different `Auth` events and update the state accordingly.

```swift
@State var authHubToken: AnyCancellable?
func observeAuthEvents() {
    // 1
    authHubToken = Amplify.Hub.publisher(for: .auth)
    
        // 2
        .compactMap { payload -> Bool? in
            let isSignedIn: Bool

            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                isSignedIn = true

            case HubPayload.EventName.Auth.signedOut:
                isSignedIn = false

            default:
                return nil
            }

            return isSignedIn
        }
        
        // 3
        .receive(on: DispatchQueue.main)
        
        // 4
        .sink { isSignedIn in
            if isSignedIn {
                // handle sign in
            } else {
                // handle sign out
            }
        }
}
```

So now we are really starting to see some of the power of using Combine. Being able to take a complex object and transform it into the relevant value makes it so much easier to understand what's going on in our code.
1. `HUB.publisher` is one of the APIs that are immediately returning a publisher on which we can perform operations like `compactMap` and `sink`.
2. `.compactMap` is taking the payload provided by `Hub.publisher` and transforming it into a simple `Bool` that we can use to determine the user's session state. `.compactMap` is much more useful in this situation than `.map` because it allows us to return `nil`, which prevents the `sink` from firing during invalid events.
3. Up until this point, all our work has been performed on a background thread, but once we enter the `sink` we will most likely be updating properties that affect UI, which is why we need to return to the main thread.
4. We take our simple `Bool` value and update our user's state accourdingly.

### Get Posts

Now that the user has signed in, we have to show them their Feed. It's time to get those `Post`'s

```swift
@State var getPostsToken: AnyCancellable?
func getPosts() {
    // 1
    getPostsToken = Amplify.DataStore.query(Post.self)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    // handle error
                    break

                case .finished:
                    // handle completed stream
                    break
                }
            },
            
            // 2
            receiveValue: { posts in
                // populate UI with posts
            }
        )
}
```

1. `DataStore.query` is another API that has been overloaded to allow us to use it directly as a Publisher, so we can apply any relevant operators to it as we would any other Publisher.
2. Our `receiveValue` block is where we would handle the `posts` and likely do something like `self.posts = post` so our UI reflects what was provided by DataStore.

### Observe Post Events

We could call `getPosts()` whenever we receive events that indicate there was a change in the data, but using `DataStore.publisher` makes it much more simple by allowing us to observe the specific change to the individual Post, making it easier to setup specific behavior for each type of change.

```swift
@State var observePostsToken: AnyCancellable?
func observePosts() {
    // 1
    observePostsToken = Amplify.DataStore.publisher(for: Post.self)
        // 2
        .compactMap { event -> (mutationType: MutationEvent.MutationType, post: Post)? in
            guard
                let mutationType = MutationEvent.MutationType(rawValue: event.mutationType),
                let post = try? event.decodeModel(as: Post.self)
            else { return nil }

            return (mutationType, post)
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // handle error
                }
            },
            receiveValue: {
                // 3
                let (mutationType, post) = $0
                
                // 4
                switch mutationType {
                case .create:
                    break

                case .update:
                    break

                case .delete:
                    break
                }
            }
        )
}
```

1. `DataStore.publisher` is a Publisher, as its name suggests, and allows us to observe the different mutation events for a specified `Model` type. In our case, we will be observing changes for `Post`.
2. We are using `compactMap` again to help filter out irrelevant data as well as change the output to a tuple `(mutationType: MutationEvent.MutationType, post: Post)`.
3. Since the value is now a tuple, one way to interact with the values is to assign the values to constants by using `let (mutationType, post)` which will map to the values of the tuple respectively.
4. Now that we're working with `mutationType: MutationEvent.MutationType` we can switch off the three different cases and update the UI accordingly using the proper animations.

### Create Post

Finally, the most important part of our app, the ability to actually create a `Post`. This is a slightly more complex operation because we would have to upload the image to Storage and create a `Post` object in our database. We may also want to do something like log analytics whenever we successfully create a `Post` to help us understand more about our user's and their posting habits.

```swift
@State var createPostToken: AnyCancellable?
func createPost() {
    // 1
    guard let imageData = image?.jpegData(compressionQuality: 0.5) else { return }
    let key = UUID().uuidString + ".jpg"

    // 2
    createPostToken = Amplify.Storage.uploadData(key: key, data: imageData)
    
        // 3
        .resultPublisher
        
        // 4
        .mapError { CreatePostError.failedUpload(error: $0) }

        // 5
        .flatMap { _ in
            Amplify.DataStore.save(
                Post(
                    userId: userId,
                    imageKey: key,
                    caption: caption
                )
            )
                // 6
                .mapError { CreatePostError.failedSave(error: $0) }
        }
        
        // 7
        .handleEvents(receiveOutput: { post in
            let event = BasicAnalyticsEvent(name: "postCreated")
            Amplify.Analytics.record(event: event)
        })
        
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // handle error
                }
            },
            receiveValue: { post in
                // 8
                print("Created post: \(post)")
            }
        )
}
```

1. We need the image data to upload to Storage, so we conver the `UIImage` to JPG data with a compression of `0.5` so upload is much smoother. The amount of compression is totally up to you though.
2. Here we are using the `Storage.uploadData` with the `key` and `imageData` that we just created.
3. We are using `resultPublisher` here because `Storage.uploadData` provides two different publishers: `resultPublisher` and `progressPublisher`. I'm not going to implement the latter, but it would be a good publisher to use to let the user know how far along they are in the upload process.
4. Since we are chaining our operations (upload image > save `Post` > record analytics event > `sink`), we need to make sure that we are working with a consistent error type throughout our chain. Thus, we use `.mapError` to convert the `StorageError` to a custom error type called `CreatePostError`.
5. Another operator we need to use when chaining publishers is `.flatMap`. This allows us to map the output of one publisher (`Storage.uploadData.resultPublisher`) to the output of another, in this case, `DataStore.save` which outputs a publisher of type `AnyPublisher<Post, DataStoreError>` 
6. Since we are inside `flatMap` and need to stay consistent with the error through the entire chain, we need to use `mapError` to convert the `DataStoreError` to a `CreatePostError`.
7. Once we have gone through the chain, we want to record events whenever a user successfully posts to the Feed. This is where `.handleEvents` comes in, specifically the `receiveOutput` argument. When working with `receiveOutput`, we have access to the desired output, `Post` in this case, and we can use any useful information about the post to include into our Analytics event. The example here doesn't use any info from the `Post` but the event is still recorded with the basic info.
8. At the very end of the chain, we are provided with our saved `Post` thanks to the output from `DataStore.save`. We could do whatever we want with this `Post`, or we can choose to simply ignore it since we will have observed the created event in our `observePosts` publisher.

Now depending on your coding style, you might be willing to wrap up the functionality of these chained publishers into their own functions. The end result could be something as condensed as this:

```swift
@State var createPostToken: AnyCancellable?
func createPost() {
    let key = UUID().uuidString + ".jpg"
    let post = Post(userId: userId, imageKey: key, caption: caption)

    createPostToken = AnyPublisher<Post, CreatePostError>
        .upload(image, key: key)
        .save(post)
        .recordEvent(.postCreated)
        .sink(
            receiveCompletion: { print($0) },
            receiveValue: { print($0) }
        )
}
```

### Wrapping Up

There are still several use cases that weren't covered in this article, but I already know that adopting them will be very straight forward since the APIs tend to follow similar patterns.

As reactive programming and declarative UI become more relevant in the native iOS space, it only makes sense to continue to work and grow with community expextations. Anything else just feels outdated 🤷🏽‍♂️

So now the only question is, "Are you going to start adding Combine to your Amplify projects"?
