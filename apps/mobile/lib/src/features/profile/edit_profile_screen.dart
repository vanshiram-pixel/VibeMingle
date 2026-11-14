import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState()=>_EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen>{
  final _name=TextEditingController(),_bio=TextEditingController(),_interests=TextEditingController(),_language=TextEditingController(text:'en');
  bool _loading=true,_saving=false,_uploading=false;String? _error,_avatarUrl;final _picker=ImagePicker();
  Map<String,String> get _headers=>{'Authorization':'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken??''}','Content-Type':'application/json'};
  Uri _uri(String path)=>Uri.parse('${AppConfig.apiBaseUrl}$path');
  @override void initState(){super.initState();load();}
  @override void dispose(){_name.dispose();_bio.dispose();_interests.dispose();_language.dispose();super.dispose();}
  Future<void> load()async{
    try{final res=await http.get(_uri('/v1/me'),headers:_headers);final body=jsonDecode(res.body);if(res.statusCode<200||res.statusCode>=300)throw Exception();
      final p=body['data'] as Map<String,dynamic>?;if(p!=null){_name.text=p['display_name']?.toString()??'';_bio.text=p['bio']?.toString()??'';_language.text=p['preferred_language']?.toString()??'en';_interests.text=(p['interests'] as List? ?? []).join(', ');_avatarUrl=p['avatar_path']?.toString();}
    }catch(_){_error='Profile load नहीं हुआ। API/migration जाँचें.';}finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> pickAvatar()async{    try{final image=await _picker.pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:1200);if(image==null)return;setState(()=>_uploading=true);final user=Supabase.instance.client.auth.currentUser;if(user==null)throw Exception('Sign in required');final bytes=await image.readAsBytes();final mime=image.mimeType??'image/jpeg';final ext=mime.split('/').last;final path='${user.id}/avatar.$ext';await Supabase.instance.client.storage.from('avatars').uploadBinary(path,bytes,fileOptions:FileOptions(upsert:true,contentType:mime));final url=Supabase.instance.client.storage.from('avatars').getPublicUrl(path);final res=await http.patch(_uri('/v1/me/profile'),headers:_headers,body:jsonEncode({'avatar_path':url}));if(res.statusCode<200||res.statusCode>=300)throw Exception('Profile update failed');if(mounted)setState(()=>_avatarUrl=url);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Avatar updated ✓')));    }catch(_){if(mounted)setState(()=>_error='Photo upload नहीं हुआ। avatars migration और Storage policy लागू करें.');}finally{if(mounted)setState(()=>_uploading=false);}  }  Future<void> save()async{
    if(_name.text.trim().length<2){setState(()=>_error='नाम कम से कम 2 अक्षर का रखें.');return;}
    setState(()=>_saving=true);_error=null;
    try{final res=await http.patch(_uri('/v1/me/profile'),headers:_headers,body:jsonEncode({'display_name':_name.text.trim(),'bio':_bio.text.trim(),'preferred_language':_language.text.trim(),'interests':_interests.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).take(20).toList()}));
      if(res.statusCode<200||res.statusCode>=300)throw Exception();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Profile saved ✓'))); 
    }catch(_){if(mounted)setState(()=>_error='Save नहीं हुआ। कृपया API और profile policy जाँचें.');}finally{if(mounted)setState(()=>_saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Edit Profile')),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
    Center(child:Stack(children:[CircleAvatar(radius:48,backgroundImage:_avatarUrl!=null?NetworkImage(_avatarUrl!):null,child:_avatarUrl==null?const Icon(Icons.person,size:44):null),Positioned(right:0,bottom:0,child:IconButton.filled(onPressed:_uploading?null:pickAvatar,icon:_uploading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.camera_alt,size:18)))])),const SizedBox(height:20),
    TextField(controller:_name,maxLength:40,decoration:const InputDecoration(labelText:'Display name *')),
    TextField(controller:_bio,maxLength:240,maxLines:3,decoration:const InputDecoration(labelText:'Bio')),
    TextField(controller:_interests,decoration:const InputDecoration(labelText:'Interests (comma separated)',hintText:'music, travel, movies')),
    TextField(controller:_language,decoration:const InputDecoration(labelText:'Preferred language',hintText:'en / hi')),
    if(_error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,style:const TextStyle(color:Colors.orange))),
    const SizedBox(height:20),FilledButton(onPressed:_saving?null:save,child:Text(_saving?'Saving…':'Save profile')),
    const SizedBox(height:12),const Text('Photo: JPG / PNG / WebP, अधिकतम 5 MB',textAlign:TextAlign.center),
  ]));
}
