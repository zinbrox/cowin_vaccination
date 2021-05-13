import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<States> states = [];
  List<Districts> districts = [];
  List<DistrictAvailability> districtAvailabilities = [];
  List<DistrictAvailability> filteredAvailabilities = [];

  bool _loadingStates = true, _hasLoadedCenters=false;
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
    String url = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=$selectedDistrict&date=13-05-2021";
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

      for(var i in filteredAvailabilities) {
        print(i.centerName);
        for(var j in i.sessions)
          print(j['min_age_limit']);
      }

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
            separatorBuilder: (context, index) => Divider(
              color: Colors.red,
            ),
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
                    child: Text(filterOptions[index], textAlign: TextAlign.center,),
                    decoration: BoxDecoration(
                      color: filterSelected[index] ? Colors.blue : Colors.grey,
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

      print(districtAvailabilities.length);
      for(var i in districtAvailabilities)
        for(var j in i.sessions) {
          if((filterSelected[0] && j['min_age_limit']==18) || (filterSelected[1] && j['min_age_limit']==45) || (filterSelected[2] && j['vaccine']=="COVISHIELD") ||
              (filterSelected[3] && j['vaccine']=="COVAXIN") || (filterSelected[4] && i.feeType=="Paid") || (filterSelected[5] && i.feeType=="Free"))
            if(!newFiltered.contains(i)) {
              print("Found");
              newFiltered.add(i);
            }
        }

        filteredAvailabilities=newFiltered;
      print(filteredAvailabilities);
      if(numFilters==0)
        filteredAvailabilities=districtAvailabilities;
      print(districtAvailabilities);
      setState(() {
        _hasLoadedCenters=true;
      });
    }

    @override
    void initState() {
      super.initState();
      getStates();
    }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
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
              selectedDistrict != null ? ElevatedButton(onPressed: () {
                getAvailability(districts[selectedDistrict].districtId);
              },
                child: Text("Search Available Slots"),
              ) : Container(),
              _hasLoadedCenters ? showFilters() : Container(),
              _hasLoadedCenters ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Available Centers: " + filteredAvailabilities.length.toString()),
                  IconButton(icon: Icon(Icons.filter_list),
                      onPressed: () {
                      })
                ],
              ) : Container(),
              _hasLoadedCenters ? Expanded(
                child: Container(
                  child: ListView.builder(
                      itemCount: filteredAvailabilities.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Center Name: " +
                                  filteredAvailabilities[index].centerName, style: TextStyle(fontSize: 20),),
                              Text("Block: " + filteredAvailabilities[index].blockName),
                              Text("Fee Type: " +
                                  filteredAvailabilities[index].feeType),
                              Text("Timing: " + filteredAvailabilities[index].timeFrom + " - " + filteredAvailabilities[index].timeTo),
                              Text("Center Address :" +
                                  filteredAvailabilities[index].centerAddress),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                Text("Date: "),
                                Text("Available Slots: "),
                                Text("Vaccine: "),
                                Text("Min Age Limit: "),
                              ],
                              ),
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
            separatorBuilder: (context, index) => Divider(thickness: 5,),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(item[index]['date']),
                    Container(
                      width: 15,
                        child: Text(item[index]['available_capacity'].toString(), textAlign: TextAlign.center,),
                      decoration: BoxDecoration(
                        color: item[index]['available_capacity']>100? Colors.green : item[index]['available_capacity']>0? Colors.yellow : Colors.red,
                      ),
                    ),
                    Text(item[index]['vaccine']),
                    Text(item[index]['min_age_limit'].toString() + "+"),
                  ],
                ),
              );
            }),
      );
    }


}
