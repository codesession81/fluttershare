import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/permissions/permission_manager.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {

  final User? currentUser;
  Upload({required this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {

  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();

  XFile? img;
  File? convertFile;
  final PermissionManager _permissionManager = PermissionManager();
  final DateTime timestamp = DateTime.now();
  bool isUploading = false;
  String postId = Uuid().v4();
  String? downloadUrl;

  @override
  void initState() {
    super.initState();
    _permissionManager.getPermissionState();
  }

  handleTakePhoto()async{
    final file = await ImagePicker().pickImage(source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    if(file!=null){
      setState(() {
        img = file;
      });
    }
  }

  handleChooseFromGallery()async{
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(file!=null){
      setState(() {
        img = file;
      });
    }
  }

  selectImage(parentContext){
    return showDialog(
      context: parentContext,
      builder: (context){
        return SimpleDialog(
          title: Text("Create Post"),
          children: <Widget>[
            SimpleDialogOption(
              child: Text("Photo with Camera"),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text("Image from Gallery"),
              onPressed: handleChooseFromGallery,
            ),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed:()=> Navigator.pop(context),
            )
          ],
        );
      }
    );
  }

  Container buildSplashScreen(){
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg', height: 260),
          Padding(
              padding: EdgeInsets.only(top: 20),
              child: TextButton(
                child: Text(
                  "Upload Image",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22
                  ),
                ),
                onPressed: ()=> selectImage(context),
              ),
          )
        ],
      ),
    );
  }

  clearImage(){
    setState(() {
      img=null;
    });
  }

  Future<String> uploadImage(File file) async {
    final ref = FirebaseStorage.instance.ref().child("post_$postId.jpg").child(file.path);
    final result = await ref.putFile(file);
    final String fileUrl = (await result.ref.getDownloadURL()).toString();
    return fileUrl;
  }

  createPostInFirestore({String? mediaUrl,String? location,String? description}){
    postRef.doc(widget.currentUser!.id)
        .collection("userPosts")
        .doc(postId)
        .set({
          "postId": postId,
          "ownerId": widget.currentUser!.id,
          "username": widget.currentUser!.username,
          "mediaUrl": mediaUrl,
          "description": description,
          "location": location,
          "timestamp": timestamp,
          "likes": {}
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      img = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  handleSubmit()async{
    setState(() {
      isUploading=true;
    });
    await compressImage();
    String mediaUrl=await uploadImage(convertFile!);
    print(mediaUrl.toString());
    createPostInFirestore(mediaUrl: mediaUrl,location: locationController.text,description: captionController.text);
  }

  compressImage()async{
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    setState(() {
      convertFile = File(img!.path);
    });
    Im.Image? imageFile = Im.decodeImage(convertFile!.readAsBytesSync());
    final compresssedImageFile=File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(imageFile!,quality: 85));
    setState(() {
      convertFile = compresssedImageFile;
    });
  }

  Scaffold buildUploadForm(){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.black),
          onPressed: clearImage,
        ),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            child: Text(
              "Post",
              style: TextStyle(color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 20
              ),
            ),
            onPressed:   ()=> handleSubmit(),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(img!.path))
                    )
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.currentUser!.photoUrl!),
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Write a caption...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop,color: Colors.orange,size: 35),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
           Container(
             width: 200,
             height: 100,
             alignment: Alignment.center,
             child:TextButton.icon(
                 onPressed: getUserLocation,
                 icon: Icon(Icons.my_location,color: Colors.white,),
                 label: Text("Use Current Location",style: TextStyle(color: Colors.white),
                 ),
             )
           )
        ],
      ),
    );
  }

  getUserLocation()async{
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark =placemarks[0];
    String completeAddress = '${placemark.subThoroughfare} ${placemark.thoroughfare} ${placemark.subLocality} ${placemark.locality} ${placemark.subAdministrativeArea} ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country} ';
    print(completeAddress);
    String formatedAdress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formatedAdress;
  }

  @override
  Widget build(BuildContext context) {
    return img==null? buildSplashScreen(): buildUploadForm();
  }
}
