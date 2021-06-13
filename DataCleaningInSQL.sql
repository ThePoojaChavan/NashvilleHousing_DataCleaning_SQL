/* 
Cleaning Data in SQL
*/

--First and foremost, selecting all columns of the table yto get a feel of columns/rows and values
select * 
from NashvilleHousingData.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--Standardized  Date Format (in mm/dd/yyyy format) 
select SaleDate from NashvilleHousingData.dbo.NashvilleHousing

--SaleDate has time component which is not required (in this case), hence we remove it


select SaleDate, convert(Date,SaleDate)
from NashvilleHousingData.dbo.NashvilleHousing

--Use update  
update NashvilleHousingData.dbo.NashvilleHousing
set SaleDate= convert(Date,SaleDate)

commit;

--Sometimes, plain UPDATE does not work (on existing column) in updating the values. We can add an ALTER statemnt to add a new column and then use an update 
alter table NashvilleHousing
add SaleDateConverted Date;

update NashvilleHousingData.dbo.NashvilleHousing
set SaleDateConverted= convert(Date,SaleDate)

commit;
------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Populate the blank Property Address Data (Why the property address is blank is not known)

--Reason to populate property address is that property address cannot change, property is not going to go anywhere)
--property address could be populated if we have a reference point to base that off



--Finding which property addresses are null
select * from NashvilleHousingData.dbo.NashvilleHousing
where PropertyAddress is null

--we obseve that in many rows, parcelId and PropertyAddress is duplicated, which basically says that if we have two ParcelId - one with property address and other is 
--null then the duplicate parcelId with a blank PropertyAddress can be populated with same address as one which conatins value for the same ParcelId

--Used self join

select * from NashvilleHousingData.dbo.NashvilleHousing
where PropertyAddress is null
order by ParcelId


select  t1.ParcelID, 
		t1.PropertyAddress,
		t2.ParcelID, 
		t2.PropertyAddress
from
		NashvilleHousingData.dbo.NashvilleHousing t1
join	NashvilleHousingData.dbo.NashvilleHousing t2
		on t1.ParcelID=t2.ParcelID
		and t1.[UniqueID ]<>t2.[UniqueID ]
where t1.PropertyAddress is null

select  t1.ParcelID, 
		t1.PropertyAddress,
		t2.ParcelID, 
		t2.PropertyAddress,
		isnull(t1.PropertyAddress,t2.PropertyAddress)
from
		NashvilleHousingData.dbo.NashvilleHousing t1
join	NashvilleHousingData.dbo.NashvilleHousing t2
		on t1.ParcelID=t2.ParcelID
		and t1.[UniqueID ]<>t2.[UniqueID ]
where t1.PropertyAddress is null

-- updating the blank PropertyAddress by populating values

update t1
set PropertyAddress=isnull(t1.PropertyAddress,t2.PropertyAddress)
from
		NashvilleHousingData.dbo.NashvilleHousing t1
join	NashvilleHousingData.dbo.NashvilleHousing t2
		on t1.ParcelID=t2.ParcelID
		and t1.[UniqueID ]<>t2.[UniqueID ]
where t1.PropertyAddress is null

------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Breaking out PropertyAddress field into individual columns(Address, City) using substring/left , charindex

select PropertyAddress from NashvilleHousingData.dbo.NashvilleHousing

select PropertyAddress, substring(PropertyAddress,1, charindex(',',PropertyAddress,1)-1)as "PropertySplitAddress",
					    substring(PropertyAddress,charindex(',', PropertyAddress)+1, len(PropertyAddress)) As "PropertySplitCity"
from NashvilleHousingData.dbo.NashvilleHousing

alter table NashvilleHousing
add PropertySplitAddress Nvarchar(255);

alter table NashvilleHousing
add PropertySplitCity Nvarchar(255);

update NashvilleHousing
set PropertySplitAddress= substring(PropertyAddress,1, charindex(',',PropertyAddress,1)-1)

update NashvilleHousing
set PropertySplitCity=  substring(PropertyAddress,charindex(',', PropertyAddress)+1, len(PropertyAddress))

select  * from 
NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Breaking out OwnerAddress field into individual columns(Address, City, State) using parsename. This function is useful if string has '.' delimeter 
select  OwnerAddress,
		parsename(replace(owneraddress,',','.'),3) as "OwnerSplitAddress",
		parsename(replace(owneraddress,',','.'),2) as "OwnerSplitCity",
		parsename(replace(owneraddress,',','.'),1) as "OwnerSplitState"
