/*CHINOOK DATASET EXPLORATORY DATA ANALYSIS USING SQL*/

-- 1. Top 5 customers by total invoice amount
SELECT CustomerId, SUM(Total) AS TotalSpent
FROM Invoice
GROUP BY CustomerId
ORDER BY TotalSpent DESC
LIMIT 5;

-- 2. Number of tracks in each genre
SELECT g.Name AS Genre, COUNT(t.TrackId) AS TrackCount
FROM Genre g
JOIN Track t ON g.GenreId = t.GenreId
GROUP BY g.Name;

-- 3. Total sales for each country
SELECT BillingCountry, SUM(Total) AS TotalSales
FROM Invoice
GROUP BY BillingCountry;


-- 4. Total number of tracks sold for each media type
SELECT m.Name AS MediaType, SUM(il.Quantity) AS TracksSold
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN MediaType m ON t.MediaTypeId = m.MediaTypeId
GROUP BY m.Name;

-- 5. Top 3 playlists by number of tracks
SELECT pt.PlaylistId, COUNT(pt.TrackId) AS TrackCount
FROM PlaylistTrack pt
GROUP BY pt.PlaylistId
ORDER BY TrackCount DESC
LIMIT 3;

-- 6. Albums with artist names
SELECT al.Title AS Album, ar.Name AS Artist
FROM Album al
JOIN Artist ar ON al.ArtistId = ar.ArtistId;

-- 7. Average unit price per genre
SELECT g.Name AS Genre, AVG(t.UnitPrice) AS AvgPrice
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.Name;

-- 8. Revenue per employee's customers
SELECT concat(e.FirstName,' ',e.LastName) AS Employee, SUM(i.Total) AS Revenue
FROM Employee e
JOIN Customer c ON e.EmployeeId = c.SupportRepId
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY e.EmployeeId;

-- 9. Top 5 selling tracks with artist and genre
SELECT t.Name AS Track, ar.Name AS Artist, g.Name AS Genre, SUM(il.Quantity) AS UnitsSold
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY t.TrackId
ORDER BY UnitsSold DESC
LIMIT 5;

-- 10. Customers who spent more than average
SELECT concat(c.FirstName,' ',c.LastName) AS Customer, SUM(i.Total) AS TotalSpent
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
HAVING SUM(i.Total) > (SELECT AVG(Total) FROM Invoice);

-- 11. Customers who bought most tracks in a single invoice
SELECT concat(c.FirstName,' ',c.LastName) AS Customer, i.InvoiceId, SUM(il.Quantity) AS TracksBought
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
GROUP BY i.InvoiceId
ORDER BY TracksBought DESC
LIMIT 1;

-- 12. Rank genres by total sales amount
SELECT g.Name AS Genre, SUM(il.UnitPrice * il.Quantity) AS TotalSales,
       DENSE_RANK() OVER (ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS GenreRank
FROM Genre g
JOIN Track t ON g.GenreId = t.GenreId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY g.Name;

-- 13. Employees without managers
SELECT concat(FirstName,' ',LastName) AS Employee
FROM Employee
WHERE ReportsTo IS NULL;

-- 14. Playlists with >5 genres
SELECT p.Name AS Playlist, COUNT(DISTINCT t.GenreId) AS GenreCount
FROM Playlist p
JOIN PlaylistTrack pt ON p.PlaylistId = pt.PlaylistId
JOIN Track t ON pt.TrackId = t.TrackId
GROUP BY p.PlaylistId
HAVING COUNT(DISTINCT t.GenreId) > 5;

-- 15. Monthly revenue trend
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month,
       SUM(Total) AS MonthlyRevenue
FROM Invoice
GROUP BY Month
ORDER BY Month;

-- 16. Find the customer who has spent the most overall.
SELECT FirstName, LastName, TotalSpent
FROM (
    SELECT c.FirstName, c.LastName, SUM(i.Total) AS TotalSpent
    FROM Customer c
    JOIN Invoice i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId
) AS CustomerTotals
ORDER BY TotalSpent DESC
LIMIT 1;

-- 17. List customers whose total invoice amount is above the average total invoice amount.
SELECT CustomerId, SUM(Total) AS TotalSpent
FROM Invoice
GROUP BY CustomerId
HAVING SUM(Total) > (
    SELECT AVG(TotalAmount)
    FROM (
        SELECT SUM(Total) AS TotalAmount
        FROM Invoice
        GROUP BY CustomerId
    ) AS CustomerInvoiceTotals
);

-- 18.Find albums that have more than 10 tracks.
SELECT Title
FROM Album
WHERE AlbumId IN (
    SELECT AlbumId
    FROM Track
    GROUP BY AlbumId
    HAVING COUNT(*) > 10
);

-- 19.Find the employee(s) managing the highest number of customers.
SELECT EmployeeId, NumberOfCustomers
FROM (
    SELECT SupportRepId AS EmployeeId, COUNT(CustomerId) AS NumberOfCustomers
    FROM Customer
    GROUP BY SupportRepId
) AS EmployeeCustomerCounts
ORDER BY NumberOfCustomers DESC
LIMIT 1;

-- 20. Trigger to update Album revenue after a new InvoiceLine is inserted

ALTER TABLE Album
ADD Revenue DECIMAL(10, 2) DEFAULT 0;

DELIMITER //
CREATE TRIGGER UpdateAlbumRevenueOnInsert
AFTER INSERT ON InvoiceLine
FOR EACH ROW
BEGIN
    -- Calculate the revenue for the newly inserted invoice line
    DECLARE trackRevenue DECIMAL(10, 2);
    DECLARE albumId INT;
    SELECT NEW.UnitPrice * NEW.Quantity INTO trackRevenue;

    -- Get the AlbumId of the track in the inserted invoice line
    SELECT AlbumId INTO albumId FROM Track WHERE TrackId = NEW.TrackId;

    -- Update the Album table by adding the new revenue
    UPDATE Album
    SET Revenue = COALESCE(Revenue, 0) + trackRevenue
    WHERE AlbumId = albumId;
END //
DELIMITER ;

INSERT INTO InvoiceLine(InvoiceLineId, InvoiceId, TrackId, UnitPrice, Quantity) values(10000,24,738,1.99,2);

