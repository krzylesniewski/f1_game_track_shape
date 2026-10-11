# Sector / F1 Tracks

Prosta gra Flutter w odtwarzanie sektorów torów z pamięci palcem lub myszą. Interfejs jest w języku polskim. Projekt zawiera konfigurację Android, iOS i web.

## Uruchomienie

Wymagany Flutter 3.44.2 lub nowsza zgodna wersja z Dart 3.12.2.

```sh
flutter pub get
flutter run -d chrome
```

Na telefonie lub emulatorze użyj `flutter run`. Budowanie iOS wymaga macOS i Xcode.

## Zasady

1. Wybierz Monzę lub Spa-Francorchamps oraz sektor S1–S3 (domyślnie Monza S1).
2. Widzisz pozostałe dwa sektory. Narysuj brakujący fragment jednym ruchem w dowolnym miejscu planszy, bez linii pomocniczej, siatki i oznaczeń.
3. Po puszczeniu palca lub przycisku myszy zobaczysz wynik od 0 do 1000 punktów, np. `873 / 1000 pkt`.
4. Spróbuj ponownie lub przejdź do kolejnego sektora.

Ocena porównuje ślady próbkowane równomiernie wzdłuż długości. Mniejsza średnia odległość od wzorca daje więcej punktów. Nadmiarowa lub niepełna długość obniża wynik. Kierunek rysowania nie wpływa na ocenę. Rekordy każdego sektora istnieją tylko w bieżącej sesji.

Monza korzysta z krzywych ścieżki `path2241` z dostarczonego `example/Circuit_Monza.svg`. Granice sektorów wyznaczono na podstawie przejść kolorów w obrazie PNG z `example/`. Są to przybliżone lokalizacje odczytane z obrazka. Mapa zachowuje stałą skalę i orientację przy zmianie sektora. Ukryta ścieżka służy tylko do punktacji i nie jest wyświetlana po próbie.

Spa-Francorchamps korzysta z trzech ścieżek sektorów zawartych w `example/Spa-Francorchamps_of_Belgium.svg`: `path5814` (S1), `path5818` (S2), `path5820` (S3). Krzywe i granice pochodzą bezpośrednio z dostarczonego pliku. Kolejne tory wymagają własnych map.

Kolory i układ interfejsu są inspirowane `example/homePage.png`, `gamepage.png` i `leaderboard.png`: granatowe tło, błękitne akcenty, czerwone przyciski oraz ukośne elementy. Plansza pozostaje bez siatki i dodatkowych podpowiedzi.

## Struktura i sprawdzenie

- `lib/main.dart`: interfejs, obsługa gestów i rysowanie planszy.
- `lib/game/sector.dart`: modele Monzy i Spa, podział na sektory i algorytm punktacji.
- `lib/game/monza_path.dart`, `spa_path.dart`: geometria wygenerowana z SVG, zachowująca krzywe Béziera.
- `assets/tracks/`: wyodrębnione ścieżki torów bez etykiet.
- `tool/import_monza.ps1`, `import_spa.ps1`: odtwarzają ścieżki Dart i oczyszczone SVG z plików źródłowych.
- `test/`: testy punktacji i interakcji z grą.

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

Katalog `.tools/` jest ignorowany: zawiera lokalne kopie narzędzi użyte podczas przygotowania projektu w ograniczonym środowisku. Nie jest potrzebny przy standardowej instalacji Flutter.



