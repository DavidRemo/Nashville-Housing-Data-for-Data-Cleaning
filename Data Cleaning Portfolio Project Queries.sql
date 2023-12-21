/*
Cleaning Data in SQL Queries
*/

USE portfolioproject_2;

SELECT * FROM nashvillehousing;


-- ------------------------------------------------------------------------------------------------------------------------


-- Standardize Date Format

-- This is done by first, adding a new column to hold the dates in a valid date format:
ALTER TABLE nashvilleHousing
ADD COLUMN SaleDateConverted DATE;

-- Next, update the newly added column NewSaleDate by converting the existing date strings to a proper date format using STR_TO_DATE()
SET SQL_SAFE_UPDATES = 0; -- Disabling Safe Update mode for the session. This allows the execution of UPDATE/DELETE statements without column restrictions.
UPDATE nashvillehousing
SET SaleDateConverted = STR_TO_DATE(saleDate, '%M %e, %Y'); -- This will convert the 'April 9, 2013'-formatted strings in the saleDate column to the DATE data type in the NewSaleDate column.

/*
Step 3: After verifying that the NewSaleDate column has the correct date values, you can either keep both columns if needed, or drop the old column and rename the new one:

-- Drop the old column

ALTER TABLE nashvillehousing
DROP COLUMN saleDate;

-- Rename the new column to match the original column name

ALTER TABLE nashvillehousing
CHANGE COLUMN NewSaleDate saleDate DATE;
*/


-- ------------------------------------------------------------------------------------------------------------------------


-- Populate Property Address data

SELECT * FROM nashvillehousing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

/*
The query below will select the ParcelID and PropertyAddress columns from tables a and b where the PropertyAddress in table a is NULL.
The IFNULL() function will return a.PropertyAddress if it's not null, otherwise, it will return b.PropertyAddress. 
*/
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress) AS MergedAddress
FROM nashvillehousing a
JOIN nashvillehousing b ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

/*
The query below updates the PropertyAddress in the nashvillehousing table where PropertyAddress is NULL in table a. 
It uses IFNULL() to set a.PropertyAddress to b.PropertyAddress when a.PropertyAddress is NULL, based on the conditions specified in the JOIN and WHERE clauses.
*/
UPDATE nashvillehousing a
JOIN nashvillehousing b ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;


-- ------------------------------------------------------------------------------------------------------------------------


-- Breaking out Address into Individual Columns (Address, City, State)

-- 1st is the PropertyAddress

SELECT PropertyAddress
From nashvillehousing;

/*
The query below selects two substrings from the PropertyAddress column in the nashvillehousing table:
Address1: Retrieves the characters before the comma in the PropertyAddress.
Address2: Retrieves the characters after the comma in the PropertyAddress.
*/
SELECT
    SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address1,
    SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS Address2
FROM nashvillehousing;

/* Split the PropertyAddress column into two separate columns, (PropertySplitAddress) and (PropertySplitCity), 
based on the comma (,) delimiter in the original PropertyAddress column. 
The first new column (PropertySplitAddress) will contain the part of the address before the comma, 
and the second new column (PropertySplitCity) will contain the part of the address after the comma. 
*/

ALTER TABLE nashvilleHousing
ADD COLUMN PropertySplitAddress VARCHAR(100);

UPDATE nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);

ALTER TABLE nashvilleHousing
ADD COLUMN PropertySplitCity VARCHAR(100);

UPDATE nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

SELECT * FROM nashvillehousing;

-- 2nd is the OwnerAddress

SELECT OwnerAddress FROM nashvillehousing;

-- Split the OwnerAddress column into multiple parts based on comma (,) delimiters
SELECT
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Street, -- extracts the substring before the first comma, which typically represents the street address.
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City, -- extracts the substring between the first and second commas, which typically represents the city name.
    SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State -- extracts the substring after the last comma, which typically represents the state.
FROM nashvillehousing;

/*
Split the OwnerAddress into three new separate columns (OwnerSplitAddress, OwnerSplitCity, and OwnerSplitState) based on comma delimiters. 
They assume a standard address structure with comma-separated parts representing address, city, and state, and populate the new columns accordingly.
*/
ALTER TABLE nashvillehousing
ADD OwnerSplitAddress VARCHAR(100);

UPDATE nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashvillehousing
ADD OwnerSplitCity VARCHAR(100);

UPDATE nashvillehousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE nashvillehousing
ADD OwnerSplitState VARCHAR(100);

UPDATE nashvillehousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT * FROM nashvillehousing;


-- ------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Create a new column displaying more understandable labels ('Yes', 'No') instead of the original 'Y' and 'N' values, leaving other values unchanged.
SELECT SoldAsVacant,
    CASE SoldAsVacant
        WHEN 'Y' THEN 'Yes'
        WHEN 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS Conversion_of_Y_to_Yes_and_N_to_No
FROM nashvillehousing;

/* Alternative approach for the same result
SELECT SoldAsVacant, 
IF(SoldAsVacant = 'Y', 'Yes', IF(SoldAsVacant = 'N', 'No', SoldAsVacant)) AS Conversion_of_Y_to_Yes_and_N_to_No
FROM nashvillehousing;
*/

-- Replace the values in the SoldAsVacant column with 'Yes' if they were 'Y', 'No' if they were 'N', and leave the values unchanged if they don't match these conditions.
UPDATE nashvillehousing
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
	    WHEN SoldAsVacant = 'N' THEN 'No'
	    ELSE SoldAsVacant
	END;


-- ------------------------------------------------------------------------------------------------------------------------


-- Remove Duplicates

-- Using Common Table Expression (CTE) named 'RowNumCTE' to fetch rows from the nashvillehousing table that have duplicate entries within the specified partition columns.
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashvillehousing
)
SELECT * FROM RowNumCTE
-- WHERE row_num > 1
;

-- Delete rows from the nashvillehousing table where there are duplicates based on the specified partitioning 
DELETE FROM nashvillehousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
               ROW_NUMBER() OVER (
                   PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                   ORDER BY UniqueID
               ) AS row_num
        FROM nashvillehousing
    ) AS RowNumCTE
    WHERE row_num > 1
);

SELECT * FROM nashvillehousing;


-- ------------------------------------------------------------------------------------------------------------------------


-- Delete Unused Columns

SELECT * FROM nashvillehousing;

ALTER TABLE nashvillehousing
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate,
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict;


SET SQL_SAFE_UPDATES = 1; -- Re-enabled Safe Updates mode to default that had been disabled in LINE 20 above. This ensures safety against unintentional data modifications or deletions.


