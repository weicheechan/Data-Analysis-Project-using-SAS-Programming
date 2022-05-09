libname dataset '/home/u48583432/PSPractical/Assignment';
*Step1: Accessing Data;

/*5647 observations and 4 variables*/
Data Customer;
	infile '/home/u48583432/PSPractical/Assignment/Customer.csv' dlm=',' dsd truncover firstobs=2;
	input customer_id $ DOB :ddmmyy10. gender $ city_code;
	format DOB ddmmyy10.;
run;


/* 23 observations and 4 variables*/
Data Products;
	infile '/home/u48583432/PSPractical/Assignment/Products.csv' dlm=',' firstobs=2;
	input prod_cat_code $ prod_cat :$16. prod_subcat_code $ prod_subcat :$19.;
run;


/* 23053 observations and 10 variables*/
proc format;
	picture negrate (default=22) low - 0='000,000,099.99' (prefix='-$') 
		other=[dollar22.];
run;

proc format;
	picture negamt (default=22) low - 0='000,000,099.99' (prefix='-$') 
		other=[dollar22.];
run;


Data Transactions;
	infile '/home/u48583432/PSPractical/Assignment/Transactions.csv' dlm=',' firstobs=2;
	input transaction_id :$11. 
		customer_id $ tran_date :ddmmyy10. prod_subcat_code $ prod_cat_code $ qty 
		rate tax total_amt store_type :$14.;
	format tran_date ddmmyy10. rate total_amt dollar11.2 tax dollar8.2 rate negrate. total_amt negamt.;
run;


/*Step2: Data Exploration*/
/**general descriptive statistics og original dataset**/
proc contents data=Customer;
run; 

proc contents data=Products;
run;

proc contents data=Transactions;
run;

* Step3: Data Merging and  Manipulation;
*Merge Customer and Transaction dataset;
proc sort data=Customer out=customer_sort;
	by customer_id;
run;

proc sort data=transactions out=trans_sort;
	by customer_id;
run;



/*23053 observations 13 variables*/ 
data customer_trans ;
	merge customer_sort trans_sort (in=intransactions);
	by customer_id;
	if intransactions;
run;


/* Merge Customer Transactions and Product dataset*/
proc sort data=customer_trans out=customer_trans_sort;
	by prod_cat_code prod_subcat_code;
run;


proc sort data=Products out=products_sort;
	by prod_cat_code prod_subcat_code;
run;

/*23053 observations,15 variables*/ 
data Customer_Trans_Product;
	merge customer_trans_sort products_sort(in=incombine);
	by prod_cat_code prod_subcat_code;
	
	if incombine;
run;

/*23036 observations and 15 variables*/
*removing unnecessary rows;
Data Customer_Trans_Product_clean;
    set Customer_Trans_Product;
    if gender ^='' AND city_code ^=. then output;
run;

proc contents data = customer_trans_product_clean;
run;


/*Step 4:Data Cleaning*/
/*18804 clean observations and 10 variables*/
/**4234 refund transactions**/
proc sort data=customer_trans_product_clean out=CTP_clean_sort;
	by transaction_id total_amt;
run;


Data clean_trans (drop=trans_count) refund_trans;
	set CTP_clean_sort;
	by transaction_id total_amt;

	if first.transaction_id then
		do;
			trans_count=1;
		end;

	/*output to refund */
	if total_amt < 0 or trans_count >1 then
		do;
			output refund_trans;
			trans_count+1;
		end;
	else
		output clean_trans;
run;


proc contents data=clean_trans;
run;

proc contents data =refund_trans;
run;


/*Step4: Data Validation**/

*Customer dataset;
*check for missing values;
title"Customer Gender Distribution";
proc freq data=Customer;
tables gender city_code /nocum nopercent;
run;
/*2 missing gender and city code**/

/** City Code Analysis**/
title'City Code Distribution where Customers Resides';
proc freq data = customer;
tables city_code / nocum nopercent;
run;
title;

*Product dataset;
*check for missing values;
proc freq data=Products;
tables prod_cat_code prod_cat prod_subcat_code prod_subcat /nocum nopercent;
run;

*Transaction dataset;
*check for missing values;
proc freq data=transactions;
tables store_type /nocum nopercent;
*tables customer_id /nocum nopercent;
run;


/* Graph Exploration*/
*Customer Gender Distribution;

title "Customer Gender Distribution";
proc template;
		define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=gender /;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;
proc sgrender template=SASStudio.Pie data=WORK.customer;
run;
title;
ods graphics / reset;

