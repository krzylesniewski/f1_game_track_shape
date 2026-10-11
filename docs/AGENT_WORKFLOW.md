# Orkiestrator i agenci projektu

## Proponowany model pracy

Główny wątek Codex pełni rolę orkiestratora: rozumie wymagania, dzieli zadanie,
przydziela pliki, zbiera wyniki i sprawdza całość. Uruchamia tylko specjalistów
potrzebnych do konkretnego zadania. Małe poprawki wykonuje sam.

To propozycja organizacji pracy; ten dokument nie uruchamia ani nie konfiguruje agentów.

## Role

| Rola | Zadania | Zakres zmian |
| --- | --- | --- |
| Flutter UI | Interfejs, gesty, skalowanie planszy | Widoki i widgety |
| Geometria torów | Import SVG, krzywe, podział na sektory, wspólny układ współrzędnych | Modele torów, parser i zasoby |
| Punktacja | Porównanie śladów, rozbieżność i kompletność rysunku | Algorytm oceny |
| QA / reviewer | Testy zachowania, regresje, kontrola zgodności z zasadami gry | Testy; uwagi do kodu |

## Zasady delegowania

1. Orkiestrator zapisuje cel, kryteria ukończenia i zależności.
2. Każdy specjalista otrzymuje listę plików, które może zmienić, oraz oczekiwany wynik.
3. Równoległe zadania mają rozłączne pliki. Zmiany wspólnego interfejsu wymagają
   wcześniejszego ustalenia kontraktu. Przy większych zmianach używaj osobnych
   gałęzi i Git worktrees.
4. Specjalista zwraca opis zmian, wykonane sprawdzenia i pozostałe problemy.
5. Orkiestrator integruje wyniki, uruchamia odpowiednie testy i analizę,
   a następnie zapisuje spójny commit. Publikacja na GitHub wymaga polecenia użytkownika.

W tej sesji dostępne są cztery miejsca: orkiestrator i maksymalnie trzech
specjalistów równocześnie. Reviewer może pracować po zakończeniu implementacji.

## Kryteria gry

- Widoczna reszta toru, ukryty wybrany sektor.
- Brak wzorca ukrytego sektora, siatki, strzałek i dodatkowych oznaczeń punktów.
- Gracz odtwarza trasę z pamięci.
- Mniejsza rozbieżność oznacza więcej punktów; odwrócony kierunek nie obniża oceny.
- Krótki fragment lub chaotyczny ślad nie powinien otrzymywać wysokiego wyniku.

## Jak rozpocząć

Przykładowe polecenie do głównego wątku:

> Działaj jako orkiestrator. Deleguj import SVG agentowi geometrii, a analizę
> punktacji drugiemu agentowi. Przydziel rozłączne pliki. Po integracji zleć
> reviewerowi kontrolę zasad gry i testów. Zbierz wyniki i sprawdź całość.

Codex obsługuje subagentów wywoływanych poleceniem oraz własne role w plikach
`.codex/agents/*.toml`. Każda definicja zawiera `name`, `description` i
`developer_instructions`. Obsługa zależy od używanego klienta i wersji;
przed konfiguracją sprawdź [oficjalną dokumentację subagentów](https://learn.chatgpt.com/docs/agent-configuration/subagents).

Na początek rekomenduję delegowanie w bieżącym wątku. Osobny program
orkiestrujący przez API warto rozważyć dopiero dla automatycznych zadań poza rozmową.
