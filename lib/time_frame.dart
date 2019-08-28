import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:quran_app/text_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class KhatmaScreen extends StatefulWidget {
  KhatmaScreenState createState() => KhatmaScreenState();
}

class KhatmaScreenState extends State<KhatmaScreen> {
  Future<SharedPreferences> _sPrefs = SharedPreferences.getInstance();
  String dropDownValue = 'Beginning of Quran';
  int startingJuz=1;
  int stackIndex = 0;
  int days=30;
  List<Juz> juzes = new List();
  Juz juz;
  DatabaseReference juzRef;
  int portion;
     @override
    void initState() { 
      juz = Juz("", "");
      final FirebaseDatabase database = FirebaseDatabase.instance;
      juzRef = database.reference().child('juzes');
      juzRef.onChildAdded.listen(_onJuzAdded);
    juzRef.onChildChanged.listen(_onJuzChanged);
      super.initState();
      
    }
    _onJuzAdded(Event event) {
    setState(() {
      juzes.add(Juz.fromSnapshot(event.snapshot));
    });
  }

  _onJuzChanged(Event event) {
    var old = juzes.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      juzes[juzes.indexOf(old)] = Juz.fromSnapshot(event.snapshot);
    });
  }

  Future<Null> setBookmark(int day,String startFrom,int portion) async {
    final SharedPreferences prefs = await _sPrefs;
    prefs.clear();
    prefs.setInt('day', day);
    prefs.setBool('seen', true);
    prefs.setString('startFrom', startFrom);
    prefs.setInt('portion', portion);
    prefs.setInt('currentDay',0);
  }
  @override
  Widget build(BuildContext context) {
    String calculate(){
     double i=(604-(startingJuz-1)*21)/days;
     int j=i.floor();
     int z=i.ceil();
     

     if(i>(j+0.1) && i<(z-0.1)){
       portion=int.parse(j.toString());
       return j.toString() + " or " + z.toString();
     }else if(i<=(j+0.1)){
       portion=int.parse(j.toString());
       return j.toString();
     }else if(i>=(z-0.1)){
       portion=int.parse(z.toString());
       return z.toString();
     }
      
    }
    // TODO: implement build
    return Scaffold(
        appBar: new AppBar(
          title: Text("New Khatmah"),
        ),
        body: new Container(
          margin: new EdgeInsets.symmetric(vertical: 120.0),
          child: new Column(
            children: <Widget>[
              IndexedStack(
                index: stackIndex,
                children: <Widget>[
                  new Column(
                    children: <Widget>[
                      new Text(
                        "From where do you wish to start your Khatmah?",
                        textAlign: TextAlign.center,
                        style: Style.cardQuranTextStyle,
                      ),
                      new Container(
                        margin: new EdgeInsets.only(top: 100.0),
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Text("Start from:    ",
                                style: new TextStyle(
                                  fontSize: 16.0,
                                )),
                            new DropdownButton(
                              value: dropDownValue,
                              onChanged: (String newValue) {
                                setState(() {
                                  dropDownValue = newValue;
                                });
                              },
                              items: <String>[
                                'Beginning of Quran',
                                'Juz\' 2',
                                'Juz\' 3',
                                'Juz\' 4',
                                'Juz\' 5',
                                'Juz\' 6',
                                'Juz\' 7',
                                'Juz\' 8',
                                'Juz\' 9',
                                'Juz\' 10',
                                'Juz\' 11',
                                'Juz\' 12',
                                'Juz\' 13',
                                'Juz\' 14',
                                'Juz\' 15',
                                'Juz\' 16',
                                'Juz\' 17',
                                'Juz\' 18',
                                'Juz\' 19',
                                'Juz\' 20',
                                'Juz\' 21',
                                'Juz\' 22',
                                'Juz\' 23',
                                'Juz\' 24',
                                'Juz\' 25',
                                'Juz\' 26',
                                'Juz\' 27',
                                'Juz\' 28',
                                'Juz\' 29',
                                'Juz\' 30'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ),
                      new Container(
                        margin: new EdgeInsets.only(top: 100.0),
                        child: RaisedButton(
                          onPressed: () {
                            setState(() {
                              stackIndex = 1;
                              if(dropDownValue=="Beginning of Quran")
                              startingJuz=1;
                              else
                              startingJuz=int.parse(dropDownValue.substring(5));
                            });
                          },
                          child: new Text(
                              "                  Continue                  "),
                        ),
                      )
                    ],
                  ),
                  new Column(
                    children: <Widget>[
                      new Text(
                        "In how many days do you want to finish reading the Quran?",
                        textAlign: TextAlign.center,
                        style: Style.cardQuranTextStyle,
                      ),
                      new Container(
                        margin: new EdgeInsets.only(top: 100.0),
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Text("Start from:    ",
                                style: new TextStyle(
                                  fontSize: 16.0,
                                )),
                            new Text(
                             days.toString(),
                            ),
                            new IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  days++;
                                });
                              },
                            ),
                            new IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  days--;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
      new Text(calculate()),

                      new Container(
                          margin: new EdgeInsets.only(top: 100.0),
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              RaisedButton(
                                onPressed: () {
                                  setState(() {
                                    stackIndex = 0;
                                  });
                                },
                                child: new Text("         Back         "),
                              ),
                              RaisedButton(
                                onPressed: () {

                                  setBookmark(days, juzes[startingJuz-1].page, portion);
                                    Navigator.of(context).pushReplacement(
                                        new MaterialPageRoute(
                                            builder: (context) =>
                                                new MyApp()));
                                
                                },
                                child: new Text("      Continue       "),
                              ),
                            ],
                          ))
                    ],
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
