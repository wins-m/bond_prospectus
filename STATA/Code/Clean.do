*** coding: utf-8 ***
*** Frank Fang ***
*** 2022/05/21 ***

*** Blockchain Project
*** Data Cleaning

// clear all
// set more off
// graph drop _all
// set scheme s1color 
// set seed 1234
//
//
// cd "/Users/frankfang/Desktop/Blockchain/Final/方清源Code"

**# 全样本
**# 1. 控制变量
import excel "./Data/全公司债+企业债变量.xlsx", sheet("企业债+公司债总控制变量") firstrow clear
	ren 发行总额百万元 volumn
	ren 债券期限 maturity
	ren 发行时债项评级 rating
	ren 利率类型 interest_type
	ren 是否含权 convert
	ren Wind债券一级分类 bond_type
	ren 是否上市公司 listed
	ren 年份 year
	ren 地区 province
	ren 发行主体属性 company_type
	ren 营业总收入TTM单位百万元人民币 income
	ren 净利润TTM单位百万元人民币 profit
	ren 现金净流量单位百万元人民币 cashflow
	ren 企业存续年限 age	
	ren 证券代码 code
	gen log_age = log(age)
	label var log_age 发行主体存续年限自然对数

	order code name ipo_date income profit cashflow listed log_age company_type maturity rating convert volumn interest_type maturity
	
	foreach x in income profit cashflow{
		replace `x' = . if `x' == 0
		replace `x' = `x'/1000
	}
	label var income 发行主体营业总收入（十亿元）
	label var profit  发行主体净利润（十亿元）
	label var cashflow  发行主体现金净流量（十亿元）
	label var listed  发行主体是否上市公司
	
	replace company_type = "0" if company_type == "民营企业"
	replace company_type = "1" if company_type == "地方国有企业"
	replace company_type = "2" if company_type == "中央国有企业"
	replace company_type = "3" if company_type != "0" &  company_type != "1" & company_type != "2"
	destring company_type,replace
	label define company_type 0 "民营企业" 1 "地方国有企业" 2 "中央国有企业" 3 "其他"
	label values company_type company_type
	
	drop if rating == "-"
	label var rating "债券发行时评级"
	replace rating = "0" if rating == "A-1"
	replace rating = "1" if rating == "AA-"
	replace rating = "2" if rating == "AA"
	replace rating = "3" if rating == "AA+"
	replace rating = "4" if rating == "AAA"
	destring rating,replace
	label define rating 0 "A-1" 1 "AA-" 2 "AA" 3 "AA+" 4 "AAA"
	label values rating rating
	
	label var convert "债券是否属于含权债券"
	replace convert = "0" if convert == "否"
	replace convert = "1" if convert == "是"
	destring convert, replace
	
	label var volumn "债券发行总额（百万元）自然对数"
	replace volumn = log(volumn)
	
	label var interest_type "债券利率类型"
	replace interest_type = "0" if interest_type == "固定利率"
	replace interest_type = "1" if interest_type == "累进利率"
	replace interest_type = "2" if interest_type == "浮动利率"
	destring interest_type,replace
	label define interest_type 0 "固定利率" 1 "累进利率" 2 "浮动利率"
	label values interest_type interest_type
	
	label var bond_type "债券属性"
	replace bond_type = "0" if bond_type == "企业债"
	replace bond_type = "1" if bond_type == "公司债"
	destring bond_type,replace
	label define bond_type 0 "企业债" 1 "公司债"
	label values bond_type bond_type
	
	drop if income == .
	drop if profit == .
	drop if cashflow == .
	drop if log_age == .
	
	ren 所属Wind行业名称 ind1
	ren 所属证监会行业名称 ind2
	gen industry = .
	replace industry = 0 if ind1 == "公用事业"
	replace industry = 1 if ind1 == "工业" & (ind2 == "0"|ind2 == "批发和零售业"|ind2 == "综合"|ind2 == "水利、环境和公共设施管理业")
	replace industry = 2 if ind1 == "工业" & ind2 == "交通运输、仓储和邮政业" & industry==.
	replace industry = 3 if ind2 == "制造业" & industry== .
	replace industry = 4 if ind2 == "建筑业" & industry== .
	replace industry = 0 if industry == .	
	label define industry 0 "其他" 1 "其他工业" 2 "交通运输业" 3 "制造业" 4 "建筑业"
	label values industry industry
	label var industry 发行主体所属行业
	
	destring year,replace
	
	label var year 债券发行年份
	label var province 发行主体所属省份
	order year industry province,a(bond_type)
	
	gen area = .
	drop if province == "香港特别行政区"
	replace area = 1 if province == "北京"|province == "天津"|province == "河北省"|province == "辽宁省"|province == "上海"|province == "江苏省"|province == "浙江省"|province == "福建省"|province == "山东省"|province == "广东省"|province == "广西壮族自治区"|province == "海南省"
	replace area = 2 if province == "山西省"|province == "内蒙古自治区"|province == "吉林省"|province == "黑龙江省"|province == "安徽省"|province == "江西省"|province == "河南省"|province == "湖北省"|province == "湖南省"
	replace area = 3 if area == .
	label define area 1 "东部" 2 "中部" 3 "西部"
	label values area area
	label var area "发行主体所属地区"

	drop name ipo_date Wind债券二级分类 中债债券一级分类 中债债券二级分类 债务主体 有关上市公司代码 ind1 ind2 age
