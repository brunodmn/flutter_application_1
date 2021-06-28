import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

Future<UserCredential?> signInWithFacebook() async {
  try {
    FacebookAuthProvider facebookProvider = FacebookAuthProvider();

    facebookProvider.addScope('email');
    facebookProvider.setCustomParameters({
      'display': 'popup',
    });

    return await _auth.signInWithPopup(facebookProvider);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'account-exists-with-different-credential') {
      e.email != null && e.credential != null
          ? _handleAccountExistDiferentCredentials(e.email!, e.credential!)
          : print('invalid email/credential');
    } else {
      print('${e.message}');
    }
  } catch (e) {
    print('$e');
  }
}

Future<UserCredential?> _handleAccountExistDiferentCredentials(
    String email, AuthCredential pendingCredential) async {
  print('_handleAccountExistDiferentCredentials...');
  try {
    // Fetch a list of what sign-in methods exist for the conflicting user
    List<String> userSignInMethods =
        await _auth.fetchSignInMethodsForEmail(email);

    // If the user has several sign-in methods,
    // the first method in the list will be the "recommended" method to use.
    if (userSignInMethods.first == 'password') {
      print('userSignInMethods is email/password');
      print('pendingCredential is $pendingCredential');

      String password = '123123';//TODO change to your [email] password

      // Sign the user in to their account with the password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.linkWithCredential(pendingCredential);
      // Link the pending credential with the existing account
      return userCredential;
    }

    // // Since other providers are now external, you must now sign the user in with another
    // // auth provider, such as Facebook.
    if (userSignInMethods.first == 'facebook.com') {
      print('userSignInMethods is facebook.com');
      print('pendingCredential is $pendingCredential');
      // Create a new Facebook credential
      UserCredential? fbCred = await signInWithFacebook();
      String accessToken = await fbCred!.user!.getIdToken();
      var facebookAuthCredential = FacebookAuthProvider.credential(accessToken);

      // Sign the user in with the credential
      UserCredential userCredential =
          await _auth.signInWithCredential(facebookAuthCredential);

      // Link the pending credential with the existing account
      return await userCredential.user!.linkWithCredential(pendingCredential);
    }
    //TODO implement another methods support
  } catch (e) {
    throw Exception('$e');
  }
}

Future<void> signInWithEmailAndPassword(String email, password,
    {AuthCredential? authCredential}) async {
  try {
    print(
        'signInWithEmailAndPassword will sign in with email $email / pwd $password');
    UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: "$email", password: "$password");

    if (authCredential != null) {
      print('signInWithEmailAndPassword will try linking $authCredential');
      await userCred.user!.linkWithCredential(authCredential);
    }
  } catch (e) {
    print('$e');
  }
}

Future<void> createWithEmailAndPassword(String email, password,
    {AuthCredential? authCredential}) async {
  try {
    print(
        'createWithEmailAndPassword will sign in with email $email / pwd $password');
    UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    if (authCredential != null) {
      print('createWithEmailAndPassword will try linking $authCredential');
      await userCred.user!.linkWithCredential(authCredential);
    }
  } on FirebaseAuthException catch (e) {
    print('${e.code}');
    if (e.code == 'email-already-in-use') {
      e.email != null && e.credential != null
          ? _handleAccountExistDiferentCredentials(e.email!, e.credential!)
          : print('invalid email/credential');
    } else {
      print('${e.message}');
    }
  } catch (e) {
    print('$e');
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _passwordController = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  @override
  void initState() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in with email ${user.email}!');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(hintText: "email"),
              ),
              TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(hintText: "password")),
              SizedBox(
                height: 32,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton(
                    onPressed: signInWithFacebook,
                    child: Text('FACEBOOK SIGN UP')),
                ElevatedButton(
                    onPressed: () => createWithEmailAndPassword(
                        '${_emailController.text}',
                        '${_passwordController.text}'),
                    child: Text('EMAIL/PWD SIGN UP'))
              ]),
            ],
          ),
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _registerFacebook() {}
}
