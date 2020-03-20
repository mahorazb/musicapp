
class Audio {
  final String id;
  final String artist;
  final String title;
  final int duration;
  final String imageURL;
  final String url;
  final int tempID;
  final int site;
  static int temp = 0;

  Audio({this.id, this.artist, this.title, this.duration, this.imageURL, this.url, this.tempID, this.site});

  static clear() => temp = 0;

  factory Audio.fromJson(Map<String, dynamic> json) {
    temp++;
    return Audio(
      id: json['id'] as String,
      artist: json['artist'] as String,
      title: json['title'] as String,
      duration: int.parse(json['duration'].toString()),
      imageURL: json['vkAlbumPictureUrl'] as String,
      url: json['url'] as String,
      tempID: temp,
      site: 0,
    );
  }
}
