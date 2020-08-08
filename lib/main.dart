import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:connectivity/connectivity.dart';


Map _data;
void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp>{
  var _connectionStatus = "Unknown";
  Connectivity connectivity;
  StreamSubscription<ConnectivityResult> subscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connectivity = new Connectivity();
    subscription =
        connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
          _connectionStatus = result.toString();
          print(_connectionStatus);
          if (result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile) {
            setState(() {});
          }
        });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: "Quake",
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Quake"),
          centerTitle: true,
        ),
        body: Center(
          child: FutureBuilder(
            future: getData(),
            builder: (context,snapshot){
              if(snapshot.hasData){
                _data = snapshot.data;
                return ListView.builder(
                    itemCount: _data["features"].length,
                    padding: const EdgeInsets.all(5.0),
                    itemBuilder:(BuildContext context ,int postion){
                      var date=DateTime.fromMicrosecondsSinceEpoch(_data["features"][postion]["properties"]["time"]*1000,isUtc: true);
                      var dateFormate =new DateFormat.yMMMMd("en_US").add_jm();
                      var formattedDate =dateFormate.format(date);
                      //dynamic Color
                      Color quakeColor = getQuakeColor(postion);
                      return Column(
                        children: <Widget>[
                          Divider(height: 6.0,),
                          ListTile(
                            title: Text(
                              "$formattedDate",
                              style:new TextStyle(
                                  color: Colors.deepOrangeAccent,
                                  fontWeight:FontWeight.bold
                              ) ,
                            ),
                            subtitle: Text(
                              "${_data["features"][postion]["properties"]["place"]}",
                              style:new TextStyle(
                                  fontStyle: FontStyle.italic
                              ) ,),
                            leading:CircleAvatar(
                              backgroundColor: quakeColor,
                              radius: 30.0,
                              child: Text("${_data["features"][postion]["properties"]["mag"]}"),
                            ) ,
                            onTap: ()=>showAlert(context,_data["features"][postion]["properties"]["title"],_data["features"][postion]["properties"]["type"]),
                          )
                        ],
                      );

                    }) ;
              }
              else if(snapshot.hasError){
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100,top: 200,right: 100,bottom: 100),
                    child: Column(
                      children: <Widget>[
                        CircularProgressIndicator(),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            "No Internet Connection",
                            style: TextStyle(
                              fontSize: 17.0
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              else{
                return Center(
                  child: new CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}



void showAlert(BuildContext context,String msg,String type){
  var alertDialog=new AlertDialog(
    title: Text(type.toUpperCase()),
    content: Text(msg),
    actions: <Widget>[
      FlatButton(
        onPressed: ()=>Navigator.of(context).pop(),
        child:Text("OK"),
      )
    ],
  );
  showDialog(context: context, builder: (context){
    return alertDialog;
  });
}

Color getQuakeColor(int index){
  var mag=_data["features"][index]["properties"]["mag"];
  Color color;
  if(mag<2.5)
    color = Colors.lightGreen;
  if(2.5<=mag && mag<3.5)
    color = Colors.amber;
  if(3.5<=mag)
    color = Colors.deepOrange;
  return color;
}

Future<Map> getData()async{
  final url="https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson";
  final http.Response response=await http.get(url);
  if(response.statusCode == 200)
    return json.decode(response.body);
  else
    throw Exception("Failed to load data");
}