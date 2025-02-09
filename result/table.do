***导入数据源
********************************************************************************
*描述性统计及回归
*作者: 何克润
*更新时间：2024年9月2日
*
********************************************************************************
clear all
***1. 数据导入
use "../data/data.dta",clear


*** 2. 样本筛选
** 系统冗余
drop if hchild == 0 | kalive == "No" // 删除没有健在子女的家庭 
drop if kblood == 4 // 删除kblood为Not our child 
keep if hinw == 1  // 仅保留当前受访的家庭受访者 
** 选择子样本
keep if kage>=18 & kage <45 // 保留子女年龄在18到44岁 【已检查】
keep if hage_min>= 45 & hage_max <=75 // 保留祖父母45-75岁 【已检查】
keep if kkid16n > 0 & kkid16n <=5 // 保留0-5个16岁以下孩子的样本 【已检查】
drop if rnhmliv == 1 | snhmliv == 1  // 删除长期居住在机构的家庭 【已检查】
drop if hadlabn_min > 0 & !missing(hadlabn_min) // 排除全部ADL的家庭 【已检查】
drop if klivedis == 3 // 排除子女居住在国外 【已检查】
drop if missing(hgkcare) | missing(hgkcarek) // 删除没有隔代抚养信息 【已检查】
drop if missing(reduc10)  // 删除没有教育信息的家庭受访者【已检查】
drop if missing(keduc10) // 删除没有教育信息的子女 【已检查】

** 观测值
**生成ID 
egen obsid = group(householdID childID year)
label variable obsid "观测值ID"

egen kid = group(householdID childID)
label variable kid "子女独特ID"

codebook obsid, compact  // 42203观测值
codebook householdID, compact // 9101祖辈家庭
codebook kid, compact // 18617成年子女

*** 3. 设置变量
replace hedugap3_min_s = hedugap3_min if missing(hedugap3_min_s)
tostring childID, gen(childIDs)

tab heduc3_min, gen(heduc3_min_i_)

egen hbyear_min = rowmin(rbyear sbyear)
label variable hbyear_min "受访家庭最小的出生年份"

egen hbyear_max = rowmax(rbyear sbyear)
label variable hbyear_max "受访家庭最大的出生年份"

gen kispart = 0
label variable kispart "是否为部分处理组"
replace kispart = 1 if kcel >0 & kcel<1


global depvar "hgkcarek"     // 被解释变量： 是否年轻父母收到来自其父母的儿童照料
global keyvar_base "hedugap3_min" // 核心解释变量：是否年轻父母的三分类教育高于最低教育的祖辈 
global pcontrols "hfemale hage_max hmstat2 hchild hadlabn_max" // 是否有祖父母、祖辈最高年龄、祖辈是否已婚、祖辈健在子女数、祖辈Katz ADL最高分
global kcontrols "kgender kage kmstat2 kkid16n kcoresid klivedis2 " // 父辈是否女性、父辈年龄、父辈是否已婚、父辈16岁以下子女数、父辈是否与祖辈共住、父辈是否与祖辈居住在同一或相邻公寓
global acontrols "hretire1  prov_kidgarn_ln kbprov_fertfine"  // 额外控制变量：是否至少一个祖辈退休、省份幼儿园数（自然对数值）、出生省份1979-2000年平均超生罚款率（年度家庭收入的倍数）
global iv "kcel_ins" // IV： 年轻父辈暴露到CSLs * 1982年16-18岁未完成9年教育的比例
global iv2 "kcel" // 额外IV: 年轻父辈暴露到CSLs
global mek "hincgap2" // 机制： 是否年轻父辈家庭劳动收入> 祖辈家庭劳动收入

