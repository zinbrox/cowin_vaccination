import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  int availableCapacity, minAgeLimit;
  String vaccine, fee, feeType, timeFrom, timeTo;
  List<dynamic> slots;
  DistrictAvailability({this.centerId, this.centerName, this.centerAddress, this.blockName, this.stateName, this.districtName, this.pincode, this.lat,
  this.long, this.availableCapacity, this.minAgeLimit, this.vaccine, this.fee, this.feeType, this.timeFrom, this.timeTo, this.slots});
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<States> states = [];
  List<Districts> districts = [];
  List<DistrictAvailability> districtAvailabilities = [];

  bool _loadingStates = true;
  String _value1, _value2;
  int selectedState, selectedDistrict;

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
    String url = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/findByDistrict?district_id=$selectedDistrict&date=13-05-2021";
    var response = await http.get(Uri.parse(url));
    var jsonData = jsonDecode(response.body);

    for(var elements in jsonData['sessions']) {
      print(elements['name']);
      districtAvailability = DistrictAvailability(
        centerId: elements['center_id'],
        centerName: elements['name'],
        centerAddress: elements['address'],
        stateName: elements['state_name'],
        districtName: elements['district_name'],
        blockName: elements['block_name'],
        pincode: elements['pincode'],
        timeFrom: elements['from'],
        timeTo: elements['to'],
        lat: elements['lat'],
        long: elements['long'],
        feeType: elements['fee_type'],
        fee: elements['fee'],
        availableCapacity: elements['available_capacity'],
        minAgeLimit: elements['min_age_limit'],
        vaccine: elements['vaccine'],
        slots: elements['slots'],
      );
      districtAvailabilities.add(districtAvailability);
    }
    setState(() {
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
              width: MediaQuery.of(context).size.width*0.5,
              child: DropdownButton<String>(
                isExpanded: true,
                value: _value1,
                hint: Text("Select State"),
                underline: Container(),
                items: states.map<DropdownMenuItem<String>>((var value){
                  return DropdownMenuItem<String>(
                    value: value.stateName,
                    child: Text(value.stateName),
                  );
                }).toList(),
                onChanged: (String value) {
                  print(value);
                  _value1 = value;
                  setState(() {
                    selectedState=null;
                    _value2=null;
                    selectedDistrict=null;
                    districts.clear();
                  });
                  selectedState = states.indexWhere((element) => element.stateName==value);
                  getDistricts(states[selectedState].stateId);
                  setState(() {
                  });
                },
              ),
            ),
            selectedState!=null ? Container(
              width: MediaQuery.of(context).size.width*0.5,
              child: DropdownButton<String>(
                isExpanded: true,
                value: _value2,
                hint: Text("Select District"),

                underline: Container(),
                items: districts.map<DropdownMenuItem<String>>((var value){
                  return DropdownMenuItem<String>(
                    value: value.districtName,
                    child: Text(value.districtName),
                  );
                }).toList(),
                onChanged: (String value) {
                  setState(() {
                    _value2=value;
                  });
                  selectedDistrict = districts.indexWhere((element) => element.districtName==value);
                  print(districts[selectedDistrict].districtId);
                },
              ),
            ) : Container(),
            selectedDistrict!=null ? ElevatedButton(onPressed: (){
                getAvailability(districts[selectedDistrict].districtId);
            },
                child: Text("Search Available Slots"),
            ) : Container(),
          ],
        ),
      ),
    );
  }
}
