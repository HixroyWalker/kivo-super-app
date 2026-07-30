import 'dart:convert';

class TajGct03ExportService {
  /// Generate official Jamaican TAJ GCT03 Return Data Format
  static Map<String, dynamic> generateGct03Data({
    required String trn,
    required String businessName,
    required String taxPeriod, // e.g. "2026-07"
    required double totalGrossSales,
    required double totalExemptSales,
    required double totalTaxableSales,
    required double totalGctOutputTax,
    required double totalGctInputTaxPaid,
  }) {
    double netTaxPayable = totalGctOutputTax - totalGctInputTaxPaid;

    return {
      'header': {
        'taxAuthority': 'Tax Authority Jamaica (TAJ)',
        'formType': 'GCT03 Return of General Consumption Tax',
        'trn': trn,
        'taxpayerName': businessName,
        'taxPeriod': taxPeriod,
        'generatedAt': DateTime.now().toIso8601String(),
      },
      'boxes': {
        'box1_GrossSalesAndServices': totalGrossSales,
        'box2_ExemptSales': totalExemptSales,
        'box3_ZeroRatedSales': 0.0,
        'box4_TaxableSalesSubjectToStandardRate': totalTaxableSales,
        'box5_OutputTaxCollectedAt15Percent': totalGctOutputTax,
        'box10_InputTaxPaidOnPurchasesAndExpenses': totalGctInputTaxPaid,
        'box15_NetGctPayableToTaj': netTaxPayable > 0 ? netTaxPayable : 0.0,
        'box16_NetGctRefundClaimableFromTaj': netTaxPayable < 0 ? netTaxPayable.abs() : 0.0,
      }
    };
  }

  /// Format GCT03 Tax Return as a downloadable CSV String for TAJ eServices Upload
  static String exportGct03ToCsv(Map<String, dynamic> gct03Data) {
    final header = gct03Data['header'] as Map<String, dynamic>;
    final boxes = gct03Data['boxes'] as Map<String, dynamic>;

    StringBuffer csv = StringBuffer();
    csv.writeln('TAX AUTHORITY JAMAICA (TAJ) - GCT03 RETURN EXPORT');
    csv.writeln('TRN,${header['trn']}');
    csv.writeln('Taxpayer Name,${header['taxpayerName']}');
    csv.writeln('Tax Period,${header['taxPeriod']}');
    csv.writeln('Generated At,${header['generatedAt']}');
    csv.writeln('');
    csv.writeln('Box Number,Description,Amount (JMD)');
    csv.writeln('Box 1,Gross Sales & Services,${boxes['box1_GrossSalesAndServices']}');
    csv.writeln('Box 2,Exempt Sales,${boxes['box2_ExemptSales']}');
    csv.writeln('Box 3,Zero Rated Sales,${boxes['box3_ZeroRatedSales']}');
    csv.writeln('Box 4,Taxable Sales (15%),${boxes['box4_TaxableSalesSubjectToStandardRate']}');
    csv.writeln('Box 5,Output Tax (15%),${boxes['box5_OutputTaxCollectedAt15Percent']}');
    csv.writeln('Box 10,Input Tax Paid (Purchases),${boxes['box10_InputTaxPaidOnPurchasesAndExpenses']}');
    csv.writeln('Box 15,Net GCT Tax Payable to TAJ,${boxes['box15_NetGctPayableToTaj']}');
    csv.writeln('Box 16,Net GCT Refund Claimable,${boxes['box16_NetGctRefundClaimableFromTaj']}');

    return csv.toString();
  }
}
