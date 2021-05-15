import 'dart:convert';
import 'dart:isolate';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:cowin_vaccination/helpers/notificationsPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> filterOptions = ["18+", "45+", "COVISHIELD", "COVAXIN", "Paid", "Free"];
List<bool> filterSelected = [false, false, false, false, false, false];

class States{
  int stateId;
  String stateName;
  States({this.stateId, this.stateName});
}

class Districts{
  int districtId;
  String districtName;
  Districts({this.districtId, this.districtName});
}

class DistrictAvailability{
  int centerId;
  String centerName, centerAddress, blockName, stateName, districtName;
  int pincode, lat, long;
  String feeType, timeFrom, timeTo, date;
  List<dynamic> slots;
  List<dynamic> sessions;
  DistrictAvailability({this.centerId, this.centerName, this.centerAddress, this.blockName, this.stateName, this.districtName, this.pincode, this.lat,
  this.long, this.feeType, this.timeFrom, this.timeTo, this.date, this.slots, this.sessions});
}

/*
void printHello() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("Hello $now");
  //print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
}
 */

void callNotification() {
  print("In callNotification");
  localNotifyManager.repeatNotification();
}



class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<States> states = [];
  List<Districts> districts = [];
  List<DistrictAvailability> districtAvailabilities = [];
  List<DistrictAvailability> filteredAvailabilities = [];

  bool _loadingStates = true, _hasLoadedCenters=false, notificationSwitch=false;
  String _value1, _value2;
  int selectedState, selectedDistrict;
  int numFilters = 0; // Number of Filters added

  Future<void> getStates() async {
    print("In getStates");
    States state;
    String url = "https://cdn-api.co-vin.in/api/v2/admin/location/states";
    var response = await http.get(Uri.parse(url));
    var jsonData = jsonDecode(response.body);

    for(var elements in jsonData['states']) {
      state = States(
        stateId: elements['state_id'],
        stateName: elements['state_name'],
      );
      states.add(state);
    }

    final prefs = await SharedPreferences.getInstance();
    notificationSwitch = prefs.getBool('notificationSwitch') ?? false;

    setState(() {
      _loadingStates=false;
    });
  }

  Future<void> getDistricts(int selectedState) async {
    print("In getDistricts");
    Districts district;
    String url = "https://cdn-api.co-vin.in/api/v2/admin/location/districts/$selectedState";
    var response = await http.get(Uri.parse(url));
    var jsonData = jsonDecode(response.body);

    for(var elements in jsonData['districts']) {
      district = Districts(
        districtId: elements['district_id'],
        districtName: elements['district_name'],
      );
      districts.add(district);
    }

    setState(() {
    });
  }

  Future<void> getAvailability(int selectedDistrict) async {
    print("In getAvailability");
    DistrictAvailability districtAvailability;
    districtAvailabilities.clear();
    filteredAvailabilities.clear();

    var now = new DateTime.now();
    var formatter = new DateFormat('dd-MM-yyyy');
    String formattedDate = formatter.format(now);

    String url = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=$selectedDistrict&date=$formattedDate";
    var response = await http.get(Uri.parse(url));
    var jsonData = jsonDecode(response.body);

    for (var elements in jsonData['centers']) {
        districtAvailability = new DistrictAvailability(
          centerId: elements['center_id'],
          centerName: elements['name'],
          centerAddress: elements['address'],
          districtName: elements['district_name'],
          blockName: elements['block_name'],
          pincode: elements['pincode'],
          timeFrom: elements['from'],
          timeTo: elements['to'],
          feeType: elements['fee_type'],
          sessions: elements['sessions'],
        );


      districtAvailabilities.add(districtAvailability);
      filteredAvailabilities.add(districtAvailability);
      /*
      for(var x in districtAvailability.sessions)
        print(x.date);

        */
      }
      /*
      for(var i in filteredAvailabilities) {
        print(i.centerName);
        for(var j in i.sessions)
          print(j['min_age_limit']);
      }
      \
       */

      setState(() {
        _hasLoadedCenters=true;
      });
    print(districtAvailabilities.length);
    }

    Widget showFilters() {
      return Container(
        height: 50,
        child: ListView.separated(
          itemCount: filterOptions.length,
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => SizedBox(width: 10,),
            itemBuilder: (BuildContext context, int index){
              return InkWell(
                onTap: (){
                  setState(() {
                    filterSelected[index] = !filterSelected[index];
                    if(filterSelected[index])
                      numFilters++;
                    else
                      numFilters--;
                  });
                  print(filterSelected);
                  filterChange();
                },
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 30,
                    width: MediaQuery.of(context).size.height*0.15,
                    child: FittedBox(child: Text(filterOptions[index], textAlign: TextAlign.center,), fit: BoxFit.none,),
                    decoration: BoxDecoration(
                      color: filterSelected[index] ? Colors.lightBlueAccent : Colors.white10,
                      border: Border.all(
                        color: Colors.black,
                      ),
                        borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                  ),
                ),
              );
        }),
      );
    }

    void filterChange() {
    setState(() {
      _hasLoadedCenters=false;
    });
    print("In filterChange");
    List<DistrictAvailability> newFiltered = [];
    DistrictAvailability tempAvailability;

      print(districtAvailabilities.length);
      for(var i in districtAvailabilities) {
        List<dynamic> tempSessions = [];
        for (var j in i.sessions) {

          if ((filterSelected[0] && j['min_age_limit'] == 18))
            tempSessions.add(j);

          if((filterSelected[1] && j['min_age_limit'] == 45) && !tempSessions.contains(j))
            tempSessions.add(j);
          else if((filterSelected[1] && j['min_age_limit'] != 45) && tempSessions.contains(j))
            tempSessions.remove(j);

          if((filterSelected[2] && j['vaccine'] == "COVISHIELD") && !tempSessions.contains(j))
            tempSessions.add(j);
          else if((filterSelected[2] && j['vaccine'] != "COVISHIELD") && tempSessions.contains(j))
            tempSessions.remove(j);

          if((filterSelected[3] && j['vaccine'] == "COVAXIN") && !tempSessions.contains(j))
            tempSessions.add(j);
          else if((filterSelected[3] && j['vaccine'] != "COVAXIN") && tempSessions.contains(j))
            tempSessions.remove(j);



        }
        tempAvailability=i;
        if(tempSessions.isEmpty)
          continue;
        tempAvailability.sessions=tempSessions;
        newFiltered.add(tempAvailability);
        if((filterSelected[4] && tempAvailability.feeType == "Paid") && !newFiltered.contains(tempAvailability))
          newFiltered.add(tempAvailability);
        else if((filterSelected[4] && tempAvailability.feeType != "Paid") && newFiltered.contains(tempAvailability))
          newFiltered.remove(tempAvailability);
        if((filterSelected[5] && tempAvailability.feeType == "Free") && !newFiltered.contains(tempAvailability))
          newFiltered.add(tempAvailability);
        else if((filterSelected[5] && tempAvailability.feeType != "Free") && newFiltered.contains(tempAvailability))
          newFiltered.remove(tempAvailability);
      }

        filteredAvailabilities=newFiltered;
      //print(filteredAvailabilities);
      if(numFilters==0)
        filteredAvailabilities=districtAvailabilities;
      //print(districtAvailabilities);
      setState(() {
        _hasLoadedCenters=true;
      });
    }

    @override
    void initState() {
      super.initState();
      getStates();
      localNotifyManager.setListenerForLowerVersions(onNotificationInLowerVersions);
      localNotifyManager.setOnNotificationClick(onNotificationClick);
    }


    /*
  void runAlarm() {
    AndroidAlarmManager.oneShot(
      Duration(seconds: 10),
      0,
      printHello,
      wakeup: true,
    ).then((val) => print(val));
  }

     */


    onNotificationInLowerVersions(ReceivedNotification receivedNotification) {}
      Future onNotificationClick(String payload) {
      print("Pressed Notification");
      print("Payload: $payload");
      //Navigator.pushNamed(context, '/article_view',arguments: ScreenArguments(payload));
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          actions: [
            IconButton(
                icon: notificationSwitch? Icon(Icons.notifications_active) : Icon(Icons.notifications_off),
                onPressed: () async {
                  //AndroidAlarmManager.oneShot(const Duration(seconds: 1), 0, printHello);

                  if(selectedDistrict==null && notificationSwitch==false)
                    Fluttertoast.showToast(
                        msg: "Please select a district first",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                    );
                  else {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() {
                      notificationSwitch = !notificationSwitch;
                    });
                    if(notificationSwitch) {
                      prefs.setInt('districtID',
                          districts[selectedDistrict].districtId);
                      print("Started Notifications");
                      Fluttertoast.showToast(
                        msg: "You'll be notified of slots in ${districts[selectedDistrict].districtName}",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                      //AndroidAlarmManager.oneShot(const Duration(seconds: 1), 0, )
                      AndroidAlarmManager.periodic(const Duration(seconds: 60), 0, callNotification);
                    }
                    else {
                      print("Cancelled Notifications");
                      Fluttertoast.showToast(
                          msg: "Notifications turned off",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                      );
                      prefs.setInt('districtID',0);
                      localNotifyManager.cancelAllNotification();
                      AndroidAlarmManager.cancel(0);
                    }
                  }



                }),
          ],
        ),
        body: _loadingStates ? CircularProgressIndicator() :
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.5,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _value1,
                  hint: Text("Select State"),
                  underline: Container(),
                  items: states.map<DropdownMenuItem<String>>((var value) {
                    return DropdownMenuItem<String>(
                      value: value.stateName,
                      child: Text(value.stateName),
                    );
                  }).toList(),
                  onChanged: (String value) {
                    print(value);
                    _value1 = value;
                    setState(() {
                      selectedState = null;
                      _value2 = null;
                      selectedDistrict = null;
                      districts.clear();
                    });
                    selectedState =
                        states.indexWhere((element) => element.stateName ==
                            value);
                    getDistricts(states[selectedState].stateId);
                    setState(() {});
                  },
                ),
              ),
              selectedState != null ? Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.5,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _value2,
                  hint: Text("Select District"),

                  underline: Container(),
                  items: districts.map<DropdownMenuItem<String>>((var value) {
                    return DropdownMenuItem<String>(
                      value: value.districtName,
                      child: Text(value.districtName),
                    );
                  }).toList(),
                  onChanged: (String value) {
                    setState(() {
                      _value2 = value;
                    });
                    selectedDistrict = districts.indexWhere((element) => element
                        .districtName == value);
                    print(districts[selectedDistrict].districtId);
                  },
                ),
              ) : Container(),
              selectedDistrict != null ?
              ElevatedButton(onPressed: () async {
               for(int i=0;i<filterSelected.length;++i)
                 filterSelected[i]=false;
               numFilters=0;
               setState(() {
               });
                print(filterSelected);
                getAvailability(districts[selectedDistrict].districtId);
              },
                child: Text("Search Available Slots"),
              ) : Container(),
              _hasLoadedCenters ? showFilters() : Container(),
              _hasLoadedCenters ? Text("Available Centers: " + filteredAvailabilities.length.toString()) : Container(),
              _hasLoadedCenters ? Expanded(
                child: Container(
                  child: ListView.separated(
                      itemCount: filteredAvailabilities.length,
                      separatorBuilder: (context, index) => SizedBox(height: 10, child: Divider(thickness: 2, color: Colors.white,),),
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          elevation: 1.0,
                          color: Colors.white10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Center: " +
                                  filteredAvailabilities[index].centerName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                              Text("Block: " + filteredAvailabilities[index].blockName),
                              Text("Fee Type: " +
                                  filteredAvailabilities[index].feeType),
                              Text("Timing: " + filteredAvailabilities[index].timeFrom + " - " + filteredAvailabilities[index].timeTo),
                              Text("Address: " +
                                  filteredAvailabilities[index].centerAddress),
                              /*
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                Expanded(child: Text("Date: ", style: TextStyle(fontSize: 20),),),
                                Expanded(child: Text("Available: ", style: TextStyle(fontSize: 20),),),
                                Expanded(child: Text("Vaccine: ", style: TextStyle(fontSize: 20),),),
                                Expanded(child: Text("Min Age: ", style: TextStyle(fontSize: 20),)),
                              ],
                              ),
                               */
                              Divider(thickness: 3,),
                              _returnSessions(filteredAvailabilities[index].sessions),
                            ],
                          ),
                        );
                      }),
                ),
              ) : Container(),

            ],
          ),
        ),
      );

  }

    Widget _returnSessions(List<dynamic> item) {
      return Container(
        child: ListView.separated(
            itemCount: item.length,
            physics: ClampingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) => Divider(thickness: 3,),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item[index]['date'], style: TextStyle(fontSize: 20),),
                    Container(
                      width: 40,
                        child: Text(item[index]['available_capacity'].toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 20),),
                      decoration: BoxDecoration(
                        color: item[index]['available_capacity']>40? Colors.green : item[index]['available_capacity']>0? Colors.yellow : Colors.red,
                      ),
                    ),
                    Text(item[index]['vaccine']=="COVAXIN"? item[index]['vaccine'] + "      " : item[index]['vaccine'], style: TextStyle(fontSize: 20),),
                    Text(item[index]['min_age_limit'].toString() + "+", style: TextStyle(fontSize: 20),),
                  ],
                ),
              );
            }),
      );
    }


}
