import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_gallery/analytics_events.dart';
import 'package:photo_gallery/analytics_service.dart';

class GalleryPage extends StatelessWidget {
  final StreamController<List<String>> imageUrlsController;
  final VoidCallback shouldLogOut;
  final VoidCallback shouldShowCamera;

  GalleryPage(
      {Key key,
      this.imageUrlsController,
      this.shouldLogOut,
      this.shouldShowCamera})
      : super(key: key) {
    AnalyticsService.log(ViewGalleryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child:
                GestureDetector(child: Icon(Icons.logout), onTap: shouldLogOut),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.camera_alt), onPressed: shouldShowCamera),
      body: Container(child: _galleryGrid()),
    );
  }

  Widget _galleryGrid() {
    return StreamBuilder(
        stream: imageUrlsController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length != 0) {
              return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
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
              return Center(child: Text('No images to display.'));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
