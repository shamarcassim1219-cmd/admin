import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/admin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyGameAdminApp());
}

class MyGameAdminApp extends StatelessWidget {
  const MyGameAdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MYGame Admin',
    theme: ThemeData(useMaterial3: true, textTheme: GoogleFonts.poppinsTextTheme(), colorSchemeSeed: Colors.indigo),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (_, snap) => snap.data == null ? const LoginPage() : const AdminShell(),
  );
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final email=TextEditingController(), pass=TextEditingController(); bool loading=false, hide=true;
  Future<void> submit() async {
    setState(()=>loading=true);
    try { await AdminService().login(email.text, pass.text); } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ','')))); }
    if(mounted) setState(()=>loading=false);
  }
  @override Widget build(BuildContext context)=>Scaffold(body: Center(child: ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Card(margin:const EdgeInsets.all(24),child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.admin_panel_settings,size:64), const SizedBox(height:12), Text('MYGame Admin',style:Theme.of(context).textTheme.headlineMedium,textAlign:TextAlign.center), const SizedBox(height:8), const Text('Administrator sign in',textAlign:TextAlign.center), const SizedBox(height:28),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Admin email',prefixIcon:Icon(Icons.email_outlined),border:OutlineInputBorder())), const SizedBox(height:14),
    TextField(controller:pass,obscureText:hide,decoration:InputDecoration(labelText:'Password',prefixIcon:const Icon(Icons.lock_outline),border:const OutlineInputBorder(),suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility:Icons.visibility_off)))), const SizedBox(height:20),
    FilledButton(onPressed:loading?null:submit,child:Padding(padding:const EdgeInsets.all(12),child:loading?const CircularProgressIndicator():const Text('Sign in'))),
  ])))));
}

enum Section { dashboard, users, listings, orders, verification, topups, withdrawals, disputes, support, bankChanges, transactions }

class AdminShell extends StatefulWidget { const AdminShell({super.key}); @override State<AdminShell> createState()=>_AdminShellState(); }
class _AdminShellState extends State<AdminShell> {
  Section section=Section.dashboard; final service=AdminService();
  String title(Section s)=>switch(s){Section.dashboard=>'Dashboard',Section.users=>'Users',Section.listings=>'Listings',Section.orders=>'Orders',Section.verification=>'Verification Queue',Section.topups=>'Top-up Requests',Section.withdrawals=>'Withdrawal Requests',Section.disputes=>'Disputes',Section.support=>'Support Requests',Section.bankChanges=>'Bank Change Requests',Section.transactions=>'Wallet Transactions'};
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(title(section)),actions:[IconButton(onPressed:()=>service.logout(),icon:const Icon(Icons.logout))]),
    drawer:Drawer(child:SafeArea(child:ListView(children:[const Padding(padding:EdgeInsets.all(20),child:Text('MYGame ADMIN',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold))),
      ...Section.values.map((s)=>ListTile(selected:section==s,leading:Icon(_icon(s)),title:Text(title(s)),onTap:(){setState(()=>section=s);Navigator.pop(context);})),
    ]))), body:_body());
  IconData _icon(Section s)=>switch(s){Section.dashboard=>Icons.dashboard_outlined,Section.users=>Icons.people_outline,Section.listings=>Icons.storefront_outlined,Section.orders=>Icons.receipt_long_outlined,Section.verification=>Icons.verified_user_outlined,Section.topups=>Icons.add_card,Section.withdrawals=>Icons.payments_outlined,Section.disputes=>Icons.report_problem_outlined,Section.support=>Icons.support_agent,Section.bankChanges=>Icons.account_balance_outlined,Section.transactions=>Icons.account_balance_wallet_outlined};
  Widget _body()=>switch(section){Section.dashboard=>DashboardPage(service:service),Section.users=>DataPage(title:'Users',stream:service.users(),collection:'users',columns:['email','displayName','verifiedStatus','walletBalance','banned'],service:service),Section.listings=>DataPage(title:'Listings',stream:service.listings(),collection:'listings',columns:['title','game','price','status','sellerId'],service:service),Section.orders=>DataPage(title:'Orders',stream:service.orders(),collection:'orders',columns:['listingId','buyerId','sellerId','price','status','disputeRaised'],service:service),Section.verification=>VerificationPage(service:service),Section.topups=>DataPage(title:'Top-ups',stream:service.topups(),collection:'topups',columns:['userId','amount','status','slipUrl'],service:service),Section.withdrawals=>DataPage(title:'Withdrawals',stream:service.withdrawals(),collection:'withdrawals',columns:['userId','amount','status'],service:service),Section.disputes=>DataPage(title:'Disputes',stream:service.disputes(),collection:'disputes',columns:['orderId','userId','reason','status'],service:service),Section.support=>DataPage(title:'Support',stream:service.supportRequests(),collection:'support_requests',columns:['userId','subject','message','status'],service:service),Section.bankChanges=>DataPage(title:'Bank changes',stream:service.bankChanges(),collection:'bank_details_changes',columns:['userId','bankName','accountName','accountNumber','status'],service:service),Section.transactions=>DataPage(title:'Transactions',stream:service.walletTransactions(),collection:'wallet_transactions',columns:['userId','type','amount','orderId'],service:service)};
}

