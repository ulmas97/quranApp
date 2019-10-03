


import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DuaViewPage extends StatefulWidget {
  final String path;

  const DuaViewPage({Key key, this.path}) : super(key: key);
  @override
  _DuaViewPageState createState() => _DuaViewPageState();
}

class _DuaViewPageState extends State<DuaViewPage> with SingleTickerProviderStateMixin{
  AnimationController _controller;
  bool _appBarVisible;

  int _totalPages = 0;
  int _currentPage = 0;
  bool pdfReady = false;
  int _value=0;
  PDFViewController _pdfViewController;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _appBarVisible=true;
    _controller=AnimationController(
      duration: const Duration(milliseconds: 100), vsync: this,
      value: 1.0
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  void _toggleAppBarVisibility(){
    _appBarVisible=!_appBarVisible;
    _appBarVisible ? _controller.forward(): _controller.reverse();
  }

  Widget get _pdfWidget{
    return Center(
          child: PDFView(
            filePath: widget.path,
            autoSpacing: true,
            enableSwipe: true,
            pageSnap: true,
            swipeHorizontal: false,
            nightMode: false,
          
            onError: (e) {
              print(e);
            },
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages;
                pdfReady = true;
                _pdfViewController.setPage(0);
              });
            },
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            onPageChanged: (int page, int total) {
              setState(() {});
            },
            onPageError: (page, e) {},
          ),
        
        
      
    );
  }

  @override
  Widget build(BuildContext context) {
    Animation<Offset> offsetAnimation = new Tween<Offset>(
      begin: Offset(1.0, -70),
      end: Offset(0.0, 0.0),
    ).animate(_controller);
    return Scaffold(
     appBar: new AppBar(
       
     ),
      body:Stack(
        children: <Widget>[
        _pdfWidget,
          !pdfReady
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Offstage(),
              SlideTransition(
            position: offsetAnimation,
            child: Container(
              height: 75,
              
            ),
          ),
          
          GestureDetector(
            onTap: () => setState(() { _toggleAppBarVisibility(); } ),

           
          )
            
       
      
        ],
      ),
     
      
      
     
    );
  }
}