global keyvars_robust "hedugap3_max hedugap3_fem hedugap3_min_s hedugap6_min hedugap2_min" // 核心解释变量稳健： 祖辈三分类最高、 祖辈三分类女性优先、父辈三分类配偶教育、祖辈6分类最低、祖辈2分类最低
**显示选项
global star_opts "star(* 0.10 ** 0.05 *** 0.01) starsps"
global stat_opts "b(%9.3f) se(%9.3f) scalars(N r2(%9.3f) widstat(%9.2f) jp(%9.3f) )"

*** 4. 描述性统计表 表1
dtable $depvar $pcontrols $kcontrols $iv $acontrols  $iv2 $mek, ///
 nformat(%9.2f mean sd) ///
 by($keyvar_base) export(table.docx,  replace) ///
 title("变量描述性统计")

tab hiscel
 
** CSL数据 表2

*** 5. 基准回归表 

** CSLs对教育的影响 表3 
reghdfe keduc2_ls $iv $pcontrols $kcontrols , absorb(provID year) cluster(provID)
est store m1

reghdfe $keyvar_base $iv $pcontrols $kcontrols, absorb(provID year) cluster(provID)
est store m2


reg2docx m1 m2  using table.docx, append $star_opts $stat_opts ///
	title("基准结果：CSLs对教育的影响")

drop _est*


** 代际教育差距对隔代照料 表4
reghdfe $depvar $keyvar_base $pcontrols $kcontrols, absorb(provID year) cluster(provID)
est store m1

ivreg2 $depvar $pcontrols $kcontrols i.provID i.year ($keyvar_base = $iv) , cluster(provID) partial(i.provID)
est store m2 

reg2docx m1 m2 using table.docx, append $star_opts $stat_opts ///
	title("基准结果: 代际教育差距对隔代照料的影响")

drop _est*


*** 6. 稳健性检验
// 表5 Plausibly IV推断
** 获取gamma的参考值
quietly reghdfe $depvar $keyvar_base $iv $pcontrols $kcontrols, absorb(provID year) cluster(provID)

est store m1 

reg2docx m1 using table.docx, append $star_opts $stat_opts ///
	title("真实的回归方程")

local ivb = _b[$iv]
local ivse = _se[$iv]

drop _est*

display "IV的系数：`ivb'" 
display "IV的标准误: `ivse'"
// UCI方法

