import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

class ReaderPage extends StatefulWidget {
  final String pageNumber;
  
  ReaderPage(this.pageNumber);

  ReaderPageState createState() => ReaderPageState(pageNumber);
}

class ReaderPageState extends State<ReaderPage> {
  final String pageNumber;
  String assetPdfPath = '';
  
  
  PDFViewController controller;
  ReaderPageState(this.pageNumber);

  @override
  void initState() {
    int page = int.parse(pageNumber);
    // TODO: implement initState
   

    super.initState();
  }

  Future<File> getFileFromAsset(String asset) async {
    try {
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      var dir = await getApplicationDocumentsDirectory();
      File file = File('${dir.path}/mypdf.pdf');
      file = await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception("error opening a file");
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new MaterialApp(
        home: Scaffold(
          body: FutureBuilder(
            future: getFileFromAsset('assets/mypdf.pdf'),
            builder: (contex,snapshot){
              if(snapshot.connectionState==ConnectionState.done){
                return  PDFView(
          filePath: snapshot.data.path,
          autoSpacing: true,
          enableSwipe: true,
          pageSnap: true,
          swipeHorizontal: true,
          onError: (e) {
            print(e);
          },
         
          
         
          onPageError: (page,err){
            print(err);
          },
        );
              }
              else{
                return Center(child: CircularProgressIndicator(),);
              }
            },
          ),
           ));
  }
}
