# ETL proces datasetu Chinook

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z **Chinook** datasetu. 
Projekt sa zameriava na preskúmanie správania používateľov a ich hudobných preferencií a demografických údajov používateľov.
Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik.

## 1. Úvod a popis zdrojových dát

Cieľom semestrálneho projektu je analyzovať dáta týkajúce sa nakupovania piesní používateľmi.
Táto analýza umožňuje identifikovať trendy v preferenciách žánrov, najpopulárnejších autorov a ich piesní a správanie používateľov.

Zdrojové dáta pochádzajú z Github datasetu dostupného [tu](https://github.com/lerocha/chinook-database/tree/master). 
Dataset obsahuje desať hlavných tabuliek:

- Employee
- Customer
- Invoice
- InvoiceLine
- Playlist
- Genre
- MediaType
- Album
- Artist
- Track

Účelom ETL procesu bolo tieto dáta pripraviť, transformovať a sprístupniť pre viacdimenzionálnu analýzu.

### 1.1 Dátová architektúra

### ERD diagram

Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na **entitno-relačnom diagrame (ERD)**:

![Obrázok 1 Entitno-relačná schéma Chinnok](https://github.com/Suzie4141/Sabova_databazove_technologie/blob/main/Chinook_ERD.png)

## 2. Dimenzionálny model
