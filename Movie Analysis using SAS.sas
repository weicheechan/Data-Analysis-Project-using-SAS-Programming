/*
Group No: Group 15
Student Name: Chan Wei Wei 16052748
Student Name: Chan Wei Chee 16052755
Student Name: Chua Wen Soong 18032573
Title: Movie Analysis in Findings Preferences by Age-Group and Time
*/

*Step1: Accessing Data;

%let path1=/home/u48583432/AEPractical/Assignment;
libname dataset "&path1";

Data dataset.movies;
	infile '/home/u48583432/AEPractical/Assignment/movies2.dat' dlmstr='::' truncover;
	input MovieID Title$:100. Genre $:50.;
run;

Data dataset.ratings;
	infile '/home/u48583432/AEPractical/Assignment/ratings.dat' dlmstr='::' ;
	input UserID MovieID Rating Timestamp; 
		Date = datepart(dhms('01jan1970'd, 0, 0, Timestamp)) ;
		Quarter = date;
		format Date date9.;
		format Quarter yyq.;
run;

Data dataset.users;
	infile '/home/u48583432/AEPractical/Assignment/users.dat' dlmstr='::';
	input UserID Gender $ Age Occupation $ Zipcode $:20.;
run;

*Step2: Data Exploration;

/**general descriptive statistics**/
ods trace on;
proc contents data=dataset.movies;
proc contents data=dataset.users;
proc contents data=dataset.ratings ;
run;
ods select default;


*Check for missing value for user dataset;
proc freq data=dataset.users;
	tables UserID Gender Age Occupation ZipCode /nocum nopercent;
run;

*Check for missing value for movie dataset;
proc freq data=dataset.movies ;
	tables MovieID Title Genre /nocum nopercent;
run;

*Validate timestamp;
proc freq data=dataset.ratings;
	where year(Date)<2000 or year(Date)>2003;
run;

*Check for duplicates movie;
proc sort data=dataset.movies nodupkey dupout=dup_movies;
	by MovieID;
run;

*Explore the genre of movie;
*seperate the pipe-seperated genre;
Data splitgenre;
	set dataset.movies;
	save=genre;
		do i=1 to countw(genre,'|');
			genre=scan(save,i,'|');
			output;
		end;
  		drop i save;
run;

*Graph Distribution of movie genre;
proc freq data=splitgenre order=freq ;
	tables genre/  nocum plots=freqplot;
run;

*Explore the occupation of the audience;
*Format occupation;
proc format;
	value $ OCP 
				"0"= 'other or not specified'
				"1"= 'academic/educator'
				"2"= 'artist'
				"3"= 'clerical/admin'
				"4"= 'college/grad student'
				"5"= 'customer service'
				"6"= 'doctor/health care'
				"7"= 'executive/managerial'
				"8"= 'farmer'
				"9"= 'homemaker'
				"10"= 'K-12 student'
				"11"= 'lawyer'
				"12"= 'programmer'
				"13"= 'retired'
				"14"= 'sales/marketing'
				"15"= 'scientist'
				"16"= 'self-employed'
				"17"= 'technician/engineer'
				"18"= 'tradesman/craftsman'
				"19"= 'unemployed'
				"20"= 'writer';
run;

*Graph Distribution of the occupation;
proc freq data= dataset.users;
	tables Occupation /nocol nocum plots=freqplot;
	format Occupation $OCP.;
run;

*Explore the agegroup by gender of the audience;
/*Format age group*/
proc format;
	value AgeGroup 1= 'Under 18'
 				18='18-24'
 				25= '25-34'
 				35='35-44'
 				45='45-49'
 				50='50-55'
 				56='56+';
run;

*Graph Distribution of the age group by gender;
proc freq data= dataset.users;
	tables Gender*Age /nocol norow nopercent nocum plots=freqplot;
	format Age AgeGroup.;
run;


*Step3:Data Cleaning and Data Manipulation;

*Count the frequency of each rating(1-5) by occupation and agegroup;
*Merge user and rating;
proc sort data = dataset.ratings;
	by UserID;
run;

data user_ratings;
	merge dataset.users dataset.ratings;
	by UserID;
run;

*Merge movie,user,ratings tables;
proc sort data= user_ratings;
	by MovieID;
run;

*Keep only records that exists in both datasets;
Data movie_ratings Missing;
	merge dataset.movies (IN=a) user_ratings (IN=b);
		by MovieID;
	if not(a=1 and b=1) then output Missing;
		else output movie_ratings;
run;
*There are 177 movies that are no ratings from the audience;

*listing of observations with no ratings;
title 'Partial Listing of Movies with No Ratings';
proc print data=Missing (obs=10);
run;
title;

*Graph Distribution of the age group by rating;
proc freq data= user_ratings;
	tables Age*Rating /nocol norow nopercent nocum plots=freqplot;
	format Age AgeGroup.;
run;

*Count the average rating of each movies ordered by descending frequency;
proc means data=movie_ratings noprint order=freq n mean;
	class MovieID Title;
	var Rating;
	output out=avgRating mean=AverageRating;
run;

title 'Top 10 Movies with Highest Number of Votes';
proc print data =avgRating (obs=10);
	ID MovieID;
	where title ^='' and MovieID ^=.;
run;
title;


/**Step4 : Anlayzing Data**/
ods pdf file="&path1/MovieAnalysis.pdf" style=Printer; /*style=Printer;*/
ods noproctitle;

