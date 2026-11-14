import 'package:flutter/material.dart'; import 'package:supabase_flutter/supabase_flutter.dart';
class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> { bool busy=false; String? error;
 Future<void> login() async { if(!Supabase.instance.isInitialized){setState(()=>error='Supabase config missing. Set SUPABASE_URL and SUPABASE_ANON_KEY.');return;}
 setState(()=>busy=true); try { await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google,redirectTo:'com.vibemingle://login-callback/'); }
 catch(_){if(mounted)setState(()=>error='Google sign-in failed to start. Verify OAuth configuration.');} finally{if(mounted)setState(()=>busy=false);} }
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[
 const Icon(Icons.public,size:70,color:Color(0xFFA78BFA)),const SizedBox(height:18),const Text('VibeMingle',style:TextStyle(fontSize:34,fontWeight:FontWeight.w800)),const Text('Connect Beyond Borders'),
 const SizedBox(height:24),const Text('Meet people around the world. Respect, consent and safety come first.',textAlign:TextAlign.center),const SizedBox(height:24),
 FilledButton.icon(onPressed:busy?null:login,icon:const Icon(Icons.login),label:Text(busy?'Opening Google…':'Continue with Google')),
 if(error!=null)Text(error!,style:const TextStyle(color:Colors.orangeAccent)),const SizedBox(height:24),const Text('18+ only • Terms and Privacy apply.',style:TextStyle(fontSize:12,color:Colors.white60))
 ]))))); }
}