class DashboardPage extends StatelessWidget { final AdminService service; const DashboardPage({super.key,required this.service});
  Widget metric(String label,Stream<QuerySnapshot<Map<String,dynamic>>> stream,IconData icon)=>StreamBuilder(stream:stream,builder:(_,s)=>Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:14),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label),Text('${s.data?.docs.length??0}',style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold))])]))));
  @override Widget build(BuildContext c)=>SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Overview',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:18),GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:2.5,crossAxisSpacing:12,mainAxisSpacing:12,children:[metric('Users',service.users(),Icons.people),metric('Listings',service.listings(),Icons.store),metric('Orders',service.orders(),Icons.receipt_long),metric('Verification queue',service.verifications(),Icons.verified_user),metric('Top-ups',service.topups(),Icons.add_card),metric('Withdrawals',service.withdrawals(),Icons.payments),metric('Disputes',service.disputes(),Icons.report_problem),metric('Support',service.supportRequests(),Icons.support_agent)])]));
}

class DataPage extends StatelessWidget { final String title,collection; final Stream<QuerySnapshot<Map<String,dynamic>>> stream; final List<String> columns; final AdminService service; const DataPage({super.key,required this.title,required this.stream,required this.collection,required this.columns,required this.service});
  @override Widget build(BuildContext c)=>StreamBuilder(stream:stream,builder:(_,snap){if(snap.hasError)return Center(child:Text('Firestore error: ${snap.error}'));if(!snap.hasData)return const Center(child:CircularProgressIndicator());final docs=snap.data!.docs;return ListView.separated(padding:const EdgeInsets.all(16),itemCount:docs.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final d=docs[i].data();return Card(child:ExpansionTile(title:Text(d['title']?.toString()??d['email']?.toString()??'${collection} #${docs[i].id}'),subtitle:Text('ID: ${docs[i].id}'),children:[Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[...columns.map((k)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Text('$k: ${d[k] ?? '-'}'))),const SizedBox(height:8),if(collection=='users')Wrap(spacing:8,children:[OutlinedButton(onPressed:()=>service.setUserBanned(docs[i].id,true,reason:'Admin action'),child:const Text('Ban')),OutlinedButton(onPressed:()=>service.setUserBanned(docs[i].id,false),child:const Text('Unban'))])]))]);});});
}

class VerificationPage extends StatelessWidget { final AdminService service; const VerificationPage({super.key,required this.service});
  @override Widget build(BuildContext c)=>StreamBuilder(stream:service.verifications(),builder:(_,snap){if(!snap.hasData)return const Center(child:CircularProgressIndicator());final docs=snap.data!.docs;return ListView.builder(padding:const EdgeInsets.all(16),itemCount:docs.length,itemBuilder:(_,i){final id=docs[i].id,d=docs[i].data();return Card(child:ExpansionTile(title:Text(d['fullName']?.toString()??id),subtitle:Text('Status: ${d['status']??'pending'} | NIC: ${d['nicNumber']??'-'}'),children:[Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Address: ${d['address']??'-'}'),Text('Province: ${d['province']??'-'}'),Text('District: ${d['district']??'-'}'),Text('Document: ${d['documentType']??'-'}'),const SizedBox(height:12),Text('Front image: ${d['frontImageUrl']??'-'}'),Text('Back image: ${d['backImageUrl']??'-'}'),Text('Selfie: ${d['selfieImageUrl']??'-'}'),const SizedBox(height:16),Wrap(spacing:8,children:[FilledButton(onPressed:()=>service.approveVerification(id),child:const Text('Approve')),OutlinedButton(onPressed:()async{final reason=await _reason(c);if(reason!=null)await service.rejectVerification(id,reason);},child:const Text('Reject'))])]))]);});});
  Future<String?> _reason(BuildContext c)async{final x=TextEditingController();return showDialog<String>(context:c,builder:(_)=>AlertDialog(title:const Text('Rejection reason'),content:TextField(controller:x,maxLines:3,decoration:const InputDecoration(hintText:'Reason')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,x.text.trim().isEmpty?'Rejected by admin':x.text.trim()),child:const Text('Reject'))]));}
}
