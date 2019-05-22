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

* import Allegheny 2016 turnout
import excel "$raw\2016_Allegheny.xlsx", sheet("Registered Voters") firstrow clear
gen turnout2016 = Ballot/Regis
	tempfile reg2016
	save `reg2016'
* import Allegheny 2018 turnout
import excel "$raw\2018_Allegheny.xlsx", sheet("Registered Voters") firstrow clear
gen turnout2018 = Ballot/Regis

* merge in both years
keep County turnout2018
ren County Precinct
merge 1:1 Precinct using `reg2016', keepus(turnout2016)
assert _m == 3
drop _m	
// find change in turnout
gen turnout_diff = turnout2018 - turnout2016

* label
label var turnout_diff "Difference in turnout pct pts."
label var turnout2018  "Turnout in 2018 election"
label var turnout2016  "Turnout in 2016 election"
label var Precinct     "Precinct"
save "$data\Allegheny_turnout_change_16_18.dta", replace

** Mapping **
*Create a Dta from a shape file
shp2dta using "$shapefiles\Allegheny_County_Voting_District_Boundaries.shp", genid(_ID) data("$data\Allegheny_precincts_data.dta") coor("$data\Allegheny_precincts_coor.dta") replace

use "$data\Allegheny_precincts_data.dta", clear
capture ren Muni_War_1 Precinct
drop in 10 // duplicate for Moon Ward 11 for some reason, keep bigger one
save, replace

use "$data\Allegheny_turnout_change_16_18.dta", clear
merge 1:1 Precinct using "$data\Allegheny_precincts_data.dta", keepus(_ID)
drop if _m != 3
drop _m

* Make Allegheny map
spmap turnout_diff using "$data\Allegheny_precincts_coor.dta", id(_ID) fcolor(Greens) ///
legend(symy(*2) symx(*2) size(*.8) position (8)) 
graph save Graph "$output\Allegheny County Precincts pct pts change 16-18.gph", replace
graph export     "$output\Allegheny County Precincts pct pts change 16-18.pdf", as(pdf) replace



