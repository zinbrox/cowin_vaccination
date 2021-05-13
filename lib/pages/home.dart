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
  List<String> slots;
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<States> states = [];
  List<Districts> districts = [];
  List<DistrictAvailability> districtAvailability = [];

  bool _loadingStates = true;
  String _value1;
  int selectedState;

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
        child: Row(
          children: [
            DropdownButton<String>(
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
                selectedState = states.indexWhere((element) => element.stateName==value);
                getDistricts(selectedState);
              },
            ),
            DropdownButton<String>(
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
                print("Changed");
              },
            ),
          ],
        ),
      ),
    );
  }
}
