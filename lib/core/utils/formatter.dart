import 'package:intl/intl.dart';

/// Format mata uang Rupiah.
String rupiah(num value) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);

String tanggal(DateTime d) => DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d);
