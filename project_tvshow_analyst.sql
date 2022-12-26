-- Create database TVSHOW
create database TVSHOW
-- Choose the database
use [TVSHOW]

/* Create table tvshow_data
Columns Description
--1) firstairdate - The date when the show was first aired on television

--2) origin_country - The country where the show was created / originates from

--3) original_language - The original language of the show

--4) name - Name of the show in English. Note that names in original language are not included in this dataset.

--5) popularity - A metric that measures how popular a TV show is based on consumer views

--6) vote_average - Average of the total number of votes the show received

--7) vote_count - The number of votes the show received

--8) overview - A brief description of the show
*/
create table tvshow
(
	first_air_date date,
	origin_country varchar(50),
	original_language varchar(50),
	name varchar(50),
	popularity varchar(50),
	vote_average varchar(50),
	vote_count varchar(50),
	overview varchar(max)
)

/* Create table country
Columns Descriptions
country_name - Full name of a country
abbreviation_name - Initials name includes two-letter of a country
*/
create table country
(
	country_name nvarchar(255),
	abbreviation_name nvarchar(255)
)


/* Explore database */
-- Explore [dbo].[country] table
select *
from
	[dbo].[country]

-- Capitalize [Abbreviation] column
update 
	[dbo].[country]
set
	[Abbreviation] = upper([Abbreviation])

-- Count the number of row in tvshow table
select *from [dbo].[tvshow]
select count(*) from [dbo].[tvshow]

-- Sort data following ascending order base on first_air_date
select *
from
	[dbo].[tvshow]
order by
	[first_air_date] asc

-- Convert data type for [popularity] column
alter table [dbo].[tvshow]
alter column [popularity] int;

-- Convert data type for [vote_count] column
alter table [dbo].[tvshow]
alter column [vote_average] float;

-- Convert data type for [vote_average] column
alter table [dbo].[tvshow]
alter column [vote_count] int;

-- Change the null or blank value of [first_air_date] column
update
	[dbo].[tvshow]
set
	[first_air_date]= '1899-12-30'
where
	[first_air_date] is null 


-- Find out the null or blank value of popularity column
select [popularity]
from 
	[dbo].[tvshow]
where 
	[popularity] is Null
	or LTRIM(RTRIM([popularity])) = ''

-- Find out the null or blank value of vote_average column
select [vote_average]
from 
	[dbo].[tvshow]
where 
	[vote_average] is Null
	or LTRIM(RTRIM([vote_average])) = ''

-- Find out the null or blank value of vote_count column
select [vote_count]
from 
	[dbo].[tvshow]
where 
	[vote_count] is Null
	or LTRIM(RTRIM([vote_count])) = '';

/* Process special value of [origin_country] column */
select 
	[origin_country] 
from 
	[dbo].[tvshow] 
where 
	[origin_country] like '%[^a-Z0-9]%'; -- Find any single character not in range (a-Z), (0-9)
-- Replace character(0) value with N/A
update 
	[dbo].[tvshow]
set 
	[origin_country] = 'N/A'
where
	[origin_country] = 'character(0)';

-- Get orgin_country values with special characters ' "c("" ', ' "" '
select 
	[origin_country]
from
	[dbo].[tvshow_data]
where
	[origin_country] like '%"c(""%""%';

-- Remove special charaters from orgin_country column
update
	[dbo].[tvshow] 
set 
	[origin_country] = replace(replace(replace(replace([origin_country],'"c(""',''),'"")"',''),'"',''), ')','')
where
	[origin_country] like '%[^a-Z0-9]%';


-- Get [original_language] value with special character
select
	[original_language]
from
	[dbo].[tvshow]
where
	[original_language] like '%[^a-Z0-9]%';

-- Top 10 popular TV shows 
select top(10)
	[name],
	[popularity]
from
	[dbo].[tvshow]
order by
	[popularity] desc

-- Top 10 average vote TV show recieved
select top(10)
	[name],
	[vote_average]
from 
	[dbo].[tvshow]
order by
	[vote_average] desc

-- Top 10 vote count TV shows received 
select top(10)
	[name],
	[vote_count]
from 
	[dbo].[tvshow]
order by
	[vote_count] desc


-- Top 10 Countries that have the most total viewed and their top 10 TV shows in last 10 years 

-- Some TV shows were created by multiple countries so the [origin_country] column includes some countries separated by a comma. We slip it into each column and popularity that assign to each country.

