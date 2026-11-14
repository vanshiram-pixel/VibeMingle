import 'package:flutter/material.dart'; import 'package:supabase_flutter/supabase_flutter.dart'; import '../home/home_screen.dart';
class OnboardingScreen extends StatefulWidget {const OnboardingScreen({super.key});@override State<OnboardingScreen> createState()=>_OnboardingScreenState();}
class _OnboardingScreenState extends State<OnboardingScreen>{final name=TextEditingController(),language=TextEditingController(text:'en');bool age=false,terms=false,privacy=false,busy=false;String? error;
@override void dispose(){name.dispose();language.dispose();super.dispose();}
Future<void> finish()async{if(!age||!terms||!privacy||name.text.trim().length<2){setState(()=>error='Name, 18+ confirmation, Terms and Privacy acceptance required.');return;}
setState(()=>busy=true);try{final c=Supabase.instance.client;final result=await c.functions.invoke('onboarding-complete',body:{'display_name':name.text.trim(),'preferred_language':language.text.trim(),'interests':<String>[],'accepted_terms_version':'v1','accepted_privacy_version':'v1','age_confirmed':true});
if(result.status<200||result.status>=300)throw Exception();if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));}catch(_){if(mounted)setState(()=>error='Onboarding function not deployed/configured yet.');}finally{if(mounted)setState(()=>busy=false);}}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Create your profile')),body:ListView(padding:const EdgeInsets.all(24),children:[
const Text('A few details before you connect.',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:18),
TextField(controller:name,maxLength:40,decoration:const InputDecoration(labelText:'Display name',border:OutlineInputBorder())),
const SizedBox(height:12),TextField(controller:language,maxLength:12,decoration:const InputDecoration(labelText:'Language (en, hi…)',border:OutlineInputBorder())),
CheckboxListTile(value:age,onChanged:(v)=>setState(()=>age=v??false),title:const Text('I confirm I am 18 or older.'),contentPadding:EdgeInsets.zero),
CheckboxListTile(value:terms,onChanged:(v)=>setState(()=>terms=v??false),title:const Text('I accept Terms of Service.'),contentPadding:EdgeInsets.zero),
CheckboxListTile(value:privacy,onChanged:(v)=>setState(()=>privacy=v??false),title:const Text('I accept Privacy Policy.'),contentPadding:EdgeInsets.zero),
if(error!=null)Text(error!,style:const TextStyle(color:Colors.orangeAccent)),FilledButton(onPressed:busy?null:finish,child:Text(busy?'Saving…':'Complete onboarding')),
const Text('Age checkbox is not jurisdiction-grade verification; stronger assurance may be required.',style:TextStyle(fontSize:12,color:Colors.white60))
]));}}
