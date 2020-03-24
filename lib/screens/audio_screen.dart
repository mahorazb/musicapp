import 'dart:ui';

import 'package:MusicApp/models/audio_model.dart';
import 'package:MusicApp/models/playlist_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exoplayer/audioplayer.dart';
import 'package:html_character_entities/html_character_entities.dart';

class AudioPage extends StatefulWidget {
  final Playlist playlist;
  final AudioPlayer player;
  final Audio current;
  final PageController myPage;

  AudioPage({this.myPage, this.playlist, this.player, this.current});

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage>
    with SingleTickerProviderStateMixin {
  Audio _current;
  Playlist playlist;
  bool dark = true;

  AnimationController controller;
  Animation animation;
  PlayerState playerState;

  get isPlaying => playerState == PlayerState.PLAYING;
  get isPaused => playerState == PlayerState.PAUSED;

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    new Future.delayed(
      Duration(milliseconds: 250),
      () => controller.forward(),
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _current = widget.current;
    playerState = widget.player.state;
    playlist = widget.playlist;

    return Scaffold(
      backgroundColor: dark ? Colors.black : Colors.white,
      body: Container(
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: BouncingScrollPhysics(),
            child: Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                        icon: Icon(
                          CupertinoIcons.back,
                          size: 26,
                          color: dark ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          controller.reverse();
                          widget.myPage.animateToPage(0,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.fastLinearToSlowEaseIn);
                          //Navigator.pop(context);
                        }),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    /*Padding(
                      padding: const EdgeInsets.only(top: 5, left: 5),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            CupertinoIcons.back,
                            size: 28,
                            color: dark ? Colors.white : Colors.black,
                          )
                        ],
                      ),
                    ),*/
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: playlist.imageURL != null
                            ? Image.network(
                                playlist.imageURL,
                                fit: BoxFit.cover,
                              )
                            : playlist.audios[0].imageURL != null
                                ? Image.network(
                                    playlist.audios[0].imageURL,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.black12,
                                    child: Center(
                                        child: Icon(Icons.music_note,
                                            color: Colors.black45)),
                                  ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Text(
                          playlist.title,
                          style: TextStyle(
                            color: dark ? Colors.white : Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      playlist.audios[0].artist,
                      style: TextStyle(
                        fontSize: 15.0,
                        color: dark ? Colors.grey[600] : Colors.grey[700],
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    FadeTransition(
                      opacity: animation,
                      child: Container(child: _buildAudiosList()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudiosList() {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
      itemCount: playlist.audios.length,
      itemBuilder: (context, i) {
        return _buildAudioTile(playlist.audios[i]);
      },
    );
  }

  Widget _buildAudioTile(Audio audio) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color:
              dark ? Colors.white.withOpacity(0) : Colors.white.withOpacity(0),
          borderRadius: BorderRadius.circular(5),
        ),
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
                                        Colors.white, BlendMode.darken),
                                child: Image.network(
                                  audio.imageURL,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                ),
                              )
                            : ColorFiltered(
                                colorFilter: _current == audio
                                    ? ColorFilter.mode(
                                        Colors.black.withOpacity(0.5),
                                        BlendMode.dstIn)
                                    : ColorFilter.mode(
                                        Colors.white, BlendMode.darken),
                                child: Container(
                                  color: Colors.black12,
                                  child: Center(
                                    child: Icon(Icons.music_note,
                                        color: Colors.black45),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                          color: dark ? Colors.grey[600] : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 5),
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
