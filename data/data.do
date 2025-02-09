********************************************************************************
*题目: 
*更新时间: 2024年9月2日
*描述:  创建隔代抚养研究的数据集
********************************************************************************

*** 1.导入CHARLS_main数据
use "CHARLS/_export/CHARLS_main.dta",clear // 全部的孩子信息
destring childID,replace
encode prov_name,gen(provID)
label variable provID "省份ID"
encode city_name, gen(cityID)
label variable cityID "城市ID"

***2. 匹配其他子模块

merge m:1 householdID childID using "CHARLS/extra/子女是否出生在调查省份.dta",nogen keep(master match)
merge m:1 prov_name year using "中国教育统计年鉴/省份幼儿园数2000_2021.dta", nogen keep(master match)  // 调查省份 和 调查年份的幼儿园数 （当前状态）

** 定义子女出生省份
gen kbprov_name = ""
label variable kbprov_name "子女出生省份名"
replace kbprov_name = prov_name if kbisprov == 1

encode kbprov_name, gen(kbprovID)
label variable kbprovID "子女出生省份ID"

merge m:1 kbprov_name using "CSL/中国1986年义务教育法.dta", nogen keep(master match)
merge m:1 kbprov_name kbyear using "OCP/省份超生罚款1979_2000.dta",nogen keep(master match)
replace prov_fertfine = 0 if kbyear <1979 


rename (prov_celyear prov_noedu9 prov_fertfiney prov_fertfiner prov_fertfine prov_ename) (kbprov_celyear kbprov_noedu9 kbprov_fertfiney kbprov_fertfiner kbprov_fertfine kbprov_ename)

label variable kbprov_celyear "出生省份义务教育法实施年份"
label variable kbprov_ename "出生省份英文名"
label variable kbprov_noedu9 "出生省份1982年未完成初中教育的16-18岁人口比例(1982年人口普查1%抽样调查)"
label variable kbprov_fertfiney "出生时出生省份的超生罚款年数"
label variable kbprov_fertfiner "出生时出生省份的超生罚款占家庭年收入比例"
label variable kbprov_fertfine "出生时出生省份的超生罚款率(家庭年收入的倍数)"

*** 3. 修改变量值
replace kliveur = hliveur if year == 2011 & missing(kliveur)
replace kage = year - kbyear


*** 4. 定义变量

** 年轻父母是否与祖辈居住在同一或相邻院子（公寓）
recode klivedis (0 1 = 1) (2 3 = 0),gen(klivedis2)
label variable klivedis2 "子女是否长期居住在受访家庭同一或相邻院子(公寓)"
label define klivedis2 0 "0 否" 1 "1 是"
label values klivedis2 klivedis2


** 祖辈退休状态
recode rlabstat (6=1) (0/5 7=0),gen(rretire)
label variable rretire "受访者是否已退休"
recode slabstat (6=1) (0/5 7=0),gen(sretire)
label variable sretire "配偶是否已退休"

egen hretire1 = rowmax(rretire sretire)
label variable hretire1 "祖辈或其配偶是否退休"
label define hretire1 0 "No" 1 "Yes"
label values hretire1 hretire1

egen hretire2 = rowmin(rretire sretire)
label variable hretire2 "祖辈及其配偶是否均退休"
label define hretire2 0 "No" 1 "Yes"
label values hretire2 hretire2





** 是否共住
recode klivedis (0=1) (1/3 = 0),gen(kcoresid)
label variable kcoresid "子女是否与受访居户共住"
label define kcoresid 0 "No" 1 "Yes"
label values kcoresid kcoresid

** 祖辈的自评健康状况
recode rshlta (0/1=1) (2/4=0) ,gen(rshlta_g)
label variable rshlta "受访者是否自评健康为good, very good"
recode sshlta (0/1=1) (2/4=0) ,gen(sshlta_g)
label variable sshlta "配偶是否自评健康为good, very good"
egen hshlta2 = rowmax(rshlta_g sshlta_g)
label variable hshlta2 "至少有一个祖辈自评健康为good,very good"

** 是否至少有一项ADL失能
gen radlab2 = (radlab6c>0) 
label variable radlab2 "受访者是否至少有一项ADL失能"
replace radlab2 = . if missing(radlab6c)

gen sadlab2 = (sadlab6c>0) 
label variable sadlab2 "配偶是否至少有一项ADL失能"
replace sadlab2 = . if missing(sadlab6c)

egen hadlab2 = rowmax(radlab2 sadlab2)
label variable hadlab2 "受访家庭是否至少有一项ADL失能"

egen hadlabn_max = rowmax(radlab6c sadlab6c)
label variable hadlabn_max "受访家庭中ADL最大项数"

egen hadlabn_min = rowmin(radlab6c sadlab6c)
label variable hadlabn_min "受访家庭中ADL最小项数"


***隔代抚养指标
gen hgkcarehr_ln = ln(hgkcarehr) 
label variable hgkcarehr_ln "家庭受访者及其配偶照看来自子女ID家的孙子女的小时数/年(自然对数值)"

