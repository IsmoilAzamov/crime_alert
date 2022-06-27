import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  String long = "", lat = "";
  late StreamSubscription<Position> positionStream;
  final TextEditingController controller = TextEditingController();
  @override
  void initState() {
    checkGps();
    super.initState();
    controller;
  }

  checkGps() async {
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
        } else if (permission == LocationPermission.deniedForever) {
          print("'Location permissions are permanently denied");
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        setState(() {
          //refresh the UI
        });

        getLocation();
      }
    } else {
      print("GPS Service is not enabled, turn on GPS location");
    }
    setState(() {
      //refresh the UI
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    long = position.longitude.toString();
    lat = position.latitude.toString();
    controller.text = "$lat $long";

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 100,
    );

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      long = position.longitude.toString();
      lat = position.latitude.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text("Get GPS Location"),
            backgroundColor: Colors.redAccent),
        body: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50),
            child: Column(children: [
              Text(servicestatus ? "GPS is Enabled" : "GPS is disabled."),
              Text(haspermission ? "App Has Permission to Use GPS" : "GPS is disabled."),
              Text(
                "Latitude: $lat",
                style: const TextStyle(fontSize: 20),
              ),
              Text("Longitude: $long", style: const TextStyle(fontSize: 20)),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green[100]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width*0.5,
                      child: TextField(
                        enabled: false,
                        controller: controller,

                      ),
                    ),
                    Container(
                      height: 60,
                      width: 50,
                      child: Center(
                        child: ElevatedButton(onPressed: (){ Clipboard.setData(ClipboardData(text: controller.text));},
                        style: ElevatedButton.styleFrom(primary: Colors.white54, ), child: const Icon(Icons.copy, color: Colors.black87,),

                        ),
                      ),
                    ) ],
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    if (!servicestatus) {
                      setState(() {
                        checkGps();
                        getLocation();
                      });
                    } else if(!haspermission){
                      checkGps();
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Alert has been Sent!"),
                      ));
                      print("$lat $long");
                      openMapsSheet(
                        context,
                        double.parse(lat),
                        double.parse(long),
                      );
                    }
                  },
                  child: const Text("Send")),
            ])));
  }

  openMapsSheet(context, double lat, double lon) async {
    try {
      final coords = Coords(lat, lon);
      final availableMaps = await MapLauncher.installedMaps;
    if(availableMaps.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Wrap(
                children: <Widget>[
                  for (var map in availableMaps)
                    ListTile(
                      leading: const Icon(Icons.location_on_sharp, color: Colors.red, size: 34,),
                      onTap: () => map.showMarker(

                        coords: coords,
                        title: "Navigating to Crime Zone",
                      ),
                      title: Text(map.mapName),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    else{

    }
    } catch (e) {
      print(e);
    }
  }
}
