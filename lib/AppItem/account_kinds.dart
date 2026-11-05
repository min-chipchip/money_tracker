import 'package:flutter/material.dart';

/// Display name and icon for each value allowed in `accounts.kind`
/// (the CHECK constraint in schema.drift lists the same five).
const Map<String, ({String label, IconData icon})> accountKinds = {
  'cash': (label: 'Cash', icon: Icons.payments),
  'bank': (label: 'Bank', icon: Icons.account_balance),
  'credit_card': (label: 'Credit card', icon: Icons.credit_card),
  'e_wallet': (label: 'E-wallet', icon: Icons.phone_iphone),
  'other': (label: 'Other', icon: Icons.account_balance_wallet),
};
