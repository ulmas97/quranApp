import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:quran_app/text_style.dart';

void main(){
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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  TabController _tabController;
  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(vsync: this, length: 2);
    super.initState();
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
              children: <Widget>[new Text("Starts From",style: Style.cardTextStyle,), new Text("Juz'1",style: Style.cardTextStyle,)],
            ),
            new Container(
              height: 67.0,
            ),
            new Center(child: new Text("أسابيع وقوعها، الو",style: Style.cardQuranTextStyle,)),
            new Container(
              height: 67.0,
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text("Surat Al-Baqarah - Aya 106",style: Style.cardTextStyle,),
                new Text("Page 17",style: Style.cardTextStyle,),
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
                new Text("To Surat Al-Baqarah - Aya 157",style: Style.cardTextStyle,),
                new Text("Page 24",style: Style.cardTextStyle,),
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
            child: Text('Continue Reading',style: new TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: Colors.white),),
            onPressed: () {},
          ),
          ),
          ButtonTheme(
            minWidth: 155.0,
            height: 50.0,
            buttonColor: Colors.lightGreenAccent[700],
            child: new RaisedButton(
            child: Text("Done Reading",style: new TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold),),
            onPressed: () {},
          ),),
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
              new Text("Khatma Sessions",style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 15.0,color: Colors.blueGrey[600]),),
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
              new Text("Previous: 2",style: new TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey[600])),
              new Text("Upcoming: 97",style: new TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey[600]))
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

    Widget buildRow(String surahTitle,int pageNumber,int index){
     
      return ListTile(
          leading: new Text((index/2+1).toInt().toString()+"."),
          title: new Text("Surat "+surahTitle),
          trailing: new Text("Page "+pageNumber.toString()),
        
      );
    }
     Widget buildMow(int pageNumber,int index){
      
      return ListTile(
          leading: new Text((index/2+1).toInt().toString()+"."),
          title: new Text("Juz' "+(index/2+1).toInt().toString()),
          trailing: new Text("Page "+pageNumber.toString()),
        
      );
    }

    final indexPage = TabBarView(
      controller: _tabController,
      children: <Widget>[
        new Container(
        child: ListView.builder(
          itemCount: 227,
      itemBuilder: (BuildContext context, int index) {
        return index%2==0 ? buildRow("Al-Fatihah",1,index) : Divider();
      },
    )),
    new Container(
        child: ListView.builder(
          itemCount: 227,
      itemBuilder: (BuildContext context, int index) {
        return index%2==0 ? buildMow(1,index) : Divider();
      },
    )),
    
      ],
    );
    final athkarPage = new Container(
      child: Text("you are on athkars page"),
    );
    final todayAppBar = AppBar(
      title: Text(widget.title),
      actions: <Widget>[
        Icon(Icons.bookmark),
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

    List<Widget> pages = [
      todayPage,
      indexPage,
      athkarPage,
    ];

    return Scaffold(
      appBar: appBars[_currentPage],
      body: pages[_currentPage],
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
