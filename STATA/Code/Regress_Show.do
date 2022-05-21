*** coding: utf-8 ***
*** Frank Fang ***
*** 2022/05/18 ***

*** Full Sample ***

// clear all
// set more off
// graph drop _all
// set scheme s1color 
// set seed 1234
//
//
// cd "/Users/frankfang/Desktop/Blockchain/Final/方清源Code"

local text2_1 "Eco Policy Heter"
local text2_2 "Eco Policy Stdd Info"


local text2_7 "Eco Eco_Green Policy Policy_Green Heter Heter_Green"
local text2_8 "Eco Eco_Green Policy Policy_Green Info Info_Green Stdd Stdd_Green"

local com_control "Income Profit Cashflow Listed Log_Age Com_Type"
local bond_control2 "Int_Type Bond_Type Maturity Convert Volumn Rating"

**# 1. Summary Statistics
use Full_0521.dta,clear

*## 1.1 Mean Difference
	tempfile table1
	tempname tb1
	postfile `tb1' str128(var) str32(A B C D E F G) using `table1'

	qui{
		foreach x in Eco Policy Heter Stdd Info Spreads Income Profit Cashflow Listed Log_Age Com_Type Int_Type Bond_Type Maturity Convert Volumn Rating{
			
			mean `x'
			local mean_all = string(r(table)[1,1], "%8.2f")
			local sd_all = string(r(table)[2,1], "%8.2f")
			
			sum `x'
			local min_all = string(r(min),"%8.2f")
			local max_all = string(r(max),"%8.2f")
		
			mean `x',over(Green)
			local mean_g = string(r(table)[1,2], "%8.2f")
			local mean_ng = string(r(table)[1,1],"%8.2f")
			local diff = string(r(table)[1,2] - r(table)[1,1],"%8.2f")
			
			test  _b[c.`x'@1.Green] =  _b[c.`x'@0.Green]
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
			
			post `tb1' ("`x'") ("`mean_all'") ("`sd_all'") ("`min_all'") ("`max_all'") ("`mean_g'") ("`mean_ng'") ("`diff'" + "`star'")  
		}
		count if Green == 1
		local N_green = string(r(N))
		count if Green == 0
		local N_nongreen = string(r(N))
		count if Green > -1
		local N_all = string(r(N))
		post `tb1' ("N") ("`N_all'") ("") ("") ("") ("`N_green'") ("`N_nongreen'") ("")
	}

	postclose `tb1'
	preserve 
		use `table1',clear
		datatotex var A B C D E F G using "./Tables_0521/Summary.tex", hlines(5 6 12 18) nonames frag replace
	restore
	
**## 1.2 Correlation Matrix
	estpost corr Green Eco Policy Heter Stdd Info Spreads, matrix
	eststo cor 
	esttab cor using "./Tables_0521/Correlation.tex", replace noobs not nogaps compress nonumbers booktabs fragment nomtitles unstack collab(none) cells(b(fmt(2) star))
	
**## 1.3 Histogram
	twoway (hist Spreads if Green == 1, fcolor(ltblue%50) width(0.2) lcolor("black") lwidth(vvvthin)) ///
 (hist Spreads if Green == 0, fcolor(orange_red%50) width(0.2) lcolor("black") lwidth(vvvthin)), ///
  ylabel(0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3" 0.4 "0.4" 0.5 "0.5" 0.6 "0.6" 0.7 "0.7",angle(0)) xlabel(-1(1)7) legend(rows(1) order(1 "Green Bond" 2 "Non-Green Bond")) ytitle("Density: Spreads")
graph export "./Tables_0521/Density_Spreads.png",replace

	twoway (hist Eco if Green == 1 & Eco <= 30, fcolor(ltblue%50) width(1) lcolor("black") lwidth(vvvthin)) ///
 (hist Eco if Green == 0 & Eco <= 30, fcolor(orange_red%50) width(1) lcolor("black") lwidth(vvvthin)), ///
  ylabel(0 "0" 0.05 "0.05" 0.1 "0.1" 0.15 "0.15" 0.2 "0.2" 0.25 "0.25" 0.3 "0.3" 0.35 "0.35" 0.4 "0.4",angle(0)) xlabel(0(5)30) legend(rows(1) order(1 "Green Bond" 2 "Non-Green Bond")) ytitle("Density: Eco")
graph export "./Tables_0521/Density_Eco.png",replace

	twoway (hist Policy if Green == 1 & Policy <=40, fcolor(ltblue%50) width(1) lcolor("black") lwidth(vvvthin)) ///
 (hist Policy if Green == 0 & Policy <= 40, fcolor(orange_red%50) width(1) lcolor("black") lwidth(vvvthin)), ///
  ylabel(0 "0" 0.02 "0.02" 0.04 "0.04" 0.06 "0.06" 0.08 "0.08" 0.1 "0.10" 0.12 "0.12",angle(0)) xlabel(5(5)40) legend(rows(1) order(1 "Green Bond" 2 "Non-Green Bond")) ytitle("Density: Policy")
graph export "./Tables_0521/Density_Policy.png",replace

	twoway (hist Heter if Green == 1 & Heter <=2, fcolor(ltblue%50) width(0.2) lcolor("black") lwidth(vvvthin)) ///
 (hist Heter if Green == 0 & Heter <=2, fcolor(orange_red%50) width(0.2) lcolor("black") lwidth(vvvthin)), ///
  ylabel(0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3" 0.4 "0.4" 0.5 "0.5" 0.6 "0.6" 0.7 "0.7" 0.8 "0.8" 0.9 "0.9",angle(0)) xlabel(-3(1)2) legend(rows(1) order(1 "Green Bond" 2 "Non-Green Bond")) ytitle("Density: Heter")
graph export "./Tables_0521/Density_Heter.png",replace

 
**# 2. Regression - 大词典(Eco Policy)
**## 2.1 Y = Spreads
	reghdfe Spreads `text2_1' Green  `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store M4
	reghdfe Spreads `text2_2' Green  `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store M5
	
	** Green 交乘项 
	reghdfe Spreads `text2_7' Green  `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store A4
	reghdfe Spreads `text2_8' Green  `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store A5

	esttab M4 M5 A4 A5 using "./Tables_0521/Regress_Spreads.tex", replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) booktabs fragment nomtitles obslast float r2 noconstant drop(Income Profit Cashflow Listed Log_Age Com_Type _cons) order(Green Eco Policy Heter Stdd Info Eco_Green Policy_Green Heter_Green Stdd_Green Info_Green) substitute("_" "\_" "Eco\_Green" "\midrule Eco\_Green" "Int\_Type" "\midrule Int\_Type" )

 
**## 2.2 Y:Eco & Y:Policy
	reghdfe Eco Green Heter `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store X4	
	reghdfe Eco Green Stdd Info `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store X5
	
	reghdfe Policy Green Heter `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store Y4	
	reghdfe Policy Green Stdd Info `com_control' `bond_control2',a(Year Province Industry) vce(cluster Province)
	est store Y5

	esttab X4 X5 Y4 Y5 using "./Tables_0521/Regress_EcoPolicy.tex", replace nogaps compress b(%20.2f) se(%7.2f) star(* 0.10 ** 0.05 *** 0.01) booktabs fragment nomtitles obslast float r2 noconstant drop(Income Profit Cashflow Listed Log_Age Com_Type _cons) order(Green Heter Stdd Info) substitute("_" "\_" "Int\_Type" "\midrule Int\_Type" )


 
 