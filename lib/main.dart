import 'dart:io';
import 'dart:ui' as prefix0;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:quran_app/reader_page.dart';
import 'package:quran_app/text_style.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MyHomePage extends StatefulWidget{
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  String assetPDFPath = "";
  List<Page> pages = new List();
  List<Book> books = new List();
  Page page;
  Book book;
  DatabaseReference pageRef;
  DatabaseReference bookRef;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  TabController _tabController;
  @override
  void initState() {
    page = Page("", "");
    book = Book("", "","");
    final FirebaseDatabase database = FirebaseDatabase.instance;
    pageRef = database.reference().child('pages');
    bookRef = database.reference().child('books');
    pageRef.onChildAdded.listen(_onEntryAdded);
    pageRef.onChildChanged.listen(_onEntryChanged);
    bookRef.onChildAdded.listen(_onBookAdded);
    bookRef.onChildChanged.listen(_onBookChanged);
    _tabController = TabController(vsync: this, length: 2);
    super.initState();
    getFileFromAsset("assets/quran_cropped.pdf").then((f) {
      setState(() {
        assetPDFPath = f.path;
        print(assetPDFPath);
      });
    });
  }

  Future<File> getFileFromAsset(String asset) async {
    try {
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/quran_cropped.pdf");

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
      bookRef.push().set(book.toJson());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  "Juz'1",
                  style: Style.cardTextStyle,
                )
              ],
            ),
            new Container(
              height: 67.0,
            ),
            new Center(
                child: new Text(
              "أسابيع وقوعها، الو",
              style: Style.cardQuranTextStyle,
            )),
            new Container(
              height: 67.0,
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(
                  "Surat Al-Baqarah - Aya 106",
                  style: Style.cardTextStyle,
                ),
                new Text(
                  "Page 17",
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
                  "To Surat Al-Baqarah - Aya 157",
                  style: Style.cardTextStyle,
                ),
                new Text(
                  "Page 24",
                  style: Style.cardTextStyle,
                ),
              ],
            )
          ],
        ),
      ),
    );

    final sessionCard = new Container(
      margin: new EdgeInsets.all(10.0),
      child: new SizedBox(
        height: 260.0,
        child: sessionCardContent,
      ),
    );

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
              onPressed: () {},
            ),
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
              onPressed: () {},
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
                    new Text("Ahead by 2 days"),
                    new Container(
                      width: 5.0,
                    ),
                    Icon(Icons.thumb_up)
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
              lineHeight: 16.0,
              animationDuration: 1000,
              percent: 0.3,
              center: Text("30.0%"),
              linearStrokeCap: LinearStrokeCap.roundAll,
              progressColor: Colors.cyan[600],
            ),
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text("Previous: 2",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[600])),
              new Text("Upcoming: 97",
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
      return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PdfViewPage(
                      path: assetPDFPath, pageNumber: pages[index].id))),
          child: ListTile(
            leading: new Text(
              (index + 1).toInt().toString() + ".  Surat " + pages[index].title,
              style: new TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: new Text("Page " + pages[index].id),
          ));
    }

    Widget buildMow(int pageNumber, int index) {
      return ListTile(
        leading: new Text((index / 2 + 1).toInt().toString() + "."),
        title: new Text("Juz' " + (index / 2 + 1).toInt().toString()),
        trailing: new Text("Page " + pageNumber.toString()),
      );
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
    final athkarPage = new Container(
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
                      initialValue: " ",
                      onSaved: (val) => book.page = val,
                      validator: (val) => val == "" ? val : null,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: TextFormField(
                      
                      initialValue: "7",
                      onSaved: (val) => book.juz = val,
                      validator: (val) => val == "" ? val : null,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: TextFormField(
                      initialValue: "المائدة",
                      onSaved: (val) => book.title = val,
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
                leading: Text(books[index].page?? ' '),
                title: Text(books[index].juz ?? ''),
                subtitle: Text(books[index].title ?? ' '),
              );
            },
          ),
        ),
      ],
    ));
    final todayAppBar = AppBar(
      title: Text(widget.title),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.bookmark),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PdfViewPage(
                        path: assetPDFPath, pageNumber: "bookmark")));
          },
        ),
        new Container(
          width: 20.0,
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

    List<Widget> appBars = [
      todayAppBar,
      indexAppBar,
      athkarAppBar,
    ];

    List<Widget> appPages = [
      todayPage,
      indexPage,
      athkarPage,
    ];

    return Scaffold(
      appBar: appBars[_currentPage],
      body: appPages[_currentPage],
      bottomNavigationBar: BottomNavigationBar(
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
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            title: Text('Index'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny),
            title: Text('Athkar'),
          )
        ],
      ),

      // This trailing comma makes auto-formatting nicer for build methods.
    );
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

class Book {
  String key;
  String page;
  String juz;
  String title;

  Book(this.title, this.page,this.juz);

  Book.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        page= snapshot.value["page"],
        juz = snapshot.value["juz"],
        title=snapshot.value["title"];

  toJson() {
    return {
      "page": page,
      "juz": juz,
      "title": title,
    };
  }
}
