*** coding: utf-8 ***
*** Frank Fang ***
*** 2022/05/18 ***

*** Full Sample ***

clear all
set more off
graph drop _all
set scheme s1color 
set seed 1234


cd "/Users/frankfang/Desktop/Blockchain/Progress"

local text1_1 "Eco1 Policy1 Heter"
local text1_2 "Eco1 Policy1 Info Stdd"
local text1_3 "Eco1 Policy1 Heter Info Stdd"
local text1_4 "Eco1 Policy1 Eco1_Policy1 Heter"
local text1_5 "Eco1 Policy1 Eco1_Policy1 Info Stdd"
local text1_6 "Eco1 Policy1 Eco1_Policy1 Heter Info Stdd"
local text1_7 "Eco1 Eco1_isgreen Policy1 Policy1_isgreen Heter Heter_isgreen"
local text1_8 "Eco1 Eco1_isgreen Policy1 Policy1_isgreen Info Info_isgreen Stdd Stdd_isgreen"
local text1_9 "Eco1 Eco1_isgreen Policy1 Policy1_isgreen Heter Heter_isgreen Info Info_isgreen Stdd Stdd_isgreen"

local text2_1 "Eco2 Policy2 Heter"
local text2_2 "Eco2 Policy2 Info Stdd"
local text2_3 "Eco2 Policy2 Heter Info Stdd" 
local text2_4 "Eco2 Policy2 Eco2_Policy2 Heter"
local text2_5 "Eco2 Policy2 Eco2_Policy2 Info Stdd"
local text2_6 "Eco2 Policy2 Eco2_Policy2 Heter Info Stdd" 
local text2_7 "Eco2 Eco2_isgreen Policy2 Policy2_isgreen Heter Heter_isgreen"
local text2_8 "Eco2 Eco2_isgreen Policy2 Policy2_isgreen Info Info_isgreen Stdd Stdd_isgreen"
local text2_9 "Eco2 Eco2_isgreen Policy2 Policy2_isgreen Heter Heter_isgreen Info Info_isgreen Stdd Stdd_isgreen"

local com_control "income profit cashflow listed log_age company_type"
local bond_control1 "maturity convert interest_type bond_type volumn"
local bond_control2 "maturity convert interest_type bond_type volumn i.rate"

**# 1. Summary Statistics
use Full_0518.dta,clear

