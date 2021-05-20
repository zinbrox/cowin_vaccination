import 'dart:convert';
import 'dart:isolate';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:cowin_vaccination/helpers/notificationsPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> filterOptions = ["18+", "45+", "COVISHIELD", "COVAXIN", "SPUTNIK V", "Paid", "Free"];
List<bool> filterSelected = [false, false, false, false, false, false, false];

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
  String _value1, _value2, _value3; // For displaying DropDownMenu
  int selectedState, selectedDistrict; // Selected values from DropDownMenu
  String selectedDose; // Selected Dose number from DropDownMenu
  int numFilters = 0; // Number of Filters added
  int statusCode=200;

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

    statusCode=response.statusCode;

    if(statusCode==200) {
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
      }
    }
     filteredAvailabilities = districtAvailabilities;
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
                    height: 35,
                    width: MediaQuery.of(context).size.width*0.3,
                    child: FittedBox(child: Text(filterOptions[index], textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: filterSelected[index]? Colors.white : Colors.black),), fit: BoxFit.scaleDown,),
                    decoration: BoxDecoration(
                      color: filterSelected[index] ? Colors.deepPurple : Colors.white,
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
    int sessionFilters = 0;
    for(int i=0;i<5;++i)
      if(filterSelected[i])
        sessionFilters++;

      print(districtAvailabilities.length);
      for(var i in districtAvailabilities) {
        List<dynamic> tempSessions = [];
        for (var j in i.sessions) {

          if ((filterSelected[0] && j['min_age_limit'] == 18) && !tempSessions.contains(j))
            tempSessions.add(j);
          else if((filterSelected[0] && j['min_age_limit'] != 18) && tempSessions.contains(j))
            tempSessions.remove(j);


          if((filterSelected[1] && j['min_age_limit'] == 45) && !tempSessions.contains(j))
            tempSessions.add(j);

          if((filterSelected[2] && j['vaccine'] == "COVISHIELD") && !tempSessions.contains(j)) {
            if ((filterSelected[0] && j['min_age_limt'] == 18) || (filterSelected[1] && j['min_age_limit'] == 45) || (!(filterSelected[0] || filterSelected[1])))
              tempSessions.add(j);
          }
          else if((filterSelected[2] && j['vaccine'] != "COVISHIELD") && tempSessions.contains(j) && !filterSelected[3] && !filterSelected[4])
            tempSessions.remove(j);

          if((filterSelected[3] && j['vaccine'] == "COVAXIN") && !tempSessions.contains(j)) {
            if ((filterSelected[0] && j['min_age_limt'] == 18) || (filterSelected[1] && j['min_age_limit'] == 45) || (!(filterSelected[0] || filterSelected[1])))
              tempSessions.add(j);
          }
          else if((filterSelected[3] && j['vaccine'] != "COVAXIN") && tempSessions.contains(j) && !filterSelected[2] && !filterSelected[4])
            tempSessions.remove(j);


          if((filterSelected[4] && j['vaccine'] == "SPUTNIK V") && !tempSessions.contains(j)) {
            if ((filterSelected[0] && j['min_age_limt'] == 18) || (filterSelected[1] && j['min_age_limit'] == 45) || (!(filterSelected[0] || filterSelected[1])))
              tempSessions.add(j);
          }
          else if((filterSelected[4] && j['vaccine'] != "SPUTNIK V") && tempSessions.contains(j) && !filterSelected[2] && !filterSelected[3])
            tempSessions.remove(j);

        }
        tempAvailability=i;

        if(tempSessions.isEmpty && sessionFilters!=0)
          continue;
        else if(tempSessions.isEmpty && sessionFilters==0)
          tempAvailability=i;
        else
          tempAvailability.sessions=tempSessions;
        newFiltered.add(tempAvailability);
        if((filterSelected[5] && tempAvailability.feeType == "Paid") && !newFiltered.contains(tempAvailability))
          newFiltered.add(tempAvailability);
        else if((filterSelected[5] && tempAvailability.feeType != "Paid") && newFiltered.contains(tempAvailability))
          newFiltered.remove(tempAvailability);
        if((filterSelected[6] && tempAvailability.feeType == "Free") && !newFiltered.contains(tempAvailability))
          newFiltered.add(tempAvailability);
        else if((filterSelected[6] && tempAvailability.feeType != "Free") && newFiltered.contains(tempAvailability))
          newFiltered.remove(tempAvailability);
      }

        filteredAvailabilities=newFiltered;
      print(filteredAvailabilities.length);
      if(numFilters==0)
        filteredAvailabilities=districtAvailabilities;
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


    onNotificationInLowerVersions(ReceivedNotification receivedNotification) {}
      Future onNotificationClick(String payload) {
      print("Pressed Notification");
      print("Payload: $payload");
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(

          title: Text("Cowin Slot Notifier"),
          actions: [
            IconButton(
                icon: notificationSwitch? Icon(Icons.notifications_active) : Icon(Icons.notifications_off),
                onPressed: () async {
                  if((selectedDistrict==null && notificationSwitch==false)||(selectedDose==null && notificationSwitch==false))
                    Fluttertoast.showToast(
                        msg: "Please select a district and dose first",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                        fontSize: 16.0
                    );
                  else {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() {
                      notificationSwitch = !notificationSwitch;
                    });
                    if(notificationSwitch) {
                      prefs.setBool('notificationSwitch', true);
                      prefs.setInt('districtID',
                          districts[selectedDistrict].districtId);
                      prefs.setString('doseNum', selectedDose);
                      print("Started Notifications");
                      HapticFeedback.vibrate();
                      Fluttertoast.showToast(
                        msg: "You'll be notified of slots in ${districts[selectedDistrict].districtName}",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                          fontSize: 16.0
                      );
                      //AndroidAlarmManager.oneShot(const Duration(seconds: 1), 0, )
                      AndroidAlarmManager.periodic(const Duration(seconds: 60), 0, callNotification);
                    }
                    else {
                      print("Cancelled Notifications");
                      prefs.setBool('notificationSwitch', false);
                      Fluttertoast.showToast(
                          msg: "Notifications turned off",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                          fontSize: 16.0
                      );
                      prefs.setInt('districtID',0);
                      localNotifyManager.cancelAllNotification();
                      AndroidAlarmManager.cancel(0);
                    }
                  }



                }),
          ],
        ),
        body: _loadingStates ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple))) :
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              filteredAvailabilities.length==0 ? Spacer() : Container(),
              Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.5,
                child: DropdownButton<String>(
                  isExpanded: true,
                  itemHeight: 50,
                  value: _value1,
                  hint: Text("Select State", style: TextStyle(fontSize: 20),),
                  underline: Container(),
                  items: states.map<DropdownMenuItem<String>>((var value) {
                    return DropdownMenuItem<String>(
                      value: value.stateName,
                      child: Text(value.stateName, style: TextStyle(fontSize: 20),),
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
                  hint: Text("Select District", style: TextStyle(fontSize: 20),),
                  underline: Container(),
                  items: districts.map<DropdownMenuItem<String>>((var value) {
                    return DropdownMenuItem<String>(
                      value: value.districtName,
                      child: Text(value.districtName, style: TextStyle(fontSize: 20),),
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
              selectedDistrict != null ? Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.5,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _value3,
                  hint: Text("Select Dose", style: TextStyle(fontSize: 20),),
                  underline: Container(),
                  onChanged: (String newValue){
                    setState(() {
                      _value3=newValue;
                      selectedDose=newValue;
                    });
                  },
                  items: <String>['Dose 1', 'Dose 2'].
                  map<DropdownMenuItem<String>>((String value){
                    return DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(fontSize: 20),),);
                  }).toList(),
                ),
              ) : Container(),
              selectedDose != null ?
              ElevatedButton(onPressed: () async {
               for(int i=0;i<filterSelected.length;++i)
                 filterSelected[i]=false;
               numFilters=0;
               setState(() {
               });
                print(filterSelected);
                getAvailability(districts[selectedDistrict].districtId);
              },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                child: Text("Search Available Slots", style: TextStyle(fontSize: 20),),
              ) : Container(),
              _hasLoadedCenters ? showFilters() : Container(),
              _hasLoadedCenters ? Text("Available Centers: " + filteredAvailabilities.length.toString()) : Container(),
              _hasLoadedCenters ? Expanded(
                child: filteredAvailabilities.isEmpty? Center(child: Column(
                  children: [
                    Text("No Available Centers", style: TextStyle(fontSize: 15),),
                    statusCode==200? Container() : statusCode==400? Text("Error Code 400. Bad Request") : statusCode==401? Text("Error Code 401. Unauthenticated Access") : Text("Error Code 500. Internal Server Error"),
                  ],
                ),) : Container(
                  child: ListView.separated(
                      itemCount: filteredAvailabilities.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12,),
                      physics: ClampingScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(
                              color: Colors.white12,
                              width: 1,
                            ),
                          ),
                          elevation: 1.0,
                          color: Colors.grey[900],
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(filteredAvailabilities[index].centerName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                              SizedBox(height: 10,),
                              Text("Block: " + filteredAvailabilities[index].blockName, style: TextStyle(color: Colors.white70),),
                              Text("Fee Type: " +
                                  filteredAvailabilities[index].feeType, style: TextStyle(color: Colors.white70),),
                              Text("Timing: " + filteredAvailabilities[index].timeFrom + " - " + filteredAvailabilities[index].timeTo, style: TextStyle(color: Colors.white70),),
                              Text("Address: " +
                                  filteredAvailabilities[index].centerAddress, style: TextStyle(color: Colors.white70),),
                              SizedBox(height: 10,),
                              Divider(thickness: 3,),
                              _returnSessions(filteredAvailabilities[index].sessions),
                              SizedBox(height: 10,),
                            ],
                          ),
                        );
                      }),
                ),
              ) : Container(),
              filteredAvailabilities.length==0 ? Spacer() : Container(),
              filteredAvailabilities.length==0 ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 20,),
                  SizedBox(width: 5,),
                  Text("Click on the Bell Icon to turn on Notifications", style: TextStyle(color: Colors.white70),),
                ],
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
                        child: Text(selectedDose=="Dose 1"? item[index]['available_capacity_dose1'].toString() : item[index]['available_capacity_dose2'].toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 20),),
                      decoration: BoxDecoration(
                        color: selectedDose=="Dose 1"? item[index]['available_capacity_dose1']>25? Colors.green : item[index]['available_capacity_dose1']>0? Colors.yellow[800] : Colors.red :
                        item[index]['available_capacity_dose2']>25? Colors.green : item[index]['available_capacity_dose2']>0? Colors.yellow[800] : Colors.red ,
                      ),
                    ),
                    Column(
                      children: [
                        Text("Dose 1: ${item[index]['available_capacity_dose1']}"),
                        Text("Dose 2: ${item[index]['available_capacity_dose2']}"),
                      ],
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
