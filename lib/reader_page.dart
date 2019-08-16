import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewPage extends StatefulWidget {
  final String path;
  final String pageNumber;

  const PdfViewPage({Key key, this.path, this.pageNumber}) : super(key: key);
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
DatabaseReference bookRef;
  PDFViewController _pdfViewController;
  Future<SharedPreferences> _sPrefs = SharedPreferences.getInstance();
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  int getInt;
  int setInt;
  @override
  void initState() {
    // TODO: implement initState
    final FirebaseDatabase database = FirebaseDatabase.instance;
    bookRef = database.reference().child('books');
    bookRef.onChildAdded.listen(_onEntryAdded);
    bookRef.onChildChanged.listen(_onEntryChanged);
    super.initState();
  getInt=0;
  widget.pageNumber=="bookmark" ? _value=0 :_value=int.parse(widget.pageNumber);
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
      margin: new EdgeInsets.only(top: 30.0),
      child: PDFView(
        filePath: widget.path,
        autoSpacing: true,
        enableSwipe: true,
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
            if (widget.pageNumber == "bookmark"){
              
                _pdfViewController.setPage(getInt);

            }
              
            else
              _pdfViewController.setPage(int.parse(widget.pageNumber) - 1);
          });
        },
        onViewCreated: (PDFViewController vc) {
          _pdfViewController = vc;
        },
        onPageChanged: (int page, int total) {
          
          _pdfViewController.getCurrentPage().then((value){
            setState(() {
              _value=value;
              _currentPage=value;
            });
          });
          
        },
        onPageError: (page, e) {},
      ),
    );
  }

  Future<Null> setBookmark(int currentPage) async {
    final SharedPreferences prefs = await _sPrefs;
    prefs.setInt('bookmark', currentPage);
    
  }

  Future<Null> getBookMark() async {
    final SharedPreferences prefs = await _sPrefs;
    getInt = prefs.getInt('bookmark');
  setState(() {
    
  });
  
  }

  @override
  Widget build(BuildContext context) {
    

    Animation<Offset> offsetAnimation = new Tween<Offset>(
      begin: Offset(1.0, -70),
      end: Offset(0.0, 0.0),
    ).animate(_controller);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          _pdfWidget,
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
              child: Builder(builder: (BuildContext context) {
               return  AppBar(
                title: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(text: books[_currentPage].title+'\n'),
                      TextSpan(text:'Page '+ books[_currentPage].page +', Juz '+books[_currentPage].juz),
                    ]
                  ),
                ),
                
                actions: <Widget>[
                  IconButton(
                      icon: Icon(Icons.bookmark),
                      onPressed: () {
                        Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("The Bookmark has been set")
    ));
                        _pdfViewController.getCurrentPage().then((value){
                          setBookmark(value);
                        });
                      }),
                  new Container(
                    width: 20.0,
                  ),
                ],
              );
              },

              )
            ),
          ),
        ],
      ),
      bottomNavigationBar: SlideTransition(
        position: offsetAnimation,
        child: Container(
          height: 30,
          child: BottomAppBar(
              child: Slider(
            value: widget.pageNumber=="bookmark" ? getInt.toDouble() : _value.toDouble(),
            min: 0.0,
            max: 569.0,
            divisions: 569,
            activeColor: Colors.cyanAccent,
            inactiveColor: Colors.black,
            label: 'Page ${books[_value].page}\n ${books[_value].title} - Juz ${books[_value].juz} ',
            onChangeEnd: (double newValue) {
              _currentPage = newValue.round();
              _pdfViewController.setPage(_currentPage);
            },
            onChanged: (double a) {
              setState(() {
                _value = a.round();
                
              });
            },
          )),
        ),
      ),
    );
  }
}
