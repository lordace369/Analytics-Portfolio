select count(*) from housing;


select * from housing;
select SaleDate , cast(SaleDate as date)
from housing;

Update housing
set SaleDate= cast(SaleDate as date);

-- Task- 1 - (data type conversion)- SaleDate 

-- Changing the data type of the SaleDate column with ALTER TABLE
alter table housing
modify column SaleDate date;

SHOW COLUMNS FROM housing;


-- Task- 2 - (missing values)- Property Address

-- Looking at the Property address to find missing data
select * from housing ; 

-- counting missing property address values
select
count(*)
from housing 
where PropertyAddress is null;

select
count(*)
from housing as h1
join housing as h2
on h1.ParcelID=h2.ParcelID and h1.UniqueID <> h2.UniqueID
where h1.PropertyAddress is null
order by h1.ParcelID;
-- so we have 35 missing values in the address column that have can be filled


-- finding the values to fill the null address columns
select
row_number() over ( order by h1.UniqueID) as indexx,
h1.ParcelID as h1P,
h2.ParcelID as h2P,
h1.PropertyAddress h1add,
h2.PropertyAddress h2add,
coalesce(h1.PropertyAddress ,h2.PropertyAddress )
from housing as h1
join housing as h2
on h1.ParcelID=h2.ParcelID and h1.UniqueID <> h2.UniqueID
where h1.PropertyAddress is null
order by h1.ParcelID;

-- Filling the null values with the available values from the corresponding parcel id 
-- using the COALESCE(c1,c2) in place of ISNULL(c1,c2) which works in microsoft sql server

update housing as h1
join housing as h2
on h1.ParcelID=h2.ParcelID and h1.UniqueID <> h2.UniqueID
set h1.PropertyAddress = coalesce(h1.PropertyAddress ,h2.PropertyAddress )
where h1.PropertyAddress is null;


-- Task 3 
-- Breaking down PropertyAdress into separate column ( add,city,state)
-- SUBSTRING(string, start_position, length)
select PropertyAddress,
substring(PropertyAddress,
			1,
            locate(',',PropertyAddress)-1) as address,
substring(PropertyAddress,
			locate(',',PropertyAddress)+1,
            length(PropertyAddress)
            ) as City
from housing;

-- Adding the PRopery Address and property city columns to the table and 
-- updating the values in the columns by the calculated values

ALTER TABLE housing
ADD COLUMN p_address varchar(225);

ALTER TABLE housing
ADD COLUMN p_city varchar(225);

UPDATE housing 
set p_address= substring(PropertyAddress,
			1,
            locate(',',PropertyAddress)-1
            ) ;
            
            
UPDATE housing 
set p_city= substring(PropertyAddress,
			locate(',',PropertyAddress)+1,
            length(PropertyAddress)
            ) ;
            
select * from housing            ;

-- Breaking down the owner address

-- we can do the same thing we did above and then further extract state from the resulting city column
-- or we can use the PARSE statement

-- microsoft sql server only-- 
-- replace(OwnerAddress,',','.')
-- parsename(   replace(OwnerAddress,',','.'),
-- 			 1 )--- this separates the string based on fullstops and gives you the 1st part from the right


-- substring_index() takes three arguments-
-- name of the columns/string from where you wanna do the extraction
-- delimiter by which you want to separate the parts of the string
-- number of parts from the left that you want-
-- 		1- gives you one part from the left
--      2- gives you two parts from the left.. (1st + 2nd)
-- 	   -1- gives you the last part.. 1st from reverse order
select OwnerAddress,
substring_index(OwnerAddress,',',1) as o_add,
substring_index(substring_index(OwnerAddress,',',2),',',-1) as o_city,
substring_index(OwnerAddress,',',-1) as o_state
from housing ;

-- making the new columns and assigning values
-- 1- address
ALTER TABLE housing
ADD COLUMN o_address varchar(225);

UPDATE housing 
set o_address= substring_index(OwnerAddress,',',1) ;


-- 2- city
ALTER TABLE housing
ADD COLUMN o_city varchar(225);

UPDATE housing 
set o_city= substring_index(substring_index(OwnerAddress,',',2),',',-1) ;

-- 3- state
ALTER TABLE housing
ADD COLUMN o_state varchar(225);

UPDATE housing 
set o_state = substring_index(OwnerAddress,',',-1) ;

select * from housing;


-- Task 4
-- Change Y and N to yes and no

-- seeing the distribution of distinct values in soldAsVacant column
select SoldAsVacant,count(SoldAsVacant)
from housing
group by SoldAsVacant
order by 2;


-- Updating the values one by one
update housing 
set SoldAsVacant='Yes'
where SoldAsVacant= 'Y';

update housing 
set SoldAsVacant='No'
where SoldAsVacant= 'N';

-- Or we can simply use a case statement
-- Case
-- 	when then
-- 	else
-- End
select SoldAsVacant,
case 
when SoldAsVacant='Yes' then 'yesh'
else SoldAsVacant
End
from housing;

update housing
set SoldAsVacant= 
case when SoldAsVacant='Y' then 'Yes'
        when SoldAsVacant='N' then 'No'
		else SoldAsVacant
        end;
        
-- task 5
    -- Remove Duplicates
with CTE as (
select  *,
row_number() over (
partition by ParcelID,
			PropertyAddress,
            SaleDate,
            SalePrice,
            LegalReference
order by UniqueID	
) as rownum
from housing)

select * 
-- replace the select with delete to delete the duplicate rows in this query
-- delete 
from CTE
where  rownum >1;


-- The above query only works in microsoft sql server  because mysql does not allow you to delete from CTE
-- Using a subquery or temp table instead

delete 
from housing 
where UniqueID in 
(select UniqueID from 
(select  *,
row_number() over (
partition by ParcelID,
			PropertyAddress,
            SaleDate,
            SalePrice,
            LegalReference
order by UniqueID	
) as rownum
from housing) 
as t1
where rownum>1
);




select * from housing ;
-- task 6- 
-- Dropping unnecessary columns
alter table housing 
drop  column PropertyAddress,
drop  column TaxDistrict,
drop  column OwnerAddress;





-- Task- 1 -- (data type conversion)- SaleDate 
-- Task- 2 -- (missing values)- Property Address
-- Task- 3 -- Breaking down PropertyAdress into separate column ( add,city,state)
-- Task- 4 -- Change Y and N to yes and no
-- Task- 5 -- Remove Duplicates
-- Task- 6 -- Dropping unnecessary columns