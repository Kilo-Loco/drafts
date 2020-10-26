# Introduction

Now that you have implemented the Photo Gallery Flutter app, you can move onto initializing your Amplify project.

At this point, you will need to have the Amplify-Flutter Developer Preview version of the Amplify CLI installed on your machine. Once installed, we will initialize Amplify at the root directory of our project, install the Amplify dependencies into our project, and ensure Amplify is properly configured during each run of our app.

## What You Will Learn

- Initialize an Amplify project from the command line
- Install Amplify as a dependency for your project
- Initialize Amplify libraries at runtime

## Key Concepts

- Amplify CLI - The Amplify CLI allows you to create, manage, and remove AWS services directly from your terminal.
- Amplify Libraries - The Amplify libraries allow you to interact with AWS services from a web or mobile application.

# Implementation

## Install Amplify CLI Developer Preview

AWS Amplify CLI depends on Node.js to be installed, which can be found [here](https://nodejs.org/en/download/).

To download the Amplify-Flutter Developer Preview version of the CLI, run the following:

```shell
npm install -g @aws-amplify/cli@flutter-preview
```

Verify you are now using the Flutter Preview version of the CLI by running `$ amplify --version` . You should see something like this:

```shell
photo_gallery git:(master) ✗ amplify --version
Scanning for plugins...
Plugin scan successful
4.26.1-flutter-preview.0
```

If you have not already configured your Amplify CLI, be sure to run this:

```shell
amplify configure
```

You will be guided through the configuration process. You can go [here](https://docs.amplify.aws/cli/start/install) for more information on configuring the CLI.

## Initialize Amplify

To create an Amplify project, you must initialize and configure the project at the root directory of your project.

Navigate to the root of your project:

```shell
cd path/to/your/project
```

Verify that you are in the correct directory by running `$ ls -al` . Yout output should look something like this:

```shell
➜  photo_gallery git:(master) ✗ ls -al
total 80
drwxr-xr-x  18 kiloloco  staff   576 Oct 19 18:07 .
drwxr-xr-x   3 kiloloco  staff    96 Oct 18 21:10 ..
drwxr-xr-x   4 kiloloco  staff   128 Oct 18 22:15 .dart_tool
-rw-r--r--   1 kiloloco  staff   536 Oct 19 19:43 .flutter-plugins
-rw-r--r--   1 kiloloco  staff  1422 Oct 19 19:43 .flutter-plugins-dependencies
-rw-r--r--   1 kiloloco  staff   621 Oct 18 21:10 .gitignore
drwxr-xr-x   6 kiloloco  staff   192 Oct 18 21:10 .idea
-rw-r--r--   1 kiloloco  staff   305 Oct 18 21:10 .metadata
-rw-r--r--   1 kiloloco  staff  3648 Oct 19 18:07 .packages
-rw-r--r--   1 kiloloco  staff   543 Oct 18 21:10 README.md
drwxr-xr-x  12 kiloloco  staff   384 Oct 18 21:10 android
drwxr-xr-x   5 kiloloco  staff   160 Oct 18 22:20 build
drwxr-xr-x  11 kiloloco  staff   352 Oct 19 19:04 ios
drwxr-xr-x  11 kiloloco  staff   352 Oct 19 18:08 lib
-rw-r--r--   1 kiloloco  staff   896 Oct 18 21:10 photo_gallery.iml
-rw-r--r--   1 kiloloco  staff  6047 Oct 19 18:07 pubspec.lock
-rw-r--r--   1 kiloloco  staff  2926 Oct 19 18:07 pubspec.yaml
drwxr-xr-x   3 kiloloco  staff    96 Oct 18 21:10 test
```

Now initialize your project Amplify project:

```shell
amplify init
```

You should now be prompted with several questions on how to configure your project. If you press the **Enter** key for each question, it will give the default answer to each question, resulting in an output that should look similar to this:

```shell
➜  photo_gallery git:(master) ✗ amplify init
Note: It is recommended to run this command from the root of your app directory
? Enter a name for the project photogallery
? Enter a name for the environment dev
? Choose your default editor: Visual Studio Code
? Choose the type of app that you're building flutter
Please tell us about your project
⚠️  Flutter project support in the Amplify CLI is in DEVELOPER PREVIEW.
Only the following categories are supported:
 * Auth
 * Analytics
 * Storage
? Where do you want to store your configuration file? ./lib/
Using default provider  awscloudformation

For more information on AWS Profiles, see:
https://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html

? Do you want to use an AWS profile? Yes
? Please choose the profile you want to use default
```

After the CLI has finished crating your project in the cloud, you should get an out like this:

```shell
✔ Successfully created initial AWS cloud resources for deployments.
✔ Initialized provider successfully.
Initialized your environment successfully.

Your project has been successfully initialized and connected to the cloud!
```

If you run `$ ls` at the root directory of your project, you should notice a new file `amplify.json` and folder `amplify` have been added to your project. Running `$ ls lib` will also reveal that a new file `amplifyconfiguration.dart` has been added there as well.

## Add Dependencies to your Project

The next step is to install Amplify as a dependency in our project so we can interface with the libraries.

Back in Visual Studio Code, open `pubspec.yaml` and add the following dependency:

```yaml
... # path:

amplify_core: '<1.0.0'

... # dev_dependencies
```

Either save the file or run `$ flutter pub get` in the terminal at the root directory of your app.

The process should finish with the following output:

```shell
exit code 0
```

For iOS, open the Podfile (ios > Podfile) and update the platform to `11.0` or higher:

```ruby
... # Uncomment this line to define a global platform for your project

platform :ios, '11.0'

... # CocoaPods analytics sends network stats synchronously affecting flutter build latency.
```

## Integrate in your App

To use the Amplify Flutter Library, it's important that Amplify is configured before any of the categories are used.

Open `main.dart` and add an instance of `Amplify` in `_MyAppState`:

```dart
... // class _MyAppState extends State<MyApp> {

final _amplify = Amplify();

... // final _authService = AuthService();
```

Now create a function to configure Amplify:

```dart
... // build closing }

void _configureAmplify() async {
  try {
    await _amplify.configure(amplifyconfig);
    print('Successfully configured Amplify 🎉');
  } catch (e) {
    print('Could not configure Amplify ☠️');
  }
}

... // _MyAppState closing }
```

This function will pass in `amplifyconfig`, provided by the generated file `/lib/amplifyconfiguration.dart`, and attempt to configure our Amplify object with any plugins we may need to use. We will start adding plugins in the following modules.

Now call `_configureAmplify()` in `initState()` of `_MyAppState`:

```dart
... // super.initState();

_configureAmplify();

... // _authService.showLogin();
```

Now run the app and you should see the following printed to your logs:

```shell
flutter: Successfully configured Amplify 🎉
```

Your app is now ready to add more categories to it 🥳

[Next](04_add_authentication.md): Add Authentication