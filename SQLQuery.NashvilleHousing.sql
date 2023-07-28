--CLEANING DATA IN SQL QUERIES
SELECT * FROM tempdb.dbo.Nashville

-------------------------STANDARDIZE DATE FORMAT AND UPDATE IT IN THE DATABASE  -----------------------------------

SELECT SaleDate, CONVERT(Date,SaleDate) 
FROM tempdb.dbo.Nashville

UPDATE  tempdb.dbo.Nashville
SET SaleDate= CONVERT(Date,SaleDate)

ALTER TABLE tempdb.dbo.Nashville
ADD SaleDateConverted Date;

UPDATE  tempdb.dbo.Nashville
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted 
FROM tempdb.dbo.Nashville

----------------------------POPULATE PROPERTY ADDRESS DATA  ---------------------------------

SELECT * 
FROM tempdb.dbo.Nashville
--WHERE PropertyAddress is Null
ORDER BY ParcelID

SELECT * 
FROM tempdb.dbo.Nashville a
JOIN tempdb.dbo.Nashville b
ON a.ParcelID= b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM tempdb.dbo.Nashville a
JOIN tempdb.dbo.Nashville b
ON a.ParcelID= b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

--IN UPDATE WHEN USING JOIN I HAVE USED 'a' ALIAS INSTEAD OF tempdb.dbo.Nashville 

UPDATE a
SET PropertyAddress= ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM  tempdb.dbo.Nashville a
JOIN tempdb.dbo.Nashville b
ON a.ParcelID= b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

-----------------------BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS,CITY,STATE)   -------------------------------

SELECT PropertyAddress 
FROM tempdb.dbo.Nashville
--WHERE PropertyAddress is Null
--ORDER BY ParcelID

SELECT
SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1),LEN(PropertyAddress)) as Address,
-- CHARINDEX(',', PropertyAddress)-1   means I am getting rid of ',' in the column
FROM tempdb.dbo.Nashville

SELECT 
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
	--This query will extract the address from the "PropertyAddress" column before the first comma (,) and after the first comma, respectively. 
	--The result will have two columns with the extracted addresses.
FROM
    tempdb.dbo.Nashville;
	
	ALTER TABLE tempdb.dbo.Nashville
    ADD	PropertySplitAddress Nvarchar(255);

	UPDATE  tempdb.dbo.Nashville
    SET PropertySplitAddress=  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

    ALTER TABLE tempdb.dbo.Nashville
    ADD	PropertySplitCity Nvarchar(255);

	UPDATE  tempdb.dbo.Nashville
    SET PropertySplitCity=  SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

	----------------NOW BREAKING OWNER ADDRESS WITH ANOTHER FUNCTION PARSENAME ----------------------------
	
	SELECT OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress,',','.'),3)
	,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
	,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
	FROM tempdb.dbo.Nashville

	ALTER TABLE tempdb.dbo.Nashville
    ADD	OwnerSplitAddress Nvarchar(255);

	UPDATE  tempdb.dbo.Nashville
    SET OwnerSplitAddress=  PARSENAME(REPLACE(OwnerAddress,',','.'),3)

    ALTER TABLE tempdb.dbo.Nashville
    ADD	OwnerSplitCity Nvarchar(255);

	UPDATE  tempdb.dbo.Nashville
    SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

	 ALTER TABLE tempdb.dbo.Nashville
    ADD	OwnerSplitState Nvarchar(255);

	UPDATE  tempdb.dbo.Nashville
    SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-------------------CHANGE 'Y' AND 'N' TO 'YES' AND 'NO' IN SOLD AS VACANT COLUMN -------------------------------------

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM tempdb.dbo.Nashville
GROUP BY SoldAsVacant
ORDER By 2


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
       WHEN SoldAsVacant = 'N' THEN 'NO'
	   ELSE SoldAsVacant
	   END
FROM tempdb.dbo.Nashville

UPDATE tempdb.dbo.Nashville
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
       WHEN SoldAsVacant = 'N' THEN 'NO'
	   ELSE SoldAsVacant
	   END

-----------------------------REMOVING DUPLICATES----------------------------------------------------

-- I have created a Common Table Expression (CTE) named "CTE" that uses the ROW_NUMBER window function to assign a row number
-- to each row within groups determined by the columns ParcelId, PropertyAddress, SalePrice, SaleDate, and LegalReference,
-- and ordered by the UniqueID column in ascending order. The purpose of this CTE is to identify duplicate rows within the
-- table "Nashville" based on the specified columns.

WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelId,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) AS Row_num
    FROM tempdb.dbo.Nashville
)
DELETE FROM CTE WHERE Row_num > 1;


----------------------------------END----------------------------------------------------------------------------------