*City Code Distribution;
ods graphics / reset width=6.4in height=4.8in imagemap;
title "City Code Distribution where Customers Resides";
proc sgplot data=WORK.customer;
	vbar city_code /;
	yaxis grid;
run;
title;

ods graphics / reset;

*measure of central tendency for transactions;
title'Descriptive Statistics of Customer Spending';
title2'Based On Transactions History from 2011-2014';
proc means data=clean_trans n mean median mode stddev min max maxdec=2;
format total_amt dollar10.2;
var total_amt;
run;
title2;
title;


/** Step6 : Data Analysis**/
/**RQ1 : How is the performance of each store type?**/
/* Trends of Total Sales over 4 year*/
Data Sales_over_4yrs;
	set clean_trans;
	
	month=month(tran_date);
	year=year(tran_date);
	quarter =qtr(tran_date);
	
	if year IN (2011,2012,2013,2014) ;
run;

proc sort data=Sales_over_4yrs;
	BY year quarter;
run;

Data Sales_over_4yrs_part2 (keep=tran_date  yearqtr total_sales);
	set Sales_over_4yrs;
	BY year quarter;
	
	if First.year or First.quarter then
		Total_Sales=0;
	Total_Sales + total_amt;

	if last.quarter;
	yearqtr=catx('/', year, put(quarter,z2.));
	
	keep tran_date  yearqtr total_sales;
run;

title 'Sales over a close 4 year period';
title2 'Breakdown of Quarterly Sales';
proc gplot data=Sales_over_4yrs_part2;
	symbol i=spline v=dot h=1;
	plot Total_Sales*yearqtr=1;
	format total_sales dollar15.2;
	run;
title2;
title;

title 'Sales over a close 4 year period';
title2 'Breakdown of Quarterly Sales';
proc print data= Sales_over_4yrs_part2 noobs;
var tran_date yearqtr total_sales;
format total_sales dollar15.2;
run;
title2;
title;


/**Store Type Distribution**/
title"Store Type Distribution";
title2 "Based On Transaction History from 2011-2014";
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=store_type / stat=pct;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=WORK.CUSTOMER_TRANS_PRODUCT_CLEAN;
run;
title;
ods graphics / reset;


proc freq data=clean_trans;
tables store_type / nocum nopercent nocol norow;
run;


/** Examine Total Sales by Each Store Type**/
proc sort data=clean_trans out=store_type_sort;
	by store_type;
run;

data SalesByStoreType;
	set store_type_sort;
	by store_type;

	if first.store_type then
		do total_sales=0;
			transaction_count=0;
		end;
	total_sales+total_amt;
	transaction_count+1;

	if last.store_type;
	keep store_type total_sales transaction_count;
run;

/*Sales By Store Type Bar Chart over the 4 years*/
ods graphics / reset width=6.4in height=4.8in imagemap;
title"Accumulating Total Sales By Each Store Type over the 4 years";
proc sgplot data=SalesByStoreType ;
	vbar store_type / response=total_sales;
	format total_sales dollar15.2;
	yaxis grid;
run;
title;
ods graphics / reset;

title"Accumulating Total Sales By Each Store Type over the 4 years";
proc print data=SalesByStoreType noobs;
format total_sales dollar15.2;
run;
title;

*RQ2 -Which customer segment should be prioritized in each store type?;
/*i.Which platform does each customer age group prefer to use*/

*Compute Age based on DOB;
*Customer Age during transaction history;
proc sort data=clean_trans out=CTP_sort;
	by customer_id;
run;

data CTP_Age;
	set CTP_sort;
	Age=year(tran_date)- year(DOB);
run;

/** Binning age group**/
data CTP_AgeGroup;
	set CTP_Age;
	length AgeGroup $10;

	if Age < 20 then
		AgeGroup ="Under20";
	else if 20 <= Age <= 29 then
		AgeGroup = "20-29";
	else if 30 <= Age <= 39 then
		AgeGroup = "30-39";
	else 
		AgeGroup = "40+";
run;


*Graph Distribution of the age group by gender;
proc freq data= CTP_AgeGroup;
	tables AgeGroup*Gender /nocol norow nopercent nocum plots=freqplot;	
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=CTP_AgeGroup;
	title height=14pt "Customer Age Group by Gender";
	vbar AgeGroup / group=Gender groupdisplay=cluster datalabel;
	yaxis grid;
run;

ods graphics / reset;
title;

*Frequency of Customer Age Group in each Store Type;
proc sort data=CTP_AgeGroup out=AgeGroup_sort;
	by agegroup store_type ;
