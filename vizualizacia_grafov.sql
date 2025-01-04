--Najpopulárnejší interpreti podľa predaja (Top 10)
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

--Predaj za posledné roky
SELECT 
    d.year AS Year,
    SUM(f.Total) AS TotalSales
FROM 
    Facts_table f
INNER JOIN dim_date d ON f.InvoiceLineId = d.dim_dateID
GROUP BY d.year
ORDER BY TotalSales DESC
LIMIT 5;

--Najpopulárnejšie žánre a počet piesní v jednotlivých žánroch
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

--Počet zákazníkov v jednotlivých krajinách
SELECT 
    Country,
    COUNT(CustomerId) AS num_customers
FROM Customer
GROUP BY Country
ORDER BY  num_customers DESC
LIMIT 10;

--Vzdelanie zamestancov
SELECT 
    Title, 
    COUNT(*) AS EmployeeCount
FROM 
    dim_employee
GROUP BY 
    Title
ORDER BY 
    EmployeeCount DESC;

--Dĺžka piesní
SELECT 
    t.Milliseconds,
    COUNT(*) AS SongCount
FROM 
    dim_track t
GROUP BY 
    t.Milliseconds
ORDER BY 
    SongCount DESC;