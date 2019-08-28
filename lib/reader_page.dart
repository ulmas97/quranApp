import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:swipedetector/swipedetector.dart';

class PdfViewPage extends StatefulWidget {
  final String path;
  final String pageNumber;
  final int portion;
  final int lastDay;

  const PdfViewPage(
      {Key key, this.path, this.pageNumber, this.portion, this.lastDay})
      : super(key: key);
  @override
  _PdfViewPageState createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  bool _appBarVisible;
  List<Book> books = new List();
  int _currentPage = 0;

  bool pdfReady = false;
  int _value;
  int _temp;
  int _portionValue;
  //int _currentDay;
  DatabaseReference bookRef;
  PDFViewController _pdfViewController;
  //Future<SharedPreferences> _sPrefs = SharedPreferences.getInstance();
  SwipeConfiguration s = new SwipeConfiguration(
    horizontalSwipeMaxHeightThreshold: 200,
    horizontalSwipeMinDisplacement: 2.0,
    horizontalSwipeMinVelocity: 1.0,
  );
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  int getInt;
  int setInt;
  @override
  void initState() {
    // TODO: implement initState

    _portionValue = widget.portion;

    final FirebaseDatabase database = FirebaseDatabase.instance;
    bookRef = database.reference().child('books');

    bookRef.onChildAdded.listen(_onEntryAdded);
    bookRef.onChildChanged.listen(_onEntryChanged);

    super.initState();
    getInt = 0;
    if (widget.pageNumber == "bookmark") {
      _value = 0;
    } else {
      _value = int.parse(widget.pageNumber);
      _temp = 602 - _value;
    }

    getBookMark();
    _appBarVisible = true;
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this, value: 1.0);
  }

  _onEntryAdded(Event event) {
    setState(() {
      books.add(Book.fromSnapshot(event.snapshot));
    });
  }

  _onEntryChanged(Event event) {
    var old = books.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      books[books.indexOf(old)] = Book.fromSnapshot(event.snapshot);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
    _controller.dispose();
  }

  void _toggleAppBarVisibility() {
    _appBarVisible = !_appBarVisible;
    _appBarVisible ? _controller.forward() : _controller.reverse();
  }

  Widget get _pdfWidget {
    return Container(
        color: Colors.black,
        // margin: new EdgeInsets.only(top: 30.0),
        child: SwipeDetector(
          onSwipeLeft: () {
            if (widget.pageNumber == "bookmark") {
              _pdfViewController.setPage(--_value);
              getInt--;
              _temp++;
              _portionValue++;
            } else if (_value == int.parse(widget.pageNumber) &&
                widget.portion != 600) {
              null;
            } else {
              _pdfViewController.setPage(--_value);
              getInt--;
              _temp++;
              _portionValue++;
            }
          },
          onSwipeRight: () {
            if (widget.pageNumber == "bookmark") {
              _pdfViewController.setPage(++_value);
              getInt++;
              _temp--;
              _portionValue--;
            } else if (_value >=
                    int.parse(widget.pageNumber) + widget.portion &&
                widget.portion != 600) {
              null;
            } else {
              if (_value < 602) {
                _pdfViewController.setPage(++_value);
                getInt++;
                _temp--;
                _portionValue--;
              }
            }
          },
          swipeConfiguration: s,
          child: PDFView(
            gestureRecognizers: null,
            filePath: widget.path,
            autoSpacing: true,
            enableSwipe: false,
            pageSnap: true,
            swipeHorizontal: true,
            pageFling: true,
            nightMode: false,
            onError: (e) {
              print(e);
            },
            onRender: (_pages) {
              setState(() {
                pdfReady = true;
                if (widget.pageNumber == "bookmark") {
                  _pdfViewController.setPage(getInt);
                } else
                  _pdfViewController.setPage(int.parse(widget.pageNumber));
              });
            },
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            onPageChanged: (int page, int total) {
              _pdfViewController.getCurrentPage().then((value) {
                setState(() {
                  _value = value;

                  _currentPage = value;
                });
              });
            },
            onPageError: (page, e) {},
          ),
        ));
  }

  Future<Null> setBookmark(int currentPage) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('bookmark', currentPage);
  }

  Future<Null> getBookMark() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    getInt = prefs.getInt('bookmark');
    // _currentDay=prefs.getInt('currentDay');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //books.insert(493,new Book("الزخرف","494","25","temp","temp"));

    Animation<Offset> offsetAnimation = new Tween<Offset>(
      begin: Offset(1.0, -70),
      end: Offset(0.0, 0.0),
    ).animate(_controller);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          // orientation == Orientation.landscape?
          _pdfWidget,
          //  _pdfWidget,
          !pdfReady
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Offstage(),
          GestureDetector(
            onTap: () => setState(() {
              _toggleAppBarVisibility();
            }),
          ),
          SlideTransition(
            position: offsetAnimation,
            child: Container(
                height: 75,
                child: Builder(
                  builder: (BuildContext context) {
                    return AppBar(
                      title: RichText(
                        text: TextSpan(children: <TextSpan>[
                          TextSpan(text: books[_currentPage].title + '\n'),
                          TextSpan(
                              text: 'Page ' +
                                  books[_currentPage].page +
                                  ', Juz ' +
                                  books[_currentPage].juz),
                        ]),
                      ),
                      actions: <Widget>[
                        IconButton(
                            icon: Icon(Icons.bookmark),
                            onPressed: () {
                              Scaffold.of(context).showSnackBar(new SnackBar(
                                  content:
                                      new Text("The Bookmark has been set")));
                              _pdfViewController.getCurrentPage().then((value) {
                                setBookmark(value);
                              });
                            }),
                        new Container(
                          width: 20.0,
                        ),
                      ],
                    );
                  },
                )),
          ),
        ],
      ),
      bottomNavigationBar: SlideTransition(
        position: offsetAnimation,
        child: Container(
          height: 30,
          child: BottomAppBar(
              child: SliderTheme(
            data: SliderThemeData(),
            child: Slider(
              value: widget.pageNumber == "bookmark"
                  ? getInt.toDouble()
                  : widget.portion != 600
                      ? _portionValue.toDouble()
                      : _temp.toDouble(),
              min: 0.0,
              max: widget.portion == 600 ? 602.0 : widget.portion.toDouble(),
              divisions: widget.portion == 600 ? 602 : widget.portion,
              activeColor: Colors.cyanAccent,
              inactiveColor: Colors.black,
              label: widget.portion == 600
                  ? 'Page ${int.parse(books[_value].page)}\n ${books[_value].title} - Juz ${books[_value].juz} '
                  : 'Page ${int.parse(books[widget.lastDay - _portionValue].page)}\n ${books[widget.lastDay - _portionValue].title} - Juz ${books[widget.lastDay - _portionValue].juz} ',
              onChangeEnd: (double newValue) {
                _currentPage = 602 - newValue.round();

                if (widget.portion == 600) {
                  _pdfViewController.setPage(_currentPage);
                } else {
                  _pdfViewController.setPage(widget.lastDay - _portionValue);
                }
              },
              onChangeStart: (double b) {},
              onChanged: (double a) {
                if (widget.portion == 600) {
                  setState(() {
                    _value = 602 - a.round();
                    _temp = a.round();
                    getInt = a.round();
                  });
                } else {
                  setState(() {
                    _value = a.round();
                    _portionValue = a.round();
                    _temp = a.round();
                    getInt = a.round();
                  });
                }
              },
            ),
          )),
        ),
      ),
    );
  }
}