run;


data AgeGroup_Count (keep=AgeGroup transaction_num store_type);
	set AgeGroup_sort;
	by agegroup store_type ;

	if first.AgeGroup or first.store_type then Transaction_Num=0;
	Transaction_Num+1;
run;


title"Store Type Preference by each Customer Age Group";
proc freq data =AgeGroup_Count order=freq;
tables ageGroup * store_type /nocum nopercent nocol norow plots=freqplot;
run;
title;

ods graphics / reset width=6.4in height=4.8in imagemap;
title" Store Type Preference by each Customer Age Group";
proc sgplot data=WORK.AGEGROUP_count;
	vbar store_type / group=AgeGroup groupdisplay=cluster;
	yaxis grid;
run;
title;
ods graphics / reset;



*Product Category Preference by Customer Age Group;
proc freq data= CTP_AgeGroup;
tables prod_cat*AgeGroup /nocol norow nopercent nocum plots=freqplot;	
run;

ods graphics / reset width=6.4in height=4.8in imagemap;
title"Product Category Preference by Customer AgeGroup";
proc sgplot data=WORK.CTP_AGEGROUP;
	vbar prod_cat / group=AgeGroup groupdisplay=cluster;
	yaxis grid;
run;
title;
ods graphics / reset;



*ii.Which age group is profitable in each store type?;

proc sort data=CTP_AgeGroup out=AgeGroup_sort2;
	by store_type AgeGroup;
run;


data AgeGroup_TotalSales (keep=agegroup total_sales age_count store_type);
	set agegroup_sort2;
	by store_type AgeGroup;

	if first.store_type or first.AgeGroup then
		do Total_sales=0;
			age_count=0;
		end;
	Total_sales+total_amt;
	age_count+1;

	if last.AgeGroup;
run;


title"Profitable Age Group by each Store Type";
proc print data=AgeGroup_TotalSales noobs;
	format Total_Sales dollar12.2 ;
run;
title;


ods graphics / reset width=6.4in height=4.8in imagemap;
title"Profitable Age Group by each Store Type";
proc sgplot data=WORK.AGEGROUP_TOTALSALES;
	vbar store_type / response=Total_sales group=AgeGroup groupdisplay=cluster;
	yaxis grid;
	format Total_sales dollar11.2;
run;
title;
ods graphics / reset;


/** Examine city code for customer from Flagship store**/
proc sort data=clean_trans out=city_sort;
by city_code;
run;


Data CityCode;
	set city_sort;
	by city_code;	
	where store_type='Flagship store';

	
 if first.city_code then do;
	 total_sales=0;
	 city_count=0;
	end;
	
	 total_sales+total_amt;
	 city_count+1;
	
	if last.city_code;
	keep city_code total_sales city_count;
run;

title'Analysis of Flagship Store Customer';
proc print data=citycode noobs;
sum city_count;
format total_sales dollar15.2;
run;
title;


*3) Which product category should be prioritized in each store type?; 
*Product Category Preference by gender;
proc freq data= clean_trans;
tables prod_cat*gender /nocol norow nopercent nocum plots=freqplot;	
run;

ods graphics / reset width=6.4in height=4.8in imagemap;
title"Product Category Preference by Gender";
proc sgplot data=WORK.clean_trans;
	vbar prod_cat / group=gender groupdisplay=cluster;
	yaxis grid;
run;
title;
ods graphics / reset;


/** Examine transaction count of product category in each store type**/
title"Amount of Quantity Sold of Each Product Category by Store Type";
title2" Based On Transaction History from 2011 - 2014";
proc freq data=clean_trans;
tables prod_cat * store_type/ nocum nopercent nocol norow;
run;
title2;
title;

title"Amount of Quantity Sold of Each Product Category by Store Type";
title2" Based On Transaction History from 2011 - 2014";
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.clean_trans;
	vbar store_type / group=prod_cat groupdisplay=cluster;
	yaxis grid;
run;
title2;
title;
ods graphics / reset;

*What is each store's overall revenue and gross profit generated over the years?;
proc sort data=clean_trans out=CTP_clean_sorted;  
by Store_type prod_cat prod_subcat;
run;