***2分类教育系统
recode keduc3 (2=1) (0/1=0),gen(keduc2) 
label variable keduc2 "子女是否接受高等教育"
recode reduc3 (2=1) (0/1=0),gen(reduc2) 
label variable reduc2 "受访者是否接受高等教育"
recode seduc3 (2=1) (0/1=0),gen(seduc2) 
label variable seduc2 "配偶是否接受高等教育"

gen heduc2_min = reduc2
replace heduc2_min = seduc2 if !missing(seduc2) & seduc2 < reduc2
label variable heduc2_min "受访家庭的受教育程度(2分类-最低)"



***代际教育差异指标
*** 6分类教育系统
gen heduc6_min = reduc6 
replace heduc6_min = seduc6 if !missing(seduc6) & seduc6 < reduc6
label variable heduc6_min "受访家庭的受教育程度(6分类-最低)"


 
gen heduc6_max = reduc6 
replace heduc6_max = seduc6 if !missing(seduc6) & seduc6 > reduc6
label variable heduc6_max "受访家庭的受教育程度(6分类-最高)"

gen heduc6_fem = reduc6 
replace heduc6_fem = seduc6 if !missing(seduc6) & sgender == 1
label variable heduc6_fem "受访家庭的受教育程度(6分类-女性优先)"

*** 3分类教育系统
gen heduc3_min = reduc3 
replace heduc3_min = seduc3 if !missing(seduc3) & seduc3 < reduc3
label variable heduc3_min "受访家庭的受教育程度(3分类-最低)"
 
gen heduc3_max = reduc3 
replace heduc3_max = seduc3 if !missing(seduc3) & seduc3 > reduc3
label variable heduc3_max "受访家庭的受教育程度(3分类-最高)"

gen heduc3_fem = reduc3 
replace heduc3_fem = seduc3 if !missing(seduc3) & sgender == 1
label variable heduc3_fem "受访家庭的受教育程度(3分类-女性优先)"

*** 是否完成初中教育
recode keduc10 (0/3 =0) (4/9=1), gen(keduc2_ls)
label variable keduc2_ls "子女是否完成Lower Secondary 教育"


*** 代际教育差异
gen hedugap2_min = (keduc2>heduc2_min)
replace hedugap2_min = . if missing(keduc2) | missing(heduc2_min)
label variable hedugap2_min "是否子女的2分类受教育程度高于其父辈的最低受教育程度"

gen hedugap6_min = (keduc6>heduc6_min)
replace hedugap6_min = . if missing(keduc6) | missing(heduc6_min)
label variable hedugap6_min "是否子女的6分类受教育程度高于其父辈的最低受教育程度"

gen hedugap6_max = (keduc6>heduc6_max)
replace hedugap6_max = . if missing(keduc6) | missing(heduc6_max)
label variable hedugap6_max "是否子女的6分类受教育程度高于其父辈的最高受教育程度"

gen hedugap6_fem = (keduc6>heduc6_fem)
replace hedugap6_fem = . if missing(keduc6) | missing(heduc6_fem)
label variable hedugap6_fem "是否子女的6分类受教育程度高于其父辈的女性优先受教育程度"


***3分类系统

gen hedugap3_min = (keduc3>heduc3_min)
replace hedugap3_min = . if missing(keduc3) | missing(heduc3_min)
label variable hedugap3_min "是否子女的3分类受教育程度高于其父辈的最低受教育程度"

gen hedugap3_max = (keduc3>heduc3_max)
replace hedugap3_max = . if missing(keduc3) | missing(heduc3_max)
label variable hedugap3_max "是否子女的3分类受教育程度高于其父辈的最高受教育程度"

gen hedugap3_fem = (keduc3>heduc3_fem)
replace hedugap3_fem = . if missing(keduc3) | missing(heduc3_fem)
label variable hedugap3_fem "是否子女的3分类受教育程度高于其父辈的女性优先受教育程度"

* 为代际教育差异变量设置值标签
label define hedugap_label 1 "Child lead" 0 "Child not lead"
label values hedugap3_min hedugap_label
label values hedugap3_max hedugap_label
label values hedugap3_fem hedugap_label
label values hedugap6_min hedugap_label
label values hedugap6_max hedugap_label
label values hedugap6_fem hedugap_label



***工具变量
*** 子女的出生地

gen kcsl_gap = kbprov_celyear - kbyear
label variable kcsl_gap "义务教育法实施年份与子女出生年份的年数差"

gen kcel =.
label variable kcel "子女暴露到1986年义务教育法的资格"
replace kcel = 0 if kcsl_gap >=16 & !missing(kcsl_gap)
replace kcel = 1 if kcsl_gap <=6
replace kcel = 1.6-0.1*kcsl_gap if kcsl_gap>6 & kcsl_gap<16


gen kcel_ins = kcel*kbprov_noedu9
label variable kcel_ins "义务教育法实施对子女的冲击强度(kcel*kbprov_noedu9)"

