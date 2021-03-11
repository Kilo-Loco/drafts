# Introduction

Now that only authenticated users can enter the app, we can allow the user to take pictures and upload them to a private folder in our app's [Amazon S3](https://aws.amazon.com/s3/) bucket.

In this module, we will add the Storage category to our Amplify app, upload pictures take from the device camera, then download and display all the photos associated with an individual user.

## What You Will Learn

- Configure the Storage category
- Upload files to Amazon S3
- Download files from Amazon S3
- Display and cache images from a url

## Key Concepts

- Storage - The concept of Storage is to be able to store files in a location and retrieve those files when needed. In this case, storing images to and downloading images from Amazon S3.

# Implementation

## Create the Storage Service

Add the Storage service to the Amplify project by entering the following command in the terminal at the root directory of the project:

```shell
amplify add storage
```

Just like any other category, the Amplify CLI will prompt you with questions on how you want to configure your Storage service. We will use the **Enter** key to answer most of the questions with the default answer:

```shell
➜  photo_gallery git:(master) amplify add storage
? Please select from one of the below mentioned services: Content (Images, audio
, video, etc.)

? Please provide a friendly name for your resource that will be used to label th
is category in the project: s33daafe54
? Please provide bucket name: photogalleryf3fb7bda3f5d47939322aa3899275aab
? Who should have access: Auth users only
```

When asked what kind of access Authenticated users should have, press the **a** key to select create/update, read, and delete:

```shell
? What kind of access do you want for Authenticated users? create/update, read,
delete
```

Then continue entering the default answers until the Storage resource is fully configured:

```shell
? Do you want to add a Lambda Trigger for your S3 Bucket? No
Successfully added resource s33daafe54 locally
```

Now we need to send the configured Storage resource to our backed so we stay in sync. Run the following command:

```shell
amplify push
```

Amplify CLI will provide a status report of what changes are taking place:

```shell
✔ Successfully pulled backend environment dev from the cloud.

Current Environment: dev

| Category | Resource name        | Operation | Provider plugin   |
| -------- | -------------------- | --------- | ----------------- |
| Storage  | s33daafe54           | Create    | awscloudformation |
| Auth     | photogallery42b5391b | No Change | awscloudformation |
? Are you sure you want to continue? (Y/n)
```

It shows that the Storage category is being created and Auth doesn't have any changes from our setup in the [previous module](04_add_authentication.md).

Once our Storage resource is finished being configured in the backend, we will see a success output:

```shell
✔ All resources are updated in the cloud
```

## Install the Dependency

Next, open the `pubspec.yaml` file in Visual Studio code to add the Storage plugin as a dependency:

```yaml
... # amplify_auth_cognito: '<1.0.0'

amplify_storage_s3: '<1.0.0'

... # dev_dependencies:
```

Now save the file to have Visual Studio Code install the Amplify Auth Cognito plugin. You can also run `$ flutter pub get` from the terminal if the dependency isn't installed on save.

You should get an output of:

```shell
exit code 0
```

## Configure the Plugin

Now navigate back to `main.dart` so Storage can be added as a plugin on our instance of `Amplify`:

```dart
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

... // import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

...

... // try {

Amplify.addPlugins([
  AmplifyAuthCognito(),
  AmplifyStorageS3()
]);

... // await Amplify.configure(amplifyconfig);
```

Run the app. You should still see the success message in the logs indicating that Amplify is still properly configured and is including the Storage plugin.

```shell
flutter: Successfully configured Amplify 🎉
```

## Implement Functionality

To keep our code organized, let's create a seperate file called `storage_service.dart` that will encapsulate the logic for uploading and downloading files. Add the following code:

```dart
import 'dart:async';
import 'package:amplify_flutter/amplify.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

class StorageService {
  // 1
  final imageUrlsController = StreamController<List<String>>();

  // 2
  void getImages() async {
    try {
      // 3
      final listOptions =
          S3ListOptions(accessLevel: StorageAccessLevel.private);
      // 4
      final result = await Amplify.Storage.list(options: listOptions);

      // 5
      final getUrlOptions =
          GetUrlOptions(accessLevel: StorageAccessLevel.private);
      // 6
      final List<String> imageUrls =
          await Future.wait(result.items.map((item) async {
        final urlResult =
            await Amplify.Storage.getUrl(key: item.key, options: getUrlOptions);
        return urlResult.url;
      }));

      // 7
      imageUrlsController.add(imageUrls);
    
    // 8
    } catch (e) {
      print('Storage List error - $e');
    }
  }
}
```
1. We start by initializing a `StreamController` which will manage the image URLs that are retrieved from Amazon S3.
2. This function will kick off the process of fetching the images that need to be displayed in `GalleryPage`.
3. Since we only want to show photos that the user has uploaded, we specify the access level as `StorageAccessLevel.private`, ensuring our users' private photos stay private.
4. Next we request Storage to list all the relevant photos given the `S3ListOptions`. 
5. If the list result is successful, we need to get the actual download URL of each photo as the list result only contains a list of keys and not the actual url of the photo.
6. We use `.map` to interate over each item in the list result and asynchronously return the download URL of each item.
7. Lastly, we simply send the list of URLs down the stream to be observed.
8. If there are any errors along the way, we will simply print out an error.

On iOS, to ensure the app can download the images, we need to update the `App Transport Security` in `Info.plist` (ios > Runner > Info.plist):

