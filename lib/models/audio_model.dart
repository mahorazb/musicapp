
class Audio {
  final String id;
  final String artist;
  final String title;
  final int duration;
  final String imageURL;
  final String url;
  final int tempID;
  static int temp = 0;

  Audio({this.id, this.artist, this.title, this.duration, this.imageURL, this.url, this.tempID});

  static clear() => temp = 0;

  factory Audio.fromJson(Map<String, dynamic> json) {
    temp++;
    var arr = json['duration'].split(":");
    return Audio(
      id: json['url'].split('=')[1].toString(),
      artist: json['artist'] as String,
      title: json['title'] as String,
      duration: int.parse(arr[1]) * 60 + int.parse(arr[2]),
      imageURL: json['image'] as String,
      url: json['url'] as String,
      tempID: temp,
    );
  }
}
