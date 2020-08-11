# AWS Amplify + Swift Combine = ❤️

While there may be a lot of great things that are included in the AWS Amplify 1.1 release for iOS, the thing that I am most excited about is the support for Combine.

Using the libraries is very straight forward already since almost all the API work with the `Swift.Result` type, but the fact that now code can be even cleaner AND reactive all while avoiding callback hell. Now that's just amazing to me!

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
        .sink(
            // 5
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Sign in error: \(error)")
                }
            },
            // 6
            receiveValue: { result in
                // 7
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
4. Our sink is where we can observe what is actually going on in regards to the resulting value, errors, or the completion of the stream.
5. Just like any Combine `sink`, we can receive a completion on a stream, stopping it from emitting any more values. Errors also cause streams to complete and this is where we can handle them.
6. The `receivedValue` is the object that we are looking for when the happy path succeeds.
7. The `result` is the same type as it would be if we were using closures/callbacks, meaning that this is an `AuthSignUpResult` which may or may not have a `nextStep` that needs to be handled.

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
3. We take our simple `Bool` value and update our user's state accourdingly.

### Get Posts

Now that the user has signed in, we have to show them their Feed. It's time to get those `Post`s

```swift
@State var getPostsToken: AnyCancellable?
func getTodos() {
    getPostsToken = Amplify.DataStore.query(Post.self)
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
            receiveValue: { posts in
                // populate UI with posts
            }
        )
}
```

### Observe Post Events
```swift
@State var observePostsToken: AnyCancellable?
func observePosts() {
    observePostsToken = Amplify.DataStore.publisher(for: Post.self)
        .compactMap { event -> (mutationType: MutationEvent.MutationType, post: Post)? in
            guard
                let mutationType = MutationEvent.MutationType(rawValue: event.mutationType),
                let post = try? event.decodeModel(as: Post.self)
            else { return nil }

            return (mutationType, post)
        }
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // handle error
                }
            },
            receiveValue: {
                let (mutationType, post) = $0

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

### Create Post
```swift
@State var createPostToken: AnyCancellable?
func createPost() {
    guard let imageData = image?.jpegData(compressionQuality: 0.5) else { return }
    let key = UUID().uuidString + ".jpg"

    createPostToken = Amplify.Storage.uploadData(key: key, data: imageData)
        .resultPublisher
        .mapError { CreatePostError.failedUpload(error: $0) }


        .flatMap { _ in
            Amplify.DataStore.save(
                Post(
                    userId: userId,
                    imageKeys: [key],
                    caption: caption
                )
            ).mapError { CreatePostError.failedSave(error: $0) }
        }
        .handleEvents(receiveOutput: { post in
            let event = BasicAnalyticsEvent(name: "postCreated")
            Amplify.Analytics.record(event: event)
        })
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // handle error
                }
            },
            receiveValue: { post in
                print("Created post: \(post)")
            }
        )
}
```

There are still several use cases that weren't covered in this article, but I already know that adopting them will be very straight forward since the APIs tend to follow similar patterns.

As reactive programming and declarative UI become more relevant in the native iOS space, it only makes sense to continue to work and grow with community expextations. Anything else just feels outdated 🤷🏽‍♂️

So now the only question is, "Are you going to start adding Combine to your Amplify projects"?
