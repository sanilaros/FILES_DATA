--project 2-- 
--San Laros 208414862
--Noa Ben Moshe 315035097

--question 1

with cte 
as 
(select year(orderDate) as year, count(distinct month(orderDate)) as numberOfDistinctMonth,
	sum(Quantity*UnitPrice) as incomePerYear,
	(sum(Quantity*UnitPrice))/(count(distinct month(orderDate)))*12 as linearYearIncome
from [Sales].[Invoices] as i inner join [Sales].[InvoiceLines] as il
	on i.InvoiceID = il.InvoiceID inner join [Sales].[Orders] as o
	on i.OrderID = o.OrderID
group by year(orderDate))

select *,
(linearYearIncome / lag(linearYearIncome) over (order by year)-1)*100 as growthRate
from cte

--question 2

select * 
from
	(select year,Quarter,StockItemName,income,
	DENSE_RANK() over (partition by Quarter,year order by income desc) as DR
	from
		(select year(orderDate) as year, DATEPART(QUARTER,orderDate) AS Quarter, StockItemName, 
			   sum(il.Quantity*il.UnitPrice) as income
		from [Sales].[Invoices] as i inner join [Sales].[InvoiceLines] as il
			on i.InvoiceID = il.InvoiceID inner join [Sales].[Orders] as o
			on i.OrderID = o.OrderID inner join [Warehouse].[StockItems] as SI
			on SI.StockItemID = il.StockItemID
		group by  year(orderDate), DATEPART(QUARTER,orderDate), StockItemName) as a) as b
where b.DR <=5
order by 1,2


--question 3

select Top 10
si.StockItemID, si.StockItemName, sum(il.ExtendedPrice - il.TaxAmount) AS TotalProfit
from Sales.InvoiceLines as il inner join Warehouse.StockItems as si on il.StockItemID = si.StockItemID
GROUP BY si.StockItemID,si.StockItemName
ORDER BY TotalProfit DESC

--question 4

SELECT 
    DENSE_RANK() OVER (ORDER BY (RecommendedRetailPrice - UnitPrice) DESC) AS DNR,
    ROW_NUMBER() OVER (ORDER BY (RecommendedRetailPrice - UnitPrice) DESC) AS Rank,
    StockItemID, 
    StockItemName,
    RecommendedRetailPrice, 
    UnitPrice, 
    (RecommendedRetailPrice - UnitPrice) AS NominalProfit,
	DENSE_RANK() OVER (ORDER BY (RecommendedRetailPrice - UnitPrice) DESC) AS DNR
FROM 
    Warehouse.StockItems
WHERE 
    ValidTo > GETDATE()
ORDER BY 
    NominalProfit DESC;


--question 5

SELECT 
    CONCAT(S.SupplierID, ' - ', S.SupplierName) AS SupplierDetails,
    STRING_AGG(CONCAT(SI.StockItemID, ' ', SI.StockItemName), ' / ') AS ProductDetails
FROM 
    Purchasing.Suppliers S INNER JOIN Warehouse.StockItems SI ON S.SupplierID = SI.SupplierID
GROUP BY 
    S.SupplierID, S.SupplierName
ORDER BY 
    S.SupplierID;


--question 6

SELECT TOP 5
    C.CustomerID,
    CT.CityName,
    SP.StateProvinceName,
    CN.CountryName,
    CN.Continent,
    SUM(IL.ExtendedPrice) AS TotalExtendedPrice
FROM 
    Sales.Customers C INNER JOIN Sales.Invoices I ON C.CustomerID = I.CustomerID
	INNER JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
	INNER JOIN Application.Cities CT ON C.DeliveryCityID = CT.CityID
	INNER JOIN Application.StateProvinces SP ON CT.StateProvinceID = SP.StateProvinceID
	INNER JOIN Application.Countries CN ON SP.CountryID = CN.CountryID
GROUP BY 
    C.CustomerID,
    CT.CityName,
    SP.StateProvinceName,
    CN.CountryName,
    CN.Continent
ORDER BY 
    TotalExtendedPrice DESC; 



--question 7

with cte 
as 
(select year(o.orderDate) as orderYear,month(o.orderDate) as orderMonth ,
	sum(il.ExtendedPrice - il.TaxAmount) as monthlyTotal
from sales.Orders as o inner join Sales.Invoices as i
on o.OrderID = i.OrderID inner join sales.InvoiceLines as il
on i.InvoiceID = il.InvoiceID
group by  year(o.orderDate),month(o.orderDate)) 