*Research Question 1: What is the top 3 favourite movie genre preferences of each age group;

/** Binning age group**/
Data AgeCategory(keep=MovieID Title Genre UserID Age AgeCat Rating);
	set movie_ratings;
	length AgeCat $20;
			if Age < 18 then AgeCat ="Teenager";
				else if 18<= Age <=34 then AgeCat ="Young Adults";
					else if 35 <= Age <= 49  then AgeCat ="Middle-Aged Adults";
						else AgeCat = "Old Adults";
run;

*Calculate the average means ratings for each movie title;
*MovieMeans contains means for everything;
proc means data=AgeCategory print maxdec=2 order=freq mean n;
	class Title AgeCat;
	var Rating;
	output out=MovieMeans n=RatingFrequency mean=AverageRating;
run;

Data SortedMeans;
	set MovieMeans;
	where Title ^= '' and AgeCat ^='';
run;

title 'Average Rating of Movie by Age Group';
proc print data=SortedMeans (obs=50) noobs;
	var Title AgeCat AverageRating RatingFrequency ;
run;
title;

*split the pipe-seperated movie genre;
Data splitgenre2 (keep= title genre AgeCat rating) ;
	set AgeCategory;
 		save=genre;
  		do i=1 to countw(genre,'|');
    		 genre=scan(save,i,'|');
     		 output;
  		end;
  		drop i save;
run;


*Average ratings of movies categories by genre and age group;
proc means data=splitgenre2 noprint maxdec=2 order=freq;
	class Genre AgeCat;
	var Rating;
	output out=GenreMeans n=RatingFrequency mean=AverageRating;
run;

*removing unnecessary rows;
Data GenreMeans_Clean;
    set GenreMeans;
    if genre ^='' and AgeCat ^='' then output;
run;

*Sorting movie genre by descending ratings;
proc sort data=GenreMeans_Clean out=SortedGenreMeans;
	by genre DESCENDING AverageRating;
run;

title'Partial Listing of Genre Categorised by Age Group';
	proc print data=SortedGenreMeans noobs;
	var Genre AgeCat RatingFrequency AverageRating;
run;
title;

/*Plot of Average rating by movie genre*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.SORTEDGENREMEANS;
	title'Average Ratings By Genre';
	vbar Genre / response=AverageRating stat=mean;
	yaxis grid;
run;

ods graphics / reset;

*Find the Favourite Movie Genre by Age-Group;
*Sorted age by descending rating;
proc sort data=GenreMeans_Clean out=AgeGenreMeans;
	by AgeCat descending AverageRating;
run;


*Picking top 3 movie genre per age group;
data Age_favourite;
	do _n_ = 1 by 1 until (Last.AgeCat);
		set AgeGenreMeans;
		by AgeCat;
		if _n_ <= 3 then output;
	end;
Run;

*Picking bottom 3 movie genre per age group;
proc sort data=GenreMeans_Clean out=AgeGenreMeans_bottom;
	by AgeCat AverageRating;
run;

Data Age_dislike;
	do _n_ = 1 by 1 until (Last.AgeCat);
		set AgeGenreMeans_bottom;
		by AgeCat;
		if _n_ <= 3 then output;
	end;
run;

title 'Top 3 Favourite Movie Genres Preferences of Each Age Group';
proc print data=Age_favourite label noobs;
	var AgeCat Genre AverageRating RatingFrequency;
	label AgeCat = AgeGroup;
run;
title;

title 'Three Least Favourite Movie of Each Age Group';
proc print data=Age_dislike label noobs;
	var AgeCat Genre AverageRating RatingFrequency;
	label AgeCat = AgeGroup;
run;
title;

*Research Question 2: What are the top rated movie for each quarter?;

Data movie_quarter (keep= title genre rating quarter);
	set movie_ratings;
run;

*sort the movie title by quarter;
proc sort data=movie_quarter out=sortedMovieQuarter;
	by quarter ;
run;

proc means data=sortedMovieQuarter noprint maxdec=2 order=freq;
	class quarter title;
	var Rating;
	output out=QuarterMeans n=RatingFrequency mean=AverageRating;
run;

*removing unnecessary rows;
Data QuarterMeans_Clean;
    set QuarterMeans;
    if title ^='' and quarter ^=. then output;
run;

*Distribution of frequency and average rating;
proc univariate data= QuarterMeans_Clean;
	var AverageRating RatingFrequency;
	where RatingFrequency between 0 and 100;
	histogram / barlabel=count;
run;

*Setting threshold=10 for rating frequency ;
Data QuarterMeans_over10;
	set QuarterMeans_Clean;
	if RatingFrequency >=10  then output;
run;

*Distribution of frequency and average rating with threshold;
proc univariate data= QuarterMeans_over10;
	var AverageRating RatingFrequency;
	histogram/barlabel=count;
run;

*Sorting quarter by descending average rating;
proc sort data=QuarterMeans_over10 out=SortedQuarterMeans;
	by quarter descending AverageRating;
run;

*Display only the movie title with the highest average rating for each quarter of year;
Data Title_Genre;
	set SortedQuarterMeans;
	by quarter;
	if First.quarter;
run;

title 'Top Rated Movie for each Quarter by Year';
proc print data=Title_Genre;
	var title quarter RatingFrequency AverageRating;
run;
title;

/*Step5 : Generating reports*/
/*Let's export report to pdf*/

ods pdf close;
 	
