import 'dart:async';
import 'dart:convert';
import 'dart:convert' show utf8;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nautic_viewer/data/parse/parse_spool.dart';
import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

import '../data/api/zipobject_services.dart';

class SimpleRender extends StatefulWidget {
  SimpleRender({Key? key, required this.url}) : super(key: key);

  String url;

  @override
  State<SimpleRender> createState() => _SimpleRender();
}

class _SimpleRender extends State<SimpleRender> {
  List<String> spoolsList = List<String>.empty(growable: true);

  final GlobalKey<three_jsm.DomLikeListenableState> _globalKey =
      GlobalKey<three_jsm.DomLikeListenableState>();

  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;
  late three.WebGLRenderTarget renderTarget;
  late three_jsm.OrbitControls controls;
  late three.AxesHelper axes;

  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;

  late three.Group group;

  three.Box3 boundingBox = three.Box3();
  three.Box3 centerBox = three.Box3();

  num aspect = 2.0;
  double dpr = 1.0;
  late int index;

  bool state = false;

  bool disposed = false;

  dynamic sourceTexture;

  var appBarHeight = 50.0;

  var localToCameraAxesPlacement;
  var data;
  var currentDocNumber;

  @override
  void initState() {
    super.initState();
    data = getData(widget.url);
    currentDocNumber = data[0];

    parseSpool(currentDocNumber).then((value) => {
          setState(() {
            value.forEach((element) {
              spoolsList.add(element);
            });
          })
        });

    // SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {},
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appBarHeight),
          child: AppBar(
            title: Text("3D viewer"),
          ),
        ),
        body: Builder(
          builder: (BuildContext context) {
            initSize(context);
            return Container(
              child: _build(context),
            );
          },
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            three_jsm.DomLikeListenable(
                key: _globalKey,
                builder: (BuildContext context) {
                  return Container(
                      width: width,
                      height: height,
                      color: Colors.white,
                      child: Builder(builder: (BuildContext context) {
                        if (kIsWeb) {
                          return three3dRender.isInitialized
                              ? HtmlElementView(
                                  viewType: three3dRender.textureId!.toString())
                              : Container();
                        } else {
                          return three3dRender.isInitialized
                              ? Texture(textureId: three3dRender.textureId!)
                              : Container();
                        }
                      }));
                }),
            Positioned(
              child: state
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: width,
                          height: height / 10.0,
                          child: Column(
                            children: <Widget>[
                              Text("Document: $currentDocNumber"),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: width,
                      height: height,
                      color: Colors.grey.shade600.withOpacity(0.5),
                      child: LoadingAnimationWidget.threeArchedCircle(
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.2),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height =
        screenSize!.height - appBarHeight - MediaQuery.of(context).padding.top;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    Future.delayed(const Duration(milliseconds: 10), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  render() {
    final gl = three3dRender.gl;

    camera.updateMatrixWorld();
    var axesPlacement = localToCameraAxesPlacement.clone();
    axes.position.copy(axesPlacement);

    renderer?.render(scene, camera);

    gl.flush();

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };

    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat,
        "samples": 4
      });
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() async {
    // create the scene
    aspect = width / height;

    scene = three.Scene();

    camera = three.PerspectiveCamera(50, aspect, 1, 10000);
    camera.position.set(0, 1, 0);
    scene.add(camera);
    scene.background = three.Color(0xA6A6A6);

    // soft white light
    var ambientLight = three.AmbientLight(0x404040, 100);
    ambientLight.intensity = 3;
    scene.add(ambientLight);

    var directionalLight = three.DirectionalLight(0xffffff, 0.3);
    scene.add(directionalLight);

    controls = three_jsm.OrbitControls(camera, _globalKey);

    controls.enableDamping = true;
    controls.dampingFactor = 0.25;
    controls.enableZoom = true;

    controls.minDistance = 10;
    controls.maxDistance = 30000;

    axes = three.AxesHelper(100000);
    localToCameraAxesPlacement = controls.target;
    scene.add(axes);

    controls.update();

    group = three.Group();

    loadObjFromZip();

    animate();
  }

  myOnMouseDownFunction(evt) {
    print("click $evt");
  }

  addObjScene() {
    loadObjFromZip();
  }

  replaceObjScene() {
    boundingBox = three.Box3();
    for (var i = scene.children.length - 1; i >= 0; i--) {
      var obj = scene.children[i];
      if (obj.type == 'Group') scene.remove(obj);
    }
    loadObjFromZip();
  }

  loadObjFromZip() {
    var loader = three_jsm.OBJLoader(null);
    bool first = true;

    fetchFiles(widget.url).then((archive) => {
      // scene.clear(),
      setState(() {
        group = three.Group();
        var archiveFiles = 0;
        archive.files.forEach((file) {
          var decode = utf8.decode(file.content);
          List<String> split;
          List<String> formatted = List.empty(growable: true);
          decode.split('\n').forEach((line) => {
            split = line.split(' '),
            if (split.isNotEmpty && split.elementAt(0) == 'v')
              {formatted.add(line)}
            else if (split.isNotEmpty && split.elementAt(0) == 'f')
              {
                formatted.add(List.from([
                  'f',
                  split.elementAt(1).replaceAll("/", "//"),
                  split.elementAt(2).replaceAll("/", "//"),
                  split.elementAt(3).replaceAll("/", "//")
                ]).join(' ')),
              }
            else if (line.trim() == "")
                {}
              else
                {formatted.add(line)}
          });

          (loader.parse(formatted.join('\n')) as Future<dynamic>)
              .then((model) => {
            group.add(model),
            if (++archiveFiles == archive.files.length)
              {scene.add(group), setView(group)}
          });
        });
      })
    });
  }

  setView(three.Object3D object) {
    boundingBox.expandByObject(object);

    //boundingBox = three.Box3().setFromObject(object);

    var center = three.Vector3();
    var size = three.Vector3();
    boundingBox.getCenter(center);
    boundingBox.getSize(size);

    var fitOffset = 1.2;
    var maxSize = Math.max(size.x, Math.max(size.y, size.z));
    var fitHeightDistance =
        maxSize / (2 * Math.atan(Math.PI * camera.fov / 360));
    var fitWidthDistance = fitHeightDistance / camera.aspect;
    var distance = fitOffset * Math.max(fitHeightDistance, fitWidthDistance);

    var direction = controls.target
        .clone()
        .sub(camera.position)
        .normalize()
        .multiplyScalar(distance);

    controls.maxDistance = distance * 10;
    controls.target.copy(center);

    camera.near = distance / 100;
    camera.far = distance * 100;
    camera.updateProjectionMatrix();

    camera.position.copy(controls.target).sub(direction);

    controls.update();

    setState(() {
      state = true;
    });
    // axesControls.update();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();
    Future.delayed(const Duration(milliseconds: 10), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }
}
