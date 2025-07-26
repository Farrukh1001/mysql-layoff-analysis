-- Data cleaning # Project 

select *
from layoffs;

-- 1) Create a copy table
-- 2) Remove duplicates
-- 3) Standardize the data
-- 4) Null or blank values
-- 5) Remove any column


# 1) 
# creating the table
create table layoffs_staging
like layoffs;

# checking if the table was created
select *
from layoffs_staging;

# inserting data
insert layoffs_staging
select *
from layoffs;

select *
from layoffs_staging;

# 2)

# creating and checking row_num
with duplicate_cte as
(select * ,
row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off, 
'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging)
select *
from duplicate_cte
where row_num = 2;

# for checking even if duplication is right??
select *
from layoffs_staging
where company = 'Casper';

# we can't delete row_num = 2 from the table 
# so creating another table

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *
from layoffs_staging2;


insert layoffs_staging2
select * ,
row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off, 
'date', stage, country, funds_raised_millions) as row_num
from layoffs_staging;


select *
from layoffs_staging2
where row_num > 1;


delete
from layoffs_staging2
where row_num > 1;


select *
from layoffs_staging2
where row_num > 1;


select *
from layoffs_staging2;

# 3) 
# trimming company
select *, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

select *
from layoffs_staging2;

# correcting similar data names
select distinct(industry)
from layoffs_staging2
order by 1;

select *
from layoffs_staging2
where industry like 'crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'crypto%';

select distinct(industry)
from layoffs_staging2
order by 1;

# filling null and empty industries
select *
from layoffs_staging2
where industry = '' or industry is null;

select *
from layoffs_staging2
where company like 'bally%';
# can't do anything about bally

select *
from layoffs_staging2
where company like 'airbnb';

update layoffs_staging2
set industry = 'Travel'
where company = 'Airbnb';
# 1 done 2 to go

select *
from layoffs_staging2
where company like 'carvana';

update layoffs_staging2
set industry = 'Transportation'
where company = 'carvana';
# 2 done 1 to go

select *
from layoffs_staging2
where company like 'juul';

update layoffs_staging2
set industry = 'Consumer'
where company = 'juul';

select *
from layoffs_staging2
where industry = '' or industry is null;

# correcting location
select distinct(location)
from layoffs_staging2
order by 1;
# nothing in location


# correcting country
select distinct(country)
from layoffs_staging2
order by 1;

select * 
from layoffs_staging2
where country like 'United States%';

update layoffs_staging2
set country = 'United States'
where country like 'United States%';

# we could've also done it this way

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%';

select * 
from layoffs_staging2
where country like '%states.';
# fixed country

# changing the data type of date column from int to date

select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

select `date`
from layoffs_staging2;

# changing data type
alter table layoffs_staging2
modify column `date` date;

# easier way to populate industry
# doing it with layoffs_staging cause layoffs_staging2 is already done

# checking null
select *
from layoffs_staging
where industry = ''
or industry is null;

# writing all of it side by side
select t1.industry, t2.industry
from layoffs_staging t1
join layoffs_staging t2
	on t1.company = t2.company
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

# making '' into null
update layoffs_staging
set industry = null
where industry = '';

update layoffs_staging t1
join layoffs_staging t2 
	on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null)
and t2.industry is not null;

# checking null
select *
from layoffs_staging
where industry = ''
or industry is null;
# no null detected

# 4)
# removing rows and columns
select *
from layoffs_staging2
where (total_laid_off is null or '')
and (percentage_laid_off is null or '');

delete
from layoffs_staging2
where (total_laid_off is null or '')
and (percentage_laid_off is null or '');

# now removing row_num

alter table layoffs_staging2
drop column row_num;


select *
from layoffs_staging2;
# Completly Done


-- Exploratory Data Analysis

select *
from layoffs_staging2;

# maximum and minimum people laid off
select max(total_laid_off), min(total_laid_off)
from layoffs_staging2;

# where company went bankrupt and with highest laid offs
select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off;

# where company went bankrupt and with most money
select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

# highest total laid offs in 3 years of a company
select company, sum(total_laid_off) as total_laid
from layoffs_staging2
group by company
order by total_laid desc;

# to see the range of date of data we've collected
select min(`date`), max(`date`)
from layoffs_staging2;

# which industry got the most laid offs
select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

# which country got the most laid offs
select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

# in which year got the most laid offs
select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 1 desc;

# which stage got the most laid offs
select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

# total laid offs by each month
select substring(`date`, 1, 7) as months, sum(total_laid_off)
from layoffs_staging2
where substring(`date`, 1, 7) is not null
group by months
order by 1 desc;


# rolling total by month
with rolling_total as
(
select substring(`date`, 1, 7) as months, sum(total_laid_off) as total_laid
from layoffs_staging2
where substring(`date`, 1, 7) is not null
group by months
order by 1 desc
)
select months, total_laid, sum(total_laid) over(order by months desc) as rolling_total
from rolling_total;


# rolling total by Year
with rolling_total as
(
select substring(`date`, 1, 4) as years, sum(total_laid_off) as total_laid
from layoffs_staging2
where substring(`date`, 1, 7) is not null
group by years
order by 1 desc
)
select years, total_laid, sum(total_laid) over(order by years desc) as rolling_total
from rolling_total;

# all comapny laid off how many in which year
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;

select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 1 asc;

# which top 5 companies had the highest laid offs in each year
with company_all (comapny_name, years, total_offs) as 
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), company_year_wise as 
(
select *, dense_rank() over(partition by years order by total_offs desc) as Year_Ranking
from company_all
where years is not null
)
select *
from company_year_wise
where year_ranking <= 5;

# Total companies and laid_offs
select 
  count(distinct company) as total_companies,
  sum(total_laid_off) as total_people_laid_off,
  count(distinct country) as countries_affected,
  concat(min(`date`), ' to ', max(`date`)) as date_range
from layoffs_staging2;


# top industry per year
with yearly_industry as (
  select year(`date`) as year, industry, sum(total_laid_off) as total
  from layoffs_staging2
  group by year, industry
),
ranked as (
  select *, rank() over(partition by year order by total desc) as rnk
  from yearly_industry
)
select *
from ranked
where rnk = 1;


# Layoff comparison by month
with monthly_layoffs as (
  select substring(`date`, 1, 7) as month, sum(total_laid_off) as layoffs
  from layoffs_staging2
  group by month
),
changes as (
  select *,
    lag(layoffs) over(order by month) as prev_layoffs
  from monthly_layoffs
)
select *, 
  round(((layoffs - prev_layoffs) / prev_layoffs) * 100, 2) as percent_change
from changes;


# layoffs per month of each year
select 
  year(`date`) as year, 
  month(`date`) as month, 
  sum(total_laid_off) as total_monthly_layoffs
from layoffs_staging2
group by year, month
order by year, month;


-- Total layoffs per industry
select industry, sum(total_laid_off) as total_layoffs
from layoffs_staging2
group by industry
order by total_layoffs desc;


-- Total layoffs by month (across all years)
select 
  month(`date`) as month_number,
  monthname(`date`) as month_name,
  sum(total_laid_off) as total_layoffs
from layoffs_staging2
group by month_number, month_name
order by month_number;