from NashvilleHousingData.dbo.NashvilleHousing

alter table NashvilleHousing
add OwnerSplitAddress Nvarchar(255);

alter table NashvilleHousing
add OwnerSplitCity Nvarchar(255);

alter table NashvilleHousing
add OwnerSplitState Nvarchar(255);

update NashvilleHousing
set OwnerSplitAddress= parsename(replace(owneraddress,',','.'),3)

update NashvilleHousing
set OwnerSplitCity= parsename(replace(owneraddress,',','.'),2)

update NashvilleHousing
set OwnerSplitState= parsename(replace(owneraddress,',','.'),1)

select  * from 
NashvilleHousing
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change 'Y' and 'N' to 'Yes' and 'No' in "Sold as Vacant" column using Case Statement

select * from
NashvilleHousingData.dbo.NashvilleHousing

--viewing different values in 'Sold as Vacant' column
select SoldAsVacant, count(soldAsVacant)
from
NashvilleHousingData.dbo.NashvilleHousing
group by soldAsVacant

select	SoldAsVacant,
		case when SoldAsVacant ='N' then 'No' 
			 when SoldAsVacant ='Y' then 'Yes' 
		else SoldAsVacant
		end
from
NashvilleHousingData.dbo.NashvilleHousing

update NashvilleHousing
set SoldAsVacant=case when SoldAsVacant ='N' then 'No' 
			 when SoldAsVacant ='Y' then 'Yes' 
		else SoldAsVacant
		end

select  * from 
NashvilleHousing
------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Remove Duplicates
/*
It's not a normal practice to delete that's in the database, better idea is put the data that you want to delete in a 
temp table.
We will be writing a CTE and use window functions to find duplicates. 
The first step is identifying duplicate rows, we can do that with row_number, rank or dense_rank. we will use row_number as it's the simplest window function
we will partition by parcelId,propertyaddress, saleprice
*/

select *
from
NashvilleHousingData.dbo.NashvilleHousing

--First step, identifying Duplicate values
--Assuming that if ParcelId, PropertyAddress, SaleDate,SalePrice,LegalReference are same then those are identified as duplicate rows
select *,
	ROW_NUMBER() over (
	partition by ParcelId, 
				 PropertyAddress, 
				 SaleDate,
				 SalePrice,
				 LegalReference
				 order by UniqueId) as Rownum
from
NashvilleHousingData.dbo.NashvilleHousing
order by ParcelId

--writing a CTE to put WHERE condition for window functions, remember that ORDER BY cannot be used in a CTE
with RowNumCTE as
(
select *,
	ROW_NUMBER() over (
	partition by ParcelId, 
				 PropertyAddress, 
				 SaleDate,
				 LegalReference
				 order by UniqueId) as Rownum
from
NashvilleHousingData.dbo.NashvilleHousing
) 
select * from RowNumCTE

--adding a where and and an ORDER BY to our CTE to see list of duplicates
with RowNumCTE as
(
select *,
	ROW_NUMBER() over (
	partition by ParcelId, 
				 PropertyAddress, 
				 SaleDate,
				 LegalReference
				 order by UniqueId) as Rownum
from
NashvilleHousingData.dbo.NashvilleHousing
) 
select * from RowNumCTE
where Rownum>1
order by PropertyAddress

--deleting these duplicates
with RowNumCTE as
(
select *,
	ROW_NUMBER() over (
	partition by ParcelId, 
				 PropertyAddress, 
				 SaleDate,
				 LegalReference
				 order by UniqueId) as Rownum
from
NashvilleHousingData.dbo.NashvilleHousing
) 

delete  from RowNumCTE
where Rownum>1

------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Delete unused columns (deleting the columns that we think will not be required  for data exploration)
/*
Usually raw data is not deleted, this is often done with a view
*/

/* syntax  for direct deleting unused columns is:
alter table <table-name>
drop column <column1>,<column2>,....*/

--Deleting from a view
--we will create a view that will have our unused columns like TaxDistrict, OwnerAddress, PropertyAddress
create view Unused_vw1 as 
select  TaxDistrict, OwnerAddress, PropertyAddress
from  NashvilleHousingData.dbo.NashvilleHousing

--select from the view
select * from 
NashvilleHousingData.dbo.Unused_vw1

--delete from the view
 delete  from 
NashvilleHousingData.dbo.Unused_vw1



