import 'package:flutter/material.dart';
import 'package:prmproject/services/support_widget.dart';
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8edc2), // Thêm 'const' để tối ưu hiệu suất
      body: Container(child: Column(children: [SizedBox(height: 120.0),// dự tính thêm const ở trc sizebox
            Image.asset("images/onboard.png"),
            SizedBox(height: 50.0),
            Expanded(
              child: Container(
                margin:EdgeInsets.only(left: 10.0, right: 10.0, bottom:20.0),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(60)),
                width: MediaQuery.of(context).size.width,
                child: Column(children: [
                    SizedBox(height: 30.0),
                    Text("Manage your daily\n life expenses", textAlign: TextAlign.center, style: AppWidget.healineTextStyle(30.0)),
                    SizedBox(height: 20.0,),
                    Padding(
                      padding: EdgeInsets.only(left: 30.0, right: 30.0),
                      child: Text("Expense Tracker is a simple and efficient personal finance management app that allows you to track your daily expenses and income.", textAlign: TextAlign.center ,style:TextStyle(color: Color.fromARGB(160,0,0,0), fontWeight: FontWeight.w500,fontSize:15.0) ),
                    ),
                  SizedBox(height: 40.0,),
                  Container(
                    margin: EdgeInsets.only(left: 40.0, right: 40.0),
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        height:70,
                        decoration: BoxDecoration(color: Color(0xffee6856), borderRadius: BorderRadius.circular(60)),
                        width: MediaQuery.of(context).size.width,
                        child: Center(child: Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  )
                  ],),
              ),
            ),
          ],
        ),
      ),
    );
  }
}