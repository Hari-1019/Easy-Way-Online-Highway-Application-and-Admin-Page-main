
import 'package:flutter/material.dart';
import 'package:firebase/screens/home/home.dart';
import 'package:firebase/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool saveCardForFuture = false;
  bool useSavedCard = false;
  String? selectedSavedCardId;
  List<Map<String, dynamic>> savedCards = [];
  
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
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
    _detailsController.text = widget.details;
    _loadSavedCards();
  }

  // Load saved cards for the current user
  Future<void> _loadSavedCards() async {
    String userId = AuthServices().userID;
    if (userId.isNotEmpty) {
      DatabaseReference savedCardsRef = _databaseReference.child('saved_cards').child(userId);
      DataSnapshot snapshot = await savedCardsRef.get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> cardsData = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> cards = [];
        
        cardsData.forEach((key, value) {
          cards.add({
            'id': key,
            'holderName': value['holder_name'],
            'maskedNumber': value['masked_number'],
            'expiryDate': value['expiry_date'],
            'cardToken': value['card_token'],
          });
        });
        
        setState(() {
          savedCards = cards;
        });
      }
    }
  }

  // Generate masked card number (e.g., **** **** **** 1234)
  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    String lastFour = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $lastFour';
  }

  // Generate a simple token for the card (in production, use proper tokenization service)
  String _generateCardToken(String cardNumber) {
    return 'token_${DateTime.now().millisecondsSinceEpoch}_${cardNumber.substring(cardNumber.length - 4)}';
  }

  // Save card details securely
  Future<void> _saveCardDetails() async {
    String userId = AuthServices().userID;
    if (userId.isNotEmpty && saveCardForFuture) {
      String cardNumber = _cardNumberController.text.replaceAll(' ', '');
      String maskedNumber = _maskCardNumber(cardNumber);
      String cardToken = _generateCardToken(cardNumber);
      
      DatabaseReference savedCardsRef = _databaseReference.child('saved_cards').child(userId).push();
      await savedCardsRef.set({
        'holder_name': _cardHolderController.text,
        'masked_number': maskedNumber,
        'expiry_date': _expiryController.text,
        'card_token': cardToken,
        'saved_date': DateTime.now().toString(),
      });
    }
  }

  // Use saved card details
  void _useSavedCard(Map<String, dynamic> card) {
    setState(() {
      useSavedCard = true;
      selectedSavedCardId = card['id'];
      _cardHolderController.text = card['holderName'];
      _cardNumberController.text = card['maskedNumber'];
      _expiryController.text = card['expiryDate'];
      _cvvController.clear(); // CVV should always be entered fresh for security
    });
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
                          
                          // Saved Cards Section
                          if (!isCashPayment && savedCards.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.credit_card, color: Colors.orange[700], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Saved Cards',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ...savedCards.map((card) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.credit_card, color: Colors.grey[600]),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                card['holderName'],
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                card['maskedNumber'],
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _useSavedCard(card),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange[700],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: const Text('Use Card', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),
                          ],
                          
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
                                      controller: _cardHolderController,
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
                                      controller: _cardNumberController,
                                      decoration: const InputDecoration(
                                        hintText: "Card Number",
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                      keyboardType: TextInputType.number,
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
                                            controller: _expiryController,
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
                                            controller: _cvvController,
                                            decoration: const InputDecoration(
                                              hintText: "CVV",
                                              hintStyle: TextStyle(color: Colors.grey),
                                              border: InputBorder.none,
                                            ),
                                            keyboardType: TextInputType.number,
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
                                  
                                  // Save Card for Future Use Checkbox
                                  if (!useSavedCard) ...[
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: saveCardForFuture,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                saveCardForFuture = value ?? false;
                                              });
                                            },
                                            activeColor: Colors.orange[700],
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  saveCardForFuture = !saveCardForFuture;
                                                });
                                              },
                                              child: Text(
                                                'Save this card for future payments',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          // Clear/New Card Button
                          if (!isCashPayment && useSavedCard) ...[
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  useSavedCard = false;
                                  selectedSavedCardId = null;
                                  _cardHolderController.clear();
                                  _cardNumberController.clear();
                                  _expiryController.clear();
                                  _cvvController.clear();
                                });
                              },
                              child: Container(
                                height: 40,
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 50),
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_card, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        "Use Different Card",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isCashPayment ? Icons.money : Icons.payment,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isCashPayment 
                                          ? "Pay with Cash" 
                                          : useSavedCard 
                                              ? "Pay with Saved Card"
                                              : "Pay Now",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
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
      // Save card details if user chose to save for future
      if (!isCashPayment && saveCardForFuture && !useSavedCard) {
        await _saveCardDetails();
      }
      
      // Save payment transaction
      final paymentRef = _databaseReference.child('payments').child(userId).push();
      await paymentRef.set({
        'payment_method': paymentMethod,
        'cost': cost,
        'payment_date': paymentDate,
        'details': details,
        'card_holder_name': !isCashPayment ? _cardHolderController.text : '',
        'card_last_four': !isCashPayment && _cardNumberController.text.length >= 4 
            ? _cardNumberController.text.replaceAll(' ', '').substring(_cardNumberController.text.replaceAll(' ', '').length - 4) 
            : '',
        'used_saved_card': useSavedCard,
        'saved_card_id': useSavedCard ? selectedSavedCardId : '',
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  saveCardForFuture 
                      ? 'Payment successful! Card saved for future use.'
                      : 'Payment successful!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Navigate back to home after a brief delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
        }
      });
    }
  }
}