**代际间收入差距
gen hinc_c = . 
replace hinc_c = 0 if hinc == 0
replace hinc_c = 1 if hinc>0 & hinc<2000
replace hinc_c = 2 if hinc>=2000 & hinc<5000
replace hinc_c = 3 if hinc>=5000 & hinc<10000
replace hinc_c = 4 if hinc>=10000 & hinc<20000
replace hinc_c = 5 if hinc>=20000 & hinc<50000
replace hinc_c = 6 if hinc>=50000 & hinc<100000
replace hinc_c = 7 if hinc>=100000 & hinc<150000
replace hinc_c = 8 if hinc>=150000 & hinc<200000
replace hinc_c = 9 if hinc>=200000 & hinc<300000
replace hinc_c = 10 if hinc>=300000 & !missing(hinc)


label variable hinc_c "老年受访家庭总收入类别"

***兄弟姐妹是否收到祖辈提供的儿童照料
egen hgkcarekn = total(hgkcarek), by(household year)
label variable hgkcarekn "受访家庭为多少个子女照顾过孩子"

gen hgkcarek_sib = 0
label variable hgkcarek_sib "祖辈是否为该子女的兄弟姐妹照顾过孩子"
replace hgkcarek_sib = 1 if hgkcarekn>1 & hchild>1

gen hincgap = .
replace hincgap = 1 if khinc>hinc_c
replace hincgap = 0 if khinc<=hinc_c
replace hincgap = . if missing(khinc) | missing(hinc_c)

label variable hincgap "是否父辈家庭收入高于祖辈家庭收入"


gen hlabinc_c = . 
replace hlabinc_c = 0 if hlabinc == 0
replace hlabinc_c = 1 if hlabinc>0 & hlabinc<2000
replace hlabinc_c = 2 if hlabinc>=2000 & hlabinc<5000
replace hlabinc_c = 3 if hlabinc>=5000 & hlabinc<10000
replace hlabinc_c = 4 if hlabinc>=10000 & hlabinc<20000
replace hlabinc_c = 5 if hlabinc>=20000 & hlabinc<50000
replace hlabinc_c = 6 if hlabinc>=50000 & hlabinc<100000
replace hlabinc_c = 7 if hlabinc>=100000 & hlabinc<150000
replace hlabinc_c = 8 if hlabinc>=150000 & hlabinc<200000
replace hlabinc_c = 9 if hlabinc>=200000 & hlabinc<300000
replace hlabinc_c = 10 if hlabinc>=300000 & !missing(hlabinc)


label variable hlabinc_c "老年受访家庭总收入类别(仅劳动收入)"

gen hincgap2 = .
replace hincgap2 = 1 if khinc>hlabinc_c
replace hincgap2 = 0 if khinc<=hlabinc_c
replace hincgap2 = . if missing(khinc) | missing(hlabinc_c)

label variable hincgap2 "是否父辈家庭收入高于祖辈家庭收入(祖辈仅劳动收入)"

gen hhinc_c = hinc_c + khinc
label variable hhinc_c "延展家庭总收入的类别"

**考虑子女配偶的教育水平
egen hkeduc3_min = rowmin(keduc3 kseduc3)
label variable hkeduc3_min "年轻父母最低的受教育程度"
replace hkeduc3_min = . if year != 2018

gen hedugap3_min_s = .
label variable hedugap3_min_s "Education gap (3-Min, Young spouse)"
replace hedugap3_min_s = 1 if hkeduc3_min > heduc3_min
replace hedugap3_min_s = 0 if hkeduc3_min <= heduc3_min
replace hedugap3_min_s = . if missing(hkeduc3_min) | missing(heduc3_min)

** 受访者或配偶是否属于义务教育暴露群体
gen rcslgap = kbprov_celyear - rbyear
label variable rcslgap "义务教育法实施年份与受访者出生年份的差"

gen riscel = .
label variable riscel "受访者是否属于义务教育法的暴露群体"
replace riscel = 0 if !missing(rcslgap) & rcslgap>=16
replace riscel = 1 if !missing(rcslgap) & rcslgap<16


gen scslgap = kbprov_celyear - sbyear
label variable scslgap "义务教育法实施年份与受访者配偶出生年份的差"

gen siscel = .
label variable siscel "受访者配偶是否属于义务教育法的暴露群体"
replace siscel = 0 if !missing(scslgap) & scslgap>=16
replace siscel = 1 if !missing(scslgap) & scslgap<16

egen hiscel = rowmax(riscel siscel)
label variable hiscel "受访者或其配偶是否属于义务教育法的暴露群体"



recode provID (4 7 16 1 14 18 22 9 11 = 1) (10 8 15 17 19 20 = 2) (2 3 6 12 13 21 23 25 26 27 = 3) (5 24 28 = 4),gen(areaID4c)
label variable areaID4c "经济分区(4类)"

drop ID
save "data.dta",replace
tab year