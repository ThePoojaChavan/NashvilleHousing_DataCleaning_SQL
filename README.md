# NashvilleHousing_DataCleaning_SQL

This dataset contains home value data for the Nashville market.

With more than 56000 records, this database was interesting and fun  to clean/wrangle with. Process includes:
1) Standardizing the date format using CONVERT()
2) Populating the blank property address data useing self join,  ISNULL()
3) Breaking the owner/property address to Address, City, State using  functions: LEFT(), RIGHT() and PARSENAME()
4) Changing 'Y and 'N' to 'Yes' and 'No' using CASE Statement
5) Removing Duplicates making use of CTE and window functions
6) Removing unused columns using a)Alter 2)creating a view

