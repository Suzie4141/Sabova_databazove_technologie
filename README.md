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

Obrázok 1 Entitno-relačná schéma Chinnok
---
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

![Obrázok 2 hviezdicová schéma Chinnok](https://github.com/Suzie4141/Sabova_databazove_technologie/blob/main/star_scheme.png)

Obrázok 2 hviezdicová schéma Chinnok

---
## 3. ETL proces v Snowflake

ETL proces zahŕňal tri kľúčové fázy: `extrakciu` (Extract), `transformáciu` (Transform) a `načítanie` (Load). 
Tento proces bol implementovaný v Snowflake s cieľom spracovať zdrojové dáta zo staging vrstvy a pripraviť ich na viacdimenzionálny model, ktorý je vhodný na analýzu a vizualizáciu.

### 3.1 Extract (Extrahovanie dát)

Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do Snowflake prostredníctvom interného stage úložiska s názvom `my_stage`. Stage v Snowflake slúži ako dočasné úložisko na import alebo export dát. Vytvorenie stage bolo zabezpečené príkazom:
**Príklad kódu:**
```sql
CREATE STAGE KOALA_chinook_stage;
```
Do stage boli následne nahraté súbory obsahujúce údaje o pesničkách, používateľoch, žánroch, zamestnancoch, playlistoch, hudobníkoch. Dáta boli importované do staging tabuliek pomocou príkazu `COPY INTO`. Pre každú tabuľku sa použil podobný príkaz:
```sql
COPY INTO album
FROM @KOALA_chinook_stage
FILES = ('album.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;
```
V prípade nekonzistentných záznamov bol použitý parameter `ON_ERROR = 'CONTINUE'`, ktorý zabezpečil pokračovanie procesu bez prerušenia pri chybách.

### 3.2 Transfor (Transformácia dát)

V tejto fáze boli dáta zo staging tabuliek vyčistené, transformované a obohatené. 
Hlavným cieľom bolo pripraviť dimenzie a faktovú tabuľku, ktoré umožnia jednoduchú a efektívnu analýzu.

Dimenzie boli navrhnuté na poskytovanie kontextu pre faktovú tabuľku.
`Dim_track` obsahuje údaje o piesňach, ich autoroch, dĺžke, žánru.
Táto dimenzia je typu SCD 1, pretože tabuľka obsahuje iba aktuálny stav údajov.
```sql
CREATE TABLE dim_track AS
SELECT 
    t.TrackId,
    t.Name,
    t.Composer,
    t.Milliseconds,
    t.Bytes,
    p.Name AS Playlist,
    g.Name AS Genre,
    m.Name AS MediaType,
    al.Title AS Album,
    a.Name AS Artist
FROM Track t
INNER JOIN Album al ON t.AlbumId = al.AlbumId  
INNER JOIN Artist a ON al.ArtistId = a.ArtistId  
INNER JOIN Genre g ON t.GenreId = g.GenreId  
INNER JOIN MediaType m ON t.MediaTypeId = m.MediaTypeId 
INNER JOIN PlaylistTrack pt ON t.TrackId = pt.TrackId  
INNER JOIN Playlist p ON pt.PlaylistId = p.PlaylistId;
```

Dimenzia `dim_date` je navrhnutá tak, aby uchovávala údaje o dátumoch faktúr spolu s odvodenými informáciami, ako sú deň, mesiac, rok, deň v týždni (v textovej aj číselnej podobe) a štvrťrok. Táto dimenzia umožňuje podrobné časové analýzy, ako napríklad identifikáciu trendov podľa dní, mesiacov alebo rokov. Z pohľadu SCD je klasifikovaná ako SCD Typ 0, čo znamená, že existujúce záznamy sú nemenné a obsahujú statické informácie.

Ak by však vznikla potreba sledovať zmeny v odvodených atribútoch, napríklad v rozlíšení medzi pracovnými dňami a sviatkami, mohlo by sa zvážiť preklasifikovanie na SCD Typ 1 (aktualizácia hodnôt) alebo SCD Typ 2 (uchovávanie histórie zmien). V súčasnom modeli takáto požiadavka nie je, a preto je dim_date navrhnutá ako SCD Typ 0 s možnosťou pridávania nových záznamov podľa potreby.
```sql
CREATE TABLE dim_date AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CAST(InvoiceDate AS DATE)) AS dim_dateID,
    CAST(InvoiceDate AS DATE) AS date,
    DATE_PART(day, InvoiceDate) AS day,
    DATE_PART(dow, InvoiceDate) + 1 AS dayOfWeek,
    CASE DATE_PART(dow, InvoiceDate) + 1
        WHEN 1 THEN 'Pondelok'
        WHEN 2 THEN 'Utorok'
        WHEN 3 THEN 'Streda'
        WHEN 4 THEN 'Štvrtok'
        WHEN 5 THEN 'Piatok'
        WHEN 6 THEN 'Sobota'
        WHEN 7 THEN 'Nedeľa'
    END AS dayOfWeekAsString,
    DATE_PART(month, InvoiceDate) AS month,
    DATE_PART(year, InvoiceDate) AS year,
    DATE_PART(quarter, InvoiceDate) AS quarter
FROM Invoice;
```

Dimenzia `dim_time` je navrhnutá tak, aby uchovávala odvodené časové údaje spojené s fakturáciou, ako je konkrétny čas, časové obdobie (AM/PM) a hodina dňa. Tieto údaje sú odvodené priamo z fakturačných časových pečiatok a sú optimalizované pre časové analýzy. Typické využitie tejto dimenzie zahŕňa analýzy trendov podľa časových intervalov, ako napríklad identifikáciu špičkových hodín predaja, sledovanie výkonnosti v rôznych časových obdobiach dňa alebo porovnávanie správania zákazníkov v rôznych časových rámcoch.
Preto je dim_time tiež klasifikovaná ako SCD Typ 0. To znamená, že raz vložené údaje zostávajú nemenné a odrážajú pôvodné časové údaje zo zdrojových záznamov. Tieto údaje sú považované za statické, pretože časové informácie, ako hodina alebo časové obdobie (AM/PM), sa nemenia a nie sú ovplyvnené budúcimi aktualizáciami zdrojových systémov.

Dimenzia `dim_employee` je navrhnutá na uchovávanie informácií o zamestnancoch spoločnosti, vrátane ich osobných a pracovných údajov, ako sú meno, priezvisko, email, telefónne číslo, adresa, pracovná pozícia (titul), dátum nástupu do práce a lokalita (mesto a štát). Tieto údaje umožňujú rôzne typy analýz, ako je sledovanie výkonu zamestnancov, geografické rozloženie zamestnancov alebo analýza trendov zamestnanosti na základe nástupu nových pracovníkov. Dimenzia je klasifikovaná ako SCD Typ 1. Ak by vznikla potreba sledovať históriu zmien zamestnaneckých údajov, bolo by potrebné prehodnotiť návrh a implementovať SCD Typ 2, aby bolo možné uchovávať viacero verzií údajov pre jedného zamestnanca.
```sql
CREATE TABLE dim_employee AS
SELECT
    EmployeeId,
    FirstName,
    LastName,
    Email,
    Phone,
    Address,
    Title,
    HireDate,
    City,
    State,
    ROW_NUMBER() OVER (ORDER BY EmployeeId) AS dim_idEmployee 
FROM Employee;
```
Dimenzia `dim_customer` je tiež klasifikovná ako SCD Typ 1. Ak by však vznikla potreba sledovať históriu zmien údajov, bolo by možné návrh upraviť na SCD Typ 2.
Dimenzia je navrhnutá na uchovávanie informácií o zákazníkoch, ktoré zahŕňajú ich identifikátory a kontaktné údaje. Medzi atribúty patria meno, priezvisko, email, adresa, mesto, štát, poštové smerovacie číslo, telefónne číslo a fax. Tieto údaje sú dôležité pre analýzu správania zákazníkov, geografické segmentovanie, personalizáciu marketingových kampaní a ďalšie obchodné rozhodovania.

Faktová tabuľka `Facts_table` je navrhnutá tak, aby uchovávala podrobné transakčné údaje súvisiace s fakturáciou a predajom.
Táto tabuľka obsahuje fakty, ktoré predstavujú merateľné hodnoty (množstvo, cena), ako aj kľúče prepojujúce tieto fakty s relevantnými dimenziami.
```sql
CREATE TABLE Facts_table AS
SELECT
    IL.InvoiceLineId,
    IL.UnitPrice,
    IL.Quantity,
    I.Total
FROM InvoiceLine IL
INNER JOIN Invoice I ON IL.InvoiceId = I.InvoiceId;
```
### 3.3 Load (Načítanie dát)

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli dáta presunuté do finálnej štruktúry.
Následne boli staging tabuľky odstránené s cieľom optimalizovať využitie úložného priestoru.
```sql
DROP TABLE IF EXISTS invoice_staging;
DROP TABLE IF EXISTS invoiceline_staging;
DROP TABLE IF EXISTS track_staging;
DROP TABLE IF EXISTS playlisttrack_staging;
DROP TABLE IF EXISTS playlist_staging;
DROP TABLE IF EXISTS mediatype_staging;
DROP TABLE IF EXISTS genre_staging;
DROP TABLE IF EXISTS emplyee_staging;
DROP TABLE IF EXISTS customer_staging;
DROP TABLE IF EXISTS artist_staging;
DROP TABLE IF EXISTS album_staging;
```

ETL proces v Snowflake umožnil spracovanie pôvodných dát z formátu .csv do viacdimenzionálneho modelu typu hviezda. Tento proces zahŕňal kroky ako čistenie, obohacovanie a reorganizáciu údajov. Výsledný model poskytuje možnosť analýzy čitateľských preferencií a správania používateľov, pričom tvorí pevný základ pre vizualizácie a reporty.

---
## 4. Vizualizácia dát
Dashboard obsahuje `6 vizualizácií`, ktoré poskytujú prehľad o kľúčových metrikách a trendoch týkajúcich sa kníh, používateľov a hodnotení. Tieto vizualizácie odpovedajú na dôležité otázky a umožňujú lepšie pochopiť správanie používateľov a ich preferencie, čím poskytujú cenné informácie pre optimalizáciu ponuky a zlepšenie používateľskej skúsenosti.

![Obrázok 3 vizualizácia dát](https://github.com/Suzie4141/Sabova_databazove_technologie/blob/main/grafy.png)
Obrázok 3 vizualizácia dát

### Najpopulárnejší interpreti podľa predaja (Top 10)
Táto vizualizácia zobrazuje 10 interpretov s najväčším počtom predaných piesní. Umožňuje identifikovať najpopulárnejšie tituly medzi používateľmi. Zistíme napríklad, že kapela Deep Purple má výrazne viac  predaných piesní v porovnaní s ostatnými interpretmi. Tieto informácie môžu byť užitočné na odporúčanie piesní alebo marketingové kampane.
```sql
SELECT 
    a.Name AS Artist,
    COUNT(*) AS Total
FROM 
    Facts_table f
INNER JOIN dim_track t ON f.InvoiceLineId = t.TrackId
INNER JOIN Artist a ON t.Artist = a.Name
GROUP BY a.Name
ORDER BY Total DESC
LIMIT 10; 
```
### Predaj za posledné roky
Táto vizualizácia zobrazuje predaj v posledných rokoch.Tieto výsledky poskytujú cenné informácie o sezónnych trendoch a výkyvoch predaja. Môžu byť použité na optimalizáciu marketingových stratégií a zvýšenie tržieb počas významných dní.
```sql
SELECT 
    d.year AS Year,
    SUM(f.Total) AS TotalSales
FROM 
    Facts_table f
INNER JOIN dim_date d ON f.InvoiceLineId = d.dim_dateID
GROUP BY d.year
ORDER BY TotalSales DESC
LIMIT 5;
```
### Najpopulárnejšie žánre a počet piesní v jednotlivých žánroch
Tento graf zobrazuje porovnanie popularity hudobných žánrov z rôznych uhlov a môže poskytnúť cenné informácie pre rozhodovanie v oblasti predaja, marketingu a trendov v hudobnom priemysle. Môže ovplyvniť stratégie vydania nových skladieb alebo albumov.
```sql
SELECT 
    g.Name AS Genre,
    SUM(f.Total) AS TotalSales,
    COUNT(t.TrackId) AS NumberOfTracks
FROM 
    Facts_table f
INNER JOIN dim_track t ON f.InvoiceLineId = t.TrackId
INNER JOIN Genre g ON t.Genre = g.Name
GROUP BY g.Name
ORDER BY TotalSales DESC;
```
### Počet zákazníkov v jednotlivých krajinách
Tento graf zobrazuje počet zákazníkov v jednotlivých krajinách. Údaj o počte zákazníkov v jednotlivých krajinách ti pomôže identifikovať silné a slabé trhy, prispôsobiť marketingové a obchodné stratégie, plánovať investície, sledovať lokálne trendy, diverzifikovať riziká a personalizovať ponuky pre efektívnejší rast a lepšie rozhodovanie.
```sql
SELECT 
    Country,
    COUNT(CustomerId) AS num_customers
FROM Customer
GROUP BY Country
ORDER BY  num_customers DESC
LIMIT 10;
```
### Vzdelanie zamestancov
Graf zobrazujúci tituly zamestnancov umožňuje rýchlo identifikovať, ktoré pozície sú v organizácii najbežnejšie, čo môže pomôcť pri optimalizácii personálnych zdrojov, rozhodovaní o nábore alebo školení. Pomáha získať prehľad o rozdelení zamestnancov, čo môže byť užitočné pri strategickom plánovaní, organizovaní tímov a sledovaní trendov v priebehu času. Okrem toho poskytne cenné informácie na zlepšenie efektivity, podporu organizácie a uľahčenie interných komunikácií, keďže bude vidieť, ktoré tímy alebo osoby sú zodpovedné za konkrétne úlohy.
```sql
SELECT 
    Title, 
    COUNT(*) AS EmployeeCount
FROM 
    dim_employee
GROUP BY 
    Title
ORDER BY 
    EmployeeCount DESC;
```
### Dĺžka piesní
Graf, ktorý zobrazuje počet piesní podľa ich dĺžky, poskytuje prehľad o tom, aké dĺžky sú v organizácii najbežnejšie, čo môže byť užitočné pri analýze trendov v hudbe, optimalizácii playlistov a správe dát. Pomôže ti identifikovať, či sú niektoré dĺžky piesní dominantné, čo môže ovplyvniť výber hudby podľa preferencií poslucháčov alebo účelu playlistu. Tento graf tiež umožňuje efektívne porovnávať rôzne kategórie piesní podľa ich trvania, čo môže byť relevantné pre organizačné rozhodnutia týkajúce sa distribúcie, nahrávania alebo streamovania hudby.

```sql
SELECT 
    t.Milliseconds,
    COUNT(*) AS SongCount
FROM 
    dim_track t
GROUP BY 
    t.Milliseconds
ORDER BY 
    SongCount DESC;
```

---
**Autor:** Zuzana Sabová