Data eshop_gp Teleshop_gp MBR_gp Flagship_gp;
	set CTP_clean_sorted;
	By Store_type prod_cat prod_subcat;
	if First.Store_type = 1 or First.prod_cat = 1 or First.prod_subcat = 1 then do 
	Transaction_count = 0;
	Total_Sales = 0;
	Total_Tax = 0;
	end;
	
	Transaction_count + 1;
	Total_Sales + total_amt;
	Total_Tax + Tax;
	Gross_profit = Total_Sales - Total_Tax;
	
	
	keep  Store_type prod_cat prod_subcat Transaction_count Total_Sales Total_Tax Gross_profit ;
	
	if Store_type = 'e-Shop' and last.prod_subcat=1 then output eshop_gp;
	else if Store_type = 'TeleShop' and last.prod_subcat=1  then output Teleshop_gp;
	else if Store_type = 'MBR' and last.prod_subcat=1 then output MBR_gp;
	else if Store_type = 'Flagship store' and last.prod_subcat=1 then output Flagship_gp;
	
run;

*Examine Top 3 most profitable product category in each Store Type ;
*Top 3 most Profitable Product For Eshop;
proc sort data=work.eshop_gp out=eshop_gp_sort;
by prod_cat;
run;

Data eshop_cat_top3gross;
	set eshop_gp_sort;
	by prod_cat;
	
	if first.prod_cat then do;
		TotGross_profit=0;
	end;
	TotGross_profit + Gross_profit;
	if last.prod_cat;
run;

proc sort data=work.eshop_cat_top3gross;
by descending TotGross_profit;
run;

title "Top 3 Most Profitable Product Categories in E-Shop";
proc print data=work.eshop_cat_top3gross (obs=3);
var prod_cat TotGross_profit;
format TotGross_profit dollar15.2;
run;
title;  


*Top3 most Profitable Product For Flagship;
proc sort data=work.flagship_gp out=flagship_gp_sort;
by prod_cat;
run;

Data Flagship_store_cat_top3gross;
	set flagship_gp_sort;
	by prod_cat;
	
	if first.prod_cat then do;
		TotGross_profit=0;
	end;
	
	TotGross_profit + Gross_profit;
	if last.prod_cat;
run;

proc sort data=Flagship_store_cat_top3gross;
by descending TotGross_profit;
run;

title 'Top 3 Most Profitable Product Categories in Flagship Stores';
proc print data=work.flagship_store_cat_top3gross (obs=3);
var prod_cat  TotGross_profit;
format TotGross_profit dollar15.2;
run;
title;  


*Top3 most Profitable Product For MBR Stores;
proc sort data=work.MBR_gp out=MBR_gp_sort;
by prod_cat;
run;

Data MBR_cat_top3gross;
	set MBR_gp_sort;
	by prod_cat;
	
	if first.prod_cat then do;
		TotGross_profit=0;
	end;
	
	TotGross_profit + Gross_profit;
	if last.prod_cat;
run;

proc sort data=MBR_cat_top3gross;
by descending TotGross_profit;
run;

title 'Top 3 Most Profitable Product Categories in MBR Stores';
proc print data=work.mbr_cat_top3gross (obs=3);
var prod_cat TotGross_profit;
format TotGross_profit dollar15.2;
run;
title;  

*Top 3 Most Profitable Product Categories for TeleShop;
proc sort data=work.teleshop_gp out=teleshop_gp_sort;
by prod_cat;
run;

Data Teleshop_cat_top3gross;
	set teleshop_gp_sort;
	by prod_cat;
	
	if first.prod_cat then do;
		TotGross_profit=0;
	end;
	
	TotGross_profit + Gross_profit;
	if last.prod_cat;
run;

proc sort data=Teleshop_cat_top3gross;
by descending TotGross_profit;
run;

title 'Top 3 Most profitable Product Categories in Teleshop';
proc print data=work.Teleshop_cat_top3gross (obs=3);
var prod_cat TotGross_profit;
format TotGross_profit dollar15.2;
run;
title;

** Which sub_cat in Books, Electronics and Home & Kitchen are most popular in each store?;
Data  gross_subcat;
	set CTP_clean_sorted;
	By Store_type prod_cat prod_subcat;
	if First.Store_type = 1 or First.prod_cat = 1 or First.prod_subcat = 1 then do 
	Transaction_count = 0;
	Gross_profit=0;
	end;
	
	Transaction_count + 1;
	Gross_profit = total_amt - Tax;
run;

Data Profitable_subcat;
	set work.gross_subcat;
	By Store_type prod_cat prod_subcat;
	Where prod_cat = 'Books' or prod_cat='Electronics' or prod_cat='Home and kitchen';
	if First.Store_type = 1 or First.prod_cat = 1 or First.prod_subcat = 1 then do 
	tot_gross_profit=0;
	end;
	
	tot_gross_profit + Gross_profit;
	if last.prod_subcat;
	keep prod_cat prod_subcat Store_type tot_gross_profit;