save ./Data/Full_0521_control.dta,replace
	
**# 2. 因变量
import excel "./Data/全公司债+企业债变量.xlsx", sheet("企业债+公司债总利差") firstrow clear
	drop name ipo_date date_int 发行时票面利率 发行时SHIBOR_1Y
	label var  Spread 债券利差
save ./Data/Full_0521_Y.dta,replace

**# 3.自变量+merge
import delimited "./Data/target_fvalue(4425, 27).csv", clear
	drop url veclen cnum wnum0 wnum1 wnum2 snum title type inst codes date url1 filename id 
	order code name ipo_date isgreen eco policy eco1 policy1 heter info90 stdd90
	
	replace isgreen = "0" if isgreen == "False"
	replace isgreen = "1" if isgreen == "True"
	destring isgreen,replace
	label var isgreen 是否是绿色债券
	
	ren eco Eco1
	ren eco1 Eco2
	ren policy Policy1
	ren policy1 Policy2
	ren heter90 Heter
	ren info90 Info
	ren stdd90 Stdd
	
	drop if Heter == .
	drop if Info == .
	drop if Stdd == .
	
	drop if docnum90<30
	drop docnum
	
	merge 1:1 code using ./Data/Full_0521_Y.dta
	drop if _m!=3
	drop _m
	
	merge 1:1 code using ./Data/Full_0521_control.dta
	drop if _m!=3
	drop _m
	
	label var Eco1 环境保护相关度1
	label var Eco2 环境保护相关度
	label var Policy1 政策响应力度1
	label var Policy2 政策响应力度
	label var Heter 特质性信息含量
	label var Info 特殊性指数
	label var Stdd 一般性指数
	

	* 后续更新
	drop Eco1 Policy1 area
	replace Heter = -1*Heter
	ren Eco2 Eco
	ren Policy2 Policy
	order Stdd,b(Info)

	ren Spread Spreads
	ren isgreen Green
	ren income profit cashflow listed log_age company_type maturity rating convert volumn interest_type bond_type year industry province,proper
	
	gen Eco_Policy = Eco * Policy
	gen Eco_Green = Eco * Green
	gen Policy_Green = Policy * Green 
	gen Heter_Green = Heter * Green
	gen Stdd_Green = Stdd * Green
	gen Info_Green = Info * Green
	
	ren Interest_Type Int_Type
	ren Company_Type Com_Type
	
	order code name ipo_date ///
	Eco Eco_Green Policy Policy_Green Eco_Policy ///
	Heter Heter_Green Stdd Stdd_Green Info Info_Green ///
	Spreads ///
	Income Profit Cashflow Listed Log_Age Com_Type ///
	Green Int_Type Bond_Type Maturity Convert Volumn Rating ///
	Year Province Industry
	
save Full_0521.dta,replace
	
	
	
	
	
	
	
	
	
	
	
