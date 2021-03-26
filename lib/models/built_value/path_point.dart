library path_point;

import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/interfaces/time_saveable.dart';

class PathPoint extends TimeSaveable {
  
  int id;
  double lat;
  double lng;
  int _saveTime;
  @override
  int get saveTime => _saveTime;

  PathPoint({
    this.id,
    this.lat,
    this.lng,
    int saveTime,
  });


  @override
  Map<String, dynamic> toMap() => toDb();

  factory PathPoint.fromMap(Map<String, dynamic> map) => PathPoint.fromDb(map);

  Map<String, dynamic> toDb() {
    return {
      COL_ID: this.id,
      COL_LAT: this.lat,
      COL_LNG: this.lng,
      COL_SAVE_TIME: this.saveTime ?? 0,
    };
  }

  factory PathPoint.fromDb(Map<String, dynamic> map) => PathPoint(
    id: map[COL_ID] as int,
    lat: map[COL_LAT] as double,
    lng: map[COL_LNG] as double,
    saveTime: map[COL_SAVE_TIME] as int,
  );
  
  static List<String> queryColumns = [
    COL_ID,
    COL_LAT,
    COL_LNG,
    COL_SAVE_TIME,
  ];
  
  static String tableCreator = '''
              CREATE TABLE $TABLE_PATH_POINTS (
                $COL_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COL_LAT REAL,
                $COL_LNG REAL,
                $COL_SAVE_TIME INTEGER
              )
              ''';
}