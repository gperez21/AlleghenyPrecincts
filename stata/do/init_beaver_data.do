// This file spatially joins xy data to shapefiles

* set up
clear
set type double

cd "C:\Users\perez_g\Desktop\Politics Data\AlleghenyPrecincts\stata"
gl root "C:\Users\perez_g\Desktop\Politics Data\AlleghenyPrecincts\stata"
gl GIS "C:\Users\perez_g\Desktop\Politics Data\AlleghenyPrecincts\GIS"
capture mkdir "$root\do"
capture mkdir "$root\raw"
capture mkdir "$root\data"
capture mkdir "$root\output"
gl do "$root\do"
gl raw "$root\raw"
gl data "$root\data"
gl output "$root\output"
gl shapefiles "$GIS\shapefiles"

* import Beaver 2016 turnout
// fake delimiter to get all data into one column
import delimited "$raw\2016_Beaver.txt", delimiter("$%@") clear
replace v1 = strtrim(v1)
* clean up the strings
gen flag = 0
replace flag = 10 if v1[_n + 1] == "VOTES PERCENT"
replace flag = 1 if strpos(v1, "REGISTERED VOTERS")
replace flag = 2 if strpos(v1, "BALLOTS CAST")
// replace flag = 3 if strpos(v1, "VOTER TURNOUT")
replace flag = 11 if strpos(v1, "STRAIGHT PARTY")
replace flag = 4 if strpos(v1, "DEMOCRATIC") & flag[_n - 2] == 11
replace flag = 5 if strpos(v1, "REPUBLICAN") & flag[_n - 3] == 11
keep if flag != 0
gen flag2 = ""
replace flag2 = v1 if flag == 10
replace flag2 = flag2[_n-1] if flag2 == "" 
drop if v1 == "STRAIGHT PARTY"
replace v1 = subinstr(v1, "REGISTERED VOTERS - TOTAL . . . . . .","",.)
replace v1 = subinstr(v1, "BALLOTS CAST - TOTAL. . . . . . . .","",.)
replace v1 = subinstr(v1, "VOTER TURNOUT - TOTAL . . . . . . .","",.)
replace v1 = subinstr(v1, "DEMOCRATIC (DEM) . . . . . . . . .","",.)
replace v1 = subinstr(v1, "REPUBLICAN (REP) . . . . . . . . .","",.)
split v1, p(" ")
// get only vote number from strings that also contain pcts
replace v1 = v11 if flag != 10
drop if flag == 10
keep v1 flag flag2
gen     type = "Registered2016"   if flag == 1
replace type = "Ballots2016"      if flag == 2
replace type = "StraightDem2016"  if flag == 4
replace type = "StraightRep2016"  if flag == 5
drop flag
destring v1, replace
reshape wide v1, i(flag2) j(type) string
ren v1* *
* find turnout
gen Turnout2016 = Ballots/Registered
gen Pct_st_dem2016 = StraightDem/Ballots
gen Pct_st_rep2016 = StraightRep/Ballots
ren flag2 Precinct
label var Precinct "Precinct"
label var Turnout2016 "Turnout in 2016 election"
label var Pct_st_dem2016  "Percentage of Ballots with Straight Democratic Vote Checked"
label var Pct_st_rep2016  "Percentage of Ballots with Straight Republican Vote Checked"
label var Ballots "Total Ballots Cast"
label var Registered "Total Registered Voters"
label var StraightDem "Ballots with Straight Democratic Vote Checked"
label var StraightRep "Ballots with Straight Republican Vote Checked"
* fix for merge
replace Precinct = "4004 NORTH SEWICKLEY TWP 4" if Precinct == "4004 NORTH SEWICKLEY ELLWOOD"
tempfile beaver2016
save `beaver2016'

* import Beaver 2018 turnout
// fake delimiter to get all data into one column
import delimited "$raw\2018_Beaver.txt", delimiter("$%@") clear
replace v1 = strtrim(v1)
* clean up the strings
gen flag = 0
replace flag = 10 if v1[_n + 1] == "VOTES  PERCENT"
replace flag = 1 if strpos(v1, "REGISTERED VOTERS")
replace flag = 2 if strpos(v1, "BALLOTS CAST")
// replace flag = 3 if strpos(v1, "VOTER TURNOUT")
replace flag = 11 if strpos(v1, "STRAIGHT PARTY")
replace flag = 4 if strpos(v1, "DEMOCRATIC") & flag[_n - 2] == 11
replace flag = 5 if strpos(v1, "REPUBLICAN") & flag[_n - 3] == 11
keep if flag != 0
gen flag2 = ""
replace flag2 = v1 if flag == 10
replace flag2 = flag2[_n-1] if flag2 == "" 
drop if v1 == "STRAIGHT PARTY"
replace v1 = subinstr(v1, "REGISTERED VOTERS - TOTAL .  .  .  .  .  .  ","",.)
replace v1 = subinstr(v1, "BALLOTS CAST - TOTAL.  .  .  .  .  .  .  .  ","",.)
replace v1 = subinstr(v1, "VOTER TURNOUT - TOTAL  .  .  .  .  .  .  .  ","",.)
replace v1 = subinstr(v1, "DEMOCRATIC (DEM) .  .  .  .  .  .  .  .  .  ","",.)
replace v1 = subinstr(v1, "REPUBLICAN (REP) .  .  .  .  .  .  .  .  .  ","",.)
split v1, p("	")
// get only vote number from strings that also contain pcts
replace v1 = v11 if flag != 10
drop if flag == 10
keep v1 flag flag2
gen     type = "Registered2018"   if flag == 1
replace type = "Ballots2018"      if flag == 2
replace type = "StraightDem2018"  if flag == 4
replace type = "StraightRep2018"  if flag == 5
drop flag
destring v1, replace
reshape wide v1, i(flag2) j(type) string
ren v1* *
* find turnout
gen Turnout2018 = Ballots/Registered
gen Pct_st_dem2018 = StraightDem/Ballots
gen Pct_st_rep2018 = StraightRep/Ballots
ren flag2 Precinct
label var Precinct "Precinct"
label var Turnout2018 "Turnout in 2018 election"
label var Pct_st_dem2018  "Percentage of Ballots with Straight Democratic Vote Checked 2018"
label var Pct_st_rep2018  "Percentage of Ballots with Straight Republican Vote Checked 2018"
label var Ballots "Total Ballots Cast 2018"
label var Registered "Total Registered Voters 2018"
label var StraightDem "Ballots with Straight Democratic Vote Checked 2018"
label var StraightRep "Ballots with Straight Republican Vote Checked 2018"
merge 1:1 Precinct using `beaver2016'
drop _m
gen turnout = Turnout2018- Turnout2016
sum turnout

save "$data\Beaver_turnout_change_16_18.dta", replace
// twoway scatter StraightDem2018 StraightDem2016, xtick(#10)
