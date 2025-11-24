import '../../MODELS/tariff_config.dart';

/// Classe di supporto per parsare le regole flessibili dal JSON raw
class FlexRule {
  final int fromHours;
  final int toHours;
  final double multiplier;

  FlexRule({
    required this.fromHours,
    required this.toHours,
    required this.multiplier,
  });

  factory FlexRule.fromMap(Map<String, dynamic> map) {
    // Gestione sicura dei tipi (int/double) che a volte arrivano come num dal JSON
    return FlexRule(
      fromHours: (map['from_hours'] as num).toInt(),
      toHours: (map['to_hours'] as num).toInt(),
      multiplier: (map['multiplier'] as num).toDouble(),
    );
  }
  
  // Helper per il manager interface (se serve riconvertire)
  factory FlexRule.fromTariffConfig(Map<String, dynamic> map) {
    return FlexRule.fromMap(map);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'from_hours': fromHours,
      'to_hours': toHours,
      'multiplier': multiplier,
    };
  }
}

class CostCalculator {
  final TariffConfig config;

  CostCalculator(this.config);

  /// Calcola il costo totale basato sulla durata in ore (es. 1.5 per 1h 30m)
  double calculateCostForHours(double durationHours) {
    if (durationHours <= 0) return 0.0;

    switch (config.type) {
      case 'FIXED_DAILY':
        return _calculateFixedDailyCost(durationHours);
      case 'HOURLY_LINEAR':
        return _calculateHourlyLinearCost(durationHours);
      case 'HOURLY_VARIABLE':
        return _calculateHourlyVariableCost(durationHours);
      default:
        // Fallback su una tariffa lineare standard se il tipo è sconosciuto
        return durationHours * config.dayBaseRate;
    }
  }

  // --- LOGICHE SPECIFICHE ---

  double _calculateFixedDailyCost(double durationHours) {
    // Logica:
    // 1. Se la durata è >= 24h, paga multipli della tariffa giornaliera.
    // 2. Se è < 24h, calcoliamo una frazione oraria basata sul costo giornaliero diviso 24.
    //    Tuttavia, non deve mai superare il costo giornaliero.
    
    double dailyRate = config.dailyRate;
    
    if (durationHours >= 24) {
      // Giorni interi + frazione
      double days = durationHours / 24;
      return days * dailyRate;
    } else {
      // Calcolo proporzionale per la singola giornata
      double hourlyProportion = dailyRate / 24.0;
      double cost = durationHours * hourlyProportion;
      // Cap al dailyRate (es. se 20€/giorno, e sto 23 ore, pago 19.xx€, mai più di 20€)
      return cost > dailyRate ? dailyRate : cost;
    }
  }

  double _calculateHourlyLinearCost(double durationHours) {
    // Logica Semplificata per Prerischio:
    // Usa la tariffa diurna base per la stima.
    // Per una precisione millimetrica (Day/Night), servirebbe l'orario di inizio esatto
    // e iterare sulle ore, ma per la selezione della durata va bene la media/base.
    return durationHours * config.dayBaseRate;
  }

  double _calculateHourlyVariableCost(double durationHours) {
    // 1. Calcola il costo base (Tariffa Base * Ore)
    double baseCost = durationHours * config.dayBaseRate;
    
    // 2. Trova il moltiplicatore applicabile in base alla DURATA TOTALE
    // (Es. "Se stai tra 4 e 8 ore, paghi il doppio della tariffa base")
    double multiplier = 1.0;
    
    if (config.flexRulesRaw.isNotEmpty) {
      for (var rawRule in config.flexRulesRaw) {
        try {
          final rule = FlexRule.fromMap(rawRule as Map<String, dynamic>);
          
          // Controlla se la durata cade in questo range (es. > 4 e <= 8)
          if (durationHours > rule.fromHours && durationHours <= rule.toHours) {
            multiplier = rule.multiplier;
            break; // Trovata la regola, esci
          }
        } catch (e) {
          print("Errore parsing regola flex: $e");
        }
      }
    }

    return baseCost * multiplier;
  }
}