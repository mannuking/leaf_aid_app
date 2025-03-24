import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlantStatsProvider extends ChangeNotifier {
  int _totalPlants = 0;
  int _healthyPlants = 0;
  int _diseasedPlants = 0;
  SharedPreferences? _prefs;

  PlantStatsProvider() {
    _loadStats();
  }

  int get totalPlants => _totalPlants;
  int get healthyPlants => _healthyPlants;
  int get diseasedPlants => _diseasedPlants;

  Future<void> _loadStats() async {
    _prefs = await SharedPreferences.getInstance();
    _totalPlants = _prefs?.getInt('total_plants') ?? 0;
    _healthyPlants = _prefs?.getInt('healthy_plants') ?? 0;
    _diseasedPlants = _prefs?.getInt('diseased_plants') ?? 0;
    notifyListeners();
  }

  Future<void> updateStats({required bool isHealthy}) async {
    _totalPlants++;
    if (isHealthy) {
      _healthyPlants++;
    } else {
      _diseasedPlants++;
    }

    await _saveStats();
    notifyListeners();
  }

  Future<void> _saveStats() async {
    await _prefs?.setInt('total_plants', _totalPlants);
    await _prefs?.setInt('healthy_plants', _healthyPlants);
    await _prefs?.setInt('diseased_plants', _diseasedPlants);
  }

  Future<void> resetStats() async {
    _totalPlants = 0;
    _healthyPlants = 0;
    _diseasedPlants = 0;
    await _saveStats();
    notifyListeners();
  }
} 
