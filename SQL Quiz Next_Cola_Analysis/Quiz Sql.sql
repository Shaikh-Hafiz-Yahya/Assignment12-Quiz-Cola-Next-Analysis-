SELECT TOP 5 
    s.CustomerID,
    c.Name AS CustomerName,
    SUM(s.TotalAmount) AS TotalSpent
FROM SalesOrder s
JOIN Customer c ON s.CustomerID = c.CustomerID
GROUP BY s.CustomerID, c.Name
ORDER BY TotalSpent DESC;

SELECT 
    s.SupplierID,
    s.Name AS SupplierName,
    COUNT(DISTINCT pod.ProductID) AS ProductCount
FROM dbo.Supplier s
INNER JOIN dbo.PurchaseOrder po ON s.SupplierID = po.SupplierID
INNER JOIN dbo.PurchaseOrderDetail pod ON po.OrderID = pod.OrderID
GROUP BY s.SupplierID, s.Name
HAVING COUNT(DISTINCT pod.ProductID) > 10
ORDER BY ProductCount DESC;

SELECT 
    p.ProductID,
    p.Name AS ProductName,
    SUM(pod.Quantity) AS TotalOrderQuantity
FROM dbo.Product p
INNER JOIN dbo.PurchaseOrderDetail pod ON p.ProductID = pod.ProductID
LEFT JOIN dbo.ReturnDetail rd ON p.ProductID = rd.ProductID
WHERE rd.ProductID IS NULL
GROUP BY p.ProductID, p.Name
ORDER BY TotalOrderQuantity DESC;

SELECT 
    c.CategoryID,
    c.Name AS CategoryName,
    p.Name AS ProductName,
    p.Price
FROM dbo.Category c
INNER JOIN dbo.Product p ON c.CategoryID = p.CategoryID
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM dbo.Product p2
    WHERE p2.CategoryID = c.CategoryID
)
ORDER BY c.CategoryID;

SELECT 
    so.OrderID,
    cust.Name AS CustomerName,
    p.Name AS ProductName,
    cat.Name AS CategoryName,
    s.Name AS SupplierName,
    sod.Quantity
FROM dbo.SalesOrder so
INNER JOIN dbo.Customer cust ON so.CustomerID = cust.CustomerID
INNER JOIN dbo.SalesOrderDetail sod ON so.OrderID = sod.OrderID
INNER JOIN dbo.Product p ON sod.ProductID = p.ProductID
INNER JOIN dbo.Category cat ON p.CategoryID = cat.CategoryID
LEFT JOIN dbo.PurchaseOrder po ON so.OrderID = po.OrderID
LEFT JOIN dbo.Supplier s ON po.SupplierID = s.SupplierID
ORDER BY so.OrderID, sod.ProductID;

SELECT 
    sh.ShipmentID,
    l.Name AS WarehouseName,
    e.Name AS ManagerName,
    p.Name AS ProductName,
    shd.Quantity AS QuantityShipped,
    sh.TrackingNumber
FROM dbo.Shipment sh
INNER JOIN dbo.Warehouse w ON sh.WarehouseID = w.WarehouseID
INNER JOIN dbo.Location l ON w.LocationID = l.LocationID
LEFT JOIN dbo.Employee e ON w.ManagerID = e.ManagerID
INNER JOIN dbo.ShipmentDetail shd ON sh.ShipmentID = shd.ShipmentID
INNER JOIN dbo.Product p ON shd.ProductID = p.ProductID
ORDER BY sh.ShipmentID, shd.ProductID;

WITH CustomerOrders AS (
    SELECT 
        so.CustomerID,
        cust.Name AS CustomerName,
        so.OrderID,
        so.TotalAmount,
        RANK() OVER (PARTITION BY so.CustomerID ORDER BY so.TotalAmount DESC) AS OrderRank
    FROM dbo.SalesOrder so
    INNER JOIN dbo.Customer cust ON so.CustomerID = cust.CustomerID
)
SELECT 
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM CustomerOrders
WHERE OrderRank <= 3
ORDER BY CustomerID, OrderRank;

SELECT 
    p.ProductID,
    p.Name AS ProductName,
    sod.OrderID,
    so.OrderDate,
    sod.Quantity,
    LAG(sod.Quantity) OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS PrevQuantity,
    LEAD(sod.Quantity) OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS NextQuantity
FROM dbo.Product p
INNER JOIN dbo.SalesOrderDetail sod ON p.ProductID = sod.ProductID
INNER JOIN dbo.SalesOrder so ON sod.OrderID = so.OrderID
ORDER BY p.ProductID, so.OrderDate;

CREATE VIEW vw_CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(so.OrderID) AS TotalOrders,
    SUM(so.TotalAmount) AS TotalAmountSpent,
    MAX(so.OrderDate) AS LastOrderDate
FROM dbo.Customer c
LEFT JOIN dbo.SalesOrder so ON c.CustomerID = so.CustomerID
GROUP BY c.CustomerID, c.Name;

CREATE PROCEDURE sp_GetSupplierSales
    @SupplierID INT
AS
BEGIN
    SELECT 
        @SupplierID AS SupplierID,
        ISNULL(SUM(sod.UnitPrice * sod.Quantity * (1 - sod.Discount)), 0) AS TotalSalesAmount
    FROM dbo.PurchaseOrder po
    INNER JOIN dbo.Supplier s ON po.SupplierID = s.SupplierID
    INNER JOIN dbo.PurchaseOrderDetail pod ON po.OrderID = pod.OrderID
    INNER JOIN dbo.SalesOrderDetail sod ON pod.ProductID = sod.ProductID
    WHERE po.SupplierID = @SupplierID;
END;

EXEC sp_GetSupplierSales @SupplierID = 1;

