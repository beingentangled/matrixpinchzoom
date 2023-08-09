import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:video_player/video_player.dart';

import 'matrix_gesture.dart';

class TransformDemo5 extends StatefulWidget {
  @override
  _TransformDemo5State createState() => _TransformDemo5State();
}

class _TransformDemo5State extends State<TransformDemo5> {
  late Matrix4 matrix;
  late ValueNotifier<Matrix4> notifier;
  late Boxer boxer;
  late VideoPlayerController _controller;
  var width = 200.0;
  var height = 150.0;
  late Rect dst;

  bool maxScale = false;
  bool minScale = false;
  double maxScaleWidth = 0;
  double maxScaleHeight = 0;

  // min
  double minScaleWidth = 0;
  double minScaleHeight = 0;

  @override
  void initState() {
    // system chrome orientation landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.initState();
    matrix = Matrix4.identity();
    notifier = ValueNotifier(matrix);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    // _controller.addListener(() {
    //   setState(() {
    //   });
    // });
    _controller.setLooping(true);
    _controller.initialize();
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          // var dx = (constraints.biggest.width - width) / 2;
          // var dy = (constraints.biggest.height - height) / 2;
          // matrix.leftTranslate(dx, dy);
          boxer = Boxer(Offset.zero & constraints.biggest,
              Rect.fromLTWH(0, 0, width, height));
          return MatrixGestureDetector(
            shouldRotate: false,
            onMatrixUpdate: (m, tm, sm, rm) {
              matrix = MatrixGestureDetector.compose(m, tm, sm, null);
              boxer.clamp(matrix);
              notifier.value = matrix;
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topLeft,
              color: Colors.black12,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    builder: (ctx, child) {
                      return Transform(
                        transform: matrix,
                        child: Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            border: Border.all(
                              color: Colors.black45,
                              width: 2,
                            ),
                          ),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: <Widget>[
                                VideoPlayer(_controller),
                                ClosedCaption(text: _controller.value.caption.text),
                                // _ControlsOverlay(controller: _controller),
                                VideoProgressIndicator(_controller,
                                    allowScrubbing: true),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    animation: notifier,
                  ),
                  // make a button
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: IconButton(
                      color: Colors.red,
                      icon: Icon(Icons.add),
                      onPressed: () {
                        debugPrint('add');
                        // matrix.scale(2.0, 2.0, 0.0);
                        // matrix = MatrixGestureDetector.compose(matrix, null, null, null);
                        // boxer.clamp(matrix);
                        // notifier.value = matrix;
                        // print('scaledWi
                        // dth: ${dst.width}');
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class Boxer {
  final Rect bounds;
  final Rect src;
  late Rect dst;

  Boxer(this.bounds, this.src);

  void clamp(Matrix4 m) {
    dst = MatrixUtils.transformRect(m, src);
    // get the scaled size from the m
    double scaledWidth = dst.width;
    double scaledHeight = dst.height;

    //print width and height
    // print('scaledWidth: $scaledWidth');
    // print('scaledHeight: $scaledHeight');
    // Create a scaled rectangle with the new dimensions
    Rect scaledRect = Rect.fromCenter(
      center: dst.center,
      width: scaledWidth,
      height: scaledHeight,
    );
    if (bounds.left <= dst.left &&
        bounds.top <= dst.top &&
        bounds.right >= dst.right &&
        bounds.bottom >= dst.bottom) {
      // bounds contains dst
      return;
    }

    if (dst.width > bounds.width || dst.height > bounds.height) {
      // return if the scaled height is less than the bounds height and the scaled width is less than the bounds width
      if (scaledHeight >= bounds.height) {
        return;
      }
      Rect intersected = dst.intersect(bounds);
      FittedSizes fs =
          applyBoxFit(BoxFit.contain, scaledRect.size, intersected.size);

      vector.Vector3 t = vector.Vector3.zero();
      intersected = Alignment.center.inscribe(fs.destination, intersected);
      if (dst.width > bounds.width)
        t.y = intersected.top;
      else
        t.x = intersected.left;

      var scale = fs.destination.width / src.width;
      vector.Vector3 s = vector.Vector3(scale, scale, 0);
      m.setFromTranslationRotationScale(t, vector.Quaternion.identity(), s);
      return;
    }

    if (dst.left < bounds.left) {
      m.leftTranslate(bounds.left - dst.left, 0.0);
    }
    if (dst.top < bounds.top) {
      m.leftTranslate(0.0, bounds.top - dst.top);
    }
    if (dst.right > bounds.right) {
      m.leftTranslate(bounds.right - dst.right, 0.0);
    }
    if (dst.bottom > bounds.bottom) {
      m.leftTranslate(0.0, bounds.bottom - dst.bottom);
    }
  }
}