select orderYear , case when ordermonth is null  then 'Grand total' else cast (OrderMonth as Varchar) end as orderMonth, monthlyTotal,cumulativeTotal
from  (
select *, sum(monthlyTotal) over(partition by orderYear order by orderMonth rows between unbounded preceding and current row) as cumulativeTotal
from cte

union all 

select year(o.orderDate) as orderYear,
	null as orderMonth,
	sum(il.ExtendedPrice - il.TaxAmount) as monthlyTotal,
	sum(il.ExtendedPrice - il.TaxAmount) as yearTotal
from sales.Orders as o inner join Sales.Invoices as i
on o.OrderID = i.OrderID inner join sales.InvoiceLines as il
on i.InvoiceID = il.InvoiceID
group by  year(o.orderDate))  a
order by 1, ISNULL(orderMonth,13)



--question 8

SELECT 
    MONTH(OrderDate) AS OrderMonth,
    SUM(CASE WHEN YEAR(OrderDate) = 2013 THEN 1 ELSE 0 END) AS [2013],
    SUM(CASE WHEN YEAR(OrderDate) = 2014 THEN 1 ELSE 0 END) AS [2014],
    SUM(CASE WHEN YEAR(OrderDate) = 2015 THEN 1 ELSE 0 END) AS [2015],
    SUM(CASE WHEN YEAR(OrderDate) = 2016 THEN 1 ELSE 0 END) AS [2016]
FROM 
    Sales.Orders
GROUP BY 
    MONTH(OrderDate)
ORDER BY 
    MONTH(OrderDate);


--question 9

WITH cte AS (
    SELECT 
        o.CustomerID,
        c.CustomerName, 
        OrderDate,
        LAG(OrderDate) OVER (PARTITION BY o.CustomerID ORDER BY OrderDate) AS prevOrder,
        MAX(OrderDate) OVER (PARTITION BY o.CustomerID) AS lastOrder,
        MAX(OrderDate) OVER () AS LastAllOrder,
        DATEDIFF(day, LAG(OrderDate) OVER (PARTITION BY o.CustomerID ORDER BY OrderDate), OrderDate) AS daysSinceLastOrder,
        DATEDIFF(day, MAX(OrderDate) OVER (PARTITION BY o.CustomerID), MAX(OrderDate) OVER ()) AS diff
    FROM sales.Customers AS c 
    INNER JOIN Sales.Orders AS o ON c.CustomerID = o.CustomerID
) 
SELECT 
    CustomerID,
    CustomerName,
    OrderDate,
    prevOrder, 
    diff,
    AVG(daysSinceLastOrder) OVER (PARTITION BY CustomerID) AS avgDaysBetweenOrders,
    CASE 
        WHEN AVG(daysSinceLastOrder) OVER (PARTITION BY CustomerID) > diff THEN 'active' 
        ELSE 'potential churn' 
    END AS status
FROM cte
ORDER BY 1;


--question 10

WITH CTE_CustomerCounts AS (
    SELECT 
        CustomerCategoryName,
        COUNT(DISTINCT CustomerName) AS CustomerCount
    FROM (
        SELECT 
            CASE 
                WHEN c.CustomerName LIKE 'Wingtip%' THEN 'Wingtip'
                WHEN c.CustomerName LIKE 'Tailspin%' THEN 'Tailspin'
                ELSE c.CustomerName
            END AS CustomerName,
            cc.CustomerCategoryName
        FROM 
            sales.CustomerCategories cc
        INNER JOIN 
            Sales.Customers c ON cc.CustomerCategoryID = c.CustomerCategoryID
    ) AS a
    GROUP BY 
        CustomerCategoryName
),
CTE_TotalCustomers AS (
    SELECT 
        SUM(CustomerCount) AS TotalCustomerCount
    FROM 
        CTE_CustomerCounts
)
SELECT 
    ccc.CustomerCategoryName,
    ccc.CustomerCount,
    tc.TotalCustomerCount,
    CAST((CAST(ccc.CustomerCount AS FLOAT) / tc.TotalCustomerCount) * 100 AS DECIMAL(5, 2)) AS DistributionFactor
FROM 
    CTE_CustomerCounts ccc
CROSS JOIN 
    CTE_TotalCustomers tc
ORDER BY 
    DistributionFactor DESC;