with country_separation as
(
-- Separate each country name abbreviation in the [origin_country] column that has multiple country comma separated, into each row 
	select 
		year([first_air_date]) as 'year',
		[origin_country].*, 
		[name], 
		[popularity]
	from 
		[dbo].[tvshow] 
		cross apply STRING_SPLIT([dbo].[tvshow].[origin_country], ',') as [origin_country]
	where 
		[origin_country] like'%,%'
		and year([first_air_date]) between 2012 and 2022
), country_separation_trim as
(
-- Trim space in the [origin_country] column after separated
	select 
		year,
		trim(value) as 'origin_country',
		name,
		popularity
	from  
		country_separation
), country_name_separation_trim as
(
-- Show full country name corresponding country name abbreviation that is separated above
	select
		year,
		origin_country,
		[country_name],
		name,
		popularity
	from
		[dbo].[country] C1
		join country_separation_trim on C1.[abbreviation_name] = country_separation_trim.origin_country
), single_country_name as
(
-- Show full country name for single value of [origin_country] column 
	select
		year([first_air_date]) as 'year',
		[origin_country],
		[country_name],
		[name],
		[popularity]
	from
		[dbo].[country] C2
		join [dbo].[tvshow] T1 on C2.[abbreviation_name] = T1.[origin_country]
	where
		year([first_air_date]) between 2012 and 2022
), country_name_separation_union_single_country_name as
(
-- Union country_name_separation_trim and single_country_name
	select *from country_name_separation_trim
	union
	select *from single_country_name
), total_viewed_country as
(
-- Calculate the total views of each country
	select
		[country_name],
		[origin_country],
		sum([popularity]) as 'total_popularity'
	from
		country_name_separation_union_single_country_name
	group by
		[country_name],
		[origin_country]
), tvshow_corresponding_country as
(
-- Show TV shows of each country
	select 
		[country_name],
		[name],
		total_popularity,
		dense_rank() over(partition by [country_name] order by total_popularity desc, [popularity] desc) as 'rank'
	from
		total_viewed_country
		join [dbo].[tvshow] T2 on total_viewed_country.[origin_country] = T2.[origin_country]
	where
		year(T2.[first_air_date]) between 2012 and 2022
), top10_tvshow_corresponding_country as 
(
-- Top 10 countries have the most total views 
	select  
		[country_name],
		[name],
		total_popularity,
		dense_rank() over(order by total_popularity desc) 'rank_country'
	from 
		tvshow_corresponding_country
	where 
		rank between 1 and 10
), top10_countries_top10_tvshows_most_viewed as
(
-- Top 10 TV shows corresponding top 10 countries
	select 
		[country_name],
		[name],
		total_popularity
	from 
		top10_tvshow_corresponding_country
	where 
		rank_country between 1 and 10
)
-- Show top 10 countries have the most total views and top 10 TV shows have the most views corresponding 
SELECT 
  t1.country_name as 'Top_10_countries_most_view',
  STUFF((
    SELECT ', ' + t2.name  
    FROM top10_countries_top10_tvshows_most_viewed t2
    WHERE t2.country_name = t1.country_name
    FOR XML PATH (''))
  ,1,2,'') AS Top_10_tv_show_most_view,
  t1.total_popularity as 'TotaL_View'
FROM top10_countries_top10_tvshows_most_viewed t1
GROUP BY 
	t1.country_name,
	t1.total_popularity
order by
	t1.total_popularity desc;

-- TV shows that have the most popularity, the most vote average and the most vote count corresponding in 2022
-- TV show have the most popularity
select 
	[name],
	[popularity]
from 
	[dbo].[tvshow]
where
	year([first_air_date])= '2022'
	and [popularity] = (select 
							max([popularity])
						from 
							[dbo].[tvshow]
						where
							year([first_air_date])='2022'
					   )
-- TV show have the most vote average
select 
	[name],
	[vote_average]
from 
	[dbo].[tvshow]
where
	year([first_air_date])= '2022'
	and [vote_average] = (select 
							max([vote_average])
						from 
							[dbo].[tvshow]
						where
							year([first_air_date])='2022'
						  )
-- TV show have he most vote count
select 
	[name],
	[vote_count]
from 
	[dbo].[tvshow]
where
	year([first_air_date])= '2022'
	and [vote_count] = (select 
							max([vote_count])
						from 
							[dbo].[tvshow]
						where
							year([first_air_date])='2022'
						  )

-- Languages that are used the most in 2022
with the_most_language as
(
	select
		[original_language],
		count([original_language]) as 'number_of_used'
	from
		[dbo].[tvshow]
	where
		year([first_air_date])='2022'
	group by
		[original_language]
)
select 
	[original_language]
from 
	the_most_language
where 
	number_of_used = (
						select
							max(number_of_used)
						from
							the_most_language
					 )