run;

proc sort data=Profitable_subcat;
by  Store_type prod_cat descending tot_gross_profit;
run;

Data Top_3_profitable_subcat;
 set Profitable_subcat;
 by Store_type prod_cat descending tot_gross_profit;
 if first.prod_cat=1 or first.store_type=1 then do;
 	counter = 0;
 	end;
 	
 	counter + 1;
run;
 
Data e_shop_profitable_subcat Flagship_profitable_subcat MBR_profitable_subcat Teleshop_profitable_subcat;
	set work.Top_3_profitable_subcat;
	where counter = 1 or counter = 2 or counter = 3;
	if Store_type = 'e-Shop' then output e_shop_profitable_subcat;
	if Store_type = 'Flagship store' then  output Flagship_profitable_subcat;
	if Store_type = 'MBR' then output MBR_profitable_subcat;
	if Store_type = 'TeleShop' then output Teleshop_profitable_subcat;
	drop counter;
run;

title 'Top 3 Most Profitable Product Sub-Categories in E-shop';
proc print data=work.e_shop_profitable_subcat noobs;
format tot_gross_profit dollar8.;
run;
title;
     
title 'Top 3 Most Profitable Product Sub-Categories in Flagship Stores';
proc print data=work.Flagship_profitable_subcat noobs;
format tot_gross_profit dollar8.;
run;
title;

title 'Top 3 Most Profitable Product Sub-Categories in MBR stores';
proc print data=work.MBR_profitable_subcat noobs;
format tot_gross_profit dollar8.;
run;
title;

title 'Top 3 Most Profitable Product Sub-Categories in Teleshop';
proc print data=work.Teleshop_profitable_subcat noobs;
format tot_gross_profit dollar8.;
run;
title;


*Analysis Sales Performance in each store type based on quantity sold;
/* Products sold the most/least in each store type*/
* sort by Top3;

proc sort data=clean_trans out=store_type_sort;
	by store_type prod_cat prod_subcat;
run;

Data eshop_qty teleshop_qty flagship_qty MBR_qty;

	set store_type_sort;
	by store_type prod_cat prod_subcat;

	if first.prod_cat or first.prod_subcat then
		do;
			total_sales=0;
			transaction_count=0;
			qty_sold=0;
		end;
	total_sales+total_amt;
	transaction_count+1;
	qty_sold + qty;

	if last.prod_cat or last.prod_subcat;

	if store_type="Flagship store" then
		output flagship_qty;
	else if store_type="e-Shop" then
		output eshop_qty;
	else if store_type="TeleShop" then
		output teleshop_qty;
	else if store_type="MBR" then
		output MBR_qty;
	keep store_type prod_cat prod_subcat total_sales transaction_count qty_sold;
run;

*Flagship Store;
proc sort data= flagship_qty out=flagship_sort;
by prod_cat descending qty_sold ;
run;

title"Sales By Product Categories and Sub Categories in Flagship Store";
title2 "Based On Transaction History From 2011 -2014";
proc print data = flagship_sort noobs;
	format total_sales dollar15.2;
	sum transaction_count total_sales;
run;
title2;
title;


*E-shop;
proc sort data=eshop_qty out=eshop_sort;
by descending qty_sold  ;
run;

title" Sales Performance By Product Categories and Sub Categories in E-Shop";
title2 "Based On Transaction History From 2011 -2014";
proc print data=eshop_sort;
	format total_sales dollar15.2;
	sum transaction_count total_sales;
run;
title2;
title;

*Teleshop;
proc sort data=teleshop_qty out=teleshop_sort;
by descending qty_sold ;
run;


title"Sales By Product Categories and Sub Categories in TeleShop";
title2 "Based On Transaction History From 2011 -2014";
proc print data=teleshop_sort noobs;
	format total_sales dollar15.2;
	sum transaction_count total_sales;
run;
title2;
title;

	
*MBR;
proc sort data=MBR_qty out=MBR_sort;
by descending qty_sold ;
run;

title"Sales By Product Categories and Sub Categories in MBR";
title2 "Based On Transaction History From 2011 -2014";
proc print data= MBR_sort noobs;
	format total_sales dollar15.2;
	sum transaction_count total_sales;
run;
title2;
title;


