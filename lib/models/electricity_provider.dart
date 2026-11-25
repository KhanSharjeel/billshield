class ElectricityProvider {
  final String code;
  final String fullName;
  final String coverageArea;

  const ElectricityProvider({
    required this.code,
    required this.fullName,
    required this.coverageArea,
  });

  static const List<ElectricityProvider> allProviders = [
    ElectricityProvider(
      code: 'IESCO',
      fullName: 'Islamabad Electric Supply Company',
      coverageArea: 'Islamabad, Rawalpindi, Attock, Jhelum, Chakwal',
    ),
    ElectricityProvider(
      code: 'LESCO',
      fullName: 'Lahore Electric Supply Company',
      coverageArea: 'Lahore, Kasur, Okara, Sheikhupura, Nankana Sahib',
    ),
    ElectricityProvider(
      code: 'MEPCO',
      fullName: 'Multan Electric Power Company',
      coverageArea: 'Multan, Sahiwal, Rahim Yar Khan, Bahawalpur, D.G. Khan',
    ),
    ElectricityProvider(
      code: 'FESCO',
      fullName: 'Faisalabad Electric Supply Company',
      coverageArea: 'Faisalabad, Sargodha, Jhang, Toba Tek Singh, Mianwali',
    ),
    ElectricityProvider(
      code: 'GEPCO',
      fullName: 'Gujranwala Electric Power Company',
      coverageArea: 'Gujranwala, Sialkot, Gujrat, Narowal, Hafizabad',
    ),
    ElectricityProvider(
      code: 'PESCO',
      fullName: 'Peshawar Electric Supply Company',
      coverageArea: 'Peshawar, Mardan, Swat, Abbottabad, Charsadda',
    ),
    ElectricityProvider(
      code: 'HESCO',
      fullName: 'Hyderabad Electric Supply Company',
      coverageArea: 'Hyderabad, Jamshoro, Thatta, Badin, Mirpurkhas',
    ),
    ElectricityProvider(
      code: 'SEPCO',
      fullName: 'Sukkur Electric Power Company',
      coverageArea: 'Sukkur, Larkana, Khairpur, Jacobabad, Ghotki',
    ),
    ElectricityProvider(
      code: 'K-Electric',
      fullName: 'K-Electric (KE Karachi)',
      coverageArea: 'Karachi Metropolitan & Surrounding Industrial Belts',
    ),
    ElectricityProvider(
      code: 'QESCO',
      fullName: 'Quetta Electric Supply Company',
      coverageArea: 'Quetta, Gwadar, Khuzdar, Sibi, Zhob, Turbat',
    ),
  ];

  static List<String> get providerCodes =>
      allProviders.map((p) => p.code).toList();

  static ElectricityProvider findByCode(String code) {
    return allProviders.firstWhere(
      (p) => p.code == code,
      orElse: () => allProviders.first,
    );
  }
}
