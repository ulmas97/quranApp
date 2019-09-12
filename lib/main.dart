import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as prefix0;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:quran_app/reader_page.dart';
import 'package:quran_app/text_style.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import 'dua_reader.dart';

void main() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.lightBlue[800],
        accentColor: Colors.cyan[600],
        scaffoldBackgroundColor: Colors.grey[100],

        // Define the default font family.
        fontFamily: 'Montserrat',

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      home: MyHomePage(title: 'Current Session'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  FlutterLocalNotificationsPlugin localNotificationsPlugin;

  bool firstDone = false;
  AnimationController controller, secondController;
  Animation animation, secondAnimation;
  int _bookmark;
  bool _seen;
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = (prefs.getBool('seen') ?? false);
    _bookmark = (prefs.getInt('bookmark') ?? 0);
    if (!_seen) {
      prefs.setBool('seen', true);
      stackIndex = 1;
    }
  }

  String morningAthkarHour;
  String morningAthkarMinute;
  String eveningAthkarHour;
  String eveningAthkarMinute;
  String mulkHour;
  String mulkMinute;
  String baqarahHour;
  String baqarahMinute;
  String khatmahHour;
  String khatmahMinute;
  bool isKhatmahSet;
  bool isMorningAthkarSet;
  bool isNightAthkarSet;
  bool isMulkSet;
  bool isKahfSet;
  bool isBaqarahSet;
  String assetPDFPath = "";
  List<Page> pages = new List();
  List<Book> books = new List();
  List<Juz> juzes = new List();
  List<String> duaTitles = new List();
  Juz juz;
  Page page;
  Book book;
  int day;
  int portion;
  String startFrom;
  int currentDay;
  String dropDownValue = '1 week';
  int startingJuz = 1;
  int stackIndex = 0;
  int days = 30;
  int thumbNumber = 0;
  DatabaseReference pageRef;
  DatabaseReference bookRef;
  DatabaseReference juzRef;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  int _currentPage = 0;
  TabController _tabController;
  bool pdfReady = false;
  
  void initializeNotifications() async {
    var initializeAndroid = AndroidInitializationSettings('app_icon');
    var initializeIOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(initializeAndroid, initializeIOS);
    await localNotificationsPlugin.initialize(initSettings,
        onSelectNotification: kkk);
  }

  @override
  void initState() {
    getNotifications();
    duaTitles = [
      'المقدمات',
      'الاساسيات',
      'البركات و طلب الرزق الدنيوي و الاخروي',
      'المعاملات',
      '‫ذكر طرفي النهار‬',
      'المحمدات‬‬',
      '‫الحرز و الحماية',
      '‫الادعية الجوامع‬‬',
      '‫أدعية في الابتهال وطلب المغفرة‬',
      'في التقرب و التحبب إلى الله‬',
      'القرآنيات',
      'الابتهالات و التضرع و شكوى الغربة‬‬',
      'الدعاء الخاص و العام من العالمين',
      'الذكر المكرر الضروري‬‬',
      'الختام'
    ];
    page = Page("", "");
    juz = Juz("", "");
    book = Book("", "", "", "", "");
    final FirebaseDatabase database = FirebaseDatabase.instance;
    pageRef = database.reference().child('pages');
    bookRef = database.reference().child('books');
    juzRef = database.reference().child('juzes');
    /*bookRef.once().then((DataSnapshot snapshot) {
          var KEYS = snapshot.value.keys;
          var DATA = snapshot.value;
          books.clear();
          for (var individualKey in KEYS) {
            Book b = new Book(
                DATA[individualKey]['title'],
                DATA[individualKey]['page'],
                DATA[individualKey]['juz'],
                DATA[individualKey]['ayah'],
                DATA[individualKey]['verse']);
                books.add(b);
          }
        });*/
    pageRef.onChildAdded.listen(_onEntryAdded);
    pageRef.onChildChanged.listen(_onEntryChanged);
    juzRef.onChildAdded.listen(_onJuzAdded);
    juzRef.onChildChanged.listen(_onJuzChanged);
    bookRef.onChildAdded.listen(_onBookAdded);
    bookRef.onChildChanged.listen(_onBookChanged);
    localNotificationsPlugin = FlutterLocalNotificationsPlugin();

    getAllInfo();

    checkFirstSeen();

    getPeriod().then((int value) {
      setState(() {
        thumbNumber = currentDay - value;
      });
      initializeNotifications();
    });
    getFileFromAsset("assets/quran_cropped.pdf", 'quran_cropped.pdf').then((f) {
      setState(() {
        assetPDFPath = f.path;
        
      });
    });

    controller = new AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    secondController = new AnimationController(
      duration: Duration(milliseconds: 350),
      vsync: this,
    );
    animation = new Tween(begin: 0.0, end: -350.0).animate(controller)
      ..addListener(() {
        setState(() {});
      });
    secondAnimation =
        new Tween(begin: 350.0, end: 0.0).animate(secondController)
          ..addListener(() {
            setState(() {});
          });
    animation.addStatusListener(animationStatusListener);
    secondAnimation.addStatusListener(secondAnimationStatusListener);

    // calcuta();
    //  setBookmark();

    _tabController = TabController(vsync: this, length: 2);
    super.initState();
  }

  Future singleNotification(Time time, String message, String subText,
      int hashcode, bool enabled, String payload,
      {String sound}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(hashcode.toString() + 'hour', time.hour.toString());
    prefs.setString(hashcode.toString() + 'minute', time.minute.toString());
    prefs.setBool(hashcode.toString() + 'bool', enabled);
    var androidChannel = AndroidNotificationDetails(
      'channel-di',
      'channel-name',
      'channel-description',
      priority: Priority.Max,
      importance: Importance.Max,
    );
    var iosChannel = IOSNotificationDetails();
    var platformChannel = NotificationDetails(androidChannel, iosChannel);
    if (enabled) {
      await localNotificationsPlugin.showDailyAtTime(
          hashcode, message, subText, time, platformChannel,
          payload: payload);
    } else {
      await localNotificationsPlugin.cancel(hashcode);
    }
  }

  Future weeklyNotification(
      String message, String subText, int hashcode, bool enabled,
      {String sound}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(hashcode.toString() + 'bool', enabled);
    var androidChannel = AndroidNotificationDetails(
      'channel-di',
      'channel-name',
      'channel-description',
      priority: Priority.Max,
      importance: Importance.Max,
    );
    var iosChannel = IOSNotificationDetails();
    var platformChannel = NotificationDetails(androidChannel, iosChannel);
    if (enabled) {
      await localNotificationsPlugin.showWeeklyAtDayAndTime(hashcode, message,
          subText, Day.Friday, Time(8, 0, 0), platformChannel);
    } else {
      await localNotificationsPlugin.cancel(hashcode);
    }
  }

  setCurrentTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var now = new DateTime.now();
    int a = now.millisecondsSinceEpoch.toInt();
    prefs.setInt('initTime', a);
  }

  Future<int> getPeriod() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int initTime = prefs.getInt('initTime');
    var now = new DateTime.now();
    int a = now.millisecondsSinceEpoch.toInt();
    int seconds = ((a - initTime) / 1000).floor();
    int days = (((seconds / 60) / 60) / 24).floor();
    return days;
  }

  getNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    morningAthkarHour = prefs.getString('222hour') ?? '12';
    morningAthkarMinute = prefs.getString('222minute') ?? '0';
    eveningAthkarHour = prefs.getString('333hour') ?? '12';
    eveningAthkarMinute = prefs.getString('333minute') ?? '0';
    mulkHour = prefs.getString('444hour') ?? '12';
    mulkMinute = prefs.getString('444minute') ?? '0';
    baqarahHour = prefs.getString('555hour') ?? '12';
    baqarahMinute = prefs.getString('555minute') ?? '0';
    khatmahHour = prefs.getString('654657hour') ?? '12';
    khatmahMinute = prefs.getString('654657minute') ?? '0';
    isKhatmahSet = prefs.getBool('654657bool') ?? true;
    isMorningAthkarSet = prefs.getBool('222bool') ?? true;
    isNightAthkarSet = prefs.getBool('333bool') ?? true;
    isMulkSet = prefs.getBool('444bool') ?? true;
    isBaqarahSet = prefs.getBool('555bool') ?? true;
    isKahfSet = prefs.getBool('777bool') ?? true;
  }

  setAllInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('startFrom', juzes[startingJuz - 1].page);
    prefs.setInt('portion', portion);
    prefs.setInt('day', days);
    prefs.setInt('currentDay', 0);
  }

  incrementAllInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('startFrom', (int.parse(startFrom) + portion).toString());
    prefs.setInt('portion', portion);
    prefs.setInt('day', day);
    prefs.setInt('currentDay', ++currentDay);
  }

  Future getAllInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    startFrom = (prefs.getString('startFrom') ?? '1');
    portion = (prefs.getInt('portion') ?? 0);
    day = (prefs.getInt('day') ?? 0);
    currentDay = (prefs.getInt('currentDay') ?? 0);
  }

  void animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      portion = ((604 - int.parse(startFrom)) / (day - currentDay)).floor();

      incrementAllInfo();
      getPeriod().then((int value) {
        setState(() {
          thumbNumber = currentDay - value;
        });
      });
      secondController.forward();
      firstDone = true;
      controller.reverse();
      getAllInfo();
    }
  }

  void secondAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      firstDone = false;
      secondController.reverse();
    }
  }

  Future<File> getFileFromAsset(String asset, String fileName) async {
    try {
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/$fileName");

      File assetFile = await file.writeAsBytes(bytes);
      return assetFile;
    } catch (e) {
      throw Exception("Error opening asset file");
    }
  }

  _onEntryAdded(Event event) {
    setState(() {
      pages.add(Page.fromSnapshot(event.snapshot));
    });
  }

  _onJuzAdded(Event event) {
    setState(() {
      juzes.add(Juz.fromSnapshot(event.snapshot));
    });
  }

  _onBookAdded(Event event) {
    setState(() {
      books.add(Book.fromSnapshot(event.snapshot));
    });
  }

  _onEntryChanged(Event event) {
    var old = pages.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      pages[pages.indexOf(old)] = Page.fromSnapshot(event.snapshot);
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

  _onBookChanged(Event event) {
    var old = books.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      books[books.indexOf(old)] = Book.fromSnapshot(event.snapshot);
    });
  }

  void handleSubmit() {
    final FormState form = formKey.currentState;

    if (form.validate()) {
      form.save();
      form.reset();
      juzRef.push().set(juz.toJson());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    controller.dispose();
    secondController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget grdidCard(String text) {
      return new Card(
        margin: new EdgeInsets.all(8),
        elevation: 5.0,
        child: new Container(
          width: (MediaQuery.of(context).size.width / 2) - 100,
          height: (MediaQuery.of(context).size.width / 2) - 100,
          child: new Center(
              child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          )),
        ),
      );
    }

    final sessionCardContent = new Card(
      elevation: 5.0,
      child: new Container(
        margin: new EdgeInsets.all(8.0),
        child: new Column(
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(
                  "Starts From",
                  style: Style.cardTextStyle,
                ),
                new Text(
                  "Juz'" +
                      (books.isEmpty ? '1' : books[int.parse(startFrom)].juz),
                  style: Style.cardTextStyle,
                )
              ],
            ),
            new Container(
              height: 60.0,
            ),
            new Center(
                child: new Text(
              books.isEmpty ?'بِسمِ اللَّهِ الرَّحمٰنِ الرَّحيمِ' : books[int.parse(startFrom)-1].verse,
              style: Style.cardQuranTextStyle,
            )),
            new Container(
              height: 60.0,
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(
                  "Surat " +
                      (books.isEmpty
                          ? '1 - Aya 106'
                          : books[int.parse(startFrom)].title +
                              " - Aya " +
                              books[int.parse(startFrom)-1].ayah),
                  style: Style.cardTextStyle,
                ),
                new Text(
                  "Page " + startFrom,
                  style: Style.cardTextStyle,
                ),
              ],
            ),
            new Container(
              height: 7.0,
            ),
            new Divider(
              height: 1.0,
            ),
            new Container(
              height: 7.0,
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(
                  int.parse(startFrom) >= 604
                      ? ''
                      : "To Surat " +
                          (books.isEmpty
                              ? '1 - Aya 157'
                              : books[int.parse(startFrom) + portion].title+
                                  ' - Aya '+
                                  books[int.parse(startFrom)-1 + portion]
                                      .ayah),
                  style: Style.cardTextStyle,
                ),
                new Text(
                  int.parse(startFrom) >= 604
                      ? ' '
                      : "Page " + (int.parse(startFrom) + portion).toString(),
                  style: Style.cardTextStyle,
                ),
              ],
            )
          ],
        ),
      ),
    );

    final endingCard = new Container(
      //margin: new EdgeInsets.only(top: 30.0),
      alignment: Alignment.center,
      child: new Text(
        "تهانينا\nلقد أكملت خاتمك\nاضغط على زر الإضافة لبدء خطمة جديدة",
        style: Style.cardQuranTextStyle,
        textAlign: TextAlign.center,
      ),
    );

    final sessionCard = Transform.translate(
        child: new Container(
          margin: new EdgeInsets.all(10.0),
          // height: 200,
          child: new SizedBox(
            height: 260.0,
            child:
                int.parse(startFrom) >= 603 ? endingCard : sessionCardContent,
          ),
        ),
        offset: firstDone == false
            ? Offset(animation.value, 0.0)
            : Offset(secondAnimation.value, 0.0));

    final readingButtons = new Container(
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ButtonTheme(
            minWidth: 155.0,
            height: 50.0,
            buttonColor: Colors.lightBlue[800],
            child: new RaisedButton(
                child: Text(
                  'Continue Reading',
                  style: new TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                onPressed: startFrom == '604'
                    ? null
                    : () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PdfViewPage(
                                      path: assetPDFPath,
                                      pageNumber:
                                          (int.parse(startFrom) - 1).toString(),
                                      portion: portion,
                                      lastDay:
                                          int.parse(startFrom) - 1 + portion,
                                    )));
                      }),
          ),
          ButtonTheme(
            minWidth: 155.0,
            height: 50.0,
            buttonColor: Colors.lightGreenAccent[700],
            child: new RaisedButton(
              child: Text(
                "Done Reading",
                style:
                    new TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              onPressed: startFrom == '604'
                  ? null
                  : () {
                      controller.forward();
                    },
            ),
          ),
        ],
      ),
    );

    final khatmaProgress = new Container(
      margin: new EdgeInsets.all(15.0),
      child: new Column(
        children: <Widget>[
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text(
                "Khatma Sessions",
                style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                    color: Colors.blueGrey[600]),
              ),
              Container(
                child: new Row(
                  children: <Widget>[
                    thumbNumber == 1
                        ? new Text("Ahead by a day")
                        : thumbNumber > 1
                            ? new Text(
                                "Ahead by " + thumbNumber.toString() + " days")
                            : thumbNumber < 0
                                ? new Text("Behind by " +
                                    thumbNumber.abs().toString() +
                                    " days")
                                : Container(),
                    new Container(
                      width: 5.0,
                    ),
                    thumbNumber > 0
                        ? Icon(Icons.thumb_up)
                        : thumbNumber < 0 ? Icon(Icons.thumb_down) : Container()
                  ],
                ),
              )
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 15.0),
            child: new LinearPercentIndicator(
              width: MediaQuery.of(context).size.width - 30,
              animation: true,
              isRTL: true,
              lineHeight: 16.0,
              animationDuration: 1000,
              percent: currentDay / day,
              center: Text((currentDay / day * 100).toStringAsFixed(0) + "%"),
              animateFromLastPercent: true,
              linearStrokeCap: LinearStrokeCap.roundAll,
              progressColor: Colors.cyan[600],
            ),
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text("Previous: " + currentDay.toString(),
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[600])),
              new Text("Upcoming: " + (day - currentDay).toString(),
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey[600]))
            ],
          )
        ],
      ),
    );
    final todayPage = new Container(
      child: new Column(
        children: <Widget>[
          sessionCard,
          readingButtons,
          new Container(
            height: 40.0,
          ),
          new Divider(
            indent: 15.0,
            endIndent: 15.0,
          ),
          new Container(
            height: 30.0,
          ),
          khatmaProgress,
        ],
      ),
    );

    Widget buildRow(int index) {
      String kek;
      if (index == 0 || index == 1)
        kek = '0';
      else
        kek = (int.parse(pages[index].id) - 2).toString();

      return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PdfViewPage(
                        path: assetPDFPath,
                        pageNumber: kek,
                        portion: 600,
                        lastDay: 1,
                      ))),
          child: ListTile(
            leading: new Text(
              (index + 1).toInt().toString() + ".  Surat " + pages[index].title,
              style: new TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: pages[index].id == "1"
                ? Text("Page 1")
                : new Text(
                    "Page " + (int.parse(pages[index].id) - 1).toString()),
          ));
    }

    Widget buildMow(int pageNumber, int index) {
      return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PdfViewPage(
                        path: assetPDFPath,
                        pageNumber: juzes[index].id,
                        portion: 600,
                        lastDay: 1,
                      ))),
          child: ListTile(
            leading: new Text((index / 2 + 1).toInt().toString() + "."),
            title: new Text("Juz' " + juzes[index].id),
            trailing: new Text("Page " + juzes[index].page),
          ));
    }

    final indexPage = TabBarView(
      controller: _tabController,
      children: <Widget>[
        new Container(
            child: ListView.builder(
          itemCount: pages.length,
          itemBuilder: (BuildContext context, int index) {
            return buildRow(index);
          },
        )),
        new Container(
            child: ListView.builder(
          itemCount: 227,
          itemBuilder: (BuildContext context, int index) {
            return index % 2 == 0 ? buildMow(1, index) : Divider();
          },
        )),
      ],
    );
    final addingPage = new Container(
        child: Column(
      children: <Widget>[
        Flexible(
          flex: 0,
          child: Center(
            child: Form(
              key: formKey,
              child: Flex(
                direction: Axis.vertical,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.info),
                    title: TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: "",
                      onSaved: (val) => juz.id = val,
                      validator: (val) => val == "" ? val : null,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: "",
                      onSaved: (val) => juz.page = val,
                      validator: (val) => val == "" ? val : null,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      handleSubmit();
                    },
                  )
                ],
              ),
            ),
          ),
        ),
        Flexible(
          child: FirebaseAnimatedList(
            query: bookRef,
            itemBuilder: (BuildContext context, DataSnapshot snapshot,
                Animation<double> animation, int index) {
              return new ListTile(
                leading: Text(juzes[index].page ?? ' '),
                title: Text(juzes[index].id ?? ''),
              );
            },
          ),
        ),
      ],
    ));
    final athkarPage =
     
     
        new GridView.builder(
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          itemCount: 15,
          itemBuilder: (BuildContext context, int index) {
            return new GestureDetector(
              onTap: () {
                getFileFromAsset('assets/${index + 1}.pdf', '${index + 1}.pdf')
                    .then((f) {
                  setState(() {
                    
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DuaViewPage(path: f.path)));
                  });
                });
              },
              child: new GridTile(
                child: grdidCard(duaTitles[index]),
              ),
            );
          },
        );
   

    final morePage = new Container(
        child: ListView(
      children: <Widget>[
        new ListTile(
          dense: true,
          leading: new Text(
            'Quranic Sunnahs',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new GestureDetector(
          child: new ListTile(
            leading: Icon(Icons.book),
            title: new Text('Surat Al-Kahf'),
          ),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PdfViewPage(
                        path: assetPDFPath,
                        pageNumber: '291',
                        portion: 12,
                        lastDay: 303,
                      ))),
        ),
        new GestureDetector(
          child: new ListTile(
            leading: Icon(Icons.book),
            title: new Text('Surat Al-Mulk'),
          ),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PdfViewPage(
                        path: assetPDFPath,
                        pageNumber: '560',
                        portion: 2,
                        lastDay: 562,
                      ))),
        ),
        new GestureDetector(
          child: new ListTile(
            leading: Icon(Icons.book),
            title: new Text('Surat Al-Baqarah'),
          ),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PdfViewPage(
                        path: assetPDFPath,
                        pageNumber: '0',
                        portion: 47,
                        lastDay: 47,
                      ))),
        ),
        Divider(),
        new ListTile(
          dense: true,
          leading: new Text(
            'Khatmah Alarm',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          leading: Icon(Icons.book),
          title: new Text('Daily Khatmah Alarm'),
          trailing: Switch(
            onChanged: (bool value) {
              setState(() {
                isKhatmahSet = value;
                singleNotification(
                    new Time(
                        int.parse(khatmahHour), int.parse(khatmahMinute), 0),
                    'khatma alarm',
                    'read daily portion',
                    654657,
                    isKhatmahSet,
                    'khatmah');
              });
            },
            value: isKhatmahSet,
          ),
        ),
        new ListTile(
            enabled: isKhatmahSet,
            leading: Icon(Icons.watch_later),
            title: new Text('Daily Khatmah Time'),
            trailing: new FlatButton(
              child: new Text((int.parse(khatmahHour) < 10
                      ? '0$khatmahHour'
                      : khatmahHour) +
                  ":" +
                  (int.parse(khatmahMinute) < 10
                      ? '0$khatmahMinute'
                      : khatmahMinute)),
              onPressed: !isKhatmahSet
                  ? null
                  : () {
                      DatePicker.showTimePicker(
                        context,
                        onChanged: (DateTime dateTime) {
                          setState(() {
                            khatmahHour = dateTime.hour.toString();
                            khatmahMinute = dateTime.minute.toString();
                          });
                        },
                        onConfirm: (DateTime dateTime) {
                          singleNotification(
                              new Time(dateTime.hour, dateTime.minute, 0),
                              'khatma alarm',
                              'read daily portion',
                              654657,
                              isKhatmahSet,
                              'khatmah');
                        },
                        locale: LocaleType.ar,
                      );
                    },
            )),
        Divider(),
        new ListTile(
          dense: true,
          leading: new Text(
            'Athkar Alarms',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          leading: Icon(Icons.wb_sunny),
          title: new Text('Day Athkar Alarm'),
          trailing: Switch(
            onChanged: (bool value) {
              setState(() {
                isMorningAthkarSet = value;
                singleNotification(
                    new Time(int.parse(morningAthkarHour),
                        int.parse(morningAthkarMinute), 0),
                    'morning athkar',
                    'read todays morning athkar',
                    222,
                    isMorningAthkarSet,
                    'morning');
              });
            },
            value: isMorningAthkarSet,
          ),
        ),
        new ListTile(
            enabled: isMorningAthkarSet,
            leading: Icon(Icons.watch_later),
            title: new Text('Day Athkar Time'),
            trailing: new FlatButton(
              child: new Text((int.parse(morningAthkarHour) < 10
                      ? '0$morningAthkarHour'
                      : morningAthkarHour) +
                  ":" +
                  (int.parse(morningAthkarMinute) < 10
                      ? '0$morningAthkarMinute'
                      : morningAthkarMinute)),
              onPressed: !isMorningAthkarSet
                  ? null
                  : () {
                      DatePicker.showTimePicker(
                        context,
                        onChanged: (DateTime dateTime) {
                          setState(() {
                            morningAthkarHour = dateTime.hour.toString();
                            morningAthkarMinute = dateTime.minute.toString();
                          });
                        },
                        onConfirm: (DateTime dateTime) {
                          singleNotification(
                              new Time(dateTime.hour, dateTime.minute, 0),
                              'morning athkar',
                              'read todays morning athkar',
                              222,
                              isMorningAthkarSet,
                              'morning');
                        },
                        locale: LocaleType.ar,
                      );
                    },
            )),
        new ListTile(
          leading: Icon(Icons.wb_sunny),
          title: new Text('Night Athkar Alarm'),
          trailing: Switch(
            onChanged: (bool value) {
              setState(() {
                isNightAthkarSet = value;
                singleNotification(
                    new Time(int.parse(eveningAthkarHour),
                        int.parse(eveningAthkarMinute), 0),
                    'night athkar',
                    'read todays night athkar',
                    333,
                    isNightAthkarSet,
                    'evening');
              });
            },
            value: isNightAthkarSet,
          ),
        ),
        new ListTile(
            enabled: isNightAthkarSet,
            leading: Icon(Icons.watch_later),
            title: new Text('Day Athkar Time'),
            trailing: new FlatButton(
              child: new Text((int.parse(eveningAthkarHour) < 10
                      ? '0$eveningAthkarHour'
                      : eveningAthkarHour) +
                  ":" +
                  (int.parse(eveningAthkarMinute) < 10
                      ? '0$eveningAthkarMinute'
                      : eveningAthkarMinute)),
              onPressed: !isNightAthkarSet
                  ? null
                  : () {
                      DatePicker.showTimePicker(
                        context,
                        onChanged: (DateTime dateTime) {
                          setState(() {
                            eveningAthkarHour = dateTime.hour.toString();
                            eveningAthkarMinute = dateTime.minute.toString();
                          });
                        },
                        onConfirm: (DateTime dateTime) {
                          singleNotification(
                              new Time(dateTime.hour, dateTime.minute, 0),
                              'night athkar',
                              'read todays night athkar',
                              333,
                              isNightAthkarSet,
                              'evening');
                        },
                        locale: LocaleType.ar,
                      );
                    },
            )),
        Divider(),
        new ListTile(
          dense: true,
          leading: new Text(
            'Sunnah Alarms',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          leading: Icon(Icons.alarm),
          title: new Text('Al-Mulk Alarm'),
          trailing: Switch(
            onChanged: (bool value) {
              setState(() {
                isMulkSet = value;
                singleNotification(
                    new Time(int.parse(mulkHour), int.parse(mulkMinute), 0),
                    'sunnah athkar',
                    'read surat Al-Mulk',
                    444,
                    isMulkSet,
                    'mulk');
              });
            },
            value: isMulkSet,
          ),
        ),
        new ListTile(
            enabled: isMulkSet,
            leading: Icon(Icons.watch_later),
            title: new Text('Al-Mulk Time'),
            trailing: new FlatButton(
              child: new Text((int.parse(mulkHour) < 10
                      ? '0$mulkHour'
                      : mulkHour) +
                  ":" +
                  (int.parse(mulkMinute) < 10 ? '0$mulkMinute' : mulkMinute)),
              onPressed: !isMulkSet
                  ? null
                  : () {
                      DatePicker.showTimePicker(
                        context,
                        onChanged: (DateTime dateTime) {
                          setState(() {
                            mulkHour = dateTime.hour.toString();
                            mulkMinute = dateTime.minute.toString();
                          });
                        },
                        onConfirm: (DateTime dateTime) {
                          singleNotification(
                              new Time(dateTime.hour, dateTime.minute, 0),
                              'sunnah athkar',
                              'read surat Al-Mulk',
                              444,
                              isMulkSet,
                              'mulk');
                        },
                        locale: LocaleType.ar,
                      );
                    },
            )),
        new ListTile(
          leading: Icon(Icons.alarm),
          title: new Text('Al-Baqarah Alarm'),
          trailing: Switch(
            onChanged: (bool value) {
              setState(() {
                isBaqarahSet = value;
                singleNotification(
                    new Time(
                        int.parse(baqarahHour), int.parse(baqarahMinute), 0),
                    'sunnah athkar',
                    'read surat Al-Baqarah',
                    555,
                    isBaqarahSet,
                    'baqarah');
              });
            },
            value: isBaqarahSet,
          ),
        ),
        new ListTile(
            enabled: isBaqarahSet,
            leading: Icon(Icons.watch_later),
            title: new Text('Al-Baqarah Time'),
            trailing: new FlatButton(
              child: new Text((int.parse(baqarahHour) < 10
                      ? '0$baqarahHour'
                      : baqarahHour) +
                  ":" +
                  (int.parse(baqarahMinute) < 10
                      ? '0$baqarahMinute'
                      : baqarahMinute)),
              onPressed: !isBaqarahSet
                  ? null
                  : () {
                      DatePicker.showTimePicker(
                        context,
                        onChanged: (DateTime dateTime) {
                          setState(() {
                            baqarahHour = dateTime.hour.toString();
                            baqarahMinute = dateTime.minute.toString();
                          });
                        },
                        onConfirm: (DateTime dateTime) {
                          singleNotification(
                              new Time(dateTime.hour, dateTime.minute, 0),
                              'sunnah athkar',
                              'read surat Al-Baqarah',
                              555,
                              isBaqarahSet,
                              'baqarah');
                        },
                        locale: LocaleType.ar,
                      );
                    },
            )),
        Divider(),
        new ListTile(
          dense: true,
          leading: new Text(
            'Friday Alarm',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          enabled: isKahfSet,
          leading: Icon(Icons.alarm),
          title: new Text('Al-Kahf Alarm'),
          trailing: Switch(
            onChanged: (bool value) {
              setState(() {
                isKahfSet = value;
                weeklyNotification(
                    'Friday Sunnah', 'Read Surat Al-Kahf', 777, isKahfSet);
              });
            },
            value: isKahfSet,
          ),
        ),
      ],
    ));

    final todayAppBar = AppBar(
      title: Text(widget.title),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.add_circle_outline),
          onPressed: () {
            setState(() {
              stackIndex = 1;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.bookmark),
          onPressed: () {
            if (_bookmark != 0) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PdfViewPage(
                            path: assetPDFPath,
                            pageNumber: "bookmark",
                            portion: 600,
                            lastDay: 1,
                          )));
            } else {
              Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text("The Bookmark has not been set yet")));
            }
          },
        ),
        new Container(
          width: 10.0,
        ),
        Icon(Icons.share),
        new Container(
          width: 20.0,
        )
      ],
    );

    final indexAppBar = AppBar(
      title: Text("Index"),
      bottom: TabBar(
          controller: _tabController,
          labelPadding: new EdgeInsets.only(bottom: 15.0),
          tabs: [new Text("Surahs"), new Text("Ajza'")]),
    );

    final athkarAppBar = AppBar(
      title: Text("Athkar"),
    );
    final notifAppBar = AppBar(
      title: Text("More"),
    );

    List<Widget> appBars = [
      todayAppBar,
      indexAppBar,
      athkarAppBar,
      notifAppBar
    ];

    List<Widget> appPages = [
      todayPage,
      indexPage,
      athkarPage,
      morePage,
    ];

    return IndexedStack(
      index: stackIndex,
      children: <Widget>[
        Scaffold(
          appBar: appBars[_currentPage],
          body: appPages[_currentPage],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentPage,
            onTap: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  title: Text('Today'),
                  backgroundColor: Colors.cyan),
              BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  title: Text('Index'),
                  backgroundColor: Colors.cyan),
              BottomNavigationBarItem(
                  icon: Icon(Icons.wb_sunny),
                  title: Text('Athkar'),
                  backgroundColor: Colors.cyan),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_alarm),
                  title: Text('Notifications'),
                  backgroundColor: Colors.cyan),
            ],
          ),
        ),
        Scaffold(
          appBar: new AppBar(
            title: Text("New Khatmah"),
            actions: <Widget>[
              _seen
                  ? new IconButton(
                      icon: new Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          stackIndex = 0;
                        });
                      })
                  : null,
            ],
          ),
          body: new Container(
            margin: new EdgeInsets.symmetric(vertical: 120.0),
            child: new Column(
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
                          '1 week',
                          '2 weeks',
                          '3 weeks',
                          '1 month',
                          '2 months',
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
                      if (dropDownValue == '1 week') {
                        portion = (604 / 7).floor();
                        days = 7;
                      } else if (dropDownValue == '2 weeks') {
                        portion = (604 / 14).floor();
                        days = 14;
                      } else if (dropDownValue == '3 weeks') {
                        portion = (604 / 21).floor();
                        days = 21;
                      } else if (dropDownValue == '1 month') {
                        portion = (604 / 30).floor();
                        days = 30;
                      } else if (dropDownValue == '2 months') {
                        portion = (604 / 60).floor();
                        days = 60;
                      }
                      startingJuz = 1;
                      setAllInfo();
                      setCurrentTime();
                      getAllInfo();
                      setState(() {
                        stackIndex = 0;
                        thumbNumber = 0;
                      });
                    },
                    child: new Text(
                        "                  Continue                  "),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future kkk(String payload) async {
    getFileFromAsset("assets/quran_cropped.pdf", 'quran_cropped.pdf').then((f) {
      setState(() {
        
         if (payload == 'mulk') {
       Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new PdfViewPage(
                  path: f.path,
                  pageNumber: '560',
                  portion: 2,
                  lastDay: 562,
                )),
      );
    } else if (payload == 'baqarah') {
       Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new PdfViewPage(
                  path: '/data/user/0/com.example.quran_app/app_flutter/quran_cropped.pdf',
                  pageNumber: '0',
                  portion: 47,
                  lastDay: 47,
                )),
      );
    }
    else if(payload=='khatmah'){
      
         Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new PdfViewPage(
                   path: f.path,
                                      pageNumber:
                                          (int.parse(startFrom) - 1).toString(),
                                      portion: portion,
                                      lastDay:
                                          int.parse(startFrom) - 1 + portion,
                )),
      );
      
    }
      });
    });
    
   
  }
}

class Page {
  String key;
  String id;
  String title;

  Page(this.id, this.title);

  Page.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        id = snapshot.value["id"],
        title = snapshot.value["title"];

  toJson() {
    return {
      "id": id,
      "title": title,
    };
  }
}

class Juz {
  String key;
  String id;
  String page;

  Juz(this.id, this.page);

  Juz.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        id = snapshot.value["id"],
        page = snapshot.value["page"];

  toJson() {
    return {
      "id": id,
      "page": page,
    };
  }
}

class Book {
  String key;
  String page;
  String ayah;
  String verse;
  String juz;
  String title;

  Book(this.title, this.page, this.juz, this.ayah, this.verse);

  Book.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        page = snapshot.value["page"],
        juz = snapshot.value["juz"],
        title = snapshot.value["title"],
        ayah = snapshot.value["ayah"],
        verse = snapshot.value["verse"];

  toJson() {
    return {
      "page": page,
      "juz": juz,
      "title": title,
      "ayah": ayah,
      "verse": verse,
    };
  }
}