**## 1.1 Mean Difference
	tempfile table1
	tempname tb1
	postfile `tb1' str128(var) str32(A B C D E F G) using `table1'

	qui{
		foreach x in Eco1 Policy1 Eco2 Policy2 Heter Info Stdd Spread income profit cashflow listed log_age company_type maturity rating rating2 convert volumn interest_type bond_type year{
			
			mean `x'
			local mean_all = string(r(table)[1,1], "%8.2f")
			local sd_all = string(r(table)[2,1],"%8.2f")
			
			mean `x',over(isgreen)
			local mean_g = string(r(table)[1,2], "%8.2f")
			local mean_ng = string(r(table)[1,1],"%8.2f")
			local sd_g = string(r(table)[2,2],"%8.2f")
			local sd_ng = string(r(table)[2,1],"%8.2f")	
			local diff = string(r(table)[1,2] - r(table)[1,1],"%8.2f")
			
			test  _b[c.`x'@1.isgreen] =  _b[c.`x'@0.isgreen]
			if r(p)<0.01{
				local star = "***"
			}
			else if r(p)<0.05{
				local star = "**"
			}
			else if r(p)<0.1{
				local star = "*"
			}
			else{
				local star = ""
			}
			if `diff' > 0{
				local sign = "+"
			}
			else{
				local sign = ""
			}
			post `tb1' ("`x'") ("`mean_all'") ("`sd_all'") ("`mean_g'") ("`sd_g'") ("`mean_ng'") ("`sd_ng'") ("`sign'" + "`diff'" + "`star'")  
		}
		count if isgreen == 1
		local N_green = string(r(N))
		count if isgreen == 0
		local N_nongreen = string(r(N))
		count if isgreen > -1
		local N_all = string(r(N))
		post `tb1' ("N") ("`N_all'") ("") ("`N_green'") ("") ("`N_nongreen'") ("") ("")
	}

	postclose `tb1'
	preserve 
		use `table1',clear
		datatotex var A B C D E F G using "./Tables_0518/Summary.tex", hlines(7 14 22) nonames frag replace
	restore
	
**## 1.2 Correlation Matrix
	estpost corr isgreen Eco1 Policy1 Eco2 Policy2 Heter Info Stdd Spread rating rating2, matrix
	eststo cor 
	esttab cor using "./Tables_0518/Correlation.tex", replace noobs not nogaps compress nonumbers booktabs fragment nomtitles unstack collab(none) cells(b(fmt(2) star))

**# 2. Regression - 小词典(Eco1 Policy1)
**## 2.1 Y = Spread
	reghdfe Spread `text1_1' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store m1
	reghdfe Spread `text1_2' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store m2
	reghdfe Spread `text1_3' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store m3
	
	reghdfe Spread `text1_1' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store m4
	reghdfe Spread `text1_2' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store m5
	reghdfe Spread `text1_3' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store m6
	
	esttab m1 m2 m3 m4 m5 m6 using "./Tables_0518/Regress_small_Spread.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)

 
**## 2.2 Y = rating or rating2
	reghdfe rating `text1_1' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store l1	
	reghdfe rating `text1_2' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store l2
	reghdfe rating `text1_3' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store l3
	
	reghdfe rating2 `text1_1' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store l4
	reghdfe rating2 `text1_2' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store l5
	reghdfe rating2 `text1_3' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store l6
	
	esttab l1 l2 l3 l4 l5 l6 using "./Tables_0518/Regress_small_rating.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 2.3 Y:Eco1
   	reghdfe Eco1 isgreen Heter `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store x1	
	reghdfe Eco1 isgreen Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store x2
	reghdfe Eco1 isgreen Heter Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store x3
	
	reghdfe Eco1 isgreen Heter `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store x4	
	reghdfe Eco1 isgreen Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store x5
	reghdfe Eco1 isgreen Heter Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store x6
	
	esttab x1 x2 x3 x4 x5 x6 using "./Tables_0518/Regress_small_Eco1.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 2.4 Y:Policy1
   	reghdfe Policy1 isgreen Heter `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store y1	
	reghdfe Policy1 isgreen Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store y2
	reghdfe Policy1 isgreen Heter Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store y3
	
	reghdfe Policy1 isgreen Heter `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store y4	
	reghdfe Policy1 isgreen Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store y5
	reghdfe Policy1 isgreen Heter Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store y6
	
	esttab y1 y2 y3 y4 y5 y6 using "./Tables_0518/Regress_small_Policy1.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 2.5 Eco1-Policy1 交乘项
	reghdfe Spread `text1_4' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store z1
	reghdfe Spread `text1_5' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store z2
	reghdfe Spread `text1_6' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store z3
	reghdfe Spread `text1_4' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store z4
	reghdfe Spread `text1_5' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store z5
	reghdfe Spread `text1_6' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store z6
	esttab z1 z2 z3 z4 z5 z6 using "./Tables_0518/Regress_small_Spread_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
	reghdfe rating `text1_4' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store w1	
	reghdfe rating `text1_5' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store w2
	reghdfe rating `text1_6' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store w3
	reghdfe rating2 `text1_4' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store w4
	reghdfe rating2 `text1_5' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store w5
	reghdfe rating2 `text1_6' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store w6
	esttab w1 w2 w3 w4 w5 w6 using "./Tables_0518/Regress_small_rating_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 2.6. isgreen 交乘项 
	reghdfe Spread `text1_7' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store a1
	reghdfe Spread `text1_8' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store a2
	reghdfe Spread `text1_9' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store a3
	reghdfe Spread `text1_7' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store a4
	reghdfe Spread `text1_8' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store a5
	reghdfe Spread `text1_9' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store a6
	esttab a1 a2 a3 a4 a5 a6 using "./Tables_0518/Regress_small_Spread_isgreen.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)

	reghdfe rating `text1_7' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store b1	
	reghdfe rating `text1_8' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store b2
	reghdfe rating `text1_9' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store b3
	reghdfe rating2 `text1_7' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store b4
	reghdfe rating2 `text1_8' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store b5
	reghdfe rating2 `text1_9' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store b6
	esttab b1 b2 b3 b4 b5 b6 using "./Tables_0518/Regress_small_rating_isgreen.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
 
**# 3. Regression - 大词典(Eco2 Policy2)
**## 3.1 Y = Spread
	reghdfe Spread `text2_1' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store M1
	reghdfe Spread `text2_2' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store M2
	reghdfe Spread `text2_3' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store M3
	
	reghdfe Spread `text2_1' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store M4
	reghdfe Spread `text2_2' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store M5
	reghdfe Spread `text2_3' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store M6
	
	esttab M1 M2 M3 M4 M5 M6 using "./Tables_0518/Regress_big_Spread.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)

 
**## 3.2 Y = rating or rating2
	reghdfe rating `text2_1' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store L1	
	reghdfe rating `text2_2' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store L2
	reghdfe rating `text2_3' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store L3
	
	reghdfe rating2 `text2_1' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store L4
	reghdfe rating2 `text2_2' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store L5
	reghdfe rating2 `text2_3' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store L6
	
	esttab L1 L2 L3 L4 L5 L6 using "./Tables_0518/Regress_big_rating.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 3.3 Y:Eco2
   	reghdfe Eco2 isgreen Heter `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store X1	
	reghdfe Eco2 isgreen Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store X2
	reghdfe Eco2 isgreen Heter Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store X3
	
	reghdfe Eco2 isgreen Heter `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store X4	
	reghdfe Eco2 isgreen Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store X5
	reghdfe Eco2 isgreen Heter Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store X6
	
	esttab X1 X2 X3 X4 X5 X6 using "./Tables_0518/Regress_big_Eco2.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 3.4 Y:Policy2
   	reghdfe Policy2 isgreen Heter `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store Y1	
	reghdfe Policy2 isgreen Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store Y2
	reghdfe Policy2 isgreen Heter Info Stdd `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store Y3
	
	reghdfe Policy2 isgreen Heter `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store Y4	
	reghdfe Policy2 isgreen Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store Y5
	reghdfe Policy2 isgreen Heter Info Stdd `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store Y6

	esttab Y1 Y2 Y3 Y4 Y5 Y6 using "./Tables_0518/Regress_big_Policy2.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 3.5 Eco2-Policy2 交乘项
	reghdfe Spread `text2_4' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store Z1
	reghdfe Spread `text2_5' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store Z2
	reghdfe Spread `text2_6' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store Z3
	reghdfe Spread `text2_4' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store Z4
	reghdfe Spread `text2_5' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store Z5
	reghdfe Spread `text2_6' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store Z6
	esttab Z1 Z2 Z3 Z4 Z5 Z6 using "./Tables_0518/Regress_big_Spread_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
	reghdfe rating `text2_4' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store W1	
	reghdfe rating `text2_5' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store W2
	reghdfe rating `text2_6' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store W3
	reghdfe rating2 `text2_4' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store W4
	reghdfe rating2 `text2_5' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store W5
	reghdfe rating2 `text2_6' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store W6
	esttab W1 W2 W3 W4 W5 W6 using "./Tables_0518/Regress_big_rating_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
**## 3.6. isgreen 交乘项 
	reghdfe Spread `text2_7' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store A1
	reghdfe Spread `text2_8' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store A2
	reghdfe Spread `text2_9' isgreen  `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store A3
	reghdfe Spread `text2_7' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store A4
	reghdfe Spread `text2_8' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store A5
	reghdfe Spread `text2_9' isgreen  `com_control' `bond_control2',a(year province industry) vce(cluster province)
	est store A6
	esttab A1 A2 A3 A4 A5 A6 using "./Tables_0518/Regress_big_Spread_isgreen.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)

	reghdfe rating `text2_7' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store B1	
	reghdfe rating `text2_8' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store B2
	reghdfe rating `text2_9' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store B3
	reghdfe rating2 `text2_7' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store B4
	reghdfe rating2 `text2_8' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store B5
	reghdfe rating2 `text2_9' isgreen `com_control' `bond_control1',a(year province industry) vce(cluster province)
	est store B6
	esttab B1 B2 B3 B4 B5 B6 using "./Tables_0518/Regress_big_rating_isgreen.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 noconstant  drop(income profit cashflow listed log_age company_type)
 
***********************
**# 4.Green Subsample
***********************

clear all

local text1_1 "Eco1 Policy1 Heter"
local text1_2 "Eco1 Policy1 Info Stdd"
local text1_3 "Eco1 Policy1 Heter Info Stdd"
local text1_4 "Eco1 Policy1 Eco1_Policy1 Heter"
local text1_5 "Eco1 Policy1 Eco1_Policy1 Info Stdd"
local text1_6 "Eco1 Policy1 Eco1_Policy1 Heter Info Stdd"

local text2_1 "Eco2 Policy2 Heter"
local text2_2 "Eco2 Policy2 Info Stdd"
local text2_3 "Eco2 Policy2 Heter Info Stdd" 
local text2_4 "Eco2 Policy2 Eco2_Policy2 Heter"
local text2_5 "Eco2 Policy2 Eco2_Policy2 Info Stdd"
local text2_6 "Eco2 Policy2 Eco2_Policy2 Heter Info Stdd" 

local com_control "income profit cashflow listed log_age company_type"
local bond_control1 "maturity convert interest_type bond_type volumn"
local bond_control2 "maturity convert interest_type bond_type volumn i.rate"
local bond_control3 "maturity convert"
local bond_control4 "maturity convert bond_type"
local bond_control5 "maturity convert interest_type bond_type"
local bond_control6 "maturity convert interest_type bond_type i.rate"	

use Full_0518.dta,clear
	keep if isgreen == 1
	
**## 4.1 Green - 小词典(Eco1 Policy1)
** Y = Spread
	reghdfe Spread `text1_1'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store m1
	reghdfe Spread `text1_2'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store m2
	reghdfe Spread `text1_3'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store m3
	
	reghdfe Spread `text1_1'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store m4
	reghdfe Spread `text1_2'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store m5
	reghdfe Spread `text1_3'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store m6
	
	esttab m1 m2 m3 m4 m5 m6 using "./Tables_0518/Green_small_Spread.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon  drop(income profit cashflow listed log_age company_type)

 
** Y = rating or rating2
	reghdfe rating `text1_1' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store l1	
	reghdfe rating `text1_2' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store l2
	reghdfe rating `text1_3' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store l3
	
	reghdfe rating2 `text1_1' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store l4
	reghdfe rating2 `text1_2' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store l5
	reghdfe rating2 `text1_3' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store l6
	
	esttab l1 l2 l3 l4 l5 l6 using "./Tables_0518/Green_small_rating.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon  drop(income profit cashflow listed log_age company_type)
 
** Eco1-Policy1 交乘项
	reghdfe Spread `text1_4'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store z1
	reghdfe Spread `text1_5'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store z2
	reghdfe Spread `text1_6'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store z3
	reghdfe Spread `text1_4'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store z4
	reghdfe Spread `text1_5'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store z5
	reghdfe Spread `text1_6'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store z6
	esttab z1 z2 z3 z4 z5 z6 using "./Tables_0518/Green_small_Spread_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon  drop(income profit cashflow listed log_age company_type)
 
	reghdfe rating `text1_4' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store w1	
	reghdfe rating `text1_5' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store w2
	reghdfe rating `text1_6' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store w3
	reghdfe rating2 `text1_4' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store w4
	reghdfe rating2 `text1_5' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store w5
	reghdfe rating2 `text1_6' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store w6
	esttab w1 w2 w3 w4 w5 w6 using "./Tables_0518/Green_small_rating_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon  drop(income profit cashflow listed log_age company_type)
 
**## 4.2. Green - 大词典(Eco2 Policy2)
**  Y = Spread
	reghdfe Spread `text2_1'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store M1
	reghdfe Spread `text2_2'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store M2
	reghdfe Spread `text2_3'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store M3
	
	reghdfe Spread `text2_1'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store M4
	reghdfe Spread `text2_2'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store M5
	reghdfe Spread `text2_3'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store M6
	
	esttab M1 M2 M3 M4 M5 M6 using "./Tables_0518/Green_big_Spread.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon  drop(income profit cashflow listed log_age company_type)

 
** Y = rating or rating2
	reghdfe rating `text2_1' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store L1	
	reghdfe rating `text2_2' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store L2
	reghdfe rating `text2_3' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store L3
	
	reghdfe rating2 `text2_1' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store L4
	reghdfe rating2 `text2_2' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store L5
	reghdfe rating2 `text2_3' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store L6
	
	esttab L1 L2 L3 L4 L5 L6 using "./Tables_0518/Green_big_rating.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon  drop(income profit cashflow listed log_age company_type)
 
** Eco2-Policy2 交乘项
	reghdfe Spread `text2_4'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store Z1
	reghdfe Spread `text2_5'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store Z2
	reghdfe Spread `text2_6'  `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store Z3
	reghdfe Spread `text2_4'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store Z4
	reghdfe Spread `text2_5'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store Z5
	reghdfe Spread `text2_6'  `com_control' `bond_control2',a(year area industry) vce(cluster area)
	est store Z6
	esttab Z1 Z2 Z3 Z4 Z5 Z6 using "./Tables_0518/Green_big_Spread_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon drop(income profit cashflow listed log_age company_type)
 
	reghdfe rating `text2_4' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store W1	
	reghdfe rating `text2_5' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store W2
	reghdfe rating `text2_6' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store W3
	reghdfe rating2 `text2_4' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store W4
	reghdfe rating2 `text2_5' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store W5
	reghdfe rating2 `text2_6' `com_control' `bond_control1',a(year area industry) vce(cluster area)
	est store W6
	esttab W1 W2 W3 W4 W5 W6 using "./Tables_0518/Green_big_rating_EcoPolicy.tex", ///
 replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) ///
 booktabs fragment nomtitles obslast float r2 nocon  drop(income profit cashflow listed log_age company_type)


