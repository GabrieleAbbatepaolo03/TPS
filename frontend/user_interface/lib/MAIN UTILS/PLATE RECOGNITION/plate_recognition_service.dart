class PlateCountry {
  final String countryCode;
  final String flagEmoji;
  final RegExp regex;

  PlateCountry(this.countryCode, this.flagEmoji, this.regex);
}

class PlateRecognitionService {
  final List<PlateCountry> _countries = [

    // =====================
    // 🇮🇹 Italia (I)
    // =====================
    PlateCountry('I', '🇮🇹', RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$')),

    // =====================
    // 🇩🇪 Germania (D)
    // =====================
    PlateCountry('D', '🇩🇪', RegExp(r'^[A-Z]{1,3}[A-Z]?[0-9]{1,4}$')),

    // =====================
    // 🇫🇷 Francia (F)
    // =====================
    PlateCountry('F', '🇫🇷', RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$')),

    // =====================
    // 🇪🇸 Spagna (E)
    // =====================
    PlateCountry('E', '🇪🇸', RegExp(r'^[0-9]{4}[A-Z]{3}$')),

    // =====================
    // 🇬🇧 Regno Unito (UK)
    // =====================
    PlateCountry('UK', '🇬🇧', RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{3}$')),

    // =====================
    // 🇵🇹 Portogallo (P)
    // =====================
    // Formati moderni: 00AA00, AA00AA, 00AA00
    PlateCountry('P', '🇵🇹', RegExp(r'^[0-9]{2}[A-Z]{2}[0-9]{2}$|^[A-Z]{2}[0-9]{2}[A-Z]{2}$|^[0-9]{2}[A-Z]{2}[A-Z]{2}$')),

    // =====================
    // 🇧🇪 Belgio (B)
    // =====================
    // 1-ABC-123
    PlateCountry('B', '🇧🇪', RegExp(r'^[0-9][A-Z]{3}[0-9]{3}$')),

    // =====================
    // 🇳🇱 Paesi Bassi (NL)
    // =====================
    PlateCountry('NL', '🇳🇱', RegExp(
      r'^[A-Z]{2}[0-9]{2}[A-Z]{2}$|'
      r'^[0-9]{2}[A-Z]{2}[0-9]{2}$|'
      r'^[A-Z]{2}[0-9]{2}[0-9]{2}$|'
      r'^[0-9]{2}[0-9]{2}[A-Z]{2}$'
    )),

    // =====================
    // 🇸🇪 Svezia (S)
    // =====================
    PlateCountry('S', '🇸🇪', RegExp(r'^[A-Z]{3}[0-9]{3}$')),

    // =====================
    // 🇵🇱 Polonia (PL)
    // =====================
    PlateCountry('PL', '🇵🇱', RegExp(r'^[A-Z]{2,3}[0-9A-Z]{4,5}$')),

    // =====================
    // 🇦🇹 Austria (A)
    // =====================
    PlateCountry('A', '🇦🇹', RegExp(r'^[A-Z]{1,2}[0-9]{3,5}[A-Z]$')),

    // =====================
    // 🇩🇰 Danimarca (DK)
    // =====================
    PlateCountry('DK', '🇩🇰', RegExp(r'^[A-Z]{2}[0-9]{5}$')),

    // =====================
    // 🇳🇴 Norvegia (N)
    // =====================
    PlateCountry('N', '🇳🇴', RegExp(r'^[A-Z]{2}[0-9]{5}$')),

    // =====================
    // 🇫🇮 Finlandia (FIN)
    // =====================
    PlateCountry('FIN', '🇫🇮', RegExp(r'^[A-Z]{2,3}[0-9]{3}$')),

    // =====================
    // 🇨🇭 Svizzera (CH)
    // =====================
    PlateCountry('CH', '🇨🇭', RegExp(r'^[A-Z]{2}[0-9]{1,6}$')),

    // =====================
    // 🇮🇸 Islanda (IS)
    // =====================
    PlateCountry('IS', '🇮🇸', RegExp(r'^[A-Z]{2}[0-9]{3}$')),

    // =====================
    // 🇨🇿 Repubblica Ceca (CZ)
    // =====================
    PlateCountry('CZ', '🇨🇿', RegExp(r'^[0-9]{3}[A-Z]{2}[0-9]{1,2}$')),

    // =====================
    // 🇸🇰 Slovacchia (SK)
    // =====================
    PlateCountry('SK', '🇸🇰', RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$')),

    // =====================
    // 🇭🇺 Ungheria (H)
    // =====================
    PlateCountry('H', '🇭🇺', RegExp(r'^[A-Z]{3}[0-9]{3}$')),

    // =====================
    // 🇷🇴 Romania (RO)
    // =====================
    PlateCountry('RO', '🇷🇴', RegExp(r'^[A-Z]{1,2}[0-9]{2,3}[A-Z]{3}$')),

    // =====================
    // 🇧🇬 Bulgaria (BG)
    // =====================
    PlateCountry('BG', '🇧🇬', RegExp(r'^[A-Z]{1,2}[0-9]{4}[A-Z]{2}$')),

    // =====================
    // 🇬🇷 Grecia (GR)
    // =====================
    PlateCountry('GR', '🇬🇷', RegExp(r'^[A-Z]{3}[0-9]{4}$')),

    // =====================
    // 🇭🇷 Croazia (HR)
    // =====================
    PlateCountry('HR', '🇭🇷', RegExp(r'^[A-Z]{2}[0-9]{3,4}[A-Z]{0,2}$')),

    // =====================
    // 🇷🇸 Serbia (SRB)
    // =====================
    PlateCountry('SRB', '🇷🇸', RegExp(r'^[A-Z]{2}[0-9]{3,4}[A-Z]{2}$')),

    // =====================
    // 🇸🇮 Slovenia (SLO)
    // =====================
    PlateCountry('SLO', '🇸🇮', RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{1,2}$')),

    // =====================
    // 🇲🇰 Macedonia del Nord (MK)
    // =====================
    PlateCountry('MK', '🇲🇰', RegExp(r'^[A-Z]{2}[0-9]{4}[A-Z]{2}$')),

    // =====================
    // 🇦🇱 Albania (AL)
    // =====================
    PlateCountry('AL', '🇦🇱', RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$')),

    // =====================
    // 🇽🇰 Kosovo (XK)
    // =====================
    PlateCountry('XK', '🇽🇰', RegExp(r'^[0-9]{2}[A-Z]{2}[0-9]{3}$')),
  ];


  Map<String, dynamic> recognizePlate(String input) {
    final String plate = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

    for (var country in _countries) {
      if (country.regex.hasMatch(plate)) {
        return {
          'plate': plate,
          'country': country,
        };
      }
    }

    return {
      'plate': plate,
      'country': null,
    };
  }
}
