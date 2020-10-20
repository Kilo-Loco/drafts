# Introduction

The first Amplify category you will be adding to the app will be Authentication. Amplify leverages [Amazon Cognito](https://aws.amazon.com/cognito/) under the hood for managing user pools and identity pools.

In this module you will learn how to sign up, confirm, login, and sign out a user.

Using the custom auth flow we created in [Module 2](02_create_a_flutter_app.md), we will be implementing the functionality for each screen in just a few lines of code.

## What You Will Learn

- Configure the Auth category
- Sign up a user
- Verify a user email
- Login an authenticated user
- Sign out an authenticated user

# Implementation

## Create the Authentication Service

To add the Authentication service to our Amplify project, we need to execute this command in the terminal at the root directory of our project:

```shell
amplify add auth
```

You will be prompted with a few questions regarding the configuration of the Auth service. Press the **Enter** key to select the default value for each question. The resulting output should look like this:

```shell
➜  photo_gallery git:(master) ✗ amplify add auth
Using service: Cognito, provided by: awscloudformation

 The current configured provider is Amazon Cognito.

 Do you want to use the default authentication and security configuration? Default configuration
 Warning: you will not be able to edit these selections.
 How do you want users to be able to sign in? Username
 Do you want to configure advanced settings? No, I am done.
```

Once the Auth resource is fully configured, you should get an output like the following:

```shell
Successfully added resource photogallery42b5391b locally
```

As stated by the output above, the resouce has only been added locally. In order to configure our backend with the changes we made locally, we must run this command:

```shell
amplify push
```

Before sending the local changes to the backend, Amplify CLI will display a status report to ensure you want to push the following changes:

```shell
Current Environment: dev

| Category | Resource name        | Operation | Provider plugin   |
| -------- | -------------------- | --------- | ----------------- |
| Auth     | photogallery42b5391b | Create    | awscloudformation |
? Are you sure you want to continue? Yes
```

You should see the following output once the Auth resource has been successfully created in the backend:

```shell
✔ All resources are updated in the cloud
```

You can also verify that your Auth resource has been properly configured by viewing the `/lib/amplifyconfiguration.dart` file and inspecting the `auth` values.

## Installing the Dependency

Back in Visual Studio Code, open `pubspec.yaml` and add the following dependency:

```yaml
... # amplify_core: '<1.0.0'

amplify_auth_cognito: '<1.0.0'

... # dev_dependencies:
```

Now save the file to have Visual Studio Code install the Amplify Auth Cognito plugin. You can also run `$ flutter pub get` from the terminal if the dependency isn't installed on save.

You should get an output of:

```shell
exit code 0
```

## Configure the Plugin

Now that the Auth dependency is installed, we can add the Auth plugin to our `Amplify` instance in `_MyAppState._configureAmplify()` of the `main.dart` file:

```dart
... // void _configureAmplify() async {

_amplify.addPlugin(authPlugins: [AmplifyAuthCognito()]);

... // try {
```

Now run the app and confirm you still get the success message in your logs.

If you continue to get the success message, now you can start implementing the fuctionality of your authentication flow. If not, repeat the steps above or visit the [Initialize Amplify](03_initialize_amplify.md) module and make sure you followed all the steps there.

## Implement Functionality

Back in the [Create A Flutter App](02_create_a_flutter_app.md) module, we implemented our `AuthService` to handle the updating of our `AuthState` based on the function called. Now we need to update each of our functions to only update the state when the user successfully completes each process.

In `auth_service.dart` add an `AuthCredentials` property in `AuthService`:

```dart
... // final authStateController = StreamController<AuthState>();

AuthCredentials _credentials;

... // void showSignUp() {
```

This property will be used to keep the `SignUpCredentials` in memory during the sign up process so a user can be logged in immediately after verifying their email address. If we didn't do this, the user would need to login manually by going to the login screen.

Update `signUpWithCredentials` to the following:

```dart
// 1
void signUpWithCredentials(SignUpCredentials credentials) async {
  try {
    // 2
    final userAttributes = {'email': credentials.email};

    // 3
    final result = await Amplify.Auth.signUp(
        username: credentials.username,
        password: credentials.password,
        options: CognitoSignUpOptions(userAttributes: userAttributes));

    // 4
    if (result.isSignUpComplete) {
      loginWithCredentials(credentials);
    } else {
      // 5
      this._credentials = credentials;

      // 6
      final state = AuthState(authFlowStatus: AuthFlowStatus.verification);
      authStateController.add(state);
    }
  
  // 7
  } on AuthError catch (authError) {
    print('Failed to sign up - ${authError.cause}');
  }
}
```

1. The function needs to be updated to be `async` as we will be using `await` to during the sign up process.
2. We must create `userAttributes` to pass in the user's email as part of the sign up.
3. We will pass in the username and password provided by the credentials, along with the user attributes containing the email to sign up with Cognito. Since this is an asynchronous process, we must use the `await` keyword.
4. If we successfully get a result back, the next step **should** be to verify their email. If the sign up process is complete for whatever reason, we will simply login the user to the app.
5. We will store the `SignUpCredentials` in `_credentials` for when the user verifies their email.
6. We update the `AuthState` to `verification` just as we did before, but only after successfully signing in and establishing that the sign up process is not complete.
7. If the sign up fails for any reason, we will simply print out the error to the logs.

Update `verifyCode` to this:

```dart
// 1
void verifyCode(String verificationCode) async {
 try {
   // 2
   final result = await Amplify.Auth.confirmSignUp(
       username: _credentials.username, confirmationCode: verificationCode);

   // 3
   if (result.isSignUpComplete) {
     loginWithCredentials(_credentials);
   } else {
     // 4
     // Follow more steps
   }
 } on AuthError catch (authError) {
   print('Could not verify code - ${authError.cause}');
 }
}
```

1. Just like we did with `signUpWithCredentials`, `verifyCode` needs to be marked as an asynchrous function as well.
2. We will use `_credentials` to supply the username and pass the code entered from `VerificationPage` to `confirmSignUp`.
3. If the result from `confirmSignUp` specifies that the sign up is complete, we then attempt to login the user with `_credentials` created during sign up. It's important to note that we are no longer updating the `AppState` during the success case as the user still needs to login to Amplify.
4. If the sign up in not complete, then use the result to find out what further steps need to be taken to complete the sign up. This should not happen in our app.

We've implemented the sign up portion of our auth flow, but now we need to update the login part. Update `loginWithCredentials` to this:

```dart
// 1
void loginWithCredentials(AuthCredentials credentials) async {
 try {
   // 2
   final result = await Amplify.Auth.signIn(
       username: credentials.username, password: credentials.password);

   // 3
   if (result.isSignedIn) {
     final state = AuthState(authFlowStatus: AuthFlowStatus.session);
     authStateController.add(state);
   } else {
     // 4
     print('User could not be signed in');
   }
 } on AuthError catch (authError) {
   print('Could not login - ${authError.cause}');
 }
}
```

1. Since `loginWithCredentials` takes `AuthCredentials` as a parameter, it will work whether it is passed `LoginCredentials` or `SignUpCredentials`.
2. We're passing the `AuthCredentials` `username` and `password` to the Amplify sign in method and awaiting the result.
3. If the sign in is successful and the `isSignedIn` property on the result confirms the user is now signed in, we update the state to `session`.
4. We should not reach this state in our app. If the user enters in the wrong credentials or gets any other error, it should result in our `catch` block.

Lastly, update the `logOut` method:

```dart
void logOut() async {
 try {
   // 1
   await Amplify.Auth.signOut();

   // 2
   showLogin();
 } on AuthError catch (authError) {
   print('Could not log out - ${authError.cause}');
 }
}
```

1. When we call `Auth.signOut()` without passing in any options, we will sign out only the user on this device as opposed to signing the user out on all devices.
2. We can reuse our `showLogin()` method to update the state and take the user back to the login screen once the sign out is successful.

Those are the only modifications needed to compliment our existing authentication flow. Build and run the app and you should be able to sign up, confirm your email, sign out, then sign in again.

![Authentication demo gif]()

You have successfully added user authentication to your photo gallery app 🤩

[Next](05_add_storage.md): Add Storage