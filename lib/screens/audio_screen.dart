import 'dart:ui';

import 'package:MusicApp/models/audio_model.dart';
import 'package:MusicApp/models/playlist_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html_character_entities/html_character_entities.dart';

class AudioPage extends StatefulWidget {
  final Playlist playlist;

  AudioPage({this.playlist});

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  var _current = 0;
  Playlist playlist;
  bool dark = true;

  @override
  Widget build(BuildContext context) {
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
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 45,),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.40,
                        height: MediaQuery.of(context).size.width * 0.40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          image: DecorationImage(
                            image: playlist.imageURL != null
                                ? NetworkImage(playlist.imageURL)
                                : playlist.audios[0].imageURL != null
                                    ? NetworkImage(playlist.audios[0].imageURL)
                                    : Container(
                                        color: Colors.black12,
                                        child: Center(
                                            child: Icon(Icons.music_note,
                                                color: dark
                                                    ? Colors.white60
                                                    : Colors.black45)),
                                      ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 25),
                          child: Container(
                            color: Colors.black.withOpacity(0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    IconButton(icon:  Icon(
                      CupertinoIcons.back,
                      size: 26,
                      color: dark ? Colors.white : Colors.black,
                    ), onPressed: (){
                      Navigator.pop(context);
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
                      height: 45,
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
                    SizedBox(height: 5,),
                    Column(
                      children: _buildAudiosList(),
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

  List<Widget> _buildAudiosList() {
    List<Widget> widgets = List<Widget>();

    for (int i = 0; i < playlist.audios.length; i++) {
      widgets.add(_buildAudioTile(playlist.audios[i]));
    }

    return widgets;
  }

  Widget _buildAudioTile(Audio audio) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: dark ? Colors.white.withOpacity(0) : Colors.white.withOpacity(0),
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
