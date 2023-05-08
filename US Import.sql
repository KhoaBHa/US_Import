SELECT *
FROM dbo.Logistics_US

--Change the data type for shipping and order dates
ALTER TABLE Logistics_US
ALTER COLUMN order_date date

ALTER TABLE Logistics_US
ALTER COLUMN shipping_date date

--Remove duplicate columns
ALTER TABLE Logistics_US
DROP COLUMN [Benefit per order]

ALTER TABLE Logistics_US
DROP COLUMN [Order Item Total]

--Remove records with incorrect customer state
DELETE FROM Logistics_US
WHERE LEN([Customer State]) != 2

SELECT round([Benefit per order], 2) as benefit_per_order, [Sales per customer], [Order Item Discount], round([Order Item Discount Rate], 4)*100 as discount_rate, 
	[Order Item Product Price], round([Order Item Profit Ratio],4)*100 as profit_ratio,
	[Order Item Quantity], Sales, [Order Item Total], [Order Profit Per Order]
FROM Logistics_US



					--CREATE VIEW FOR DATA EXPLORATION AND VISUALIZATION
--DROP VIEW IF EXISTS shipping_US --Recreate the current view with changes in columns and data
CREATE VIEW shipping_US AS
SELECT 
	Type as payment_type,
	[Days for shipping (real)],
	[Days for shipment (scheduled)],
	Day_difference_real_vs_scheduled,
	[Delivery Status],
	Late_delivery_risk,
	[Customer Segment],
	[Category Name],
	[Department Name],
	[Product Name],
	Latitude,
	Longitude,
	[Customer State],
	[Customer City],
	[Customer Zipcode],
	[Customer Street],
	[Customer Id] as customer_address,
	customer_full_name,
	[Order Region],
	[Order Country],
	[Order Customer Id],
	[Order Id],
	[Order Status],
	order_date,
	[Order Item Id],
	[Order Item Product Price] as unit_price,
	[Order Item Quantity] as quantity,
	Sales as total_sale,
	[Order Item Discount Rate] as discount_rate,
	[Order Item Discount] as discount_amount,
	[Sales per customer] as total_sales_after_discount,
	[Order Item Profit Ratio] as profit_ratio,
	[Order Profit Per Order] as profit_loss,
	shipping_date,
	[Shipping Mode]
FROM Logistics_US

--DATA EXPLORATION
SELECT *
FROM shipping_US
	
	--Total sales from each department/product
SELECT [Department Name], [Product Name], SUM(total_sale)
FROM shipping_US
GROUP BY [Department Name], [Product Name]
ORDER BY [Department Name], 3 desc

	--Highest discount rate of each department/product
SELECT [Department Name], [Product Name], MAX(round(discount_rate,2))
FROM shipping_US
GROUP BY [Department Name], [Product Name]
ORDER BY [Department Name], [Product Name]

	--Department/product that deals with the most late delivery number
SELECT [Department Name], Late_delivery_risk, COUNT(*) as number_of_late_delivery
FROM shipping_US
GROUP BY [Department Name], Late_delivery_risk
HAVING Late_delivery_risk = 1
ORDER BY 3 desc

	--Total sales/revenues created from each state
SELECT [Customer State], sum(total_sale) as total_sale_each_state
FROM shipping_US
GROUP BY [Customer State]
ORDER BY [Customer State]

	--Total sales/revenue from each export region each year
SELECT [Order Region], sum(total_sale) as total_sale_each_state
FROM shipping_US
GROUP BY [Order Region]
ORDER BY [Order Region]

	--Total profit/loss from each region each year
WITH CTE_profit_loss AS
	(SELECT [Order Region], sum(profit_loss) as total_profit_each_state --Calculate the profit/loss for each region
	FROM shipping_US
	GROUP BY [Order Region])

SELECT [Order Region], total_profit_each_state, --Label if the region is making a profit/loss
	CASE
		WHEN total_profit_each_state > 0 then 'Profitable'
		WHEN total_profit_each_state < 0 then 'Unprofitable'
		ELSE 'Breakeven'
	END as profitability
FROM CTE_profit_loss

	--Preferred shipping mode of each payment type
WITH CTE_shipping_method AS (
SELECT a.payment_type, a.[Shipping Mode], a.number_of_order,
	RANK() OVER (PARTITION BY a.payment_type ORDER BY a.number_of_order DESC) as most_preferred_shipping_method --Rank the number of order, the highest as 1
FROM 
	(SELECT payment_type, [Shipping Mode], COUNT(*) as number_of_order --Count the numbers of shipping modes for each payment type
	FROM shipping_US
	GROUP BY payment_type, [Shipping Mode]) a)

SELECT *
FROM CTE_shipping_method
WHERE most_preferred_shipping_method = 1

	--Delivery statuses of each payment type
SELECT payment_type, [Delivery Status], COUNT(*) as number_of_order
FROM shipping_US
GROUP BY payment_type, [Delivery Status]
ORDER BY payment_type

	--Which country imports the most to each state
WITH CTE_ranking_sales AS (
SELECT a.*, RANK() OVER (PARTITION BY a.[Customer State] ORDER BY a.total_sale desc) as ranking_sales --Rank the total sale by states, the highest as 1
FROM
	(SELECT [Customer State], [Order Region], [Order Country], SUM(total_sale) as total_sale --Calculate the total sale
	FROM shipping_US
	GROUP BY [Customer State], [Order Region], [Order Country]) a)

SELECT [Customer State], [Order Region], [Order Country], total_sale
FROM CTE_ranking_sales
WHERE ranking_sales = 1
	
	--Calculate the total sale by each country between '2016-08-01' and '2018-12-01'
SELECT SUM(a.total_sale), a.[Order Country]
FROM 
	(SELECT total_sale, [Order Country]
	FROM shipping_US
	WHERE order_date between '2016-08-01' and '2018-12-01') a
GROUP BY a.[Order Country]
ORDER BY 1 desc
