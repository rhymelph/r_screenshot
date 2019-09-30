library r_screenshot;

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SingleScreenShot extends StatelessWidget {
  final SingleScreenShotController controller;
  final Widget child;

  const SingleScreenShot({Key key, this.controller, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    SingleScreenShotController _controller =
        controller ?? SingleScreenShotController();
    return RepaintBoundary(
      key: _controller._key,
      child: child,
    );
  }
}

class SingleScreenShotController {
  GlobalKey _key = GlobalKey();

  // capture the child to image
  Future<ui.Image> captureImage({double pixelRatio}) async {
    RenderRepaintBoundary boundary = _key.currentContext.findRenderObject();
    return await boundary.toImage(
        pixelRatio: pixelRatio ?? ui.window.devicePixelRatio);
  }
}

class LongScreenShot extends StatelessWidget {
  final LongScreenShotController controller;
  final Widget child;

  const LongScreenShot({Key key, this.controller, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    LongScreenShotController _controller =
        controller ?? LongScreenShotController();
    return SingleScreenShot(
      controller: _controller.singleController,
      child: child,
    );
  }
}

class ScreenShotListView extends StatelessWidget {
  final LongScreenShotController controller;
  final List<Widget> children;

  const ScreenShotListView({
    Key key,
    this.controller,
    this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LongScreenShot(
      controller: controller,
      child: ListView(
        controller: controller,
        children: children,
      ),
    );
  }
}

class ScreenShotCustomScrollView extends StatelessWidget {
  final LongScreenShotController controller;
  final List<Widget> slivers;

  const ScreenShotCustomScrollView({
    Key key,
    this.controller,
    this.slivers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LongScreenShot(
      controller: controller,
      child: CustomScrollView(
        controller: controller,
        slivers: slivers,
      ),
    );
  }
}

class LongScreenShotController extends ScrollController {
  ValueChanged<ui.Image> imageCallBack;
  SingleScreenShotController singleController = SingleScreenShotController();
  VoidCallback _listener;

  void setImageCallBack(ValueChanged<ui.Image> imageCallBack) {
    imageCallBack = imageCallBack;
  }

  //start capture image
  void startCaptureImage({double pixelRatio}) async {
    double maxScroll = position.maxScrollExtent; //max scroll distance
    double viewPort = position.viewportDimension; //screen distance
    double _pixelRatio = pixelRatio ?? ui.window.devicePixelRatio;
    if (maxScroll == 0.0) {
      //no max scroll and content not full screen
      if (imageCallBack != null) {
        imageCallBack(
            await singleController.captureImage(pixelRatio: _pixelRatio));
      }
      return;
    }
    double fullHeight, fullWidth, lastPosition;
    ui.Canvas canvas;
    ui.PictureRecorder recorder;
    Paint paint;
    void _init() {
      recorder = ui.PictureRecorder();
      canvas = ui.Canvas(recorder);
      fullHeight = (maxScroll + viewPort) * _pixelRatio;
      fullWidth = (singleController._key.currentContext.findRenderObject()
                  as RenderRepaintBoundary)
              .size
              .width *
          _pixelRatio;
      paint = Paint()
        ..color = Color(0xFFFFFFFF)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..blendMode = BlendMode.dstATop
        ..filterQuality = FilterQuality.low;
    }

    _init();

    void _record() async {
      if (position.pixels == position.maxScrollExtent ||
          lastPosition == 0 ||
          position.pixels - lastPosition > 300) {
        lastPosition = position.pixels;
        ui.Image image =
            await singleController.captureImage(pixelRatio: pixelRatio);
        canvas.drawImage(image, Offset(0.0, lastPosition * pixelRatio), paint);
        if (position.pixels == position.maxScrollExtent) {
          if (imageCallBack != null) {
            imageCallBack(await recorder
                .endRecording()
                .toImage(fullWidth.toInt(), fullHeight.toInt()));
          }
          removeListener(_listener);
        }
      }
    }

    _listener = () {
      _record();
    };

    //jump to start
    jumpTo(0.0);
    await Future.delayed(Duration(milliseconds: 200));
    addListener(_listener);
    animateTo(position.maxScrollExtent,
        duration: Duration(milliseconds: position.maxScrollExtent * 10 ~/ 1),
        curve: Curves.linear);
  }
}
