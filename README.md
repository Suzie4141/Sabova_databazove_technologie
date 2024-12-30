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

               *Obrázok 1 Entitno-relačná schéma Chinnok* 

## 2. Dimenzionálny model

Navrhnutý bol **hviezdicový model (star schema)**, pre efektívnu analýzu kde centrálny bod predstavuje faktová tabuľka `Facts_table` ,ktorá pozostáva z údajov tabuľky InvoiceLine.
`Facts_table` je prepojená s nasledujúcimi dimenziami:
- `dim_customer` : Obsahuje demografické údaje o zákazníkoch napr. adresa.
- `dim_track` : Obsahuje podrobné údaje o piesňach napr. autor, žáner, album v ktorom sa daná pieseň nachádza.
- `dim_employee` : Obsahuje informácie o zamestnancoch ako napr. nastupný dátum, titul, adresu.
- `dim_time` : Obsahuje podrobné časové údaje (hodina, AM/PM).
- `dim_date` : Zahrňuje informácie o dátumoch hodnotení (deň, mesiac, rok, štvrťrok).

Štruktúra hviezdicového modelu je znázornená na diagrame nižšie. 
Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami, čo zjednodušuje pochopenie a implementáciu modelu.

![Obrázok 2 hviezdicová schéma Chinnok](https://github.com/Suzie4141/Sabova_databazove_technologie/blob/main/star__scheme.png)

             *Obrázok 2 hviezdicová schéma Chinnok* 

## 3. ETL proces v Snowflake

ETL proces zahŕňal tri kľúčové fázy: `extrakciu` (Extract), `transformáciu` (Transform) a `načítanie` (Load). 
Tento proces bol implementovaný v Snowflake s cieľom spracovať zdrojové dáta zo staging vrstvy a pripraviť ich na viacdimenzionálny model, ktorý je vhodný na analýzu a vizualizáciu.

### 3.1 Extract (Extrahovanie dát)

Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do Snowflake prostredníctvom interného stage úložiska s názvom `my_stage`. Stage v Snowflake slúži ako dočasné úložisko na import alebo export dát. Vytvorenie stage bolo zabezpečené príkazom:
**Príklad kódu:**
```sql
CREATE OR REPLACE STAGE my_stage;
```
