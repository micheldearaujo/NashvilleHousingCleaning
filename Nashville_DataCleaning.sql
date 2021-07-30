
/*
Hi there! In this project I will go through a data cleaning in the "Nashville Housing" dataset

@author: micheldearaujo         created at THU 22 Jul 2021   17:41 -03:00 GMT
@github: micheldearaujo
*/

-- Let's get right into it! In this dataset I intend to make some data cleaning, for example

-- Standardize the date format
-- Fill in the NULL values in the Property Address column
-- Separate the Property Address and the Owner Address
-- Change the Y and N to Yes and No in the Sold as Vacant column
-- Remove duplicates
-- Delete unused column

----------------------\\ 1. Configuration \\----------------------
-- I am using PostgreSQL version 12.6 for database system and Valentina Studio as SQL editor


----------------------\\ 2. Standardize date format \\----------------------

-- First of all, let's take a look at our dataset
SELECT *
FROM "NashvilleDataCleaning".housing;

-- We have 56477 records and 19 columns! That is a nice dataset to work on.

-- Now lets transform the SaleDate into the standard format
SELECT date("SaleDate"), "SaleDate"
FROM "NashvilleDataCleaning".housing;
-- It works

-- Now we have to update it
UPDATE "NashvilleDataCleaning".housing
SET "SaleDate" = date("SaleDate")

-- Seeing if it worked

SELECT "SaleDate"
FROM "NashvilleDataCleaning".housing;
-- Alright, that is it. Let's move on



----------------------\\ 3. Fill in the NULL values in the Property Address column \\----------------------

SELECT "PropertyAddress"
FROM "NashvilleDataCleaning".housing
WHERE "PropertyAddress" IS NULL;
-- There is 29 NULL property address, which a relativily small number compared to the dataset size.

-- How is the relation between the property address and the parcelid? We can use a order by parcel ID to verify
-- if this number is unique or not

SELECT "ParcelID",*
FROM "NashvilleDataCleaning".housing
ORDER BY "ParcelID";

-- As you can see, when the ParcelID is duplicated, so is the Property Address. We can use this feature to fill in the missing values
-- of the property address column.

-- Lets make a self join using the ParcelID and UniqueID columns. This should returns the fields where
-- a given row has null property address but there is another row if the same ParcelID which property address is not null

SELECT a."ParcelID", a."PropertyAddress", b."ParcelID", b."PropertyAddress"
FROM "NashvilleDataCleaning".housing AS a
JOIN "NashvilleDataCleaning".housing AS b
    ON a."ParcelID" = b."ParcelID" AND a."UniqueID" != b."UniqueID" -- The lines must be different!
WHERE a."PropertyAddress" IS NULL;

-- Now we have all the cases where the a property address in a given line is missing but the same ParcelID has already
-- appeared with the property address.

-- So, to populate the missing values of the property addres I will use a subquery, that substitutes the missing values
-- with values returned by the inside query


UPDATE "NashvilleDataCleaning".housing AS a
    SET "PropertyAddress" = (
        SELECT "PropertyAddress"
        FROM "NashvilleDataCleaning".housing AS b
        WHERE a."ParcelID" = b."ParcelID" AND "PropertyAddress" IS NOT NULL
          LIMIT 1
    )
WHERE "PropertyAddress" IS NULL;


-- So, if we re-run that query again it should return no values because there will be none null values
SELECT a."ParcelID", COALESCE(a."PropertyAddress", b."PropertyAddress"), b."ParcelID", b."PropertyAddress"
FROM "NashvilleDataCleaning".housing AS a
JOIN "NashvilleDataCleaning".housing AS b
    ON a."ParcelID" = b."ParcelID" AND a."UniqueID" != b."UniqueID" -- The lines must be different!
WHERE a."PropertyAddress" IS NULL;
-- Done!


----------------------\\ 4. Separate the Property Address and the Owner Address \\----------------------
-- Let's take a closer look at the PropertyAddress column
SELECT DISTINCT "PropertyAddress"
FROM "NashvilleDataCleaning".housing;
SELECT 

-- In the same field we have the street address and the city, separated by a comma.
/*
Let's use this comma delimiter to separate those columns together with the "Split_part()" function from postgresql.
But why do so?
If I want to perform a exploratory analysis on this data it would be much more pleasent to have this informations
in different columns so I can make groups by to aggregate the data and extract insights!
*/

