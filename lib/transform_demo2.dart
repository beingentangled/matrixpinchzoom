import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:video_player/video_player.dart';

import 'matrix_gesture.dart';

class TransformDemo2 extends StatefulWidget {
  @override
  _TransformDemo2State createState() => _TransformDemo2State();
}

class _TransformDemo2State extends State<TransformDemo2> {
  late Matrix4 matrix;
  late ValueNotifier<Matrix4> notifier;
  late Boxer boxer;
  late VideoPlayerController _controller;
  var width = 200.0;
  var height = 150.0;
  late Rect dst;

  bool maxScale = false;
  bool minScale = false;

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
              matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);
              // get the scaled size from the m
              dst = MatrixUtils.transformRect(
                  m, Rect.fromLTWH(0, 0, width, height));
              double scaledWidth = dst.width;
              double scaledHeight = dst.height;
              if (scaledWidth <= 200 && scaledHeight <= 150) {
                print('return: $scaledWidth, $scaledHeight');
                // provide the initial width and height to the notifier to scale to initial size
                if (!minScale) {
                  // matrix.scale(1.0, 1.0, 0.0);
                  minScale = true;
                  matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);
                  boxer.clamp(matrix);
                  notifier.value = matrix;
                  return;
                } else {
                  matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);
                  boxer.clamp(matrix);
                  notifier.value = matrix;
                  return;
                }
              } else if (scaledWidth <= 400 && scaledHeight <= 300) {
                boxer.clamp(matrix);
                notifier.value = matrix;
                print('return 1: $scaledWidth, $scaledHeight');
                return;
              } else {
                if (maxScale) {
                  // provide scale values to sm
                  // boxer.clamp(matrix);
                  matrix.row0.x = 2.0;
                  matrix.row1.y = 2.0;
                  notifier.value =
                      MatrixGestureDetector.compose(matrix, null, null, null);
                  maxScale = false;
                  return;
                } else {
                  //   matrix.scale(2.0, 2.0, 0.0);
                  matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);
                  boxer.clamp(matrix);
                  notifier.value = matrix;
                  print('return 2: $scaledWidth, $scaledHeight');
                  maxScale = true;
                  return;
                }
              }
              // //print width and height
              // print('scaledWidth: $scaledWidth');
              // print('scaledHeight: $scaledHeight');
              // notifier.value = matrix;
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topLeft,
              color: Colors.deepPurple,
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
                    top: 0,
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

  void scaleAndClamp(Matrix4 m) {
    // Calculate the transformed rectangle 'dst' by applying the transformation matrix 'm' to the source rectangle 'src'
    dst = MatrixUtils.transformRect(m, src);

    // Calculate the scaled size (twice the original size)
    double scaledWidth = src.width * 2;
    double scaledHeight = src.height * 2;

    // Create a scaled rectangle with the new dimensions
    Rect scaledRect = Rect.fromCenter(
      center: dst.center,
      width: scaledWidth,
      height: scaledHeight,
    );

    // Calculate the intersection between the scaled rectangle and the specified bounds
    Rect intersected = scaledRect.intersect(bounds);

    // Apply BoxFit.contain to fit the intersected rectangle within bounds
    FittedSizes fs =
        applyBoxFit(BoxFit.contain, scaledRect.size, intersected.size);

    // Calculate translation vector 't' to position intersected rectangle
    vector.Vector3 t = vector.Vector3.zero();
    intersected = Alignment.center.inscribe(fs.destination, intersected);
    t.x = intersected.left;
    t.y = intersected.top;

    // Calculate scaling factor and create a new transformation matrix 'm'
    var scale = fs.destination.width / src.width;
    vector.Vector3 s = vector.Vector3(scale, scale, 0);
    m.setFromTranslationRotationScale(t, vector.Quaternion.identity(), s);
  }

  void clamp(Matrix4 m) {
    dst = MatrixUtils.transformRect(m, src);
    // get the scaled size from the m
    double scaledWidth = dst.width;
    double scaledHeight = dst.height;

    //print width and height
    print('scaledWidth: $scaledWidth');
    print('scaledHeight: $scaledHeight');
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
      if (scaledHeight < bounds.height && scaledWidth < bounds.width) {
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
