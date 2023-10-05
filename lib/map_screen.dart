import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';


class CurrentSearchLocation extends StatefulWidget {
  const CurrentSearchLocation({super.key});


  @override
  State<CurrentSearchLocation> createState() => _CurrentSearchLocationState();
}
const kGoogleApiKey= 'AIzaSyAojG0m2L8gnI4GFn5qR5VmqrDOLlCDNY4';
final homeScaffoldKey= GlobalKey<ScaffoldState>();
class _CurrentSearchLocationState extends State<CurrentSearchLocation> {

  final Mode _mode= Mode.overlay;

  late GoogleMapController googleMapController;
  static const CameraPosition initialCameraPosition= CameraPosition(target: LatLng(23.80, 90.41),zoom: 14);

  Set<Marker> markersList={};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      appBar: AppBar(title: Text("Google Map"),),
      body: Stack(children: [
        GoogleMap(initialCameraPosition: initialCameraPosition,
          markers: markersList,
          mapType: MapType.normal,
          scrollGesturesEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,


          onMapCreated: (GoogleMapController controller){
            googleMapController=controller;


          },

        ),


        Positioned(
          top: 80,
          right: 5,
          child:   Container(
              height: 50,
              width:50,
              decoration: BoxDecoration(color: Colors.red,
                  borderRadius: BorderRadius.circular(50)

              ),
              child: IconButton(onPressed: _pressedButton, icon: Icon(Icons.search, size: 30,color: Colors.white,))),
        ),

        Positioned(
          top: 150,
          right: 5,
          child:   Container(
              height: 50,
              width:50,
              decoration: BoxDecoration(color: Colors.red,
                  borderRadius: BorderRadius.circular(50)

              ),
              child: IconButton(onPressed: () async{


                Position position =await _determinePosition();

                googleMapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(position.latitude, position.longitude),zoom: 14)));

                markersList.clear();
                markersList.add(Marker(markerId:MarkerId("Current Location"),position: LatLng(position.latitude, position.longitude)));

                setState(() {

                });
              }, icon: Icon(Icons.my_location, size: 30,color: Colors.white,))),
        )
      ],),
    );
  }


//search

  Future<void> _pressedButton()async{

    Prediction ? p= await PlacesAutocomplete.show(context: context,
        apiKey: kGoogleApiKey,
        onError: onError,
        mode: _mode,
        language:'en',
        strictbounds: false,
        types: [""],decoration: InputDecoration(hintText: 'Search Location'), components: [Component(Component.country,"bd"), Component(Component.country, "us")]
    );

    displayPrediction(p!, homeScaffoldKey.currentState);
  }

  void onError(PlacesAutocompleteResponse response){

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Message',
        message: response.errorMessage!,
        contentType: ContentType.failure,
      ),
    ));

    //homeScaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(response.errorMessage!)));
  }

  Future<void>displayPrediction(Prediction p, ScaffoldState? currentState) async{


    GoogleMapsPlaces places = GoogleMapsPlaces(
      apiKey: kGoogleApiKey,
      apiHeaders: await const GoogleApiHeaders().getHeaders(),

    );

    PlacesDetailsResponse detail= await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    markersList.clear();
    markersList.add(Marker(markerId: const MarkerId("0"),position: LatLng(lat, lng),infoWindow: InfoWindow(title: detail.result.name) ));

    setState(() {

    });

    googleMapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14));
  }

  // cutrrent location

  Future<Position> _determinePosition() async{

    bool serviceEnabled;

    LocationPermission permission;

    serviceEnabled= await Geolocator.isLocationServiceEnabled();

    if(!serviceEnabled){
      return Future.error("Location Service disabled");
    }
    permission = await Geolocator.checkPermission();

    if(permission==LocationPermission.denied){

      permission= await Geolocator.requestPermission();

      if(permission==LocationPermission.denied){

        return Future.error("Location Permission Denied");
      }
    }

    if(permission==LocationPermission.deniedForever){
      return Future.error("Permission denied permanently");
    }

    Position position= await Geolocator.getCurrentPosition();
    return position;



  }

}
