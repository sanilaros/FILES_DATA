--שאילתות
--1
SELECT TOP 5
    P.Name AS ProductName, 
    SUM(SOD.LineTotal) AS TotalSales
FROM [dbo].[SalesOrderDetail] SOD
	INNER JOIN [dbo].[Product] AS P 
ON SOD.ProductID = P.ProductID
GROUP BY P.Name
ORDER BY TotalSales DESC


--2
SELECT
	pc.[Name] as CategoryName, AVG(SOD.UnitPrice) as AvgUnitePrice
FROM SalesOrderDetail SOD
	INNER JOIN Product p ON SOD.ProductID = p.ProductID
	INNER JOIN ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
	INNER JOIN ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.[Name] in ('Bike', 'Components')
GROUP BY pc.[Name]
ORDER BY AvgUnitePrice DESC


--3
SELECT
	P.Name AS ProductName,SUM(SOD.OrderQty) AS TotalOrderQty
FROM SalesOrderDetail SOD
	INNER JOIN Product p ON SOD.ProductID = p.ProductID
	INNER JOIN ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
	INNER JOIN ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.[Name] NOT IN ('Clothing', 'components') OR pc.Name IS NULL
GROUP BY P.[Name]
ORDER BY TotalOrderQty DESC;


--4
SELECT TOP 3 
	SOH.TerritoryID, SUM(SOH.TotalDue) AS TotalSales
FROM SalesTerritory ST
	INNER JOIN SalesOrderHeader SOH ON ST.TerritoryID = SOH.TerritoryID
GROUP BY SOH.TerritoryID
ORDER BY SUM(SOH.TotalDue) DESC


--5
SELECT CustomerID, FirstName +' '+ LastName AS "Full Name"
FROM Customer C Left Join Person p ON C.CustomerID = p.BusinessEntityID
WHERE C.CustomerID not in (Select SOH.CustomerID From SalesOrderHeader SOH)
ORDER BY CustomerID


--6
DELETE FROM SalesTerritory
WHERE TerritoryID NOT IN (Select distinct TerritoryID From SalesPerson)


--7
INSERT INTO SalesTerritory (TerritoryID, [Name], CountryRegionCode, [Group], SalesYTD, SalesLastYear,CostYTD,CostLastYear,rowguid,ModifiedDate)
SELECT TerritoryID,[Name], CountryRegionCode, [Group], SalesYTD, SalesLastYear,CostYTD,CostLastYear,rowguid,ModifiedDate
FROM SalesTerritory 
WHERE TerritoryID NOT IN (Select TerritoryID From SalesTerritory)


--בדיקה שהוחזר כנדרש בשאילתה 7
SELECT * FROM SalesTerritory
WHERE TerritoryID IN (Select TerritoryID From SalesTerritory)


--8
SELECT c.CustomerID, FirstName+' '+LastName as "Full Name",
	COUNT(SOH.SalesOrderID) AS OrderCount
FROM Customer c
	Inner Join SalesOrderHeader soh ON c.CustomerID = SOH.CustomerID
	Inner Join Person p on c.PersonID = p.BusinessEntityID
GROUP BY c.CustomerID, FirstName,LastName
HAVING COUNT(SOH.SalesOrderID) > 20


--9
SELECT GroupName,
    COUNT(DepartmentID) AS DepartmentCount
FROM Department
GROUP BY GroupName
HAVING COUNT(DepartmentID) > 2


--10
SELECT e.BusinessEntityID, FirstName+' '+LastName AS FullName, d.[Name] AS DepartmentName, s.[Name] AS ShiftName, EDH.StartDate
FROM EmployeeDepartmentHistory EDH
	Inner Join [Shift] s ON EDH.ShiftID = s.ShiftID
	Inner Join Department d ON EDH.DepartmentID = d.DepartmentID
	Inner Join Employee e ON EDH.BusinessEntityID = e.BusinessEntityID
	Inner Join Person p ON e.BusinessEntityID = p.BusinessEntityID

WHERE EDH.StartDate > '2010' 
	and d.[GroupName] in ('Quality Assurance', 'Manufacturing')
