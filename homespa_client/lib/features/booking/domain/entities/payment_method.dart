import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String label;

  const PaymentMethod({required this.id, required this.label});

  IconData get icon => Icons.payments_rounded;

  static const cod = PaymentMethod(id: 'cod', label: 'Cash on Delivery');

  @override
  List<Object?> get props => [id, label];
}
