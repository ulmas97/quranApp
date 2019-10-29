import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as prefix0;
import 'package:flutter/material.dart' as prefix1;
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
  WidgetsFlutterBinding.ensureInitialized();
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
        primaryColorBrightness: Brightness.dark,
       
        primaryColor:prefix0.Color.fromRGBO(255, 147, 30, 1),
        accentColor:Colors.white,
        scaffoldBackgroundColor: Colors.grey[300],

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
      home: MyHomePage(title: 'الورد الحالي'),
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
  int _bookmark = 100;
  bool _seen = true;

  String morningAthkarHour = '1';
  String morningAthkarMinute = '1';
  String eveningAthkarHour = '1';
  String eveningAthkarMinute = '1';
  String mulkHour = '1';
  String mulkMinute = '1';
  String baqarahHour = '1';
  String baqarahMinute = '1';
  String khatmahHour = '1';
  String khatmahMinute = '1';
  bool isKhatmahSet = true;
  bool isMorningAthkarSet = true;
  bool isNightAthkarSet = true;
  bool isMulkSet = true;
  bool isKahfSet = true;
  bool isBaqarahSet = true;
  String assetPDFPath = "";
  List<Page> pages = new List();
  List<Book> books = new List();
  List<Juz> juzes = new List();
  List<String> duaTitles = [
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
  Juz juz;
  Page page;
  Book book;
  int day = 30;
  int portion = 1;
  String startFrom = '1';
  int currentDay = 0;
  String dropDownValue = 'أسبوع واحد';
  int startingJuz = 1;
  int stackIndex = 0;
  int days = 30;
  int thumbNumber = 0;
  DatabaseReference pageRef;
  DatabaseReference bookRef;
  DatabaseReference juzRef;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  int _currentPage = 3;
  TabController _tabController;

  @override
  void initState() {
    localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    checkFirstSeen();
    initializeNotifications();
    getNotifications();

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

    getAllInfo();
    getPeriod().then((int value) {
      setState(() {
        thumbNumber = currentDay - value;
      });
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

    _tabController = TabController(vsync: this, length: 2,initialIndex: 1);
    super.initState();
  }

  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _seen = (prefs.getBool('seen') ?? false);
    _bookmark = (prefs.getInt('bookmark') ?? 0);
    if (!_seen) {
      prefs.setBool('seen', true);
      stackIndex = 1;
    }
  }

  void initializeNotifications() async {
    var initializeAndroid = AndroidInitializationSettings('app_icon');
    var initializeIOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(initializeAndroid, initializeIOS);
    await localNotificationsPlugin.initialize(initSettings,
        onSelectNotification: kkk);
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

    books[books.indexOf(old)] = Book.fromSnapshot(event.snapshot);
  }

  /*void handleSubmit() {
    final FormState form = formKey.currentState;

    if (form.validate()) {
      form.save();
      form.reset();
      juzRef.push().set(juz.toJson());
    }
  }*/

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
                  "الجزء " +
                      (books.isEmpty ? '1' : books[int.parse(startFrom)].juz),
                  style: Style.cardTextStyle,
                ),
                new Text(
                  "من قوله تعالى",
                  style: Style.cardTextStyle,
                ),
                
              ],
            ),
            new Container(
              height: 60.0,
            ),
            new Center(
                child: new Text(
              books.isEmpty
                  ? 'بِسمِ اللَّهِ الرَّحمٰنِ الرَّحيمِ'
                  : books[int.parse(startFrom) - 1].verse,
              style: Style.cardQuranTextStyle,
            )),
            new Container(
              height: 50.0,
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(
                  startFrom + " صفحة",
                  style: Style.cardTextStyle,
                ),
                new Text(
                  (books.isEmpty
                          ? '1 - Aya 106'
                          : (books[int.parse(startFrom) - 1].ayah) +" سورة "
                      +
                      books[int.parse(startFrom)].title +
                      " - آية"),
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
                      ? ' '
                      : (int.parse(startFrom) + portion).toString() + " صفحة",
                  style: Style.cardTextStyle,
                ),
                new Text(
                  int.parse(startFrom) >= 604
                      ? ''
                      : (books.isEmpty
                              ? '1 - Aya 157'
                              : (books[int.parse(startFrom) - 1 + portion]
                                  .ayah +
                          " إلى سورة"+
                          books[int.parse(startFrom) + portion].title + " - آية"))
                          ,
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
        " تهانينا لقد أكملت ختمتك اضغط على زر الاضافه لبدأ ختمه جديدة",
       
        style: Style.cardQuranTextStyle,
        textAlign: TextAlign.center,
      ),
    );

    final sessionCard = Transform.translate(
        child: new Container(
          margin: new EdgeInsets.all(10.0),
          // height: 200,
          child: new SizedBox(
            height: 270.0,
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
            buttonColor: prefix0.Color.fromRGBO(255, 147, 30, 1),
            child: new RaisedButton(
              child: Text(
                "أتممت القراءة",
                style:
                    new TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,color: Colors.white),
              ),
              onPressed: startFrom == '604'
                  ? null
                  : () {
                      controller.forward();
                    },
            ),
          ),
          ButtonTheme(
            minWidth: 155.0,
            height: 50.0,
            buttonColor: Colors.yellow,
            child: new RaisedButton(
                child: Text(
                  'تابع قراءة الورد',
                  style: new TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
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
              Container(
                child: new Row(
                  children: <Widget>[
                     thumbNumber > 0
                        ? Icon(Icons.thumb_up,color: prefix0.Color.fromRGBO(255, 147, 30, 1),)
                        : thumbNumber < 0 ? Icon(Icons.thumb_down) : Container(),
                        new Container(
                      width: 5.0,
                    ),
                    thumbNumber == 1
                        ? new Text("سابق يوم")
                        : (thumbNumber > 1
                            ? new Text(
                                "يوما " + thumbNumber.toString() + " سابق")
                            : (thumbNumber < 0
                                ? new Text("متأخر ب " +
                                    thumbNumber.abs().toString() +
                                    "يوما")
                                : Container())),
                    
                   
                  ],
                ),
              ),
              new Text(
                "الختمة الحالية",
                style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                    color: Colors.blueGrey[600]),
              ),
              
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
              percent: (currentDay / day).toDouble(),
              center: Text((currentDay / day * 100).toStringAsFixed(0) + "%"),
              animateFromLastPercent: true,
              linearStrokeCap: LinearStrokeCap.roundAll,
              progressColor: Colors.green
            ),
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text((day - currentDay).toString() + " :الأوراد القادمة",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey[600])),
              new Text(currentDay.toString() + " :الأوراد السابقة",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[600])),
              
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
            height: 20.0,
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
            trailing: new Text(
              (index + 1).toInt().toString() + ".  سورة " + pages[index].title,
              style: new TextStyle(fontWeight: FontWeight.bold),
            textDirection: prefix1.TextDirection.rtl),
            leading: pages[index].id == "1"
                ? Text("صفحة 1")
                : new Text(
                    (int.parse(pages[index].id) - 1).toString() + " صفحة"),
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
            trailing: new Text("."+juzes[index].id),
            title: new Text(juzes[index].id + " الجزء",textAlign: TextAlign.end,),
            leading: new Text("صفحة " + juzes[index].page),
          ));
    }

    final indexPage = TabBarView(
      controller: _tabController,
      children: <Widget>[
        new Container(
            child: ListView.separated(
          itemCount: juzes.length,
          itemBuilder: (BuildContext context, int index) {
            return buildMow(1, index);
          },
          separatorBuilder: (BuildContext context, int index){
            return Divider();
          }
        )),
        new Container(
            child: ListView.separated(
              
          itemCount: pages.length,
          itemBuilder: (BuildContext context, int index) {
            return buildRow(index);
          }, separatorBuilder: (BuildContext context, int index) {
            return Divider();
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
                      //onSaved: (val) => juz.id = val,
                      validator: (val) => val == "" ? val : null,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: "",
                      // onSaved: (val) => juz.page = val,
                      validator: (val) => val == "" ? val : null,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      //  handleSubmit();
                    },
                  )
                ],
              ),
            ),
          ),
        ),
        /*  Flexible(
          child: FirebaseAnimatedList(
            query: bookRef,
            itemBuilder: (BuildContext context, DataSnapshot snapshot,
                Animation<double> animation, int index) {
              return new ListTile(
               // leading: Text(juzes[index].page ?? ' '),
                //title: Text(juzes[index].id ?? ''),
              );
            },
          ),
        ),*/
      ],
    ));
    final athkarPage = new GridView.builder(
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
                        builder: (context) => DuaViewPage(path: f.path)));
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
          trailing: new Text(
            'سُنَّة اليومية',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new GestureDetector(
          child: new ListTile(
           
            trailing: Icon(Icons.book),
            title: new Text('سورة الكهف',textAlign: TextAlign.end),
            
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
            
            trailing: Icon(Icons.book),
            title: new Text('سورة الملك',textAlign: TextAlign.end),
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
            
            trailing: Icon(Icons.book),
            title: new Text('سورة البقرة',textAlign: TextAlign.end),
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
          trailing: new Text(
            'تنبيه الختمة',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          trailing: Icon(Icons.book),
          title: new Text('منبه الختمة اليومي',textAlign: TextAlign.end,),
          leading: Switch(
            activeColor: Colors.green,
            onChanged: (bool value) {
              setState(() {
                isKhatmahSet = value;
                singleNotification(
                    new Time(
                        int.parse(khatmahHour), int.parse(khatmahMinute), 0),
                    'المنبه اليومي',
                    'قراءة الجزء اليومي',
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
            trailing: Icon(Icons.watch_later),
            title: new Text('وقت المنبه اليومي',textAlign: TextAlign.end,),
            leading: new FlatButton(
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
                              'المنبه اليومي',
                              'قراءة الجزء اليومي',
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
          trailing: new Text(
            'تنبيهات الأذكار',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          trailing: Icon(Icons.wb_sunny),
          title: new Text('تنبيه أذكار الصباح',textAlign: TextAlign.end,),
          leading: Switch(
            activeColor: Colors.green,
            onChanged: (bool value) {
              setState(() {
                isMorningAthkarSet = value;
                singleNotification(
                    new Time(int.parse(morningAthkarHour),
                        int.parse(morningAthkarMinute), 0),
                    'صباح الأذكار',
                    'قراءة  اليوم الصباح  الأذكار',
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
            trailing: Icon(Icons.watch_later),
            title: new Text('وقت أذكار الصباح',textAlign: TextAlign.end,),
            leading: new FlatButton(
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
                              'صباح الأذكار',
                              'قراءة  اليوم الصباح  الأذكار  ',
                              222,
                              isMorningAthkarSet,
                              'morning');
                        },
                        locale: LocaleType.ar,
                      );
                    },
            )),
        new ListTile(
          trailing: Icon(Icons.wb_sunny),
          title: new Text('تنبيه أذكار المساء',textAlign: TextAlign.end,),
          leading: Switch(
            activeColor: Colors.green,
            onChanged: (bool value) {
              setState(() {
                isNightAthkarSet = value;
                singleNotification(
                    new Time(int.parse(eveningAthkarHour),
                        int.parse(eveningAthkarMinute), 0),
                    'ليل الأذكار',
                    'قراءة أذكار ليلة اليوم',
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
            trailing: Icon(Icons.watch_later),
            title: new Text('وقت أذكار المساء',textAlign: TextAlign.end),
           leading : new FlatButton(
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
                              'ليل الأذكار',
                              'قراءة أذكار ليلة اليوم',
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
          trailing: new Text(
            'تبيه السنن',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          trailing: Icon(Icons.alarm),
          title: new Text('تنبيه سورة الملك',textAlign: TextAlign.end),
          leading: Switch(
            activeColor: Colors.green,
            onChanged: (bool value) {
              setState(() {
                isMulkSet = value;
                singleNotification(
                    new Time(int.parse(mulkHour), int.parse(mulkMinute), 0),
                    'تبيه الأذكار',
                    'اقرأ سورة الملك',
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
            trailing: Icon(Icons.watch_later),
            title: new Text('وقت سوره الملك',textAlign: TextAlign.end,),
            leading: new FlatButton(
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
                              'تبيه الأذكار',
                              'اقرأ سورة الملك',
                              444,
                              isMulkSet,
                              'mulk');
                        },
                        locale: LocaleType.ar,
                      );
                    },
            )),
        new ListTile(
          trailing: Icon(Icons.alarm),
          title: new Text(' تنبيه سوره البقره',textAlign: TextAlign.end,),
          leading: Switch(
            activeColor: Colors.green,
            onChanged: (bool value) {
              setState(() {
                isBaqarahSet = value;
                singleNotification(
                    new Time(
                        int.parse(baqarahHour), int.parse(baqarahMinute), 0),
                    'تبيه الأذكار',
                    'اقرأ سورة البقره',
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
            trailing: Icon(Icons.watch_later),
            title: new Text('وقت سوره البقره',textAlign: TextAlign.end),
            leading: new FlatButton(
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
                              'تبيه الأذكار',
                              'اقرأ سورة البقره',
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
          trailing: new Text(
            'تنبيه يوم الجمعة',
            style: new TextStyle(fontSize: 15.0),
          ),
        ),
        new ListTile(
          enabled: isKahfSet,
          trailing: Icon(Icons.alarm),
          title: new Text('تنبيه سورة الكهف',textAlign: TextAlign.end),
          leading: Switch(
            activeColor: Colors.green,
            onChanged: (bool value) {
              setState(() {
                isKahfSet = value;
                weeklyNotification(
                    'يوم الجمعة سُنَّة', 'اقرأ سورة  الكهف', 777, isKahfSet);
              });
            },
            value: isKahfSet,
          ),
        ),
      ],
    ));

    final todayAppBar = AppBar(
      title: new prefix1.Row(
children: <Widget>[
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
],
      ),
      actions: <Widget>[
        prefix1.Padding(
          child: Text(widget.title,style: new prefix1.TextStyle(fontSize: 22.0  ),),
          padding: new prefix1.EdgeInsets.fromLTRB(0, 8, 15, 0),
        )
        
        
       
        
        
      ],
    );

    final indexAppBar = AppBar(
      
      actions: <Widget>[
        
         Padding(
           padding: new EdgeInsets.fromLTRB(0, 8, 15, 0),
           child: Text("الفهرس ",style: new TextStyle(fontSize: 22.0),),
         )
      ],
      bottom: TabBar(
          controller: _tabController,
          labelPadding: new EdgeInsets.only(bottom: 15.0),
          tabs: [new Text("أَجْزَاءْ"), new Text("سورة")]),
    );

    final athkarAppBar = AppBar(
     
      actions: <Widget>[
        
         Padding(
           padding: new EdgeInsets.fromLTRB(0, 8, 15, 0),
           child: Text("الأذكار ",style: new TextStyle(fontSize: 22.0),),
         )
      ],
    );
    final notifAppBar = AppBar(
      actions: <Widget>[
        
         Padding(
           padding: new EdgeInsets.fromLTRB(0, 8, 15, 0),
           child: Text("المزيد ",style: new TextStyle(fontSize: 22.0),),
         )
      ],
      
    );

    List<Widget> appBars = [
        
     
      notifAppBar,
       athkarAppBar,
      indexAppBar,
      todayAppBar,
    
      
      
    ];

    List<Widget> appPages = [
         
      
       morePage,
       athkarPage,
       indexPage,
      todayPage,
   
      
     
    ];

    return IndexedStack(
      index: stackIndex,
      children: <Widget>[
        Scaffold(
          appBar: appBars[_currentPage],
          body: appPages[_currentPage],
          bottomNavigationBar: BottomNavigationBar(
            
            backgroundColor: Colors.black,
            unselectedItemColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentPage,
            onTap: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_alarm),
                  title: Text('التنبيهات'),
                  
                  backgroundColor: Colors.cyan),
                   BottomNavigationBarItem(
                  icon: Icon(Icons.wb_sunny),
                  title: Text('الأذكار'),
                  backgroundColor: Colors.cyan),
                  BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  title: Text('الفهرس'),
                  backgroundColor: Colors.cyan),
              BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  title: Text('ورد اليوم'),
                  backgroundColor: Colors.cyan),
              
             
              
            ],
          ),
        ),
        Scaffold(
          appBar: new AppBar(
            title: _seen
                  ? new IconButton(
                      icon: new Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          stackIndex = 0;
                        });
                      })
                  : null,
            actions: <Widget>[
             new prefix1.Padding(
               child:  new prefix1.Text("New Khatmah",style:new prefix1.TextStyle(fontSize: 21.0)),
               padding: new prefix1.EdgeInsets.fromLTRB(0, 16, 16, 0),
             )
            ],
          ),
          body: new Container(
            margin: new EdgeInsets.symmetric(vertical: 120.0),
            child: new Column(
              children: <Widget>[
                new Text(
                  "مدة الختمة",
                  textAlign: TextAlign.center,
                  style: Style.cardQuranTextStyle,
                ),
                new Container(
                  margin: new EdgeInsets.only(top: 100.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Text("     يبدأ من",
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
                          'أسبوع واحد',
                          'أسبوعان',
                          'ثلاثة أسابيع',
                          'شهر واحد',
                          'شهرين',
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
                      if (dropDownValue == 'أسبوع واحد') {
                        portion = (604 / 7).floor();
                        days = 7;
                      } else if (dropDownValue == 'أسبوعان') {
                        portion = (604 / 14).floor();
                        days = 14;
                      } else if (dropDownValue == 'ثلاثة أسابيع') {
                        portion = (604 / 21).floor();
                        days = 21;
                      } else if (dropDownValue == 'شهر واحد') {
                        portion = (604 / 30).floor();
                        days = 30;
                      } else if (dropDownValue == 'شهرين') {
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
                        "                 استمر                  "),
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
                      path:
                          '/data/user/0/com.example.quran_app/app_flutter/quran_cropped.pdf',
                      pageNumber: '0',
                      portion: 47,
                      lastDay: 47,
                    )),
          );
        } else if (payload == 'khatmah') {
          Navigator.push(
            context,
            new MaterialPageRoute(
                builder: (context) => new PdfViewPage(
                      path: f.path,
                      pageNumber: (int.parse(startFrom) - 1).toString(),
                      portion: portion,
                      lastDay: int.parse(startFrom) - 1 + portion,
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