SELECT "PropertyAddress",
        split_part("PropertyAddress", ',', 1) AS "StreetAddress",
        split_part("PropertyAddress", ',', 2) AS "City"
FROM "NashvilleDataCleaning".housing;

-- In MS SQL Server the syntax is a little bit more complex:


-- How about updating it into the table?
-- First we need to create two new columns using the alter table command

ALTER TABLE "NashvilleDataCleaning".housing
ADD COLUMN "StreetAddress" VARCHAR(100);

ALTER TABLE "NashvilleDataCleaning".housing
ADD COLUMN "City" VARCHAR(100);

-- Now I insert the values using the split_part() function.
UPDATE "NashvilleDataCleaning".housing
SET "StreetAddress" = split_part("PropertyAddress", ',', 1);

UPDATE "NashvilleDataCleaning".housing
SET "City" = split_part("PropertyAddress", ',', 2);

----- Now to the Owner Address. The difference is that it has the state name.
SELECT "OwnerName", "OwnerAddress"
FROM "NashvilleDataCleaning".housing
WHERE "OwnerAddress" IS NOT NULL ;

-- Lets test
SELECT "OwnerAddress",
        split_part("OwnerAddress", ',', 1) AS "StreetAddress",
        split_part("OwnerAddress", ',', 2) AS "City",
        split_part("OwnerAddress", ',', 3) AS "State"
FROM "NashvilleDataCleaning".housing;

-- Ok, no problems. Lets create new columns and then update them.
-- For the Stree Address
ALTER TABLE "NashvilleDataCleaning".housing
ADD COLUMN "OwnerStreetAddress" VARCHAR(100);   -- Trying to use a adequate character length.

UPDATE "NashvilleDataCleaning".housing
SET "OwnerStreetAddress" = split_part("OwnerAddress", ',', 1);

-- For the city name
ALTER TABLE "NashvilleDataCleaning".housing
ADD COLUMN "OwnerCityAddress" VARCHAR(20);

UPDATE "NashvilleDataCleaning".housing
SET "OwnerCityAddress" = split_part("OwnerAddress", ',', 2);

-- For the State name
ALTER TABLE "NashvilleDataCleaning".housing
ADD COLUMN "OwnerStateAddress" VARCHAR(5);

UPDATE "NashvilleDataCleaning".housing
SET "OwnerStateAddress" = split_part("OwnerAddress", ',', 3);


SELECT *
FROM "NashvilleDataCleaning"."housing"
-- Nice! Now that we have each information in a different table it becomes more useful and easier to make
-- Data analysis.
-- Lets move to the next step

----------------------\\ 6. Change the Y and N to Yes and No in the Sold as Vacant column \\----------------------
-- At first sight the "SoldAsVacant" column seems to have no problem, but if we inspect it...
SELECT DISTINCT "SoldAsVacant"
FROM "NashvilleDataCleaning"."housing";

-- We find that there is some Ys and Ns overthere. So lets correct that!
-- For this, a simple REPLACE should be enough.

SELECT REPLACE("SoldAsVacant", 'Y', 'Yes')
FROM "NashvilleDataCleaning"."housing";

-- It went wrong! Because the word "Yes" contains the "y" letter, the old "Yes" becomes "Yeses"!
-- To prevent that it is necessery to use the WHERE clause:

SELECT REPLACE("SoldAsVacant", 'Y', 'Yes')
FROM "NashvilleDataCleaning"."housing"
WHERE "SoldAsVacant" = 'Y';
-- Now it works! Now lets update it.

UPDATE "NashvilleDataCleaning"."housing"
SET "SoldAsVacant" = REPLACE("SoldAsVacant", 'Y', 'Yes')
WHERE "SoldAsVacant" = 'Y';

-- And the same for the No:
UPDATE "NashvilleDataCleaning"."housing"
SET "SoldAsVacant" = REPLACE("SoldAsVacant", 'N', 'No')
WHERE "SoldAsVacant" = 'N';

SELECT DISTINCT "SoldAsVacant"
FROM "NashvilleDataCleaning"."housing";
-- Cool!
-- So far so good. But there is a couple more work to be done.

