import 'dart:async';
import 'dart:convert';

import 'package:MusicApp/models/audio_model.dart';
import 'package:MusicApp/models/playlist_model.dart';
import 'package:MusicApp/screens/audio_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exoplayer/audioplayer.dart';
import 'package:flutter_exoplayer/audio_notification.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html_character_entities/html_character_entities.dart';
import 'package:rxdart/rxdart.dart';

//const int playerID = 396433116;
const int playerID = 157211115;
bool showedTitle = true;
bool dark = true;
int overHound = 0;
String status = 'hidden';

void main() => runApp(MusicApp());

class MusicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: dark ? Colors.black : Colors.white.withOpacity(0),
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: dark ? Colors.black : Colors.white,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
    ));
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
          if (!showedTitle) showedTitle = true;
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mahorazb Music',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'SFPro',
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> sliderKey = new GlobalKey<ScaffoldState>();

  final _slider = PublishSubject<double>();
  Stream<double> get sliderStream => _slider.stream;

  AnimationController controller;
  Animation<double> animation;
  TextEditingController editingController = TextEditingController();
  PersistentBottomSheetController bottomSheetController;

  List<Audio> audios = new List<Audio>();
  List<Audio> loadedAudios = new List<Audio>();
  List<Playlist> playlists = new List<Playlist>();

  bool loaded = false;
  bool updatePlaylist = true;
  bool showPlayer = false;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  bool changing = false;
  double changeValue = 0.0;

  Audio _current;

  AudioPlayer audioPlayer;
  double progress = 50.0;
  double volume = 1.0;
  PlayerState playerState = PlayerState.RELEASED;

  Duration duration;
  Duration position;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _onPlayerError;
  StreamSubscription _playerIndexSubscription;
  StreamSubscription _onNotificationActionCallback;
  StreamSubscription _onDurationChanged;

  PageController _myPage = PageController(initialPage: 0);
  int playlistindex = 0;

  get isPlaying => playerState == PlayerState.PLAYING;
  get isPaused => playerState == PlayerState.PAUSED;
  //get _durationText => duration?.toString()?.split('.')?.first ?? '';
  //get _positionText => position?.toString()?.split('.')?.first ?? '';

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
    getAudioList();
    debugPrint('123');
    controller = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    _playerCompleteSubscription.cancel();
    _onPlayerError.cancel();
    _playerIndexSubscription.cancel();
    _onNotificationActionCallback.cancel();
    _onDurationChanged.cancel();
    audioPlayer.release();
    audioPlayer.dispose();
    _slider.close();
    super.dispose();
  }

  void initAudioPlayer() {
    audioPlayer = new AudioPlayer();
    audioPlayer.release();
    _playerCompleteSubscription =
        audioPlayer.onPlayerCompletion.listen((event) {
      position = duration;
      debugPrint('1 complete');
    });

    _onPlayerError = audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        playerState = PlayerState.STOPPED;
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });

    _playerIndexSubscription =
        audioPlayer.onCurrentAudioIndexChanged.listen((index) {
      setState(() {});
    });

    _onNotificationActionCallback = audioPlayer.onNotificationActionCallback
        .listen((notificationActionName) {
      if (notificationActionName == NotificationActionName.NEXT) {
        next();
      } else if (notificationActionName == NotificationActionName.PREVIOUS) {
        pervios();
      } else if (notificationActionName == NotificationActionName.PAUSE) {
        pause();
      } else if (notificationActionName == NotificationActionName.PLAY) {
        resume();
      }

      debugPrint('$notificationActionName');
    });

    _positionSubscription = audioPlayer.onAudioPositionChanged.listen((p) {
      setState(() => position = p);

      if (showPlayer) _slider.sink.add(position.inMilliseconds.toDouble());
    });
    _onDurationChanged = audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => duration = d);
    });
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
      setState(() {
        playerState = s;
        print(playerState);
        debugPrint('$volume');
      });

      if (showPlayer) _slider.sink.add(position.inMilliseconds.toDouble());

      if (s == PlayerState.RELEASED) {
        audioPlayer.setVolume(volume);
      } else if (s == PlayerState.COMPLETED) {
        stop();
        next();
        debugPrint('2 complete');
      }
    });
  }

  Future<void> play(String url) async {
    //await audioPlayer.release();

    await audioPlayer.play(
      url,
      repeatMode: false,
      respectAudioFocus: true,
      playerMode: PlayerMode.FOREGROUND,
      audioNotification: AudioNotification(
          smallIconFileName: 'appicon',
          title: _current.title,
          subTitle: _current.artist,
          largeIconUrl: _current.imageURL != null
              ? _current.imageURL
              : 'images/giphy.gif',
          isLocal: false,
          notificationDefaultActions: NotificationDefaultActions.ALL,
          notificationActionCallbackMode:
              NotificationActionCallbackMode.CUSTOM),
    );

    setState(() {
      playerState = PlayerState.PLAYING;
    });
  }

  Future<void> pause() async {
    await audioPlayer.pause();
    debugPrint('pause');
    setState(() {});
    if (showPlayer) _slider.sink.add(position.inMilliseconds.toDouble());
  }

  Future<void> stop() async {
    await audioPlayer.stop();
    setState(() {
      position = new Duration();
      duration = new Duration();
    });
  }

  Future<void> next() async {
    debugPrint('next');
    setState(() {
      int index = audios.indexOf(_current);
      if (index < audios.length - 1) {
        _current = audios[index + 1];
      } else
        _current = audios[0];
    });
    await play(buildUrl(_current));
  }

  Future<void> pervios() async {
    debugPrint('previ');
    setState(() {
      int index = audios.indexOf(_current);
      if (index == 0) {
        _current = audios[audios.length - 1];
      } else
        _current = audios[index - 1];
    });
    await play(buildUrl(_current));
  }

  Future<void> resume() async {
    await audioPlayer.resume();
    debugPrint('resumed');
    setState(() {});
    //setState(() => playerState = PlayerState.PLAYING);
  }

  Future<void> onComplete() async {
    debugPrint('next');
    await next();
  }

  Future<void> getAudioList() async {
    //debugPrint('[Loading] GetAudiosList');

    setState(() {
      loadedAudios.clear();
    });

    Audio.clear();

/*
    response = await http.get(
        'https://i1.kissvk.com/api/song/user/get_songs/$playerID?origin=kissvk.com&page=1&r=0.4');

    var preParsedAudios = json.decode(response.body);

    debugPrint('loaded');

    for (int i = 0; i < preParsedAudios['pagesCount']; i++) {
      response = await http.get(
          'https://i${i + 1}.kissvk.com/api/song/user/get_songs/$playerID?origin=kissvk.com&page=$i');

      var parsedAudios = json.decode(response.body);
      var parsedAudios2 = parsedAudios['songs'];
      if (i == 0) overHound = parsedAudios['songs'].length;
      debugPrint('Size ${parsedAudios['songs'].length}');
      loadedAudios.addAll(
          parsedAudios2.map<Audio>((json) => Audio.fromJson(json)).toList());
      debugPrint('${Audio.temp}');
    }
    */

    await _getPlaylists();
    updatePlaylist = false;

    setState(() {
      loaded = true;
    });
  }

  Future<void> _getPlaylists() async {
    http.Response response;

    response = await http
        .get('https://brumobile.000webhostapp.com/getvk.php?id=$playerID');
    debugPrint('go');

    List splits = response.body.split('%/&');

    List jsonAudios = json.decode(splits[0]);
    loadedAudios
        .addAll(jsonAudios.map<Audio>((json) => Audio.fromJson(json)).toList());

    setState(() {
      audios.clear();
      audios.addAll(loadedAudios);
    });

    playlists.clear();

    List parsed = json.decode(splits[1]);
    int i = 0;
    parsed.forEach((p) {
      Playlist plist = new Playlist(
        id: i,
        urlid: p['id'] as String,
        title: p['title'] as String,
        imageURL: p['image'] as String,
      );

      if (p['items'] != null) {
        p['items'].forEach((audio) {
          String id = audio['url'].split('=')[1].toString();
          var arr = audio['duration'].split(":");
          int duration = int.parse(arr[1]) * 60 + int.parse(arr[2]);

          Audio.temp++;

          plist.addToList(new Audio(
            id: id,
            artist: audio['artist'] as String,
            title: audio['title'] as String,
            duration: duration,
            imageURL: audio['image'] as String,
            url: audio['url'] as String,
          ));
        });

        playlists.add(plist);
        i++;
      }
    });
  }

  String buildUrl(Audio audio) {
    String val;

    /* if (audio.site == 0) {
      if (audio.tempID <= overHound)
        val = 1.toString();
      else
        val = 2.toString();

      val = "https://i$val.kissvk.com/api/song/download/get/10/";
      //debugPrint("$val");

      val = val +
          _filterString(audio.artist) +
          '-' +
          _filterString(audio.title) +
          '-kissvk.com.mp3?origin=kissvk.com&url=' +
          audio.url +
          '&artist=' +
          _filterString(audio.artist) +
          '&title=' +
          _filterString(audio.title) +
          '&index=1';
    } else {
   }*/

    val = "https://music7s.org" + audio.url;

    return val;
  }

  /* String _filterString(String string) {
    return string
        .replaceAll('#', '-')
        .replaceAll('[', '-')
        .replaceAll(']', '-')
        .replaceAll('/', '-')
        .replaceAll('(', '-')
        .replaceAll(')', '-')
        .replaceAll('&', '-')
        .replaceAll(';', '-');
  }
*/
  void _onRefresh() async {
    await getAudioList();
    _refreshController.refreshCompleted();
  }

  void filterSearchResults(String query) {
    List<Audio> dummySearchList = List<Audio>();
    dummySearchList.addAll(loadedAudios);
    if (query.isNotEmpty) {
      List<Audio> dummyListData = List<Audio>();
      dummySearchList.forEach((item) {
        if (item.artist.toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
        if (item.title.toLowerCase().contains(query.toLowerCase())) {
          if (!dummyListData.contains(item)) dummyListData.add(item);
        }
      });
      setState(() {
        audios.clear();
        audios.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        audios.clear();
        audios.addAll(loadedAudios);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: dark ? Colors.black : Colors.white,
      body: PageView(
        controller: _myPage,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Stack(
                      //crossAxisAlignment: CrossAxisAlignment.start,
                      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        showedTitle
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    top: 5.0, left: 20, right: 15, bottom: 0),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          'Музыка',
                                          style: TextStyle(
                                            color: dark
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 5.0, right: 20, left: 20, bottom: 5),
                            child: AnimatedContainer(
                              curve: Curves.easeIn,
                              duration: Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: !showedTitle
                                    ? dark ? Colors.grey[900] : Colors.grey[100]
                                    : dark ? Colors.black : Colors.white,
                              ),
                              padding: EdgeInsets.all(3),
                              width: showedTitle
                                  ? 30
                                  : MediaQuery.of(context).size.width - 40,
                              height: 30,
                              child: TextFormField(
                                showCursor: false,
                                controller: editingController,
                                onChanged: (value) {
                                  filterSearchResults(value);
                                },
                                onTap: () {
                                  setState(() {
                                    showedTitle = false;
                                  });
                                },
                                onEditingComplete: () {
                                  setState(() {
                                    showedTitle = true;
                                  });
                                  FocusScopeNode currentFocus =
                                      FocusScope.of(context);

                                  if (!currentFocus.hasPrimaryFocus) {
                                    currentFocus.unfocus();
                                  }
                                },
                                decoration: InputDecoration(
                                  hoverColor: Colors.grey[800],
                                  fillColor: Colors.black,
                                  border: InputBorder.none,
                                  icon: Icon(
                                    Icons.search,
                                    color: Colors.grey[700],
                                  ),
                                  alignLabelWithHint: true,
                                ),
                                cursorColor: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding:
                                EdgeInsets.only(top: 46, left: 20, right: 20),
                            child: Divider(
                                height: 1, thickness: 0.2, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: loaded
                      ? Scrollbar(
                          child: RefreshConfiguration(
                            enableBallisticLoad: false,
                            child: SmartRefresher(
                              header: CustomHeader(
                                builder:
                                    (BuildContext context, RefreshStatus mode) {
                                  Widget body;
                                  if (mode == RefreshStatus.idle) {
                                    body = Text(
                                      "Тащите вниз что бы обновить",
                                      style: TextStyle(
                                        color:
                                            dark ? Colors.white : Colors.black,
                                      ),
                                    );
                                  } else if (mode == RefreshStatus.refreshing) {
                                    body = CupertinoActivityIndicator(
                                      radius: 15,
                                    );
                                  } else if (mode == RefreshStatus.failed) {
                                    body = Text(
                                      "Ошибка.",
                                      style: TextStyle(
                                        color:
                                            dark ? Colors.white : Colors.black,
                                      ),
                                    );
                                  } else if (mode == RefreshStatus.canRefresh) {
                                    body = Text(
                                      "Обновить",
                                      style: TextStyle(
                                        color:
                                            dark ? Colors.white : Colors.black,
                                      ),
                                    );
                                  } else {
                                    body = Text(
                                      "Обновлено",
                                      style: TextStyle(
                                        color:
                                            dark ? Colors.white : Colors.black,
                                      ),
                                    );
                                  }
                                  return Container(
                                    height: 55.0,
                                    child: Center(child: body),
                                  );
                                },
                              ),
                              enablePullUp: false,
                              enablePullDown: true,
                              physics: BouncingScrollPhysics(),
                              onRefresh: _onRefresh,
                              controller: _refreshController,
                              scrollDirection: Axis.vertical,
                              child: _buildAudiosList(),
                            ),
                          ),
                        )
                      : Container(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ],
            ),
          ),
          !playlists.isEmpty
              ? AudioPage(
                  myPage: _myPage,
                  playlist: playlists[playlistindex],
                  player: audioPlayer,
                  current: _current,
                )
              : Container(),
        ],
      ),
      bottomNavigationBar: _current != null
          ? showPlayer
              ? null
              : GestureDetector(
                  onTap: () {
                    setState(() => showPlayer = true);

                    bottomSheetController = scaffoldKey.currentState
                        .showBottomSheet(
                            (BuildContext context) => _bottomSheetPlayer(),
                            elevation: 0.0,
                            backgroundColor: Colors.white.withOpacity(0));

                    bottomSheetController.closed.then((value) {
                      Future.delayed(Duration(milliseconds: 250),
                          () => setState(() => showPlayer = false));
                    });
                  },
                  child: Container(
                    color: dark ? Colors.grey.withOpacity(0.1) : Colors.white,
                    height: 60,
                    child: Column(
                      children: <Widget>[
                        Divider(
                          color: dark
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.4),
                          height: 1.0,
                          thickness: 0.7,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, top: 5, bottom: 5, right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  FadeTransition(
                                    opacity: animation,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      width: 45,
                                      height: 45,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        child: _current.imageURL != null
                                            ? Image.network(
                                                _current.imageURL,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                child: Center(
                                                    child: Icon(
                                                        Icons.music_note,
                                                        color: dark
                                                            ? Colors.white
                                                            : Colors.black45)),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.45,
                                        child: Text(
                                          HtmlCharacterEntities.decode(
                                              _current.title),
                                          style: TextStyle(
                                              color: dark
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 17.0,
                                              fontWeight: FontWeight.w400),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  IconButton(
                                      icon: !isPlaying
                                          ? FaIcon(FontAwesomeIcons.play,
                                              size: 18,
                                              color: dark
                                                  ? Colors.white
                                                  : Colors.black)
                                          : FaIcon(FontAwesomeIcons.pause,
                                              size: 18,
                                              color: dark
                                                  ? Colors.white
                                                  : Colors.black),
                                      onPressed: isPlaying
                                          ? () => pause()
                                          : () => resume()),
                                  IconButton(
                                    icon: FaIcon(FontAwesomeIcons.forward,
                                        size: 18,
                                        color:
                                            dark ? Colors.white : Colors.black),
                                    onPressed: () => next(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
          : Container(
              height: 0,
            ),
    );
  }

  Widget _buildAudiosList() {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      physics: BouncingScrollPhysics(),
      shrinkWrap: false,
      itemCount: audios.length + 1,
      itemBuilder: (context, i) {
        if (i == 0)
          return _buildButtons();
        else
          return _buildAudioTile(audios[i - 1]);
      },
    );
  }

  Widget _buildPlayLists() {
    return playlists.length != 0
        ? ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            shrinkWrap: false,
            itemCount: playlists.length,
            itemBuilder: (context, i) {
              return _buildPlaylist(i);
            },
          )
        : GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AudioPage()),
              );
            },
            child: Container(
              color: Colors.red,
              width: 100,
              height: 100,
            ),
          );
  }

  Widget _buildPlaylist(int index) {
    return Padding(
      padding: EdgeInsets.only(left: index == 0 ? 20.0 : 0.0, right: 15.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              /* Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AudioPage(
                          playlist: playlists[index],
                          player: audioPlayer,
                          current: _current,
                        )),
              );*/
              setState(() {
                playlistindex = index;
              });
              _myPage.animateToPage(1,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.fastLinearToSlowEaseIn);
            },
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  playlists[index].imageURL != null
                      ? playlists[index].imageURL
                      : playlists[index].audios[0].imageURL,
                  fit: BoxFit.cover,
                ), //: Icon(Icons.music_note, color: dark ? Colors.white : Colors.black45,),
              ),
            ),
          ),
          SizedBox(height: 3),
          Container(
            width: 125,
            child: Text(
              playlists[index].title,
              style: TextStyle(
                  fontSize: 15, color: dark ? Colors.white : Colors.black),
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          SizedBox(height: 2),
          Container(
            width: 125,
            child: Text(
              playlists[index].audios[0].artist,
              style: TextStyle(
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: EdgeInsets.only(top: 10.0, left: 0, right: 0, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 170, child: _buildPlayLists()),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 20, top: 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  splashColor: dark
                      ? Colors.grey.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: () {
                    setState(() {
                      _current = audios[0];
                    });
                    play(buildUrl(audios[0]));
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.42,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: dark
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.play_arrow_solid,
                          size: 17,
                          color: dark ? Colors.grey[300] : Colors.black,
                        ),
                        Text(
                          ' Слушать все',
                          style: TextStyle(
                            fontSize: 16,
                            color: dark ? Colors.grey[300] : Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                InkWell(
                  splashColor: dark
                      ? Colors.grey.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: () {
                    setState(() {
                      audios.shuffle();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: dark
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                    width: MediaQuery.of(context).size.width * 0.42,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.shuffle_thick,
                          size: 17,
                          color: dark ? Colors.grey[300] : Colors.black,
                        ),
                        Text(
                          ' Перемешать',
                          style: TextStyle(
                            fontSize: 16,
                            color: dark ? Colors.grey[300] : Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSheetPlayer() {
    return SafeArea(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            46,
        color: dark ? Colors.black : Colors.white,
        child: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
            Duration upset = duration - position;
            return Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  splashColor: Colors.grey.withOpacity(0.5),
                  icon: FaIcon(
                    FontAwesomeIcons.windowMinimize,
                    size: 28,
                    color: dark ? Colors.white : Colors.grey,
                  ),
                  onPressed: () {
                    bottomSheetController.close();
                  },
                ),
                Spacer(flex: 1),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    color: Colors.grey[800],
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10.0,
                        color: dark
                            ? Colors.grey.withOpacity(.1)
                            : Colors.black.withOpacity(.5),
                        offset: Offset(0.0, 0.0),
                      ),
                      BoxShadow(
                        blurRadius: 15.0,
                        spreadRadius: 5,
                        color: dark
                            ? Colors.grey.withOpacity(.3)
                            : Colors.black.withOpacity(.3),
                        offset: Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  height: MediaQuery.of(context).size.height / 2.8,
                  width: MediaQuery.of(context).size.height / 2.8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: _current.imageURL != null
                        ? Image.network(
                            _current.imageURL,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(Icons.music_note, size: 60),
                          ),
                  ),
                ),
                Spacer(flex: 1),
                Container(
                  width: MediaQuery.of(context).size.height / 2.5,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor:
                          dark ? Colors.grey[900] : Colors.grey[400],
                      trackHeight: 1.0,
                      thumbShape:
                          RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayColor: Colors.purple.withAlpha(32),
                      overlayShape:
                          RoundSliderOverlayShape(overlayRadius: 14.0),
                    ),
                    child: Slider(
                      value: !changing
                          ? snapshot.data == null ? 0.0 : snapshot.data
                          : changeValue,
                      onChanged: (value) async {
                        await audioPlayer.seekPosition(
                            Duration(milliseconds: value.toInt()));
                      },
                      min: 0.0,
                      max: duration != null
                          ? duration.inMilliseconds.toDouble() < 0.0
                              ? 0.1
                              : duration.inMilliseconds.toDouble()
                          : 0.1,
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.height / 2.7,
                  child: Padding(
                    padding: EdgeInsets.only(left: 0, right: 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          '${position.inMinutes.remainder(60)}:${position.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          '-${upset.inMinutes.remainder(60)}:${upset.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      ],
                    ),
                  ),
                ),
                Spacer(flex: 1),
                Container(
                  child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _current.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                        ),
                        Text(
                          _current.artist,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ]),
                ),
                Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Spacer(flex: 2),
                    IconButton(
                        splashColor: Colors.grey.withOpacity(0.5),
                        icon: Icon(Icons.shuffle,
                            color: dark ? Colors.grey[700] : Colors.grey[700],
                            size: 24),
                        onPressed: () {}),
                    Spacer(),
                    IconButton(
                        splashColor: Colors.grey.withOpacity(0.5),
                        icon: FaIcon(FontAwesomeIcons.backward,
                            color: dark ? Colors.white : Colors.grey[700],
                            size: 24),
                        onPressed: () => pervios()),
                    Spacer(),
                    IconButton(
                        splashColor: Colors.grey,
                        hoverColor: Colors.black,
                        focusColor: Colors.black,
                        highlightColor: Colors.green,
                        icon: FaIcon(
                            isPlaying
                                ? FontAwesomeIcons.pause
                                : FontAwesomeIcons.play,
                            color: dark ? Colors.white : Colors.grey[700],
                            size: 30),
                        onPressed: () => isPlaying ? pause() : resume()),
                    Spacer(),
                    IconButton(
                        splashColor: Colors.grey.withOpacity(0.5),
                        icon: FaIcon(FontAwesomeIcons.forward,
                            color: dark ? Colors.white : Colors.grey[700],
                            size: 24),
                        onPressed: () => next()),
                    Spacer(),
                    IconButton(
                        splashColor: Colors.white,
                        icon: Icon(Icons.replay,
                            color: dark ? Colors.grey[700] : Colors.grey[700],
                            size: 24),
                        onPressed: () {}),
                    Spacer(flex: 2),
                  ],
                ),
                Spacer(flex: 2),
                Row(
                  children: <Widget>[
                    Spacer(flex: 2),
                    FaIcon(FontAwesomeIcons.volumeOff,
                        color: dark ? Colors.white : Colors.grey[700],
                        size: 19),
                    Spacer(flex: 1),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor:
                            dark ? Colors.white : Colors.grey[800],
                        inactiveTrackColor:
                            dark ? Colors.grey[900] : Colors.grey[400],
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 10.0),
                        thumbColor: dark ? Colors.grey[200] : Colors.grey[800],
                      ),
                      child: Slider(
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) async {
                            volume = value;

                            await audioPlayer.setVolume(value);
                          }),
                    ),
                    Spacer(
                      flex: 1,
                    ),
                    FaIcon(FontAwesomeIcons.volumeUp,
                        color: dark ? Colors.white : Colors.grey[700],
                        size: 19),
                    Spacer(
                      flex: 2,
                    ),
                  ],
                ),
                Spacer(flex: 2),
              ],
            );
          },
          stream: _slider,
          initialData: position.inMilliseconds.toDouble(),
        ),
      ),
    );
  }

  Widget _buildAudioTile(Audio audio) {
    return GestureDetector(
      onTap: () {
        debugPrint('=================${audio.tempID}');
        if (_current == audio) return;
        setState(() {
          _current = audio;
        });
        if (isPaused || isPlaying) {
          debugPrint('stop tile');
          stop();
        }
        debugPrint('${audio.tempID}');
        controller.forward(from: 0.0);
        play(buildUrl(audio));
      },
      child: Container(
        decoration: BoxDecoration(
            color: _current == audio
                ? dark ? Colors.grey.withOpacity(0.3) : Colors.blueGrey[50]
                : dark ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(5)),
        padding: EdgeInsets.only(right: 10, left: 10, top: 5, bottom: 5),
        margin: EdgeInsets.only(right: 10, left: 10, top: 5, bottom: 5),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: dark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  height: 45,
                  width: 45,
                  child: Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5.0),
                        child: audio.imageURL != null
                            ? ColorFiltered(
                                colorFilter: _current == audio
                                    ? ColorFilter.mode(
                                        Colors.black.withOpacity(0.5),
                                        BlendMode.dstIn)
                                    : ColorFilter.mode(
                                        Colors.white.withOpacity(0.0),
                                        BlendMode.darken),
                                child: FadeInImage.assetNetwork(
                                  placeholder: 'images/music.jpg',
                                  image: audio.imageURL,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ColorFiltered(
                                colorFilter: _current == audio
                                    ? ColorFilter.mode(
                                        Colors.black.withOpacity(0.5),
                                        BlendMode.dstIn)
                                    : ColorFilter.mode(
                                        Colors.white.withOpacity(0.0),
                                        BlendMode.darken),
                                child: Container(
                                  color: dark ? Colors.black54 : Colors.black12,
                                  child: Center(
                                    child: Icon(Icons.music_note,
                                        color: dark
                                            ? Colors.white
                                            : Colors.black45),
                                  ),
                                ),
                              ),
                      ),
                      _current == audio
                          ? Center(
                              child: IconButton(
                                icon: FaIcon(
                                  isPlaying
                                      ? FontAwesomeIcons.pause
                                      : FontAwesomeIcons.play,
                                  size: 14,
                                  color: dark
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black.withOpacity(0.9),
                                ),
                                onPressed:
                                    isPlaying ? () => pause() : () => resume(),
                              ),
                            )
                          : Container(),
                      _current == audio
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  value: position != null &&
                                          position.inMilliseconds > 0
                                      ? (position?.inMilliseconds?.toDouble() ??
                                              0.0) /
                                          (duration?.inMilliseconds
                                                  ?.toDouble() ??
                                              0.0)
                                      : 0.0,
                                  valueColor: new AlwaysStoppedAnimation(dark
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black.withOpacity(0.7)),
                                  backgroundColor: Colors.black.withOpacity(0),
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.60,
                      child: Text(
                        HtmlCharacterEntities.decode(audio.title),
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w400,
                          color: dark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 3),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.60,
                      child: Text(
                        HtmlCharacterEntities.decode(audio.artist),
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              ],
            ),
            Text(
              '${audio.duration ~/ 60}:${(audio.duration % 60).toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
