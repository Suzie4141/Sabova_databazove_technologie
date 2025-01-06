-- Vytvorí alebo nahradí databázu KOALA_CHINOOK_DB
CREATE OR REPLACE DATABASE KOALA_CHINOOK_DB;

-- Vytvorí stage s názvom KOALA_chinook_stage pre prácu so súbormi
CREATE STAGE KOALA_chinook_stage;

-- Vytvorí formát súboru na načítanie CSV súborov bez kompresie
CREATE OR REPLACE FILE FORMAT MYPIPEFORMAT
  TYPE = CSV
  COMPRESSION = NONE
  FIELD_DELIMITER = ','
  FILE_EXTENSION = 'csv'
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1;

-- Vytvorí tabuľku album s tromi stĺpcami
CREATE or REPLACE TABLE album (
    AlbumID INT,
    Title STRING,
    ArtistID INT
);

-- Načíta údaje z album.csv do tabuľky album
COPY INTO album
FROM @KOALA_chinook_stage
FILES = ('album.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku artist s dvoma stĺpcami
CREATE or REPLACE TABLE artist (
    ArtistID INT,
    Name STRING
);

-- Načíta údaje z artist.csv do tabuľky artist
COPY INTO artist
FROM @KOALA_chinook_stage
FILES = ('artist.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku customer s rôznymi stĺpcami pre údaje o zákazníkoch
CREATE or REPLACE TABLE customer (
    CustomerId INT,
    FirstName STRING,
    LastName STRING,
    Company STRING,
    Address STRING,
    City STRING,
    State STRING,
    Country STRING,
    PostalCode STRING,
    Phone STRING,
    Fax STRING,
    Email STRING,
    SupportRepId INT
);

-- Načíta údaje z customer.csv do tabuľky customer
COPY INTO customer
FROM @KOALA_chinook_stage
FILES = ('customer.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku employee s rôznymi stĺpcami pre údaje o zamestnancoch
CREATE or REPLACE TABLE employee (
    EmployeeId INT,
    LastName STRING,
    FirstName STRING,
    Title STRING,
    ReportsTo STRING,
    BirthDate DATE,
    HireDate DATE,
    Address STRING,
    City STRING,
    State STRING,
    Country STRING,
    PostalCode STRING,
    Phone STRING,
    Fax STRING,
    Email STRING
);

-- Načíta údaje z employee.csv do tabuľky employee
COPY INTO employee
FROM @KOALA_chinook_stage
FILES = ('employee.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku genre s dvoma stĺpcami pre žánre
CREATE or REPLACE TABLE genre (
    GenreID INT,
    Name STRING
);

-- Načíta údaje z genre.csv do tabuľky genre
COPY INTO genre
FROM @KOALA_chinook_stage
FILES = ('genre.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku invoice pre faktúry so špecifikovanými stĺpcami
CREATE or REPLACE TABLE invoice (
    InvoiceId INT,
    CustomerId INT,
    InvoiceDate DATE,
    BillingAddress STRING,
    BillingCity STRING,
    BillingState STRING,
    BillingCountry STRING,
    BillingPostalCode STRING,
    Total DECIMAL(10,2)
);

-- Načíta údaje z invoice.csv do tabuľky invoice
COPY INTO invoice
FROM @KOALA_chinook_stage
FILES = ('invoice.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku invoiceline pre detaily faktúr
CREATE or REPLACE TABLE invoiceline (
    InvoiceLineId INT,
    InvoiceId INT,
    TrackId INT,
    UnitPrice DECIMAL(10,2),
    Quantity INT
);

-- Načíta údaje z invoiceline.csv do tabuľky invoiceline
COPY INTO invoiceline
FROM @KOALA_chinook_stage
FILES = ('invoiceline.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku mediatype pre typy médií
CREATE or REPLACE TABLE mediatype (
    MediaTypeId INT,
    Name STRING
);

-- Načíta údaje z mediatype.csv do tabuľky mediatype
COPY INTO mediatype
FROM @KOALA_chinook_stage
FILES = ('mediatype.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku playlist pre playlisty
CREATE or REPLACE TABLE playlist (
    PlaylistId INT,
    Name STRING
);

-- Načíta údaje z playlist.csv do tabuľky playlist
COPY INTO playlist
FROM @KOALA_chinook_stage
FILES = ('playlist.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku playlisttrack pre spojenie playlistov a piesní
CREATE or REPLACE TABLE playlisttrack (
    PlaylistId INT,
    TrackId INT
);

-- Načíta údaje z playlisttrack.csv do tabuľky playlisttrack
COPY INTO playlisttrack
FROM @KOALA_chinook_stage
FILES = ('playlisttrack.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vytvorí tabuľku track pre piesne so špecifikovanými stĺpcami
CREATE or REPLACE TABLE track (
    TrackId INT,
    Name STRING,
    AlbumId INT,
    MediaTypeId INT,
    GenreId INT,
    Composer STRING,
    Milliseconds INT,
    Bytes INT,
    UnitPrice DECIMAL(10,2)
);

-- Načíta údaje z track.csv do tabuľky track
COPY INTO track
FROM @KOALA_chinook_stage
FILES = ('track.csv')
FILE_FORMAT = (FORMAT_NAME = MYPIPEFORMAT)
ON_ERROR = CONTINUE;

-- Vkladá špecifické záznamy do tabuľky track 
INSERT INTO track (
    TrackId,
    Name,
    AlbumId,
    MediaTypeId,
    GenreId,
    Composer,
    Milliseconds,
    Bytes,
    UnitPrice
)
VALUES (
    3412,
    '"Eine Kleine Nachtmusik" Serenade In G, K. 525: I. Allegro',
    281,
    2,
    24,
    'Wolfgang Amadeus Mozart',
    348971,
    5760129,
    0.99
);

-- Vytvorí dimenzionálnu tabuľku pre dátumy (dim_date)
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

-- Vytvorí dimenzionálnu tabuľku pre čas (dim_time)
CREATE TABLE dim_time AS
SELECT
    ROW_NUMBER() OVER (ORDER BY INVOICEDATE) AS iddim_time,
    TO_CHAR(INVOICEDATE, 'HH24:MI:SS') AS time,  
    EXTRACT(HOUR FROM CAST(INVOICEDATE AS TIMESTAMP)) AS hour, 
    CASE 
        WHEN EXTRACT(HOUR FROM CAST(INVOICEDATE AS TIMESTAMP)) < 12 THEN 'AM'
        ELSE 'PM'
    END AS period
FROM Invoice;

-- Vytvorí dimenziu pre zamestnancov (dim_employee)
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

-- Vytvorí dimenziu pre zákazníkov (dim_customer)
CREATE TABLE dim_customer AS
SELECT
    CustomerId,
    FirstName,
    LastName,
    Email,
    Address,
    City,
    State,
    PostalCode,
    Phone,
    Fax,
    ROW_NUMBER() OVER (ORDER BY CustomerId) AS dim_CustomerId
FROM Customer;

-- Vytvorí faktovú tabuľku spájajúcu detaily faktúr a sumy (Facts_table)
CREATE TABLE Facts_table AS
SELECT
    IL.InvoiceLineId,
    IL.UnitPrice,
    IL.Quantity,
    I.Total,
    CASE
        WHEN I.Total >= 0 AND I.Total < 5 THEN '0-5 EUR'
        WHEN I.Total >= 5 AND I.Total < 10 THEN '5-10 EUR'
        WHEN I.Total >= 10 AND I.Total < 15 THEN '10-15 EUR'
        WHEN I.Total >= 15 AND I.Total < 20 THEN '15-20 EUR'
        WHEN I.Total >= 20 AND I.Total < 25 THEN '20-25 EUR'
        ELSE 'Nad 25 EUR' 
    END AS Total_Category
FROM InvoiceLine IL
INNER JOIN Invoice I ON IL.InvoiceId = I.InvoiceId;


-- Vytvorí dimenziu pre piesne (dim_track) s ďalšími informáciami o piesňach
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

-- Odstráni staging tabuľky, ktoré už nie sú potrebné
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