----------------------\\ 6. Remove duplicates \\----------------------
-- To see how many rows have duplicates we can use a group by:
-- But first lets create a View without the "UniqueID" column.
-- So we can use the select * 
CREATE VIEW "NashvilleDataCleaning"."NoUniqueID" AS 
    SELECT "ParcelID", "LandUse", "PropertyAddress", "SaleDate", "SalePrice", "LegalReference", "SoldAsVacant",
    "OwnerName", "OwnerAddress", "Acreage", "TaxDistrict", "LandValue", "BuildingValue", "TotalValue", "YearBuilt", 
    "Bedrooms", "FullBath", "HalfBath", "StreetAddress", "City", "OwnerStreetAddress", "OwnerCityAddress", "OwnerStateAddress"
    FROM "NashvilleDataCleaning".housing;
    

SELECT count("PropertyAddress") AS "Duplicates", *
FROM "NashvilleDataCleaning"."NoUniqueID"
GROUP BY "ParcelID", "LandUse", "PropertyAddress", "SaleDate", "SalePrice", "LegalReference", "SoldAsVacant",
    "OwnerName", "OwnerAddress", "Acreage", "TaxDistrict", "LandValue", "BuildingValue", "TotalValue", "YearBuilt", 
    "Bedrooms", "FullBath", "HalfBath", "StreetAddress", "City", "OwnerStreetAddress", "OwnerCityAddress", "OwnerStateAddress"
HAVING count("PropertyAddress") > 1;

-- So, there are 102 duplicates in the dataset!
    
SELECT * FROM "NashvilleDataCleaning"."housing";

-- There is a couple of ways of removing duplicated records of a table.
-- For example, we can use a partition by to delete those rows

CREATE VIEW "NashvilleDataCleaning"."temptable" AS 
SELECT *, 
    row_number() OVER (
    PARTITION BY "ParcelID", "LandUse", "PropertyAddress", "SaleDate", "SalePrice", "LegalReference", "SoldAsVacant",
    "OwnerName", "OwnerAddress", "Acreage", "TaxDistrict", "LandValue", "BuildingValue", "TotalValue", "YearBuilt", 
    "Bedrooms", "FullBath", "HalfBath", "StreetAddress", "City", "OwnerStreetAddress", "OwnerCityAddress", "OwnerStateAddress"
    ORDER BY "UniqueID") AS row_num
FROM "NashvilleDataCleaning"."housing";

-- If we select everything where row_num < 2 we have a new table without duplicates!

SELECT * 
FROM "NashvilleDataCleaning"."temptable"
WHERE row_num < 2;

-- Create a new VIEW

CREATE VIEW "NashvilleDataCleaning"."finaltable" AS 
SELECT * 
FROM "NashvilleDataCleaning"."temptable"
WHERE row_num < 2;

-- And now we test if there is any duplicated ROW

SELECT count("PropertyAddress") AS "Duplicates"
FROM "NashvilleDataCleaning"."finaltable"
GROUP BY "ParcelID", "LandUse", "PropertyAddress", "SaleDate", "SalePrice", "LegalReference", "SoldAsVacant",
    "OwnerName", "OwnerAddress", "Acreage", "TaxDistrict", "LandValue", "BuildingValue", "TotalValue", "YearBuilt", 
    "Bedrooms", "FullBath", "HalfBath", "StreetAddress", "City", "OwnerStreetAddress", "OwnerCityAddress", "OwnerStateAddress"
HAVING count("PropertyAddress") > 1;
-- Nothing, so it worked! 

-- Now we just need to transform this View in a proper TABLE
CREATE TABLE "NashvilleDataCleaning".nashville AS SELECT * FROM "NashvilleDataCleaning"."finaltable";

-- Checking out the new table:
SELECT * FROM "NashvilleDataCleaning".nashville

-- Now lets move to the last step that is to remove not useful columns.

----------------------\\ 6. Delete unused column \\----------------------

-- We just need to make a alter TABLE

ALTER TABLE "NashvilleDataCleaning".nashville
DROP COLUMN "OwnerAddress", "PropertyAddress", "TaxDistrict", row_num;

-- And renaming some of the created columns to a giver a better description
ALTER TABLE "NashvilleDataCleaning".nashville
RENAME COLUMN "StreetAddress" TO "PropertyStreetAddress";

ALTER TABLE "NashvilleDataCleaning".nashville
RENAME COLUMN "City" TO "PropertyCityAddress";

SELECT * FROM "NashvilleDataCleaning".nashville;