/*Analysis of Sales Performance by Product Category in each StoreType*/
*Eshop;
proc sort data=eshop_qty out=eshop_sort;
by descending qty_sold ;
run;

title"Sales Performance By Product Categories and Sub Categories in E-Shop";
title2 "Based On Transaction History From 2011 -2014";
proc print data=eshop_sort noobs;
	format total_sales dollar15.2;
	sum transaction_count total_sales;
run;
title2;
title;


ods graphics / reset width=6.4in height=4.8in imagemap;

proc sort data=WORK.TELESHOP_SORT out=_BarChartTaskData;
	by prod_cat;
run;

proc sgplot data=_BarChartTaskData;
	by prod_cat;
	vbar store_type / response=qty_sold group=prod_subcat groupdisplay=cluster;
	yaxis grid;
run;

ods graphics / reset;

proc datasets library=WORK noprint;
	delete _BarChartTaskData;
	run;


**iii) Which product is refunded the most overall?;
proc sort data= refund_trans out=refund_overall_sort;
by prod_cat;
run;

Data refund_overall;
 set refund_overall_sort;
 by prod_cat ;
 	where total_amt > 0;
	if  First.prod_cat = 1 then do
	count_refund = 0;
	end;
	
	count_refund + 1;
	if last.prod_cat;
	keep prod_cat count_refund store_type;
run;

proc sort data=refund_overall;
    by descending count_refund;
run;

title"Frequency of Refunded Products";
proc print data=refund_overall noobs;
var prod_cat count_refund;
run;
title;

ods graphics / reset width=6.4in height=4.8in imagemap;
title"Frequency of Refunded Products";
title2"Based On Transaction History from 2011-2014";
proc sgplot data=WORK.REFUND_OVERALL;
	vbar prod_cat / response=count_refund;
	yaxis grid;
run;
title2;
title;
ods graphics / reset;



**iv) which product is refunded the most in which store type?;
*Calculate the Total Loss ;
proc sort data=refund_trans out=store_refund;
	by Store_type prod_cat;
run;
Data refund_eshop refund_Teleshop refund_MBR refund_Flagship;
	set store_refund;
	by Store_type prod_cat;
	where total_amt > 0;
	if First.Store_type = 1 or First.prod_cat = 1 then do
	Refund_Freq = 0;
	total_loss=0;
	end;
	
	Refund_Freq + 1;
	total_loss + total_amt;
	
	if Store_type = 'e-Shop' and last.prod_cat=1 then output refund_eshop;
	else if Store_type = 'TeleShop' and last.prod_cat=1  then output refund_Teleshop;
	else if Store_type = 'MBR' and last.prod_cat=1 then output refund_MBR;
	else if Store_type = 'Flagship store' and last.prod_cat=1 then output refund_Flagship;
	keep Store_type prod_cat  Refund_Freq total_loss;
run;

*Count of Refunded Product in eshop;
proc sort data= refund_eshop;
by descending Refund_Freq;
run;
title "Number of refunds for each product category in E-Shop";
proc print data=refund_eshop noobs;
sum refund_freq total_loss;
format total_loss dollar15.2;
run;
title;

*Count of Refunded Product in Teleshop;
proc sort data= refund_Teleshop;
by descending Refund_Freq;
run;

title "Number of refunds for each product category in Teleshop";
proc print data=refund_Teleshop noobs;
sum refund_freq total_loss;
format total_loss dollar15.2;
run;
title;

*Count of Refunded Product in  MBR;
proc sort data= refund_MBR;
by descending Refund_Freq;
run;

title "Number of refunds for each product category in MBR";
proc print data=refund_MBR noobs;
sum refund_freq total_loss;
format total_loss dollar15.2;
run;
title;

*Count of Refunded Product in Flagship;
proc sort data= refund_Flagship;
by descending Refund_Freq;
run;

title "Number of refunds for each product category in Flagship Store";
proc print data=refund_Flagship noobs;
sum refund_freq total_loss;
format total_loss dollar15.2;
run;
title;

*Count of Refund Product by Each Store Type; 
title"Frequency of Refunded Products by Each Store Type";
title2"Based On Transaction History from 2011-2014";
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.REFUND_OVERALL;
	vbar store_type / response=count_refund group=prod_cat
		groupdisplay=cluster;
	yaxis grid;
run;
title2;
title;
ods graphics / reset;

* Identified possible efficiency;
Data duplicate_refund;
set refund_trans;
where trans_count>=3;
run;

title' posibble inefficient: duplicated refund';
proc print data=Transactions;
where transaction_id= "426787191";
run;
title;


