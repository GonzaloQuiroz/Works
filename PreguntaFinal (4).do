clear all
global main "C:\Users\GONZALO\Desktop\Tarea_eco_inter"
global dta  "$main\Datos"
global works "$main\resultados"


*Importo a stata la base de datos csv solo considerando los datos del país asignado (CHILE)

import delimited "$dta\WDIData.csv", varnames(1) encoding(UTF-8) 
keep if countryname=="Chile" | countryname=="United States"
drop v65

*Loop para cambiar el nombre de las variables de los años v1,v2.. a años

foreach v of varlist v5-v64 {
  local lb_var : var label `v'
  rename `v' YR`lb_var'
}
   
drop YR1960-YR1990

* Paso las variables que se encuentran en indicadores que están en forma horizontal a forma vertical para obtener variables como GDP entre otras 

reshape long YR, i(countrycode  indicatorname) j(year)
gen series= substr(strtoname(indicatorname), 1, 30)
drop indicatorname indicatorcode
collapse (sum) YR , by(year series countrycode)
reshape wide YR, i( year countrycode) j(series) string
rename YR* *

keep if year >1990 & year<2019
* Renombro algunas variables que se utilizarán

rename (GDP__current_LCU_ GDP__current_US__ Inflation__consumer_prices__an) (GDP_current_LCU GDP_current_US InflationRateCHL)

/// Pregunta 1
 
* Genero la variable tipo de cambio nominal

gen TCN_chile= GDP_current_LCU/GDP_current_US


*Guardo las bases de datos que se usarán USA-CHILE

preserve
keep if countrycode=="CHL"
save "$works\WDIChile.dta", replace
restore
preserve 
keep if countrycode=="USA"
save "$works\WDIUSA.dta" , replace
restore

*Uso la base de datos solo de Chile

clear all 

use "$works\WDIChile.dta", replace

*Convierto la variable year en variable de tiempo para poder graficar el TCN a lo largo de los años
tsset year

*** 1.1 Gráfica del TC nominal de Chile

tsline TCN_chile  , xlabel(1991(1)2018, angle(vertical) labsize(small)) /// 
graphregion(color(white)) ylabel(,nogrid labsize(small)) ///
xtitle("Año", size(*0.8)) ytitle("TC nominal en pesos chilenos", margin(medsmall) size(*0.8)) ///
lcolor(black) ///
title("Tipo de cambio nominal respecto al dólar (CHILE-USA)", size(*0.8)) 

graph export "$works\TCnominal.png", as (png) replace

*** 1.1.2 Gráfica de la tasa de inflación de Chile

tsline InflationRate , xlabel(1991(2)2019, angle(vertical) labsize(small)) /// 
graphregion(color(white)) ylabel(,nogrid labsize(small)) ///
xtitle("Año", size(*0.8)) ytitle("%", margin(medsmall) size(*0.8)) ///
lcolor(black) ///
title("Tasa de Inflación de Chile", size(*0.8)) 

graph export "$works\inflacion.png", as (png) replace

****1.2 Gráfica del Índice de precios de Chile

* Genero la variable indice de precios de Chile tomando como año base 1991

gen index1991CHL=100 if year==1991
replace index1991CHL=100*(1+InflationRateCHL/100)  if  year==1992
replace index1991CHL=index1991CHL[_n-1]*(1+InflationRateCHL/100) if year > 1992

tsline index1991CHL , xlabel(1992(2)2019, angle(vertical) labsize(small)) /// 
graphregion(color(white)) ylabel(,nogrid labsize(small)) ///
xtitle("Año", size(*0.8)) ytitle("IPC(1991=100)", margin(medsmall) size(*0.8)) ///
lcolor(black) ///
title("Índice de precios de Chile (Año Base=1991)", size(*0.8)) 

graph export "$works\IPC_Chile.png", as (png) replace

save "$works\WDIChile.dta", replace

//////// 


** Índice de precios de USA

use "$works\WDIUSA.dta" , replace

rename InflationRateCHL InflationRateUSA

*Convierto la variable year en variable de tiempo para poder graficar el IPC a lo largo de los años
tsset year

***1.3 Gráfica del Índice de precios de USA

* Genero la variable indice de precios de USA tomando como año base 1991
gen index1991USA=100 if year==1991
replace index1991USA=100*(1+InflationRateUSA/100)  if year==1992
replace index1991USA=index1991USA[_n-1]*(1+InflationRateUSA/100) if year > 1992

