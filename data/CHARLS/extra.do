*** 子女是否出生在调查省份

***清理CHARLS子女的出生地
*** 2011年
cap mkdir ".temp"

use "raw/datafile/dta/datafile-child2011_v20170920.dta",clear
keep householdID childID cb081

replace householdID = householdID + "0"
rename cb081 k1bplace_c
label variable k1bplace_c "w1:子女的出生地"
label define k1bplace_c 1 "1 本村/社区" 2 "2 本县/市其他村/社区" 3 "3 本省其他县/市" 4 "4 外省" 5 "5 国外" 6 "6 本省或外省其他县/市"
label values k1bplace_c k1bplace_c
save ".temp/2011kbplace.dta",replace

*** 2013年
use "raw/datafile/dta/datafile-child2013_v20151118.dta",clear
keep householdID childID cb081
rename cb081 k2bplace_c
label variable k2bplace_c "w2:子女的出生地"
label define k2bplace_c 1 "1 本村/社区" 2 "2 本县/市其他村/社区" 3 "3 本省其他县/市" 4 "4 外省" 5 "5 国外" 6 "6 本省或外省其他县/市"
label values k2bplace_c k2bplace_c
save ".temp/2013kbplace.dta",replace

*** Harmonized CHARLS
use "raw/datafile/dta/datafile-H_CHARLS_D_Data_v202106D.dta",clear
keep ID rabplace_c communityID
label define rabplace_c 1 "1 本村/社区" 2 "2 本省其他村/社区" 3 "3 外省" 4 "4 国外",replace
label values rabplace_c rabplace_c
** 重编码出生省份类型, 以与子女模块选项保持一致
recode rabplace_c (3 =4) (4=5),gen(rbplace_c) 
label variable rbplace_c "受访者出生省份"
label define rbplace_c 1 "1 本村/社区" 2 "2 本县/市其他村/社区" 3 "3 本省其他县/市" 4 "4 外省" 5 "5 国外"
label values rbplace_c rbplace_c

keep ID communityID rbplace_c
save ".temp/rbplace.dta",replace

*** 2015年
use "raw/datafile/dta/datafile-child2015_v20171011.dta",clear
keep ID householdID childID cb081
merge m:1 ID using ".temp/rbplace.dta",nogen keep(master match)
gen k3bplace_c = . 
label variable k3bplace_c "w3:子女的出生地"
replace k3bplace_c = rbplace_c if cb081 == 1
replace k3bplace_c = 1 if cb081 == 2
replace k3bplace_c = 2 if cb081 == 3
replace k3bplace_c = 6 if cb081 == 4
replace k3bplace_c = 5 if cb081 == 5

label define k3bplace_c 1 "1 本村/社区"  2 "2 本县/市其他村/社区" 3 "3 本省其他县/市" 4 "4 外省" 5 "5 国外" 6 "6 本省或外省其他县/市"
label values k3bplace_c k3bplace_c

keep householdID childID communityID k3bplace_c

save ".temp/2015kbplace.dta",replace



*** 根据2011，2013，2015以及家庭受访者的出生省份，以及psu中的出生省份确定子女的出生省份
use ".temp/2011kbplace.dta",clear

merge 1:1 householdID childID using ".temp/2013kbplace.dta",nogen
merge 1:1 householdID childID using ".temp/2015kbplace.dta",nogen

gen kbplace_c = k3bplace_c 
label variable kbplace_c "子女出生省份"
replace kbplace_c = k2bplace_c if missing(kbplace_c) & !missing(k2bplace_c)
replace kbplace_c = k1bplace_c if missing(kbplace_c) & !missing(k1bplace_c)

label define kbplace_c 1 "1 本村/社区"  2 "2 本县/市其他村/社区" 3 "3 本省其他县/市" 4 "4 外省" 5 "5 国外" 6 "6 本省或外省其他县/市"
label values kbplace_c kbplace_c

recode kbplace_c (1/3 = 1) (4/5=0) (6=.n),gen(kbisprov)
label variable kbisprov "子女是否出生在调查省份"

keep householdID childID kbisprov 
replace householdID = "X" + householdID
save "extra/子女是否出生在调查省份.dta", replace