import 'package:flutter/widgets.dart';

class Team extends Comparable {
  final int id;
  final String city;
  final String name;
  final String abbreviation;
  final Color primaryColor;
  final Color secondaryColor;

  Team(this.id, this.city, this.name, this.abbreviation, this.primaryColor,
      this.secondaryColor);

  static Map<int, Team> mlbTeams = {
    108: Team(108, "Los Angeles", "Angels", "LAA",
        Color.fromRGBO(186, 0, 33, 1.0), Color.fromRGBO(196, 206, 212, 1.0)),
    109: Team(109, "Arizona", "D-backs", "ARI",
        Color.fromRGBO(167, 25, 48, 1.0), Color.fromRGBO(227, 212, 173, 1.0)),
    110: Team(110, "Baltimore", "Orioles", "BAL",
        Color.fromRGBO(223, 70, 1, 1.0), Color.fromRGBO(39, 37, 31, 1.0)),
    111: Team(111, "Boston", "Red Sox", "BOS", Color.fromRGBO(198, 1, 31, 1.0),
        Color.fromRGBO(255, 255, 255, 1.0)),
    112: Team(112, "Chicago", "Cubs", "CHC", Color.fromRGBO(14, 51, 134, 1.0),
        Color.fromRGBO(204, 52, 51, 1.0)),
    113: Team(113, "Cincinnati", "Reds", "CIN", Color.fromRGBO(198, 1, 31, 1.0),
        Color.fromRGBO(0, 0, 0, 1.0)),
    114: Team(114, "Cleveland", "Indians", "CLE",
        Color.fromRGBO(227, 25, 55, 1.0), Color.fromRGBO(12, 35, 64, 1.0)),
    115: Team(115, "Colorado", "Rockies", "COL",
        Color.fromRGBO(51, 0, 111, 1.0), Color.fromRGBO(196, 206, 212, 1.0)),
    116: Team(116, "Detroit", "Tigers", "DET", Color.fromRGBO(12, 35, 64, 1.0),
        Color.fromRGBO(250, 70, 22, 1.0)),
    117: Team(117, "Houston", "Astros", "HOU", Color.fromRGBO(0, 45, 98, 1.0),
        Color.fromRGBO(244, 145, 30, 1.0)),
    118: Team(118, "Kansas", "Royals", "KC", Color.fromRGBO(0, 70, 135, 1.0),
        Color.fromRGBO(189, 155, 96, 1.0)),
    119: Team(119, "Los Angeles", "Dodgers", "LAD",
        Color.fromRGBO(0, 90, 156, 1.0), Color.fromRGBO(239, 62, 66, 1.0)),
    120: Team(120, "Washington", "Nationals", "WSH",
        Color.fromRGBO(171, 0, 3, 1.0), Color.fromRGBO(20, 34, 90, 1.0)),
    121: Team(121, "New York", "Mets", "NYM", Color.fromRGBO(0, 45, 114, 1.0),
        Color.fromRGBO(252, 89, 16, 1.0)),
    133: Team(133, "Oakland", "Athletics", "OAK",
        Color.fromRGBO(0, 56, 49, 1.0), Color.fromRGBO(239, 178, 30, 1.0)),
    134: Team(134, "Pittsburgh", "Pirates", "PIT",
        Color.fromRGBO(253, 184, 39, 1.0), Color.fromRGBO(39, 37, 31, 1.0)),
    135: Team(135, "San Diego", "Padres", "SD", Color.fromRGBO(0, 45, 98, 1.0),
        Color.fromRGBO(162, 170, 173, 1.0)),
    136: Team(136, "Seattle", "Mariners", "SEA", Color.fromRGBO(0, 92, 92, 1.0),
        Color.fromRGBO(196, 206, 212, 1.0)),
    137: Team(137, "San Francisco", "Giants", "SF",
        Color.fromRGBO(39, 37, 31, 1.0), Color.fromRGBO(253, 90, 30, 1.0)),
    138: Team(138, "St. Louis", "Cardinals", "STL",
        Color.fromRGBO(196, 30, 58, 1.0), Color.fromRGBO(12, 35, 64, 1.0)),
    139: Team(139, "Tampa Bay", "Rays", "TB", Color.fromRGBO(214, 90, 36, 1.0),
        Color.fromRGBO(255, 255, 255, 1.0)),
    140: Team(140, "Texas", "Rangers", "TEX", Color.fromRGBO(0, 50, 120, 1.0),
        Color.fromRGBO(192, 17, 31, 1.0)),
    141: Team(141, "Toronto", "Blue Jays", "TOR",
        Color.fromRGBO(19, 74, 142, 1.0), Color.fromRGBO(177, 179, 179, 1.0)),
    142: Team(142, "Minnesota", "Twins", "MIN", Color.fromRGBO(0, 43, 92, 1.0),
        Color.fromRGBO(211, 17, 69, 1.0)),
    143: Team(143, "Philadelphia", "Phillies", "PHI",
        Color.fromRGBO(232, 24, 40, 1.0), Color.fromRGBO(0, 45, 114, 1.0)),
    144: Team(144, "Atlanta", "Braves", "ATL", Color.fromRGBO(19, 39, 79, 1.0),
        Color.fromRGBO(206, 17, 65, 1.0)),
    145: Team(145, "Chicago", "White Sox", "CWS",
        Color.fromRGBO(39, 37, 31, 1.0), Color.fromRGBO(196, 206, 212, 1.0)),
    146: Team(146, "Miami", "Marlins", "MIA", Color.fromRGBO(0, 0, 0, 1.0),
        Color.fromRGBO(0, 163, 224, 1.0)),
    147: Team(147, "New York", "Yankees", "NYY",
        Color.fromRGBO(12, 35, 64, 1.0), Color.fromRGBO(255, 255, 255, 1.0)),
    158: Team(158, "Milkwaukee", "Brewers", "MIL",
        Color.fromRGBO(19, 41, 75, 1.0), Color.fromRGBO(182, 146, 46, 1.0))
  };