tsline index1991USA if year>1991 , xlabel(1992(2)2019, angle(vertical) labsize(small)) /// 
graphregion(color(white)) ylabel(,nogrid labsize(small)) ///
xtitle("Año", size(*0.8)) ytitle("IPC(1991=100)", margin(medsmall) size(*0.8)) ///
lcolor(black) ///
title("Índice de precios de USA (Año Base=1991)", size(*0.8)) 

graph export "$works\IPC_USA.png", as (png) replace

save "$works\WDIUSA.dta" , replace

////// Pregunta 2

**2.1 Tipo de cambio de paridad absoluta 

clear all 
use "$works\WDIChile.dta"  , clear  
merge 1:1 year countrycode  using "$works\WDIUSA.dta"

collapse (sum) InflationRateCHL InflationRateUSA TCN_chile index1991CHL index1991USA  , by(year)

**Genero la variable tipo de cambio de paridad absoluta 

gen TC_absoluta=index1991CHL/index1991USA

** Gráfico tipo de cambio paridad absoluto 

twoway line TC_absoluta year  , lpattern(dash) lcolor(black) ytitle("TC absoluto", margin(medsmall))||line TCN_chile year    , yaxis(2) ytitle("TC nominal", axis(2)) ///
xlabel(1991(3)2018) ///
graphregion(color(white)) ylabel(,nogrid labsize(small) format(%3.2f)) ///
title("Tipo de cambio de paridad absoluto y Tipo de cambio nominal de Chile ", margin(medium) size(*0.8)) ///
lcolor(black) ///
legend(rows(1) stack size(8pt) order(1 "TC absoluto" 2 "TC nominal ") ) 

graph export "$works\absoluta_TCN.png", as (png) replace

twoway line TC_absoluta year if year>1991, lpattern(dash) lcolor(black) ytitle("TC absoluto", margin(medsmall))|| line InflationRateCHL  year , yaxis(2) ytitle("Inflación", axis(2))   ///
xlabel(1991(3)2018) ///
graphregion(color(white)) ylabel(,nogrid labsize(small) format(%3.2f)) ///
title("Tipo de cambio de paridad absoluto e inflación de Chile", margin(medium) size(*0.8)) ///
lcolor(black) ///
legend(rows(1) stack size(8pt) order(1 "TC absoluto" 2 "Inflación") ) 

graph export "$works\absoluta_INFLATION.png", as (png) replace
 
**2.2 Tipo de cambio de paridad relativa 
gen var_indexCHL= ((index1991CHL - index1991CHL[_n-1])/index1991CHL[_n-1])*100
gen var_indexUSA= ((index1991USA - index1991USA[_n-1])/index1991USA[_n-1])*100

gen TC_relativo= var_indexCHL -  var_indexUSA
gen TCrelativoAcum= (TC_relativo + TC_relativo[_n-1]) if year==1993
replace TCrelativoAcum=(TCrelativoAcum[_n-1]+TC_relativo) if year>1993
gen var_TC=((TCN_chile - TCN_chile[_n-1])/TCN_chile[_n-1])*100
gen var_TCAcum= (var_TC + var_TC[_n-1]) if year==1993
replace var_TCAcum=(var_TCAcum[_n-1]+var_TC) if year>1993

** Gráfico tipo de cambio de paridad relativa 

twoway line TCrelativoAcum year , lpattern(dash) lcolor(black) ytitle("TC relativo acumulada", margin(medium)) ||line var_TCAcum year  ,  yaxis(2) ytitle("var. del TC nominal  ", axis(2)) /// 
xlabel(1991(3)2018) ///
graphregion(color(white)) ylabel(,nogrid labsize(small)) ///
title("TC de paridad relativo acumulada y variación del tipo de cambio acumulada", margin(medium) size(*0.8)) /// 
lcolor(black) ///
legend(rows(1) stack size(8pt) order(1 "TC relativo" 2 "var. del TC nominal acumulada") )   

graph export "$works\relativaAcum_TCN.png", as (png) replace


twoway line TC_relativo year, lpattern(dash) lcolor(black) ytitle("TC relativo") || line var_TC  year  , yaxis(2) ytitle("Inflación", axis(2))  ///
xlabel(1991(3)2018) ///
graphregion(color(white)) ylabel(,nogrid labsize(small)) ///
title("Tipo de cambio de paridad relativo e inflación de Chile", margin(medium) size(*0.8)) ///
lcolor(black) ///
legend(rows(1) stack size(8pt) order(1 "TC relativo" 2 "Inflación") )   


graph export "$works\relativa_inflation.png", as (png) replace