foreach i of numlist 0.15(-0.05)0.05 {
	quietly plausexog uci $depvar $pcontrols $kcontrols i.provID i.year ($keyvar_base = $iv) , vce(cluster provID) gmin(-`i') gmax(`i')
	local uci_lb = e(lb_$keyvar_base)
	local uci_ub = e(ub_$keyvar_base)
	local pos_pr = `uci_ub' / (`uci_ub'-`uci_lb') 
	display "UCI-[-`i',`i']95%置信区间:[`uci_lb',`uci_ub']"
	display "UCI-[-`i',`i']95%置信区间正效应比例:`pos_pr'"
	
	quietly plausexog uci $depvar $pcontrols $kcontrols i.provID i.year ($keyvar_base = $iv) , vce(cluster provID) gmin(0) gmax(`i')
	local uci_lb = e(lb_$keyvar_base)
	local uci_ub = e(ub_$keyvar_base)
	local pos_pr = `uci_ub' / (`uci_ub'-`uci_lb') 
	display "UCI-[0,`i']95%置信区间:[`uci_lb',`uci_ub']"
	display "UCI-[0,`i']95%置信区间正效应比例:`pos_pr'"
}

** LTZ方法

tab provID, gen(_provID)
tab year, gen(_year)

foreach mu of numlist 0(0.05)0.10 {
	foreach sd of numlist 0.05 0.10 0.15 {
		local omega = `sd'*`sd'
		quietly plausexog ltz $depvar $pcontrols $kcontrols _provID1-_provID27 _year1-_year3  ($keyvar_base = $iv) , vce(cluster provID) mu(`mu') omega(`omega')
		local ltz_lb  = e(lb_$keyvar_base)
		local ltz_ub  = e(ub_$keyvar_base)
		local ltz_b = _b[$keyvar_base]
		local pos_pr = `ltz_ub' / (`ltz_ub'-`ltz_lb') 
		display "UCI-N(`mu',`sd'^2)系数:`ltz_b'"
		display "UCI-N(`mu',`sd'^2)95%置信区间:[`ltz_lb',`ltz_ub']"
		display "UCI-N(`mu',`sd'^2)95%置信区间正效应比例:`pos_pr'"
	}  
}

// 表A1： 替换核心解释变量


foreach v of global keyvars_robust {
	reghdfe $depvar `v' $pcontrols $kcontrols, absorb(provID year) cluster(provID)
	est store m1
	ivreg2 $depvar  $pcontrols $kcontrols i.provID i.year (`v' = $iv), cluster(provID) partial(i.provID) first
	est store m2
	reg2docx m1 m2 using table.docx, append $star_opts $stat_opts  ///
	title("替换核心解释变量："`v'"")
	drop _est*
	
}



// 表A2： 额外控制变量
*** 退休
foreach acv of global acontrols {
	reghdfe $depvar $keyvar_base $pcontrols $kcontrols `acv', absorb(provID year) cluster(provID)
	est store m1

	ivreg2 $depvar $pcontrols $kcontrols  i.provID i.year `acv' ($keyvar_base = $iv), cluster(provID) partial(i.provID)
	est store m2
	
	reg2docx m1 m2  using table.docx, append $star_opts $stat_opts ///
	title("稳健性检验:额外控制变量-`acv'")

	drop _est*
} 

// 表A3： 样本选择
global subconds "(kbyear>=1970&kbyear<=1996) (hbyear_min>=1945&hbyear_max<=1970) (kispart!=1)"

foreach cd of global subconds {
	reghdfe $depvar $keyvar_base $pcontrols $kcontrols if `cd', absorb(provID year) cluster(provID)
	est store m1

	ivreg2 $depvar  $pcontrols $kcontrols  i.provID i.year ($keyvar_base = $iv) if `cd', cluster(provID) partial(i.provID)
	est store m2

	reg2docx m1 m2  using table.docx, append $star_opts $stat_opts ///
		title("稳健性检验:样本选择-if `cd'")
		
	drop _est*
}

// 表A4： 其他的IV


ivreg2 $depvar $pcontrols $kcontrols i.provID i.year ($keyvar_base = $iv2),  partial(i.provID) cluster(provID)
est store m1

ivreg2 $depvar $pcontrols $kcontrols i.provID i.year ($keyvar_base = $iv2 $iv),  partial(i.provID) cluster(provID)
est store m2


reg2docx m1 m2 using table.docx, append $star_opts $stat_opts ///
	title("稳健性检验：其他IV")

drop _est*

// 表A5 估计方法和聚类

probit $depvar $keyvar_base $pcontrols $kcontrols  i.provID i.year, vce(cluster provID)
est store m1
ivprobit $depvar  $pcontrols $kcontrols i.provID i.year ($keyvar_base = $iv), vce(cluster provID)
est store m2

reg2docx m1 m2 using table.docx, append $star_opts $stat_opts ///
title("替换估计方法:Probit / IVProbit")

drop _est*

// 聚类到城市
reghdfe $depvar $keyvar_base $pcontrols $kcontrols, absorb(provID year) cluster(cityID)
est store m1

ivreg2 $depvar $pcontrols $kcontrols i.provID i.year ($keyvar_base = $iv), cluster(cityID)  partial(i.provID)
est store m2

// 异方差稳健标准误
reghdfe $depvar $keyvar_base $pcontrols $kcontrols, absorb(provID year) vce(robust)
est store m3

ivreg2 $depvar $pcontrols $kcontrols  i.provID i.year ($keyvar_base = $iv),  partial(i.provID) robust
est store m4


reg2docx m1 m2 m3 m4  using table.docx, append $star_opts $stat_opts ///
	title("稳健性检验：城市聚类或稳健标准误")

drop _est*

