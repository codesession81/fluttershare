
import 'package:permission_handler/permission_handler.dart';

class PermissionManager{

  late Permission _permission;
  PermissionStatus _permissionStorageStatus = PermissionStatus.denied;
  PermissionStatus _permissionGalleryStatus = PermissionStatus.denied;
  PermissionStatus _permissionCameraStatus = PermissionStatus.denied;
  PermissionStatus _permissionExternalStorageStatus = PermissionStatus.denied;

  void getPermissionState()async{
    final storageStatus = await Permission.storage.status;
    final galleryStatus = await Permission.photos.status;
    final cameraStatus = await Permission.camera.status;
    final externalStorageStatus = await Permission.manageExternalStorage.status;

    _permissionStorageStatus=storageStatus;
    _permissionGalleryStatus=galleryStatus;
    _permissionCameraStatus=cameraStatus;
    _permissionExternalStorageStatus = externalStorageStatus;

    if(storageStatus==PermissionStatus.denied){
      requestStoragePermission();
    }else if(galleryStatus==PermissionStatus.denied){
      requestGalleryPermission();
    }else if(cameraStatus== PermissionStatus.denied){
      requestCameraPermission();
    }else if(externalStorageStatus==PermissionStatus.denied){
      requestExternalStoragePermission();
    }
  }

  Future<void>requestStoragePermission()async{
    final status = await Permission.storage.request();
    _permissionStorageStatus = status;
  }

  Future<void>requestGalleryPermission()async{
    final status = await Permission.photos.request();
    _permissionGalleryStatus = status;
  }

  Future<void>requestCameraPermission()async{
    final status = await Permission.camera.request();
    _permissionCameraStatus = status;
  }

  Future<void>requestExternalStoragePermission()async{
    final status = await Permission.manageExternalStorage.request();
    _permissionExternalStorageStatus = status;
  }

}