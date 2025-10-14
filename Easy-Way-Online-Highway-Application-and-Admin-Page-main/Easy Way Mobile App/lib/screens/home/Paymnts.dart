import 'package:flutter/material.dart';
import 'package:firebase/screens/home/home.dart';
import 'package:firebase/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PaymentPage extends StatefulWidget {
  final double totalCost;
  final String details; // Add this parameter
  final String description;

  const PaymentPage({super.key, required this.totalCost, required this.details, required this.description});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isCashPayment = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _validateCost(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the cost.';
    }
    double? cost = double.tryParse(value);
    if (cost == null || cost <= 0) {
      return 'Please enter a valid cost.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _costController.text = widget.totalCost.toString();
    _detailsController.text = widget.details; // Set the initial text for details
  }

  @override
  Widget build(BuildContext context) {
    _costController.text = widget.totalCost.toString();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 50),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.orange[900]!,
              Colors.orange[800]!,
              Colors.orange[400]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text("     Payment", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("          Enter Payment Details", style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          // Icons at the top of the card
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Icon(Icons.payment, color: Colors.orange[900], size: 30),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (!isCashPayment) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(255, 95, 27, 0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey[200]!),
                                      ),
                                    ),
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        hintText: "Card Holder Name",
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter card holder name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey[200]!),
                                      ),
                                    ),
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        hintText: "Card Number",
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter card number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(color: Colors.grey[200]!),
                                            ),
                                          ),
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              hintText: "Expiry Date (MM/YY)",
                                              hintStyle: TextStyle(color: Colors.grey),
                                              border: InputBorder.none,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter expiry date';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          child: TextFormField(
                                            decoration: const InputDecoration(
                                              hintText: "CVV",
                                              hintStyle: TextStyle(color: Colors.grey),
                                              border: InputBorder.none,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter CVV';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey[200]!),
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _costController,
                                            decoration: const InputDecoration(
                                              hintText: "Cost (RS)",
                                              hintStyle: TextStyle(color: Colors.grey),
                                              border: InputBorder.none,
                                            ),
                                            readOnly: true,
                                            validator: _validateCost,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey[200]!),
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _detailsController,
                                            decoration: const InputDecoration(
                                              hintText: "Details",
                                              hintStyle: TextStyle(color: Colors.grey),
                                              border: InputBorder.none,
                                            ),
                                            readOnly: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                savePaymentDetails();
                              }
                            },
                            child: Container(
                              height: 50,
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 50),
                              decoration: BoxDecoration(
                                color: Colors.orange[900],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  isCashPayment ? "Pay with Cash" : "Pay Now",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> savePaymentDetails() async {
    String paymentMethod = isCashPayment ? "Cash" : "Card";
    String paymentDate = DateTime.now().toString();
    double cost = double.tryParse(_costController.text) ?? widget.totalCost;
    String details = _detailsController.text;
    String userId = AuthServices().userID;

    if (userId.isNotEmpty) {
      final paymentRef = _databaseReference.child('payments').child(userId).push();
      await paymentRef.set({
        'payment_method': paymentMethod,
        'cost': cost,
        'payment_date': paymentDate,
        'details': details,
      });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
    }
  }
}
