import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'volume_channel.dart'; // for volume
import 'dart:async';


const String backendUrl = "https://rk-vx3e.onrender.com"; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SurakshaApp());
}

class SurakshaApp extends StatelessWidget {
  const SurakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Canara Bank Suraksha',
        theme: ThemeData(
          primaryColor: Color(0xFF003366),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF003366),
            primary: Color(0xFF003366),
            secondary: Color(0xFFFFD700),
          ),
          scaffoldBackgroundColor: Color(0xFFF5F6FA),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isLoggedIn) {
      return DashboardScreen(username: auth.username);
    } else {
      return LoginScreen();
    }
  }
}

class AuthProvider extends ChangeNotifier {
  bool isLoggedIn = false;
  String username = "";
  User? firebaseUser;
  void login(String user, User? fbUser) {
    isLoggedIn = true;
    username = user;
    firebaseUser = fbUser;
    notifyListeners();
  }
  void logout() {
    isLoggedIn = false;
    username = "";
    firebaseUser = null;
    notifyListeners();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = "";
  String password = "";
  String error = "";
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canara Bank Suraksha Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (v) => username = v,
                validator: (v) => v == null || v.isEmpty ? 'Enter username' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (v) => password = v,
                validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 16),
              if (error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() { loading = true; error = ""; });
                    try {
                      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: username + '@example.com',
                        password: password,
                      );
                      // Always create/update user doc in Firestore
                      final user = credential.user;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'username': username,
                        }, SetOptions(merge: true));
                      }
                      Provider.of<AuthProvider>(context, listen: false).login(username, credential.user);
                    } catch (e) {
                      setState(() { error = 'Invalid credentials'; });
                    }
                    setState(() { loading = false; });
                  }
                },
                child: loading ? CircularProgressIndicator() : Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
                child: Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                  );
                },
                child: Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = "";
  String password = "";
  String error = "";
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (v) => username = v,
                validator: (v) => v == null || v.isEmpty ? 'Enter username' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (v) => password = v,
                validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 16),
              if (error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() { loading = true; error = ""; });
                    try {
                      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: username + '@example.com',
                        password: password,
                      );
                      // Always create user doc in Firestore
                      final user = credential.user;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'username': username,
                        }, SetOptions(merge: true));
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      setState(() { error = 'Registration failed'; });
                    }
                    setState(() { loading = false; });
                  }
                },
                child: loading ? CircularProgressIndicator() : Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = "";
  String newPassword = "";
  String error = "";
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (v) => username = v,
                validator: (v) => v == null || v.isEmpty ? 'Enter username' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
                onChanged: (v) => newPassword = v,
                validator: (v) => v == null || v.isEmpty ? 'Enter new password' : null,
              ),
              const SizedBox(height: 16),
              if (error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() { loading = true; error = ""; });
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: username + '@example.com',
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      setState(() { error = 'Reset failed'; });
                    }
                    setState(() { loading = false; });
                  }
                },
                child: loading ? CircularProgressIndicator() : Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String username;
  const DashboardScreen({required this.username, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int consent = 0;
  bool loading = false;
  String status = "";

  // Real session data fields
  String swipeGesture = "";
  List<List<double>> gyroscopePattern = [];
  String wifiSsid = "";
  String wifiBssid = "";
  double locationLat = 0.0;
  double locationLon = 0.0;
  double screenBrightness = -1.0;
  double volume = -1.0;
  String sessionStart = "";
  String sessionEnd = "";
  String loginTime = "";
  String timestamp = "";
  List<int> typingLatencies = [];
  int? _lastKeyTime;
  StreamSubscription? _gyroSub;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    sessionStart = DateTime.now().toUtc().toIso8601String();
    loginTime = sessionStart;
    final loc = Location();
    bool serviceEnabled = await loc.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await loc.requestService();
    PermissionStatus permission = await loc.hasPermission();
    if (permission == PermissionStatus.denied) permission = await loc.requestPermission();
    if (permission == PermissionStatus.granted) {
      try {
        final info = NetworkInfo();
        wifiSsid = (await info.getWifiName()) ?? "";
        wifiBssid = (await info.getWifiBSSID()) ?? "";
        if (wifiBssid == "02:00:00:00:00:00") wifiBssid = "";
        if (wifiSsid.isEmpty || wifiSsid == "<unknown ssid>") wifiSsid = "";
      } catch (_) {}
      try {
        final locData = await loc.getLocation();
        locationLat = locData.latitude ?? 0.0;
        locationLon = locData.longitude ?? 0.0;
      } catch (_) {}
    }
    try {
      screenBrightness = await ScreenBrightness().current ?? -1.0;
    } catch (_) {}
    try {
      volume = await VolumeChannel.getMediaVolume();
    } catch (_) {}
    _gyroSub = gyroscopeEvents.listen((event) {
      gyroscopePattern.add([event.x, event.y, event.z]);
    });
    setState(() {});
  }

  void _endSession() {
    sessionEnd = DateTime.now().toUtc().toIso8601String();
    _gyroSub?.cancel();
  }

  void _onSwipe(String direction) {
    setState(() {
      swipeGesture = direction;
    });
  }

  void _onTextChanged(String value) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastKeyTime != null) {
      typingLatencies.add(now - _lastKeyTime!);
    }
    _lastKeyTime = now;
  }

  Future<void> _submitSession() async {
    setState(() { loading = true; status = ""; });
    _endSession();
    timestamp = DateTime.now().toUtc().toIso8601String();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { status = "User not logged in"; loading = false; });
      return;
    }
    final sessionData = {
      'session_start': sessionStart,
      'session_end': sessionEnd,
      'swipe_gesture': swipeGesture,
      'gyroscope_pattern': gyroscopePattern
          .map((e) => {'x': e[0], 'y': e[1], 'z': e[2]})
          .toList(),
      'wifi_ssid': wifiSsid,
      'wifi_bssid': wifiBssid,
      'location': [locationLat, locationLon],
      'login_time': loginTime,
      'screen_brightness': screenBrightness,
      'volume': volume,
      'consent': consent,
      'timestamp': timestamp,
      'typing_speed': typingLatencies.isNotEmpty
          ? typingLatencies.reduce((a, b) => a + b) / typingLatencies.length
          : null,
    };
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDoc.set({'username': widget.username}, SetOptions(merge: true));
    await userDoc.collection('sessions').add(sessionData);
    setState(() {
      status = "Session data submitted!";
      loading = false;
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color canaraBlue = Color(0xFF003366);
    final Color canaraGold = Color(0xFFFFD700);
    final accountNumber = "1234 5678 9012 3456";
    final balance = "₹ 1,23,456.78";
    final transactions = [
      {"date": "2024-06-01", "desc": "UPI Payment", "amount": "-₹500.00"},
      {"date": "2024-05-30", "desc": "Salary Credit", "amount": "+₹50,000.00"},
      {"date": "2024-05-28", "desc": "ATM Withdrawal", "amount": "-₹2,000.00"},
    ];
    final uidController = TextEditingController();
    final amountController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: canaraBlue,
        title: Text("Canara Bank Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      backgroundColor: Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Card
              Card(
                color: canaraGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Make a Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: canaraBlue)),
                      SizedBox(height: 12),
                      TextField(
                        controller: uidController,
                        decoration: InputDecoration(
                          labelText: "Enter Recipient UID",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Enter Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canaraBlue,
                            foregroundColor: canaraGold,
                          ),
                          onPressed: () {
                            final uid = uidController.text.trim();
                            final amount = amountController.text.trim();
                            if (uid.isEmpty || amount.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text("Error"),
                                  content: Text("Please enter both UID and amount."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text("Payment Successful"),
                                  content: Text("₹$amount paid to UID: $uid successfully!"),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                                ),
                              );
                              uidController.clear();
                              amountController.clear();
                            }
                          },
                          child: Text("Pay"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Consent & Data Submission Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Behavioral Data Consent & Submission", style: TextStyle(fontWeight: FontWeight.bold, color: canaraBlue)),
                      SwitchListTile(
                        title: Text('Consent to data collection'),
                        value: consent == 1,
                        onChanged: (v) => setState(() => consent = v ? 1 : 0),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canaraBlue,
                          foregroundColor: canaraGold,
                        ),
                        onPressed: loading ? null : _submitSession,
                        child: loading ? CircularProgressIndicator() : Text("Submit Session Data"),
                      ),
                      if (status.isNotEmpty) Text(status, style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text("Welcome, ${widget.username}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: canaraBlue)),
              SizedBox(height: 16),
              Card(
                color: canaraBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Account Number", style: TextStyle(color: canaraGold)),
                      Text(accountNumber, style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 8),
                      Text("Balance", style: TextStyle(color: canaraGold)),
                      Text(balance, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text("Recent Transactions", style: TextStyle(fontSize: 18, color: canaraBlue)),
              ...transactions.map((tx) => ListTile(
                leading: Icon(Icons.account_balance_wallet, color: canaraBlue),
                title: Text(tx["desc"]!),
                subtitle: Text(tx["date"]!),
                trailing: Text(tx["amount"]!, style: TextStyle(
                  color: tx["amount"]!.startsWith('-') ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                )),
              )),
              SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _dashboardButton(context, "Fund Transfer", Icons.send, canaraBlue, canaraGold),
                  _dashboardButton(context, "Mini Statement", Icons.receipt_long, canaraBlue, canaraGold),
                  _dashboardButton(context, "Card Services", Icons.credit_card, canaraBlue, canaraGold),
                  _dashboardButton(context, "Loan Application", Icons.account_balance, canaraBlue, canaraGold),
                  _dashboardButton(context, "Offers", Icons.local_offer, canaraBlue, canaraGold),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardButton(BuildContext context, String label, IconData icon, Color bg, Color fg) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(label),
            content: Text("This is a dummy $label feature."),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
          ),
        );
      },
    );
  }
}

