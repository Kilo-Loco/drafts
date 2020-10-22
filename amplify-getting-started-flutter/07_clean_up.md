# Introduction

Now that the Photo Gallery is finished and you have implemented the Authentication, Storage, and Analytics services, there are only a few routes to go from here: make the code publicly viewable, expand the project to a different platform, or delete the project.

In this module, we will explore the steps required to go down each of these routes.

## What You Will Learn

- Make your project secure for open source
- Expanding the app to a different platform or sharing with a team
- Deleting the Amplify project locally and in the cloud

# Implementation

## Securely Share Your Project

If you're looking to make the Photo Gallery app viewable by others by hosting the code on a public repo or accessible to others in general, it is recommended that you remove sensitive information from your project that could lead to your AWS resources being abused. Most of the sensitive files should already be listed in `.gitignore`, but it is recommended you ensure these two lines are included in your repo:

```
amplify/
**/amplifyconfiguration.dart
```

These lines will ensure that the `amplify` directory and the `amplifyconfiguration.dart` file are not included when pushing your code to a repo.

## Sharing Your Backend

AWS Amplify makes it easy to share your configure Amplify backend across multiple platforms or with team members. If you're looking to creating the app on a new platform, web for example, simply navigate to the root directory of your project and run the following command:

```shell
amplify pull
```

You should be presented with a prompt that will verify which AWS profile you want to use as well as which Amplify project you want to pull. Be sure to select the same project used for the Photo Gallery app:

```shell
? Do you want to use an AWS profile? Yes
? Please choose the profile you want to use default
? Which app are you working on? d3p0ir7eqcu4le
Backend environment 'dev' found. Initializing...
? Choose your default editor: Visual Studio Code
? Choose the type of app that you're building javascript
Please tell us about your project
? What javascript framework are you using react
? Source Directory Path:  src
? Distribution Directory Path: build
? Build Command:  npm run-script build
? Start Command: npm run-script start

? Do you plan on modifying this backend? Yes
```

The above is the output if you were to choose a JavaScript platform with React.

You would still run `$ amplify pull` if you intend to work on a team, but the team member would need to have access to the same AWS profile where the Photo Gallery Amplify app is stored.

## Deleting the Project

If you're finished with the project and don't intend on working on it any further, you should consider deleting the Amplify app. This ensures that your resources wont be abused in the event someone gains access to your projects' credentials.

To delete all the local Amplify associated files and the Amplify project in the backend, run the following command:

```shell
amplify delete
```

If you follow through on deleting the Amplify project, you will get an output like this:

```shell
✔ Project deleted in the cloud
Project deleted locally.
```

⚠️ This action cannot be undone. Once the project is deleted, you cannot recover it and will have to reconfigure the categories and the project configuration files if you need to use the project again.

## Conclusion

You have gone through the entire process of creating a fully functional photo gallery app that allows a user to sign in and store images in a private space. You learned how to authenticate the user with Authentication, upload and download files with Storage, and track user behavior with Analytics.

Thank you for making to the end of this tutorial and feel free to give feedback on this end to end walkthrough by creating issues or pull requests on our [GitHub repo](https://github.com/Kilo-Loco/drafts/tree/master/amplify-getting-started-flutter).

[Back](01_introduction.md) to the start.