  static Map<int, Team> nhlTeams = {
    1: Team(1, "New Jersey", "Devils", "NJD", Color.fromRGBO(200, 16, 46, 1.0),
        Color.fromRGBO(0, 0, 0, 1.0)),
    2: Team(2, "New York", "Islanders", "NYI", Color.fromRGBO(0, 48, 135, 1.0),
        Color.fromRGBO(252, 76, 2, 1.0)),
    3: Team(3, "New York", "Rangers", "NYR", Color.fromRGBO(0, 51, 160, 1.0),
        Color.fromRGBO(200, 16, 46, 1.0)),
    4: Team(4, "Philadelphia", "Flyers", "PHI",
        Color.fromRGBO(250, 70, 22, 1.0), Color.fromRGBO(0, 0, 0, 1.0)),
    5: Team(5, "Pittsburgh", "Penguins", "PIT",
        Color.fromRGBO(255, 184, 28, 1.0), Color.fromRGBO(0, 0, 0, 1.0)),
    6: Team(6, "Boston", "Bruins", "BOS", Color.fromRGBO(252, 181, 20, 1.0),
        Color.fromRGBO(0, 0, 0, 1.0)),
    7: Team(7, "Buffalo", "Sabres", "BUF", Color.fromRGBO(0, 38, 84, 1.0),
        Color.fromRGBO(252, 181, 20, 1.0)),
    8: Team(8, "Montréal", "Canadiens", "MTL", Color.fromRGBO(166, 25, 46, 1.0),
        Color.fromRGBO(0, 30, 98, 1.0)),
    9: Team(9, "Ottawa", "Senators", "OTT", Color.fromRGBO(200, 16, 46, 1.0),
        Color.fromRGBO(198, 146, 20, 1.0)),
    10: Team(10, "Toronto", "Maple Leafs", "TOR",
        Color.fromRGBO(0, 32, 91, 1.0), Color.fromRGBO(255, 255, 255, 1.0)),
    12: Team(12, "Carolina", "Hurricanes", "CAR",
        Color.fromRGBO(204, 0, 0, 1.0), Color.fromRGBO(162, 169, 175, 1.0)),
    13: Team(13, "Florida", "Panthers", "FLA", Color.fromRGBO(200, 16, 46, 1.0),
        Color.fromRGBO(185, 151, 91, 1.0)),
    14: Team(14, "Tampa Bay", "Lightning", "TBL",
        Color.fromRGBO(0, 32, 91, 1.0), Color.fromRGBO(255, 255, 255, 1.0)),
    15: Team(15, "Washington", "Capitals", "WSH",
        Color.fromRGBO(4, 30, 66, 1.0), Color.fromRGBO(200, 16, 46, 1.0)),
    16: Team(16, "Chicago", "Blackhawks", "CHI",
        Color.fromRGBO(206, 17, 38, 1.0), Color.fromRGBO(255, 255, 255, 1.0)),
    17: Team(17, "Detroit", "Red Wings", "DET",
        Color.fromRGBO(200, 16, 46, 1.0), Color.fromRGBO(255, 255, 255, 1.0)),
    18: Team(18, "Nashville", "Predators", "NSH",
        Color.fromRGBO(255, 184, 28, 1.0), Color.fromRGBO(4, 30, 66, 1.0)),
    19: Team(19, "St. Louis", "Blues", "STL", Color.fromRGBO(0, 47, 135, 1.0),
        Color.fromRGBO(255, 184, 28, 1.0)),
    20: Team(20, "Calgary", "Flames", "CGY", Color.fromRGBO(206, 17, 38, 1.0),
        Color.fromRGBO(243, 188, 82, 1.0)),
    21: Team(21, "Colorado", "Avalanche", "COL",
        Color.fromRGBO(111, 38, 61, 1.0), Color.fromRGBO(35, 97, 146, 1.0)),
    22: Team(22, "Edmonton", "Oilers", "EDM", Color.fromRGBO(252, 76, 2, 1.0),
        Color.fromRGBO(4, 30, 66, 1.0)),
    23: Team(23, "Vancouver", "Canucks", "VAN", Color.fromRGBO(0, 136, 82, 1.0),
        Color.fromRGBO(0, 32, 91, 1.0)),
    24: Team(24, "Anaheim", "Ducks", "ANA", Color.fromRGBO(249, 86, 2, 1.0),
        Color.fromRGBO(181, 152, 90, 1.0)),
    25: Team(25, "Dallas", "Stars", "DAL", Color.fromRGBO(0, 99, 65, 1.0),
        Color.fromRGBO(162, 170, 173, 1.0)),
    26: Team(26, "Los Angeles", "Kings", "LAK",
        Color.fromRGBO(162, 170, 173, 1.0), Color.fromRGBO(0, 0, 0, 1.0)),
    28: Team(28, "San Jose", "Sharks", "SJS", Color.fromRGBO(0, 98, 114, 1.0),
        Color.fromRGBO(229, 114, 0, 1.0)),
    29: Team(29, "Columbus", "Blue Jackets", "CBJ",
        Color.fromRGBO(4, 30, 66, 1.0), Color.fromRGBO(200, 16, 46, 1.0)),
    30: Team(30, "Minnesota", "Wild", "MIN", Color.fromRGBO(21, 71, 52, 1.0),
        Color.fromRGBO(166, 25, 46, 1.0)),
    52: Team(52, "Winnipeg", "Jets", "WPG", Color.fromRGBO(4, 30, 66, 1.0),
        Color.fromRGBO(162, 170, 173, 1.0)),
    53: Team(53, "Arizona", "Coyotes", "ARI", Color.fromRGBO(140, 38, 51, 1.0),
        Color.fromRGBO(226, 214, 181, 1.0)),
    54: Team(54, "Vegas", "Golden Knights", "VGK",
        Color.fromRGBO(185, 151, 91, 1.0), Color.fromRGBO(0, 0, 0, 1.0))
  };

  @override
  int compareTo(other) {
    return this.city.compareTo(other.city);
  }

  @override
  String toString() {
    return city + " " + name;
  }
}
