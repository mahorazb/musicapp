import 'package:MusicApp/models/audio_model.dart';

class Playlist {
  final int id;
  final String urlid;
  final String title;
  final String artist;
  String imageURL;
  List<Audio> audios = List<Audio>();

  void addToList(Audio audio){
    audios.add(audio);
  }

  set setAll(List<Audio> value) => audios = value;

  Playlist({this.id, this.urlid, this.title, this.artist, this.imageURL});
  
}