class SessionDataScreen extends StatefulWidget {
  @override
  State<SessionDataScreen> createState() => _SessionDataScreenState();
}

class _SessionDataScreenState extends State<SessionDataScreen> {
  String swipeGesture = "";
  List<List<double>> gyroscopePattern = [];
  String wifiSsid = "";
  String wifiBssid = "";
  double locationLat = 0.0;
  double locationLon = 0.0;
  double screenBrightness = -1.0;
  double volume = -1.0;
  String sessionStart = "";
  String sessionEnd = "";
  String loginTime = "";
  String timestamp = "";
  int consent = 0;
  List<int> typingLatencies = [];
  int? _lastKeyTime;
  StreamSubscription? _gyroSub;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    sessionStart = DateTime.now().toUtc().toIso8601String();
    loginTime = sessionStart;
    final loc = Location();
    bool serviceEnabled = await loc.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await loc.requestService();
    PermissionStatus permission = await loc.hasPermission();
    if (permission == PermissionStatus.denied) permission = await loc.requestPermission();
    if (permission == PermissionStatus.granted) {
      try {
        final info = NetworkInfo();
        wifiSsid = (await info.getWifiName()) ?? "";
        wifiBssid = (await info.getWifiBSSID()) ?? "";
        if (wifiBssid == "02:00:00:00:00:00") wifiBssid = "";
        if (wifiSsid.isEmpty || wifiSsid == "<unknown ssid>") wifiSsid = "";
      } catch (_) {}
      try {
        final locData = await loc.getLocation();
        locationLat = locData.latitude ?? 0.0;
        locationLon = locData.longitude ?? 0.0;
      } catch (_) {}
    }
    try {
      screenBrightness = await ScreenBrightness().current ?? -1.0;
    } catch (_) {}
    try {
      volume = await VolumeChannel.getMediaVolume();
    } catch (_) {}
    _gyroSub = gyroscopeEvents.listen((event) {
      gyroscopePattern.add([event.x, event.y, event.z]);
    });
    setState(() {});
  }

  void _endSession() {
    sessionEnd = DateTime.now().toUtc().toIso8601String();
    _gyroSub?.cancel();
  }

  void _onSwipe(String direction) {
    setState(() {
      swipeGesture = direction;
    });
  }

  void _onTextChanged(String value) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastKeyTime != null) {
      typingLatencies.add(now - _lastKeyTime!);
    }
    _lastKeyTime = now;
  }

  Future<void> _submitSession() async {
    _endSession();
    timestamp = DateTime.now().toUtc().toIso8601String();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.firebaseUser;
    if (user == null) return;
    final sessionData = {
      'session_start': sessionStart,
      'session_end': sessionEnd,
      'swipe_gesture': swipeGesture,
      'gyroscope_pattern': gyroscopePattern
          .map((e) => {'x': e[0], 'y': e[1], 'z': e[2]})
          .toList(),
      'wifi_ssid': wifiSsid,
      'wifi_bssid': wifiBssid,
      'location': [locationLat, locationLon],
      'login_time': loginTime,
      'screen_brightness': screenBrightness,
      'volume': volume,
      'consent': consent,
      'timestamp': timestamp,
      'typing_speed': typingLatencies.isNotEmpty
          ? typingLatencies.reduce((a, b) => a + b) / typingLatencies.length
          : null,
    };
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDoc.set({'username': authProvider.username}, SetOptions(merge: true));
    await userDoc.collection('sessions').add(sessionData);
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          _onSwipe(details.primaryVelocity! > 0 ? "right" : "left");
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          _onSwipe(details.primaryVelocity! > 0 ? "down" : "up");
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            SwitchListTile(
              title: Text('Consent to data collection'),
              value: consent == 1,
              onChanged: (v) => setState(() => consent = v ? 1 : 0),
            ),
            TextField(
              onChanged: _onTextChanged,
              decoration: InputDecoration(labelText: 'Type here to measure typing speed'),
            ),
            ElevatedButton(
              onPressed: _submitSession,
              child: Text('Submit Session Data'),
            ),
          ],
        ),
      ),
    );
  }
}
