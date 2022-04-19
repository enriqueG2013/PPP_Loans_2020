--ENRIQUE GONZALEZ - PPP LOANS IN 2020 (VA, VI, VT, WA, WI, WV, WY)

--DATA CLEANING

--1)Delete unused column
alter table standards
drop column F3;

--2) Delete rows that are null on both columns
select [NAICS Codes], [NAICS Industry Description]
from standards
where [NAICS Codes] is null;

delete from standards
where [NAICS Codes] is null and
[NAICS Industry Description] is null;

delete from standards
where [NAICS Codes] is null and
[NAICS Industry Description] not like 'S%';


--3) Create Look Up Code for each sector

--extract sector numbers into their own column
select [NAICS Industry Description],
iif([NAICS Industry Description] like '%–%', substring([NAICS Industry Description], 8, 2), '') as Lookup_Code --if( the column has a row with the '-' character, then use substring, else add nothing)
from standards
where [NAICS Codes] is null;

--extract sector description into theor own column
select [NAICS Industry Description],
iif([NAICS Industry Description] like '%–%', substring([NAICS Industry Description], 8, 2), '') as Sector_Code,
substring([NAICS Industry Description], charindex('–', [NAICS Industry Description]) + 1, len([NAICS Industry Description])) as Sector --charindex will make it so the substring begins wherever there is a '-' in the column.
from standards                                                                                                                         --The Len will tell it to get all the string in the column after where the charindex tells it to begin.    
where [NAICS Codes] is null;

--Delete leading white space in Sector column
select [NAICS Industry Description],
iif([NAICS Industry Description] like '%–%', substring([NAICS Industry Description], 8, 2), '') as Sector_Code,
ltrim(substring([NAICS Industry Description], charindex('–', [NAICS Industry Description]) + 1, len([NAICS Industry Description]))) as Sector  --add LTRIM to delete white space for this column
from standards
where [NAICS Codes] is null;

--4) Create table with new cleaned data
select * into sector_codes_description
from(
	select [NAICS Industry Description],
	iif([NAICS Industry Description] like '%–%', substring([NAICS Industry Description], 8, 2), '') as Sector_Code,
	ltrim(substring([NAICS Industry Description], charindex('–', [NAICS Industry Description]) + 1, len([NAICS Industry Description]))) as Sector  --add LTRIM to delete white space for this column
	from standards
	where [NAICS Codes] is null) main;

--5) Insert codes for sectors with multiple codes
insert into sector_codes_description
values ('Sector 31 – 33 – Manufacturing', 32, 'Manufacturing'),
('Sector 31 – 33 – Manufacturing', 33, 'Manufacturing'),
('Sector 44 - 45 – Retail Trade', 45, 'Retail Trade'),
('Sector 48 - 49 – Transportation and Warehousing', 46, 'Transportation and Warehousing');

--6) Clean Sector colum where rows begin with numbers
update sector_codes_description
set Sector = 'Manufacturing'
where Sector_Code = 31;

--FINAL TABLE
select * from sector_codes_description
order by Sector_Code;


--DATA EXPLORATION

--1) What is the summary of all approved PPP Loans
select 
	year(DateApproved) as 'Year Approved',
	count(loanNumber) as 'Number of Approved Loans', 
	sum(initialapprovalamount) as 'Total Approved Amount',
	AVG(initialapprovalamount) as 'Average Loan Amount'
from 
	businesses
where 
	year(dateapproved) = 2020
group by
	year(dateapproved)
	
union

select 
	year(DateApproved) as 'Year Approved',
	count(loanNumber) as 'Number of Approved Loans', 
	sum(initialapprovalamount) as 'Total Approved Amount',
	AVG(initialapprovalamount) as 'Average Loan Amount'
from 
	businesses
where 
	year(dateapproved) = 2021
group by
	year(dateapproved);

--2)Number of originating lendors that helped small businesses get approved loan

select 
	year(DateApproved) as 'Year Approved',
	count(distinct OriginatingLender ) as 'Number of Originating Lenders',
	count(loanNumber) as 'Number of Approved Loans', 
	sum(initialapprovalamount) as 'Total Approved Amount',
	AVG(initialapprovalamount) as 'Average Loan Amount'
from 
	businesses
where 
	year(dateapproved) = 2020
group by
	year(dateapproved)

union

select 
	year(DateApproved) as 'Year Approved',
	count(distinct OriginatingLender ) as 'Number of Originating Lenders',
	count(loanNumber) as 'Number of Approved Loans', 
	sum(initialapprovalamount) as 'Total Approved Amount',
	AVG(initialapprovalamount) as 'Average Loan Amount'
from 
	businesses
where 
	year(dateapproved) = 2021
group by
	year(dateapproved);

--3) Top 15 Originating Lenders by loan amount and average in 2020
select top 15
	OriginatingLender,
	count(loanNumber) as 'Number of Approved Loans', 
	sum(initialapprovalamount) as 'Total Approved Amount',
	AVG(initialapprovalamount) as 'Average Loan Amount'
from 
	businesses
where 
	year(dateapproved) = 2020
group by
	OriginatingLender
order by
	3 desc;

--3) Top Industries that received PPP loans in 2020
with cte as
(
select top 20
	b.Sector,
	count(loanNumber) as Num_Approved_Loans, 
	sum(initialapprovalamount) as Total_Approved_Amount,
	AVG(initialapprovalamount) as Average_Loan_Amount
from 
	businesses a
	inner join sector_codes_description b
		on left(a.NAICSCode, 2) = b.Sector_Code
where 
	year(dateapproved) = 2020
group by
	b.Sector
--order by 3 desc
)
select 
	Sector, Num_Approved_Loans, Total_Approved_Amount, Average_Loan_Amount,
	Total_Approved_Amount/sum(Total_Approved_Amount) over() * 100 as 'Percent of Total Amount'
from cte
order by 3 desc;

--4) How much of the PPP loans of 2021 have been fully forgiven
select
	count(loanNumber) as Number_of_approved,
	sum(CurrentApprovalAmount) as Current_Approved_Amount,
	avg(CurrentApprovalAmount) as Current_Average_Loan_Size,
	sum(forgivenessAmount) as Amount_Forgiven,
	sum(ForgivenessAmount)/sum(currentApprovalAmount) * 100 as Percent_Forgiven
from
	businesses
where
	year(dateApproved) = 2020
order by 3 desc;

--5) Check the year and month with highest PPP Loan
select
	year(dateApproved) as Year_Approved,
	month(dateApproved) as Month_Approved,
	count(loanNumber) as Number_of_approved,
	sum(CurrentApprovalAmount) as Current_Approved_Amount,
	avg(CurrentApprovalAmount) as Current_Average_Loan_Size
from
	businesses
group by
	year(dateApproved),
	month(dateApproved)
order by 4 desc;

--6) Check the total amounts of each state
select
	BorrowerState,
	sum(initialapprovalamount) as Total_Approved_Amount,
	AVG(initialapprovalamount) as Average_Loan_Amount
from 
	businesses
group by
	BorrowerState;

