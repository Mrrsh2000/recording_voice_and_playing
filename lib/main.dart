import 'dart:async';
import 'dart:math';

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:chengguo_audio_recorder_v2/audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';


import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  Timer? _timer;
  int  _tick = 0;
  double  _db = 0;
  String dirPath = "";

  bool _isVisibleStart = true;
  bool _isVisibleStop = false;
  bool _isVisiblePlay = true;
  bool _isVisibleStopMusic = false;

  AudioPlayer audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('تست ظبط صدا')),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 50),
                child: Text("${_tick}s  ${_db}db",
                    style: TextStyle(fontSize: 40, color: Colors.blue)),
              ),
              widgetRecording(),
              widgetPlayRecording(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget >[
                  Text("    Output audio path:"),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: Text(
                      "${_audioPath ?? "Empty"}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget widgetRecording(){
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.white,
          boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
          ),]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Visibility (
                visible: _isVisibleStop,
                child: IconButton(
                  onPressed: _isRecording ? () => _stopRecord() : null,
                  icon: Icon(Icons.stop_circle),
                  color: Colors.red,
                  iconSize: 25,
                ),
              ),
              Visibility (
                visible: _isVisibleStart,
                child: IconButton(
                  onPressed: _isRecording ? null : () => _startRecord(),
                  icon: Icon(Icons.play_circle_fill),
                  color: Colors.green,
                  iconSize: 25,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget widgetPlayRecording(){
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.white,
          boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
          ),]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Visibility (
                visible: _isVisibleStopMusic,
                child: IconButton(
                  onPressed: _isPlaying ? () => stopPlayRecord() : null,
                  icon: Icon(Icons.stop_circle),
                  color: Colors.red,
                  iconSize: 25,
                ),
              ),
              Visibility (
                visible: _isVisiblePlay,
                child: IconButton(
                  onPressed: _isPlaying ? null : () => playRecord(),
                  icon: Icon(Icons.play_circle_fill),
                  color: Colors.green,
                  iconSize: 25,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  _startRecord() async {
    var random = new Random();
    try {
      var storage = await Permission.storage.status;
      if(storage.isGranted){
        final directory = await getExternalStorageDirectory();
        File outFile = new File(directory!.path + "/workManager_" + random.nextInt(100).toString() + ".mp3");
        dirPath = outFile.path;
        var path = await AudioRecorder.startRecord(outFile.path);
        var isRecording = await AudioRecorder.isRecording();
        setState(() {
          _audioPath = path;
          _isRecording = isRecording;
          _isVisibleStart = !_isVisibleStart;
          _isVisibleStop = !_isVisibleStop;
        });
        _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
          double db = await AudioRecorder.db;
          setState(() {
            _tick = timer.tick;
            _db = db.floorToDouble();
          });
        });
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  _stopRecord() async {
    try {
      await AudioRecorder.stopRecord();
    } catch (e) {
      debugPrint("$e");
    } finally {
      _timer?.cancel();
      var isRecording = await AudioRecorder.isRecording();
      setState(() {
        _audioPath = null;
        _tick = 0;
        _isRecording = isRecording;
        _isVisibleStart = !_isVisibleStart;
        _isVisibleStop = !_isVisibleStop;
      });
    }
  }

  playRecord() async {
    audioPlayer.setVolume(100);
    int result = await audioPlayer.play(dirPath, isLocal: true);
    setState(() {
      _isVisiblePlay = !_isVisiblePlay;
      _isVisibleStopMusic = !_isVisibleStopMusic;
      _isPlaying = !_isPlaying;
    });
  }

  stopPlayRecord() async{
    int result = await audioPlayer.stop();
    setState(() {
      _isVisiblePlay = !_isVisiblePlay;
      _isVisibleStopMusic = !_isVisibleStopMusic;
      _isPlaying = !_isPlaying;
    });
  }
}
