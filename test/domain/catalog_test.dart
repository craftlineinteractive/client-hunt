import 'package:clienthunt/domain/catalogs/city_catalog.dart';
import 'package:clienthunt/domain/catalogs/niche_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NicheCatalog', () {
    test('ships about sixty niches and six popular ones', () {
      expect(NicheCatalog.all.length, greaterThanOrEqualTo(55));
      expect(NicheCatalog.popular.length, greaterThanOrEqualTo(6));
      expect(NicheCatalog.popular.first.name, 'Dentists');
      // Canonical names are unique, or normalize could be ambiguous.
      final Set<String> names = NicheCatalog.all
          .map((Niche niche) => niche.name.toLowerCase())
          .toSet();
      expect(names.length, NicheCatalog.all.length);
    });

    test('prefix and alias matching, case-insensitive', () {
      expect(NicheCatalog.suggest('dent').first.name, 'Dentists');
      expect(NicheCatalog.suggest('DENT').first.name, 'Dentists');
      expect(NicheCatalog.suggest('dental clinic').first.name, 'Dentists');
      expect(NicheCatalog.suggest('dental c').first.name, 'Dentists');
      expect(NicheCatalog.suggest('coffee').first.name, 'Cafes');
      expect(NicheCatalog.suggest('estate').first.name, 'Real Estate Agents');
      expect(NicheCatalog.suggest('zzzz'), isEmpty);
    });

    test('ranking puts popularity before the alphabet', () {
      // Both are name-prefix matches for "s"; Salons is popular, Schools is not.
      final List<Niche> matches = NicheCatalog.suggest('s', limit: 8);
      final int salons = matches.indexWhere((Niche n) => n.name == 'Salons');
      final int schools = matches.indexWhere((Niche n) => n.name == 'Schools');
      expect(salons, isNot(-1));
      expect(schools, isNot(-1));
      expect(salons, lessThan(schools));
    });

    test('limit, empty input and extra spaces', () {
      expect(NicheCatalog.suggest('a', limit: 2).length, 2);
      expect(NicheCatalog.suggest('a', limit: 0), isEmpty);
      expect(NicheCatalog.suggest(''), isEmpty);
      expect(NicheCatalog.suggest('    '), isEmpty);
      expect(NicheCatalog.suggest('  dental   c ').first.name, 'Dentists');
    });

    test('normalize maps aliases and trims unknown input', () {
      expect(NicheCatalog.normalize('dentist'), 'Dentists');
      expect(NicheCatalog.normalize('  dental   clinic '), 'Dentists');
      expect(NicheCatalog.normalize('CA'), 'CA and Accountants');
      expect(NicheCatalog.normalize('My Niche'), 'My Niche');
      expect(NicheCatalog.normalize('  a   b  '), 'a b');
      expect(NicheCatalog.normalize(''), '');
      expect(NicheCatalog.canonicalOrNull('nothing here'), isNull);
    });
  });

  group('CityCatalog', () {
    test('ships about forty Indian cities with states', () {
      expect(CityCatalog.all.length, greaterThanOrEqualTo(40));
      final Set<String> names = CityCatalog.all
          .map((City city) => city.name.toLowerCase())
          .toSet();
      expect(names.length, CityCatalog.all.length);
      expect(
        CityCatalog.all.every((City city) => city.state.isNotEmpty),
        isTrue,
      );
    });

    test('prefix and alias matching', () {
      expect(CityCatalog.suggest('ahm').first.name, 'Ahmedabad');
      expect(CityCatalog.suggest('bomb').first.name, 'Mumbai');
      expect(CityCatalog.suggest('bang').first.name, 'Bengaluru');
      expect(CityCatalog.suggest('new del').first.name, 'Delhi');
      expect(CityCatalog.suggest('nowhere'), isEmpty);
      expect(CityCatalog.suggest('  mumb  ').first.name, 'Mumbai');
    });

    test('exact name beats a prefix of a longer name', () {
      expect(CityCatalog.suggest('pune').first.name, 'Pune');
      expect(CityCatalog.suggest('delhi').first.name, 'Delhi');
    });

    test('normalize maps aliases and collapses spaces', () {
      expect(CityCatalog.normalize('bombay'), 'Mumbai');
      expect(CityCatalog.normalize(' Bangalore '), 'Bengaluru');
      expect(CityCatalog.normalize('baroda'), 'Vadodara');
      expect(CityCatalog.normalize('Some Village'), 'Some Village');
      expect(CityCatalog.normalize('  a   b '), 'a b');
      expect(CityCatalog.normalize(''), '');
      expect(CityCatalog.canonicalOrNull('atlantis'), isNull);
    });
  });
}