```xml
... <!-- <string>Need to take pictures</string> -->

<key>NSAppTransportSecurity</key>
<dict>
   <key>NSAllowsArbitraryLoads</key>
   <true/>
</dict>

... <!-- </dict> -->
```

Attempting to list image urls from S3 is pointless if you haven't uploaded anything, so let's add a function to upload images:

```dart
// 1
void uploadImageAtPath(String imagePath) async {
 final imageFile = File(imagePath);
 // 2
 final imageKey = '${DateTime.now().millisecondsSinceEpoch}.jpg';

 try {
   // 3
   final options = S3UploadFileOptions(
       accessLevel: StorageAccessLevel.private);

   // 4
   await Amplify.Storage.uploadFile(
       local: imageFile, key: imageKey, options: options);

   // 5
   getImages();
 } catch (e) {
   print('upload error - $e');
 }
}
```

1. This will be an asynchronous function that takes an image path provided by the camera.
2. To ensure the photo has a unique key, we will use a timestamp as the key.
3. As stated when implementing `getImages`, we need to specify the access level as `StorageAccessLevel.private` so the user is uploading images to their own folder in the S3 bucket.
4. Then we simply upload the file specifying its key and upload file options.
5. Lastly, we call `getImages` to get the latest list of image urls and send them down stream.

We have finished all the coding required to get our uploading and downloading working. Now we need to connect everything and test it.

Let's start by updating `GalleryPage` to take a `StreamController` as an argument so it can observe the image urls retrieved from Storage.

```dart
... // class GalleryPage extends StatelessWidget {

final StreamController<List<String>> imageUrlsController;

... // final VoidCallback shouldLogOut;
... // final VoidCallback shouldShowCamera;

GalleryPage(
   {Key key,
   this.imageUrlsController,
   this.shouldLogOut,
   this.shouldShowCamera})
    : super(key: key);

... // @override
```

Next, update `_galleryGrid` to return a `StreamBuilder` instead of just the `GridView.builder`:

```dart
Widget _galleryGrid() {
 return StreamBuilder(
     // 1
     stream: imageUrlsController.stream,
     builder: (context, snapshot) {
       // 2
       if (snapshot.hasData) {
         // 3
         if (snapshot.data.length != 0) {
           return GridView.builder(
               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 2),
               // 4
               itemCount: snapshot.data.length,
               itemBuilder: (context, index) {
                 return CachedNetworkImage(
                   imageUrl: snapshot.data[index],
                   fit: BoxFit.cover,
                   placeholder: (context, url) => Container(
                       alignment: Alignment.center,
                       child: CircularProgressIndicator()),
                 );
               });
         } else {
           // 5
           return Center(child: Text('No images to display.'));
         }
       } else {
         // 6
         return Center(child: CircularProgressIndicator());
       }
     });
}
```

1. The `StreamBuilder` will be using the `imageUrlsController` that will be passed in from `StorageService` to provide snapshots of our data.
2. The UI requires that the snapshot has data to display anything relevant to the user.
3. We also need to determine if the data actually has items. If it does, then we continue on to building the `GridView`.
4. Instead of using a hardcoded number, we can now make our `GridView` size based on the length of the data in our snapshot.
5. If the snapshot doesn't have any items, we will display some text indicating that there is nothing to show.

Right now we're still showing a `Placeholder` for each item in the grid. We will need to download each image from the URL provided by the stream. To make that easier, let's add a new dependency in `pubspec.yaml`:

```yaml
... # amplify_storage_s3: '<1.0.0'

cached_network_image: ^2.5.1

... # dev_dependencies:
```

This library provides a widget that can download and cache an image by simply receiving a URL. Save the changes and navigate back to `GalleryPage` so we can replace the `Placeholder`:

```dart
... // itemBuilder: (context, index) {

return CachedNetworkImage(
  imageUrl: snapshot.data[index],
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(
      alignment: Alignment.center,
      child: CircularProgressIndicator()),
);

... // itemBuilder closing });
```

The `Placeholder` has been replaced with `CachedNetworkImage` which is passed the URL from the snapshot and indexed through the `itemBuilder`. While the image loads, the widget will display a `CircularProgressIndicator`.

Now we can connect `GalleryPage` and `CameraPage` to the `StorageService` in `_CameraFlowState`. Start by creating a property to hold an instance of `StorageService`:

```dart
... // bool _shouldShowCamera = false;

StorageService _storageService;

... // List<MaterialPage> get _pages {
```

Next, initialize `_storageService` in the `initState` method:

```dart
... // _getCamera();

_storageService = StorageService();
_storageService.getImages();

... // initState closing }
```

Immediately after initializing `StorageService`, we call `getImages` so that any uploaded images will be retrieved.

Let's pass the `StreamController` to the `GalleryPage` now:

```dart
... // child: GalleryPage(
    
imageUrlsController: _storageService.imageUrlsController,

... // shouldLogOut: widget.shouldLogOut,
```

Lastly, update the functionality of `didProvideImagePath` of the `CameraPage` once a picture is taken:

```dart
... // this._toggleCameraOpen(false);

this._storageService.uploadImageAtPath(imagePath);

... // didProvideImagePath closing }
```

That's it! We're ready to start taking pictures with our app and upload them to S3.

Build and run to give it a try!

![First picture demo](assets/first-picture-demo.gif)

Awesome! The core functionality of the app has been implemented and the user can take pictures which will be stored in a private section of the app's S3 bucket.

[Next](06_add_analytics.md): Add Analytics
