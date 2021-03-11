# Introduction

## Overview

In this tutorial, you will create a cross-platform photo gallery app using AWS Amplify as a serverless backend that interfaces with your Flutter app. Through the modules of this tutorial, you will implement a UI that allows the user to take pictures, create a sign-in flow, upload and download images to/from a private Amazon S3 bucket, and add various analytics event that can be monitored through Amazon Pinpoint.

## What You Will Learn

- Manage a serverless backend using the AWS Amplify CLI
- Authenticate users using Amazon Cognito
- Uploading and downloading files to/from Amazon S3
- Record analytics events to Amazon Pinpoint

## Modules

This tutoial is divided into five modules focused on covering a particular topic in each one. Each module will continue to build off the previous modules, so it is recommended that you finish each module in the order listed.

- [Create a Flutter App](02_create_a_flutter_app.md) (30 minutes): Create a Flutter application with all the UI components implemented.
- [Initialize Amplify](03_initialize_amplify.md) (10 minutes): Initialize a local Amplify app using the AWS Amplify CLI.
- [Add Authentication](04_add_authentication.md) (10 minutes): Implement user authentication to your app.
- [Add Storage](05_add_storage.md) (10 minutes): Implement image upload and download to/from Amazon S3.
- [Add Analytics](06_add_analytics.md) (10 minutes): Implement event logging in multiple areas throughout the app.

The last module, [Clean Up](07_clean_up.md), is optional but recommended if you intend to make your project public as a security measure.

## Side Bar

| Info | Level |
| --- | --- |
| ✅ AWS Level    | Beginner |
| ✅ Flutter Level    | Beginner - Intermediate |
| ✅ Dart Level  | Beginner - Intermediate |
| ⏱ Time to complete | 70 minutes |
| 💰 Cost to complete | [Free tier](https://aws.amazon.com/free) eligible |

This tutorial will not require any previous knowledge with AWS or any of its services to follow along. However, there will be some more intermediate concepts covered when working with Flutter and Dart. For the best experience, be sure to familiarize yourself with concepts like `async`, the higher order function `map`, `Navigator` 2.0, and `StreamBuilder`; you can find recipes covering these topics [here](https://flutter.dev/docs/cookbook).

## Prerequisites

- [Install Flutter](https://flutter.dev/docs/get-started/install) version 1.22.0 or higher
- An [editor](https://flutter.dev/docs/get-started/editor?tab=vscode) that compatible with Flutter. (This tutorial will assume you are using Visual Studio Code, but you can use a different editor if you want.)
- Install the Amplify CLI by running:
  ```bash
  npm install -g @aws-amplify/cli
  ```
- Sign up for an [AWS account](https://signin.aws.amazon.com/signin?redirect_uri=https%3A%2F%2Fportal.aws.amazon.com%2Fbilling%2Fsignup%2Fresume&client_id=signup#/start)
- An Android or iOS device so you can take pictures

## Next

[Create a Flutter App](02_create_a_flutter_app.md)
