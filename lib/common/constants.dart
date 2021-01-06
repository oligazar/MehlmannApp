// prod: https://mm.maehlmann-gemuesebau.de/de
// stg: https://mmg.webapp.is/de
//
// Admin: admin@mahlmann.com / password
// Driver: driver1@mahlmann.com / password
// Test: test.mobile@elie.de / 123456  // isAdmin=false !! change this !!


const String STAG = 'stag';
const String PROD = 'prod';

const AUTHORITY_PRODUCTION = "mm.maehlmann-gemuesebau.de"; // production
const AUTHORITY_STAGING = "mmg.webapp.is";
// staging
const TEST_PREFIX = "test."; // staging

const int RECEIVE_TIMEOUT = 20 * 1000;
const int SEND_TIMEOUT = 20 * 1000;

// Widget keys
const String LOGIN_BTN = 'loginBtn';


// Prefs
const String PREF_ADMIN = 'prefAdmin';
const String PREF_EXPIRY = 'prefExpiry';
const String PREF_EMAIL = 'prefEmail';
const String PREF_TOKEN = 'prefToken';

const String TABLE_GROUPS = 'tableGroups';
const String TABLE_FOUNTAINS = 'tableFountains';
const String TABLE_FIELDS = 'tableFields';

const String COL_ID = 'id';
const String COL_LAT = 'lat';
const String COL_LNG = 'lng';
const String COL_NAME = 'name';
const String COL_NOTE = 'note';
const String COL_AREA = 'area';
const String COL_EMAIL = 'email';
const String COL_COLOR = 'color';
const String COL_STATUS = 'status';
const String COL_CENTROID = 'centroid';
const String COL_FIELD_IDS = 'fieldIds';
const String COL_SAVE_TIME = 'save_time';
const String COL_IS_CABBAGE = 'is_cabbage';
const String COL_COORDINATES = 'coordinates';
const String PREF_BACKEND = "prefBackend";
const String PREF_LAST_UPDATE = "prefLastUpdate";

