# Getting Started with AWS Amplify DataStore Multi-Auth for Android

Managing which users have access to specific content is a problem that most modern apps face. With the recent release, AWS Amplify DataStore allows you to define multiple authorization (multi-auth) types for your GraphQL data schemas. Multi-auth types make it easier to manage user access and enable personalized content for users once they sign in.

This article will cover how to get up and running with multiple authorization types for Amplify DataStore so you can keep your users' data protected and offer a better experience in your Android app.

## Prerequisites

To follow along, you should have the following prerequisites:

- An [AWS Account](https://portal.aws.amazon.com/billing/signup)
- Install Amplify CLI version 5.1.0 or later by running:
  ```bash
  $ curl -sL https://aws-amplify.github.io/amplify-cli/install | bash && $SHELL
  ```
- Android development experience
  - Logging to Logcat in Android Studio
  - Building simple UI
  - Handling user input
- [Android Studio Preview](https://developer.android.com/studio/preview) (Optional)
  - The UI will be built using Jetpack Compose, but XML can be used instead

## Configuring Amplify Categories

To create an Amplify app, run the following command at the root directory of your Android project:

```bash
$ amplify init
```

Respond to the prompts with the following answers:

```
? Enter a name for the project: <YourProjectName>
? Initialize the project with the above configuration? Yes
? Select the authentication method you want to use: AWS Profile
? Please choose the profile you want to use: default
```

> I hit **Enter** for each of these prompts to select the default answer.

Next, add the API category by entering the following command:

```bash
$ amplify add api
```

Use the following answers so your project can be properly configured to support multi-auth:

```
? Please select from one of the below mentioned services: GraphQL
? Provide API name: <YourApiName>
? Choose the default authorization type for the API: API key
? Enter a description for the API key: <YourDescription>
? After how many days from now the API key should expire (1-365): 7
? Do you want to configure advanced settings for the GraphQL API: **Yes, I want to make some additional changes.**
? Configure additional auth types: **Yes**
? Choose the additional authorization types you want to configure for the API: **Amazon Cognito User Pool**
? Do you want to use the default authentication and security configuration: **Default configuration**
? How do you want users to be able to sign in: **Username**
? Do you want to configure advanced settings: **No, I am done.**
? Enable conflict detection: **Yes**
? Select the default resolution strategy: **Auto Merge**
? Do you have an annotated GraphQL schema: **No**
? Choose a schema template: **Single object with fields**
? Do you want to edit the schema now: **Yes**
? Choose your default editor: **<YourFavoriteEditor>**
```

You have now set `API key` as the default authorization type and `Amazon Cognito User Pool` as the second authorization type. Since Cognito User Pools require a user to be authenticated, the Amplify Auth category was set up with the default configuration as well.

When prompted to edit the GraphQL schema, replace it with the following:

```graphql
type Post
  @model
  @auth(
    rules: [
      { allow: owner, provider: userPools, operations: [create, update, delete] },
      { allow: public, provider: apiKey, operations: [read] }
    ]
  ) {
  id: ID!
  content: String!
}
```

This simple `Post` object has two authentication rules:

1. a user authenticated with User Pools can create, update, and delete a `Post`
2. all other users, authenticated and unauthenticated, can read/query a `Post` using the API key

These rules would be common for social media and blogs, which allow all users to view content, but only allow authenticated users to create, update, or delete their own posts.

With the Amplify app fully configured locally, it's time to push the app to the backend. Run the following command in the terminal:

```bash
$ amplify push -y
```

Lastly, to ensure that a `Post` model has been generated in Kotlin and added to your project, run the following:

```bash
$ amplify codegen models
```

## Implementing on Android

The upcoming Android implementation will be based on a basic Jetpack Compose app and will use logging to Logcat to explore the behavior of multi-auth.

### Adding Dependencies

Before using the Amplify Libraries, add them to your build configuration. Include the following code in your app's **build.gradle** file:

```groovy
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    def amplifyVersion = '1.22.0'
    implementation "com.amplifyframework:core:$amplifyVersion"
    implementation "com.amplifyframework:aws-api:$amplifyVersion"
    implementation "com.amplifyframework:aws-auth-cognito:$amplifyVersion"
    implementation "com.amplifyframework:aws-datastore:$amplifyVersion"
    
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.1.5'
}
```

Then sync the new configuration with your project. You will see the following output in the **Build** console:

```
CONFIGURE SUCCESSFUL in 5s
```

### Configuring Plugins

With the dependencies installed to the project, Amplify is ready to be configured in the app. 

Start by creating a new Kotlin class called `MyApplication` (Right-click project namespace > **New** > **Kotlin Class/File** > **Class**) and add the following code:

```kotlin
package com.example.multiauthtmp

import android.app.Application
import android.util.Log
import com.amplifyframework.AmplifyException
import com.amplifyframework.api.aws.AWSApiPlugin
import com.amplifyframework.api.aws.AuthModeStrategyType
import com.amplifyframework.auth.cognito.AWSCognitoAuthPlugin
import com.amplifyframework.core.Amplify
import com.amplifyframework.datastore.AWSDataStorePlugin

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        configureAmplify()
    }

    private fun configureAmplify() {
        try {
            Amplify.addPlugin(AWSApiPlugin())
            Amplify.addPlugin(AWSCognitoAuthPlugin())
            val dataStorePlugin = AWSDataStorePlugin.builder()
                .authModeStrategy(AuthModeStrategyType.MULTIAUTH)
                .build()
            Amplify.addPlugin(dataStorePlugin)
            Amplify.configure(applicationContext)

            Log.i("kilo", "Initialized amplify")

        } catch (error: AmplifyException) {
            Log.e("kilo", "Could not init amplify", error)
        }
    }
}
```

Adding `AWSApiPlugin` and `AWSCognitoAuthPlugin` are the same as any other Amplify Android project. The `AWSDataStorePlugin` is modified to accept an auth strategy, which `AuthModeStrategyType.MULTIAUTH` is used in place of the default configuration. This modification configures DataStore to synchronize data based on authorization priority.

> You can learn more about authorization priority at [Multiple authorization types priority order](https://docs.amplify.aws/lib/datastore/setup-auth-rules/q/platform/android#multiple-authorization-types-priority-order).

### Functionality and UI

To test the capabilities and behaviors of multi-auth, make queries and mutations with authenticated and unauthenticated users. Since the default authentication and security configuration was selected during `$ amplify add api`, the user will need to authenticate using the app. Add the following methods to `MainActivity`:

```kotlin
private fun fetchCurrentAuthSession() {
    Amplify.Auth.fetchAuthSession(
        { Log.i("kilo", "Is signed in: ${it.isSignedIn}") },
        { Log.e("kilo", "Failed to fetch session", it) }
    )
}

private fun signUp() {
    val options = AuthSignUpOptions.builder()
        .userAttribute(AuthUserAttributeKey.email(), EMAIL)
        .build()
    Amplify.Auth.signUp(USERNAME, PASSWORD, options,
        { Log.i("kilo", "Result: $it") },
        { Log.e("kilo", "failed sign up", it) }
    )
}

private fun confirmSignUp(confirmationCode: String) {
    Amplify.Auth.confirmSignUp(USERNAME, confirmationCode,
        { Log.i("kilo", "Confirmed sign up: $it") },
        { Log.e("kilo", "Failed to confirm sign up", it) }
    )
}

private fun signIn() {
    Amplify.Auth.signIn(USERNAME, PASSWORD,
        { Log.i("kilo", "Signed in: $it") },
        { Log.e("kilo", "Failed sign in", it) }
    )
}

private fun signOut() {
    Amplify.Auth.signOut(
        { Log.i("kilo","Signed out") },
        { Log.e("kilo", "Failed to sign out", it) }
    )
}
```

Each method will be called on the tap of a button, and the results of each process will be logged to Logcat. To create Jetpack Compose buttons for each of these methods, add the following `Composable` function to `MainActivity`:

```kotlin
@Composable
private fun interactionUI() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = Modifier.fillMaxSize()
    ) {
        TextButton(onClick = ::fetchCurrentAuthSession) {
            Text(text = "Fetch Auth Session")
        }
        TextButton(onClick = ::signUp) {
            Text(text = "Sign Up")
        }

        val codeState = remember { mutableStateOf(TextFieldValue()) }
        TextField(
            value = codeState.value,
            onValueChange = { codeState.value = it },
            placeholder = { Text("Confirmation Code") }
        )

        TextButton(onClick = { confirmSignUp(confirmationCode = codeState.value.text) }) {
            Text(text = "Confirm Sign Up")
        }
        TextButton(onClick = ::signIn) {
            Text(text = "Sign In")
        }
        TextButton(onClick = ::signOut) {
            Text(text = "Sign Out")
        }
    }
}
```

To display `interactionUI`, add the following to code to `onCreate`:

```kotlin
setContent {
    MultiAuthTmpTheme {
        interactionUI()
    }
}
```

Note that there is also a confirmation code `TextField` in the UI, allowing the user to enter the verification code sent to the email. Creating an authenticated user can now be done without having to rebuild the app.

To test the create, query, and delete functionality of multi-auth with Amplify DataStore; add the following methods to the `MainActivity`:

```kotlin
private fun queryPosts() {
    Amplify.DataStore.query(
        Post::class.java,
        { posts ->
            if (!posts.hasNext()) Log.i("kilo", "No posts")
            while (posts.hasNext()) {
                val post = posts.next()
                Log.i("kilo", post.toString())
            }
        },
        { Log.e("kilo", "Failed query", it) }
    )
}

private fun createPost() {
    val newPost = Post.builder()
        .content("My content ${Random.nextInt(0, 100)}")
        .build()
    Amplify.DataStore.save(newPost,
        {Log.i("kilo", "Saved post: $newPost") },
        { Log.e("kilo", "Failed to save", it) }
    )
}

private fun deleteFirstPost() {
    Amplify.DataStore.query(Post::class.java,
        { posts ->
            posts.next()?.let { post ->
                Amplify.DataStore.delete(post,
                    { Log.i("kilo", "Deleted post") },
                    { Log.e("kilo", "Failed to delete", it) }
                )
            }
        },
        { Log.e("kilo", "Failed query", it) }
    )
}
```

Each of these methods will log their respective results to Logcat, making it easy to see what `Post` objects are in the table by performing a query, or logging a successful creation or deletion of a `Post` object.

To connect these methods to buttons, add the following code to the same `Column` as the authentication buttons:

```kotlin
TextButton(onClick = ::queryPosts) {
    Text(text = "Query Posts")
}
TextButton(onClick = ::createPost) {
    Text(text = "Create Post")
}
TextButton(onClick = ::deleteFirstPost) {
    Text(text = "Delete First Post")
}
```

### Testing Multi-Auth

An authenticated user will be required to explore the different behaviors of the authorization types. Use the app to create an authenticated user and sign in. Once signed in, test the authorization rules of the `Post` model.

#### Authenticated User

To start, run a query on the `Post` table by tapping the **Query Post** button in the app. You will see the following:

```
No posts
```

As expected, nothing has been created, so no posts can be logged to Logcat.

Next, tap **Create Post** twice, then **Query Post** to see the following output:

```
Post {
    id=895d2356-b67b-438c-a9e8-699cb00762b0, 
    content=My content 91, 
    createdAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:57.138Z'}, 
    updatedAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:57.138Z'}
}
Post {
    id=e220dd30-c839-4064-b386-94a3a9fd28ce, 
    content=My content 90, 
    createdAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}, 
    updatedAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}
}
```

Now there are two `Post` objects in the database.

The last authenticated test is to delete one of the posts. Tap **Delete First Post**, then **Query Post** to see the following result:

```
Post {
    id=e220dd30-c839-4064-b386-94a3a9fd28ce, 
    content=My content 90, 
    createdAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}, 
    updatedAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}
}
```

The first post has been deleted, so only one `Post` object is logged.

To verify that the data has been created and deleted successfully, run the app again and tap **Query Posts** to make sure only one `Post` remains.

#### Unauthenticated User

Now that there is some data in the `Post` table, test the behavior of an unauthenticated user.

First, sign out by tapping **Sign Out**, then **Fetch Auth Session** to verify that you're no longer signed in. The output should indicate that you are no longer signed in:

```
Signed out
```

Next, run the same tests as done for an authenticated user. Tap **Query Posts**. You will see the following output:

```
Post {
    id=e220dd30-c839-4064-b386-94a3a9fd28ce, 
    content=My content 90, 
    createdAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}, 
    updatedAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}
}
```

Since `Post` objects can be read by the public using `API key`, the `Post` from the authenticated user can be queried by the unauthenticated user.

Attempt to create a new `Post` object as an unauthenticated user by tapping **Create Post**, then **Query Posts**. Observe the following output:

```
Post {
    id=e220dd30-c839-4064-b386-94a3a9fd28ce, 
    content=My content 90, 
    createdAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}, 
    updatedAt=Temporal.DateTime{offsetDateTime='2021-07-20T19:55:59.084Z'}
}
Post {
    id=140BB206-3591-4E7E-B60A-16C4DD61EA37, 
    content=My content 38, 
    createdAt=null, 
    updatedAt=null'}
}
```

The unauthenticated user can still create `Post` objects and save them locally. The `Post` authorization rules only apply to synchronizing the data with the backend, not to CRUD (create, read, update, delete) operations locally.

Another difference you'll notice is that `createdAt` and `updatedAt` are `null`. This is because `createdAt` and `updatedAt` will only be updated when synced to the backend. Since this new object is not synced to the backend, those values remain `null`.

The next test is deleting the first `Post`, which was created by the authenticated user. Tap **Delete First Post**, then **Query Posts** to get the following results:

```
Post {
    id=140BB206-3591-4E7E-B60A-16C4DD61EA37, 
    content=My content 38, 
    createdAt=null, 
    updatedAt=null'}
}
```

In the output above, there is only one `Post` being returned in the array, the one created by the unauthenticated user. As mentioned previously, CRUD operations will still work locally for unauthenticated users, but will not affect the backend data if the authorization rules do not allow the operation. This behavior can be useful for apps that allow unauthenticated users to have limited access while giving authenticated users the advantage of keeping data synchronized across app instances.

It's important to keep in mind that the local data from the unauthenticated user can end up being synced with the backend if the user signs in and starts performing CRUD operations. This can be beneficial for keeping the user experience consistent after authenticating. However, if this is not the desired user experience, performing `Amplify.DataStore.clear()` and `Amplify.DataStore.start()` during sign in and sign out will clear the local database.

## Clean Up

Now that you have finished testing multiple authorization types with Amplify DataStore, it's recommended that you delete your Amplify app if you aren't going to use it anymore. This ensures that your resources won't be abused in the event someone gains access to your project's credentials.

To delete all the local Amplify associated files and the Amplify project in the backend, run the following command:

```bash
$ amplify delete
```

> This action cannot be undone. Once the project is deleted, you cannot recover it and will have to reconfigure the categories and the project configuration files if you need to use the project again.

## Conclusion

Now you know how to configure and use multiple authorization types with Amplify DataStore on Android. To learn more about different authorization scenarios, check out [Setup authorization rules](https://docs.amplify.aws/lib/datastore/setup-auth-rules/q/platform/android). If you have additional ideas to improve the experience of using Amplify for Android, [please leave us a feature request on GitHub](https://github.com/aws-amplify/amplify-android/issues/new), or come [chat with us on Discord](https://discord.gg/amplify).