import 'package:prmproject/pages/home.dart';
import 'package:prmproject/pages/login.dart';
import 'package:prmproject/services/database.dart';
import 'package:prmproject/services/shared_pref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}
class _SignUpState extends State<SignUp> {
  String email = "", password = "", name = "";
  TextEditingController namecontroller = new TextEditingController();
  TextEditingController passwordcontroller = new TextEditingController();
  TextEditingController mailcontroller = new TextEditingController();

  registration() async {
    if (passwordcontroller.text != "" &&
        namecontroller.text != "" &&
        mailcontroller.text != "") {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        String Id= randomAlphaNumeric(10);
        Map<String, dynamic> userInfoMap={
          "Name": namecontroller.text,
          "Email": mailcontroller.text,
          "Id": Id,
        };
        await DatabaseMethdos().addUserInfo(userInfoMap, Id);
        await SharedPreferenceHelper().saveUserId(Id);
        await SharedPreferenceHelper().saveUserName(namecontroller.text);
        await SharedPreferenceHelper().saveUserEmail(mailcontroller.text);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Registered Successfully",
              style: TextStyle(fontSize: 20.0),
            ))); // Text // SnackBar
        // ignore: use_build_context_synchronously
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Home()));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                "Password Provided is too Weak",
                style: TextStyle(fontSize: 18.0),
              ))); // Text // SnackBar
        } else if (e.code == "email-already-in-use") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text(
                "Account Already exists",
                style: TextStyle(fontSize: 18.0),
              ))); // Text // SnackBar
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(child: Stack(children: [
            Image.asset("images/signup.png", height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width, fit: BoxFit.cover),
          SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 50.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text("Create\nAccount!", style: TextStyle(color: Colors.white, fontSize: 30.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 100.0,),
                  Text("Name", style: TextStyle(color: Colors.white, fontSize: 20.0)),
                  SizedBox(height: 10.0,),
                  Container(
                    margin: EdgeInsets.only(right: 30.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: namecontroller,
                      decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.person)),
                    ), // TextField
                  ), // Container
                  SizedBox(height: 20.0,),
                  Text("Email", style: TextStyle(color: Colors.white, fontSize: 20.0)),
                  SizedBox(height: 10.0,),
                  Container(
                    margin: EdgeInsets.only(right: 30.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: mailcontroller,
                      decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.email)),
                    ), // TextField
                  ), // Container
                  SizedBox(height: 20.0,),
                  Text("Password", style: TextStyle(color: Colors.white, fontSize: 20.0)),
                  SizedBox(height: 10.0,),
                  Container(
                    margin: EdgeInsets.only(right: 30.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      obscureText: true,
                      controller: passwordcontroller,
                      decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.lock)),
                    ), // TextField
                  ), // Container
                  SizedBox(height: 40.0,),
                  Padding(
                    padding: const EdgeInsets.only(left: 40.0, right: 60.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Next", style: TextStyle(color: Colors.white, fontSize: 30.0, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: (){
                            if(mailcontroller.text!="" && namecontroller.text!="" && passwordcontroller.text!=""){
                              setState(() {
                                name= namecontroller.text;
                                email= mailcontroller.text;
                                password= passwordcontroller.text;
                              });
              
                              registration();
                            }
                          },
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(color: Color(0xff904c6e), borderRadius: BorderRadius.circular(50)),
                          ), // Container
                        ) // GestureDetector
                      ],), // Row
                  ), // Padding
                  SizedBox(height: 50.0,),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white, fontSize: 18.0),
                        ),
                        const SizedBox(width: 5.0),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Login()));
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                                color: Color(0xff904c6e),
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                  ), // Row
                      ],
                  ), // Column
              ),
            ), // Padding
        ],
        ), // Stack
        ), // Container
    ); // Scaffold
  }
}