-- TV showes is the most popular in North Korea in 2022
select
	[first_air_date],
	[name], 
	[popularity], 
	[vote_average], 
	[vote_count], 
	[overview]
from
	[dbo].[tvshow] tvshow
	join [dbo].[country] c on tvshow.[origin_country] = c.[abbreviation_name]
where
	[country_name] like '%Korea%'
	and year([first_air_date])='2022'
order by
	[popularity] desc

-- Percentage of total views of per country compared to total views in 2022
with mutilple_country_separation as
(
-- Separate each country name abbreviation in the [origin_country] column that has multiple country comma separated, into each row 
	select 
		year([first_air_date]) as 'year',
		[origin_country].*, 
		[name], 
		[popularity]
	from 
		[dbo].[tvshow] 
		cross apply STRING_SPLIT([dbo].[tvshow].[origin_country], ',') as [origin_country]
	where 
		[origin_country] like'%,%'
		and year([first_air_date])='2022'
), mutilple_country_separation_trim as
(
-- Trim space in the [origin_country] column after separated
	select 
		year,
		trim(value) as 'origin_country',
		name,
		popularity
	from  
		mutilple_country_separation
), single_country as
(
	select 
		year([first_air_date]) as 'year',
		[origin_country],
		[name],
		[popularity]
	from
		[dbo].[tvshow]
	where
		[origin_country] not like'%,%'
		and year([first_air_date])='2022'
), Union_mutilple_country_separation_trim_with_single_country as
(
	select *from mutilple_country_separation_trim
	union 
	select *from single_country

), total_views_in_2022 as
(
	select 
		sum([popularity]) 'total_views'
	from
		Union_mutilple_country_separation_trim_with_single_country
), total_view_per_country_2022 as
(
	select
		year,
		[country_name],
		sum([popularity]) as 'total_views_of_country'
	from
		Union_mutilple_country_separation_trim_with_single_country  Un
		join [dbo].[country] c on un.[origin_country] = c.[abbreviation_name]
	group by
		year,
		[country_name]
), percentage_per_country_in2022 as
(
	select
		year,
		[country_name],
		total_views_of_country,
		Concat(round((cast(total_views_of_country as float)/cast(total_views as float))*100.00, 2),'%') as 'percentage_in2022'
	from
		total_views_in_2022,
		total_view_per_country_2022
)
select *from percentage_per_country_in2022


-- Percentage of total views by each country this year compared to the same period last year
with mutilple_country_separation as
(
-- Separate each country name abbreviation in the [origin_country] column that has multiple country comma separated, into each row 
	select 
		year([first_air_date]) as 'year',
		[origin_country].*, 
		[name], 
		[popularity]
	from 
		[dbo].[tvshow] 
		cross apply STRING_SPLIT([dbo].[tvshow].[origin_country], ',') as [origin_country]
	where 
		[origin_country] like'%,%'
		and year([first_air_date]) in (2021,2022) 
), mutilple_country_separation_trim as
(
-- Trim space in the [origin_country] column after separated
	select 
		year,
		trim(value) as 'origin_country',
		name,
		popularity
	from  
		mutilple_country_separation
), single_country as
(
	select 
		year([first_air_date]) as 'year',
		[origin_country],
		[name],
		[popularity]
	from
		[dbo].[tvshow]
	where
		[origin_country] not like'%,%'
		and year([first_air_date]) in (2021,2022)
), Union_mutilple_country_separation_trim_with_single_country as
(
	select *from mutilple_country_separation_trim
	union 
	select *from single_country
), total_views_per_country_in_2021 as
(
	select
		year,
		origin_country,
		sum(popularity) as 'total_views'
	from
		Union_mutilple_country_separation_trim_with_single_country
	where
		year='2021'
		and origin_country != 'N/A'
	group by
		year,
		origin_country
), total_views_per_country_in_2022 as
(
	select
		year,
		origin_country,
		sum(popularity) as 'total_views'
	from
		Union_mutilple_country_separation_trim_with_single_country
	where
		year='2022'
		and origin_country != 'N/A'
	group by
		year,
		origin_country
), percentage_2022_vs_2021_per_country as
(
	select
		T1.year,
		[country_name],
		T1.total_views as 'total_views_2022',
		T2.total_views as 'total_views_2021',
		concat(round(cast(T1.total_views - T2.total_views as float)/cast(T2.total_views as float)*100, 2),'%') as 'percentage'
	from
		total_views_per_country_in_2022 T1
		join total_views_per_country_in_2021 T2 on T1.origin_country = T2.origin_country
		join [dbo].[country] C on T1.origin_country = C.[abbreviation_name]
)
select *from percentage_2022_vs_2021_per_country 
order by total_views_2022 desc

