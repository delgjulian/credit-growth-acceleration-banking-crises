************************************************************************************************************
* PARTE - I
* 01_gmd_preprocessing.do
* Proyecto: Mini-paper Finanzas Internacionales (UBA)
* Autor: Julián Delgadillo Marín
* Fecha: 10/06/2025
* Objetivo:
*   - Explorar, limpiar y preparar la base Global Macro Database (GMD)
*     para análisis macrofinanciero 1960–2023
************************************************************************************************************

* 1. Cargar base original
clear all
cls
set more off

* Definir directorio de trabajo
cd "C:\Users\julla\Downloads\Datos"

use "GMD.dta", clear

*-------------------------------------------------------------------
* 2. Inspección básica
*-------------------------------------------------------------------
display "✅ Archivo cargado correctamente: " c(filename)
describe
list countryname ISO3 year in 1/20, abbreviate(15)
duplicates report countryname year

*-------------------------------------------------------------------
* 3. Diagnóstico temporal del panel
*-------------------------------------------------------------------
bys ISO3: egen first_year = min(year)
bys ISO3: egen last_year  = max(year)
summ first_year last_year

*-------------------------------------------------------------------
* 4. Recorte del rango temporal útil (1960–2023)
*-------------------------------------------------------------------
keep if year >= 1960 & year <= 2023
summ year

*-------------------------------------------------------------------
* 5. Revisión de variables clave
*-------------------------------------------------------------------
summ rGDP_pc nGDP_USD infl CA_GDP gen_govdef_GDP gen_govdebt_GDP
tab BankingCrisis
tab CurrencyCrisis
tab SovDebtCrisis

*-------------------------------------------------------------------
* 6. Creación variable de apertura comercial
*-------------------------------------------------------------------
* Si no existe, crearla manualmente: *open* *trade*
capture confirm variable openness
if _rc {
    gen openness = exports_GDP + imports_GDP
    label var openness "Trade Openness (% of GDP)"
}

*-------------------------------------------------------------------
* 7. Filtrar variables macroeconómicas principales
*-------------------------------------------------------------------
keep ISO3 year countryname rGDP_pc infl CA_GDP gen_govdebt_GDP openness
order ISO3 year countryname rGDP_pc infl CA_GDP gen_govdebt_GDP openness

*-------------------------------------------------------------------
* 8. Filtrar solo países presentes en BIS y Crisis Database
*-------------------------------------------------------------------

local iso "COL ARG CHL MEX BRA USA GBR DEU JPN FRA ESP ITA CAN KOR AUS"

gen byte keepme = 0
foreach c of local iso {
    replace keepme = 1 if ISO3 == "`c'"
}
keep if keepme
drop keepme

* Verificar
levelsof ISO3, clean
tab ISO3
display "✅ Países filtrados correctamente por ISO3."

*-------------------------------------------------------------------
* 9. Checklist final GMD (macro clean)
*-------------------------------------------------------------------

* Estructura panel confirmada
isid ISO3 year
order countryname, first

* Variables relevantes renombradas (si quieres estandarizar)
rename (rGDP_pc infl CA_GDP gen_govdebt_GDP openness) ///
       (rgdppc inflation ca_gdp debt_gdp openness)


* Etiquetas y unidades (documentación interna)
label variable rgdppc "Real GDP per capita (2015 USD)"
label variable inflation "Inflation rate (%)"
label variable ca_gdp "Current account (% of GDP)"
label variable debt_gdp "General government debt (% of GDP)"
label variable openness "Trade openness index"

* Verificación rápida de missing values
misstable summarize rgdppc inflation ca_gdp debt_gdp openness

* Guardar la base limpia final
save "GMD_macro_clean.dta", replace

*-------------------------------------------------------------------
* Fin del script
*-------------------------------------------------------------------
tabulate countryname
tabulate ISO3

display "✅ GMD_macro_clean.dta creada correctamente (1960–2023)"


************************************************************************************************************
* PARTE - II
* LIMPIEZA DE BASE BIS – CRÉDITO PRIVADO (% PIB)
* Fuente: Bank for International Settlements (BIS)
* Archivo original: bis_dp_search_export_20251006-215935.xlsx
* Hoja: "timeseries observations"
************************************************************************************************************

cls
clear all
set more off

*-----------------------------------------------------
* 1. Importar hoja de datos
*-----------------------------------------------------
import excel "C:\Users\julla\Downloads\Datos\bis_dp_search_export_20251006-215935.xlsx", ///
    sheet("timeseries observations") firstrow clear
	
* Visualizar las primeras observaciones
list in 1/10

*-----------------------------------------------------
* 2. Inspección general de estructura
*-----------------------------------------------------
describe
codebook

* Revisar nombres de variables
ds

* Obtener número de observaciones y variables
count
display "Total de observaciones: " r(N)
display "Total de variables: " r(k)

* Verificar número de observaciones
count
display "Observaciones iniciales: " r(N)

*-----------------------------------------------------
* 3. Identificar valores únicos de variables clave
*-----------------------------------------------------
* Países incluidos
tab BORROWERS_CTYB, sort

* Frecuencias de la unidad y tipo de crédito
tab UNIT_TYPE
tab TC_BORROWERS
tab TC_LENDERS
tab VALUATION

*-----------------------------------------------------
* 4. Inspeccionar valores faltantes y estructura temporal
*-----------------------------------------------------
summarize OBS_VALUE, detail
inspect OBS_VALUE

* Fechas disponibles
summarize TIME_PERIOD
list TIME_PERIOD in 1/20

*-----------------------------------------------------
* 5. Mantener solo las columnas necesarias
*-----------------------------------------------------
keep BORROWERS_CTYB TIME_PERIODPe~d OBS_VALUEValue

*-----------------------------------------------------
* 6. Renombrar variables para mayor claridad
*-----------------------------------------------------
rename BORROWERS_CTYB country
rename TIME_PERIODPe~d date
rename OBS_VALUEValue credit_gdp

*-----------------------------------------------------
* 7. Extraer código ISO3 y año calendario
*-----------------------------------------------------
* El código ISO3 está antes de los dos puntos (ej. 'AR:Argentina')
gen ISO3 = substr(country,1,2)

* Extraer año (AAAA) de la fecha tipo "1984-12-31"
gen year = real(substr(date,1,4))

*-----------------------------------------------------
* 8. Comprobar duplicados y observaciones inválidas
*-----------------------------------------------------
drop if missing(credit_gdp)
duplicates report ISO3 year

*-----------------------------------------------------
* 9. Agregar de trimestral a anual (promedio)
*-----------------------------------------------------
collapse (mean) credit_gdp, by(ISO3 year)

*-----------------------------------------------------
* 10. Calcular crecimiento y aceleración del crédito
*-----------------------------------------------------
bys ISO3 (year): gen d_credit = credit_gdp - credit_gdp[_n-1]
bys ISO3 (year): gen accel_credit = d_credit - d_credit[_n-1]

*-----------------------------------------------------
* 11. Ordenar y etiquetar variables
*-----------------------------------------------------
order ISO3 year credit_gdp d_credit accel_credit
sort ISO3 year
label variable credit_gdp "Crédito privado (% PIB, promedio anual)"
label variable d_credit "Crecimiento interanual del crédito (% PIB)"
label variable accel_credit "Aceleración del crédito (2da derivada)"

gen countryname = ""
replace countryname = "Argentina" if ISO3 == "AR"
replace countryname = "Brazil"    if ISO3 == "BR"
replace countryname = "Chile"     if ISO3 == "CL"
replace countryname = "Mexico"    if ISO3 == "MX"
replace countryname = "United States" if ISO3 == "US"
replace countryname = "Canada"    if ISO3 == "CA"
replace countryname = "Australia"        if ISO3 == "AU"
replace countryname = "Colombia"         if ISO3 == "CO"
replace countryname = "Germany"          if ISO3 == "DE"
replace countryname = "Spain"            if ISO3 == "ES"
replace countryname = "France"           if ISO3 == "FR"
replace countryname = "United Kingdom"   if ISO3 == "GB"
replace countryname = "Italy"            if ISO3 == "IT"
replace countryname = "Japan"            if ISO3 == "JP"
replace countryname = "South Korea" if ISO3 == "KR"
order countryname, first

replace ISO3 = "ARG" if ISO3 == "AR"
replace ISO3 = "AUS" if ISO3 == "AU"
replace ISO3 = "BRA" if ISO3 == "BR"
replace ISO3 = "CAN" if ISO3 == "CA"
replace ISO3 = "CHL" if ISO3 == "CL"
replace ISO3 = "COL" if ISO3 == "CO"
replace ISO3 = "FRA" if ISO3 == "FR"
replace ISO3 = "DEU" if ISO3 == "DE"
replace ISO3 = "ITA" if ISO3 == "IT"
replace ISO3 = "JPN" if ISO3 == "JP"
replace ISO3 = "MEX" if ISO3 == "MX"
replace ISO3 = "KOR" if ISO3 == "KR"
replace ISO3 = "ESP" if ISO3 == "ES"
replace ISO3 = "GBR" if ISO3 == "GB"
replace ISO3 = "USA" if ISO3 == "US"

tabulate countryname
tabulate ISO3

*-----------------------------------------------------
* 12. Guardar una copia sin modificar (para referencia)
*-----------------------------------------------------
save "C:\Users\julla\Downloads\Datos\BIS_credit_raw.dta", replace

display "Fin de la exploración de la base BIS"
******************************************************


************************************************************************************************************
* PARTE - III
* MERGE DE BASE MACRO (GMD) Y CRÉDITO (BIS)
************************************************************************************************************

cls
clear all
set more off

*-----------------------------------------------------
* 1. Cargar la base principal (BIS)
*-----------------------------------------------------
use "C:\Users\julla\Downloads\Datos\BIS_credit_raw.dta", clear

*-----------------------------------------------------
* 2. Verificar variables clave
*-----------------------------------------------------
describe ISO3 year
isid ISO3 year   // Confirma que la combinación país-año sea única

*-----------------------------------------------------
* 3. Ejecutar el merge con la base GMD
*-----------------------------------------------------
merge 1:1 ISO3 year using "C:\Users\julla\Downloads\Datos\GMD_macro_clean.dta"

*-----------------------------------------------------
* 4. Diagnóstico del merge
*-----------------------------------------------------
tab _merge

* Significado:
* _merge==1 → solo en BIS
* _merge==2 → solo en GMD
* _merge==3 → emparejadas correctamente

*-----------------------------------------------------
* 5. (Opcional) Filtrar solo los años comunes
*-----------------------------------------------------
* keep if _merge == 3

*-----------------------------------------------------
* 6. (Opcional) Limitar rango temporal común (si querés panel balanceado)
*-----------------------------------------------------
* keep if year >= 1984 & year <= 2023

*-----------------------------------------------------
* 7. Verificar resultado final
*-----------------------------------------------------
summarize credit_gdp rgdppc inflation debt_gdp openness
tab countryname if _merge==3

*-----------------------------------------------------
* 8. Eliminar variable auxiliar y guardar
*-----------------------------------------------------
drop _merge
save "C:\Users\julla\Downloads\Datos\Panel_GMD_BIS_merged.dta", replace


************************************************************************************************************
* PARTE - IV
* LIMPIEZA DE BASE DE CRISIS BANCARIAS
* Fuente: Laeven & Valencia (IMF Banking Crisis Database, actualización 2020)
* Archivo original: Banking_crisis_database.xlsx
* Hoja: "Crisis Years"
************************************************************************************************************

cls
clear all
set more off

*-----------------------------------------------------
* 1. Importar hoja de crisis desde Excel (hoja 2)
*-----------------------------------------------------
import excel "C:\Users\julla\Downloads\Datos\Banking_crisis_database.xlsx", ///
    sheet("Crisis Years") firstrow clear

*-----------------------------------------------------
* 2. Revisar estructura inicial
*-----------------------------------------------------
describe
list in 1/10
describe, fullnames

*-----------------------------------------------------
* 3. Renombrar variables para consistencia
*-----------------------------------------------------
rename Country countryname
rename SystemicBankingCrisisstartin banking_crisis
rename CurrencyCrisis currency_crisis
rename SovereignDebtCrisisyear debt_crisis
rename SovereignDebtRestructuringye restructuring_crisis

*-----------------------------------------------------
* 4. Mantener solo país y años de crisis bancaria
*-----------------------------------------------------
keep countryname banking_crisis

*-----------------------------------------------------
* 5. Limpiar espacios y uniformar nombres de país
*-----------------------------------------------------
replace countryname = trim(countryname)

*-----------------------------------------------------
* 6. Expandir lista de años separados por comas a formato largo (una fila por país-año)
*-----------------------------------------------------
split banking_crisis, parse(",") destring
drop banking_crisis
reshape long banking_crisis, i(countryname) j(obs)

*-----------------------------------------------------
* 7. Renombrar variable, eliminar missing y ordenar
*-----------------------------------------------------
rename banking_crisis year
drop if missing(year)
sort countryname year


*-----------------------------------------------------
* 8. Generar variable ISO3 vacía
*-----------------------------------------------------
gen ISO3 = ""

replace ISO3 = "ARG" if countryname == "Argentina"
replace ISO3 = "AUS" if countryname == "Australia"
replace ISO3 = "BRA" if countryname == "Brazil"
replace ISO3 = "CAN" if countryname == "Canada"
replace ISO3 = "CHL" if countryname == "Chile"
replace ISO3 = "COL" if countryname == "Colombia"
replace ISO3 = "FRA" if countryname == "France"
replace ISO3 = "DEU" if countryname == "Germany"
replace ISO3 = "ITA" if countryname == "Italy"
replace ISO3 = "JPN" if countryname == "Japan"
replace ISO3 = "MEX" if countryname == "Mexico"
replace ISO3 = "KOR" if countryname == "South Korea"
replace ISO3 = "ESP" if countryname == "Spain"
replace ISO3 = "GBR" if countryname == "United Kingdom"
replace ISO3 = "USA" if countryname == "United States"

order ISO3, after(countryname)


*-----------------------------------------------------
* 9. Mantener solo los países relevantes para el análisis
*-----------------------------------------------------
local iso "COL ARG CHL MEX BRA USA GBR DEU JPN FRA ESP ITA CAN KOR AUS"

gen byte keepme = 0
foreach c of local iso {
    replace keepme = 1 if ISO3 == "`c'"
}
keep if keepme
drop keepme

* Verificar
levelsof ISO3, clean
tab ISO3

*-----------------------------------------------------
* 10. Crear variable dummy de crisis bancaria
*-----------------------------------------------------
gen crisis_banking = 1

*-----------------------------------------------------
* 11. Guardar base limpia
*-----------------------------------------------------
save "C:\Users\julla\Downloads\Datos\Crisis_banking_clean.dta", replace


************************************************************************************************************
* PARTE - V
* MERGE FINAL: BIS + GMD + BASE DE CRISIS BANCARIAS
* Fuente: BIS, IMF-WEO, Laeven & Valencia (2020)
************************************************************************************************************

cls
clear all
set more off

*-----------------------------------------------------
* 1. Cargar base combinada BIS + GMD
*-----------------------------------------------------
use "C:\Users\julla\Downloads\Datos\Panel_GMD_BIS_merged.dta", clear

*-----------------------------------------------------
* 2. Hacer merge con la base de crisis bancarias
*-----------------------------------------------------
merge 1:1 ISO3 year using "C:\Users\julla\Downloads\Datos\Crisis_banking_clean.dta"

*-----------------------------------------------------
* 3. Diagnóstico del merge
*-----------------------------------------------------
tab _merge
tab ISO3 if crisis_banking == 1
tab year if crisis_banking == 1
list countryname year if crisis_banking == 1

* _merge==3 → observaciones con match completo (país-año en ambas bases)
* _merge==1 → observaciones solo en Panel_GMD_BIS_merged (sin crisis)
* _merge==2 → observaciones solo en Crisis_banking_clean (sin macro/finanzas)

*-----------------------------------------------------
* 4. Reemplazar missing de crisis_banking por 0 (países sin crisis)
*-----------------------------------------------------
replace crisis_banking = 0 if missing(crisis_banking)

*-----------------------------------------------------
* 5. Eliminar variable auxiliar del merge
*-----------------------------------------------------
drop _merge

*-----------------------------------------------------
* 6. Guardar panel final completo
*-----------------------------------------------------
* Crear identificador de panel y declarar estructura
egen id = group(ISO3), label
xtset id year
order id, after(ISO3)

save "C:\Users\julla\Downloads\Datos\Panel_final_macro_credit_crisis.dta", replace


************************************************************************************************************
* PARTE VI
* ANÁLISIS DESCRIPTIVO DEL PANEL FINAL
* Fuente: Panel_final_macro_credit_crisis.dta
* Objetivo: Diagnóstico y visualización inicial de la relación crédito–crisis
************************************************************************************************************

cls
clear all
set more off

*-----------------------------------------------------
* 1. Cargar base final
*-----------------------------------------------------
use "C:\Users\julla\Downloads\Datos\Panel_final_macro_credit_crisis.dta", clear

*-----------------------------------------------------
* 2. Verificar estructura general del panel
*-----------------------------------------------------
describe
summarize

xtdescribe
xtsum credit_gdp d_credit accel_credit rgdppc inflation debt_gdp openness
	
*-----------------------------------------------------
* 3. Revisar cobertura temporal y países
*-----------------------------------------------------
tab ISO3
tab countryname
summarize year
tab year

*-----------------------------------------------------
* 4. Estadísticas descriptivas básicas de variables clave
*-----------------------------------------------------
summarize credit_gdp d_credit accel_credit rgdppc inflation ca_gdp debt_gdp openness

tabstat credit_gdp d_credit accel_credit rgdppc inflation debt_gdp openness, ///
    by(crisis_banking) stats(mean sd min max n)
	
* Medias y desviaciones agrupadas por país
bys countryname: summarize credit_gdp d_credit accel_credit

*-----------------------------------------------------
* 5. Verificar valores faltantes
*-----------------------------------------------------
misstable summarize

* Verificar gaps o panel desbalanceado
xtset id year

*-----------------------------------------------------
* 6. Correlaciones entre variables
*-----------------------------------------------------
pwcorr credit_gdp d_credit accel_credit rgdppc inflation debt_gdp openness, sig star(0.05)

*-----------------------------------------------------
* 7. Gráficos descriptivos
*-----------------------------------------------------

* 7.0. Visualizar cobertura temporal por país
xtline credit_gdp, overlay legend(off) ///
    title("Evolución del crédito privado (% PIB)") ///
    subtitle("Panel 15 países, 1960–2023")
	
* Gráfico mejorado con etiquetas de país
xtline credit_gdp, overlay ///
    legend(order(1 "Argentina" 2 "Australia" 3 "Brasil" 4 "Canadá" 5 "Chile" ///
                 6 "Colombia" 7 "Alemania" 8 "España" 9 "Francia" 10 "Italia" ///
                 11 "Japón" 12 "Corea del Sur" 13 "México" 14 "Reino Unido" 15 "EE.UU.") ///
           rows(3) size(vsmall) region(lstyle(none))) ///
    title("Evolución del crédito privado (% PIB)", size(small)) ///
    subtitle("Panel de 15 países, 1960–2023", size(small)) ///
    ytitle("Crédito privado (% PIB, promedio anual)", size(small)) ///
    xtitle("Año", size(small)) ///
    plotregion(margin(zero)) ///
    graphregion(color(white)) ///
    scheme(s2color)

* 7.1 Evolución del crédito (% PIB) en países seleccionados
twoway (line credit_gdp year if ISO3=="ARG", lcolor(red)) ///
       (line credit_gdp year if ISO3=="BRA", lcolor(blue)) ///
       (line credit_gdp year if ISO3=="MEX", lcolor(green)), ///
       legend(order(1 "Argentina" 2 "Brazil" 3 "Mexico")) ///
       title("Evolución del crédito privado (% PIB)") ///
       ytitle("% del PIB") xtitle("Año")

* 7.1 Evolución del crédito (% PIB) en países seleccionados (corregido)	   
twoway ///
 (line credit_gdp year if ISO3=="ARG", lcolor(cranberry) lwidth(medthick)) ///
 (line credit_gdp year if ISO3=="BRA",  lcolor(forest_green) lwidth(medthick)) ///
 (line credit_gdp year if ISO3=="MEX",  lcolor(orange) lwidth(medthick)), ///
 legend(order(1 "Argentina" 2 "Brasil" 3 "México") rows(1) region(lstyle(none))) ///
 title("Evolución del crédito privado (% PIB)") ///
 ytitle("% del PIB") xtitle("Año") ///
 graphregion(color(white)) ///
 scheme(s2color)   // <--- NO usar s1mono

* 7.2 Crecimiento y aceleración del crédito (Argentina)
twoway (line d_credit year if ISO3=="ARG", lcolor(navy)) ///
       (line accel_credit year if ISO3=="ARG", lcolor(red)), ///
       legend(order(1 "Crecimiento" 2 "Aceleración")) ///
       title("Crecimiento vs Aceleración del crédito - Argentina") ///
       ytitle("Variación anual (%)") xtitle("Año")
	   	   
twoway ///
 (line d_credit year if ISO3=="ARG", lcolor(navy) lwidth(medthick)) ///
 (line accel_credit year if ISO3=="ARG", lcolor(red) lwidth(medthick)), ///
 legend(order(1 "Crecimiento" 2 "Aceleración") region(lstyle(none))) ///
 title("Crecimiento vs Aceleración del crédito - Argentina") ///
 ytitle("Variación anual (%)") xtitle("Año") ///
 graphregion(color(white)) ///
 plotregion(color(white)) ///
 scheme(s2color)


* 7.3 Distribución del crédito y aceleración (histogramas)
histogram d_credit, normal title("Distribución del crecimiento del crédito") xtitle("Δ Crédito (% PIB)")
histogram accel_credit, normal title("Distribución de la aceleración del crédito") xtitle("Δ² Crédito (% PIB)")

histogram d_credit, normal ///
    fcolor(gs13) lcolor(gs8) ///
    title("Distribución del crecimiento del crédito", size(medsmall)) ///
    xtitle("Δ Crédito (% PIB)", size(small)) ///
    ytitle("Densidad", size(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s2color)

histogram accel_credit, normal ///
    fcolor(gs13) lcolor(gs8) ///
    title("Distribución de la aceleración del crédito", size(medsmall)) ///
    xtitle("Δ² Crédito (% PIB)", size(small)) ///
    ytitle("Densidad", size(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s2color)

* 7.4 Promedio del crédito antes, durante y después de crisis

* Calcular promedio de crédito en ventanas de tiempo
gen t_event = .
bysort ISO3: replace t_event = year - year[_n] if crisis_banking==1  // base inicial
* Simplificar: crear una variable que mida distancia a la última crisis
bysort ISO3 (year): replace t_event = year - year[_n-1] if missing(t_event)
recode t_event (min/-3 = -1 "Pre-crisis") (0 = 0 "Crisis") (1/3 = 1 "Post-crisis"), gen(periodo)

collapse (mean) credit_gdp, by(periodo)
graph bar (mean) credit_gdp, over(periodo, gap(5)) ///
    bar(1, color(navy)) bar(2, color(red)) bar(3, color(gs8)) ///
    title("Crédito bancario promedio antes, durante y después de crisis") ///
    ytitle("Crédito privado (% PIB)") blabel(bar)
	
graph bar (mean) credit_gdp, over(periodo, gap(10)) ///
    bar(1, fcolor(gs13) lcolor(gs8)) ///
    bar(2, fcolor(navy*0.6) lcolor(gs8)) ///
    blabel(bar, size(small) format(%9.2f)) ///
    title("Crédito bancario promedio antes, durante y después de crisis", size(medsmall)) ///
    ytitle("Crédito privado (% PIB)", size(small)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s2color)
	
* 7.5 Promedio del crédito antes, durante y después de crisis
clear all
set more off
use "C:\Users\julla\Downloads\Datos\Panel_final_macro_credit_crisis.dta", clear
twoway (line credit_gdp year if ISO3=="ARG", lcolor(navy)) ///
       (line rgdppc year if ISO3=="ARG", yaxis(2) lcolor(red)) ///
       , title("Crédito privado y PIB real - Argentina") ///
         ytitle("Crédito (% PIB)") ytitle("PIB per cápita (USD)", axis(2)) ///
         xtitle("Año") legend(order(1 "Crédito" 2 "PIB per cápita"))
		 
twoway (line credit_gdp year if ISO3=="ARG", lcolor(navy)) ///
       (line rgdppc year if ISO3=="ARG", yaxis(2) lcolor(red)), ///
       title("Crédito privado y PIB real - Argentina", size(medsmall)) ///
       ytitle("Crédito (% PIB)", size(small)) ///
       ytitle("PIB per cápita (USD)", axis(2) size(small)) ///
       xtitle("Año", size(small)) ///
       legend(order(1 "Crédito" 2 "PIB per cápita") region(lstyle(none)) size(vsmall)) ///
       graphregion(color(white)) plotregion(color(white)) ///
       scheme(s2color)

		 
* 7.6 Boxplot del crédito según presencia de crisis
graph box credit_gdp, over(crisis_banking) ///
    title("Distribución del crédito privado según crisis bancaria") ///
    ytitle("Crédito privado (% PIB)") ///
    legend(off)

graph box credit_gdp, over(crisis_banking) ///
    title("Distribución del crédito privado según crisis bancaria", size(medsmall)) ///
    ytitle("Crédito privado (% PIB)", size(small)) ///
    box(1, fcolor(gs13) lcolor(gs8)) ///
    box(2, fcolor(gs10) lcolor(gs8)) ///
    medtype(line) ///
    graphregion(color(white)) plotregion(color(white)) ///
    legend(off) scheme(s2color)

*-----------------------------------------------------
* 8. Timeline de crisis bancarias (corrige variable string)
*-----------------------------------------------------
capture drop id_iso
encode ISO3, gen(id_iso)
quietly su id_iso, meanonly
local ymax = r(max)

twoway scatter id_iso year if crisis_banking==1, ///
    msymbol(circle) msize(vsmall) mcolor(red) ///
    ylabel(1(1)`ymax', valuelabel angle(horizontal)) ///
    yscale(reverse range(1 `ymax')) ///
    xtitle("Año") ytitle("País (ISO3)") ///
    title("Crisis bancarias (1976–2008)") ///
    xscale(range(1960 2025)) graphregion(color(white))


/*************************************************************************************************
* PARTE VII – ECONOMETRÍA (definitiva)
* Objetivo: ¿ΔCrédito y su aceleración (t−1 / t−2) predicen crisis bancarias?
* Base: Panel_final_macro_credit_crisis.dta
* Estructura: ISO3 (string), year (int), crisis_banking, credit_gdp, d_credit, accel_credit,
*             rgdppc, inflation, openness, debt_gdp, (y ya generaste id en PARTE V).
**************************************************************************************************/

cls
clear all
set more off
version 17

*-----------------------------------------------------------------------------------------------
* 1) Cargar panel y declarar estructura
*-----------------------------------------------------------------------------------------------
use "C:\Users\julla\Downloads\Datos\Panel_final_macro_credit_crisis.dta", clear

* Asegurar identificadores de panel NUMÉRICOS (xtset requiere robustez)
capture confirm variable id
if _rc {
    encode ISO3, gen(id)
    label var id "País (ID numérico)"
}
xtset id year, yearly

* Controles (log de PIB pc)
capture confirm variable ln_rgdp_pc
if _rc {
    gen ln_rgdp_pc = ln(rgdppc)
    label var ln_rgdp_pc "ln(PIB per cápita real)"
}

* Rezagos: aseguramos que existan (Stata entiende L. tras xtset)
* (No generamos copias L1_*, usamos operadores L. directamente)
local ctrls ln_rgdp_pc inflation openness debt_gdp

* Cuántas crisis estarian siendo eliminadas por datos faltantes antes del drop. (eliminar o no eliminar?)
count if crisis_banking==1
count if crisis_banking==1 & missing(d_credit, accel_credit, ln_rgdp_pc, inflation, openness, debt_gdp)

* Limpieza mínima para el set de variables del modelo base
drop if missing(d_credit, accel_credit) & crisis_banking==0
bysort ISO3: count if missing(d_credit, accel_credit)

* Limpieza mínima: eliminar solo observaciones sin datos de crédito fuera de crisis
drop if missing(d_credit, accel_credit) & crisis_banking==0

* Cuántas crisis se mantienen luego de las que fueron eliminadas por datos faltantes.
count if crisis_banking==1
count if crisis_banking==1 & missing(d_credit, accel_credit, ln_rgdp_pc, inflation, openness, debt_gdp)

* (Opcional) Ventana común para no perder demasiadas obs por rezagos
* keep if inrange(year, 1984, 2023)

*----------------------------------------------------------------------
* 2. Crear versión "completa" y "reducida" del dataset
*----------------------------------------------------------------------
preserve
    * versión reducida solo con variables principales
    keep id year ISO3 crisis_banking d_credit accel_credit ln_rgdp_pc
    save Panel_reducido_credit.dta, replace
restore

preserve
    * versión completa con todos los controles
    keep id year ISO3 crisis_banking d_credit accel_credit ln_rgdp_pc inflation openness debt_gdp
    save Panel_completo_macro.dta, replace
restore

* Configuración del panel antes de la estimación
sort id year
xtset id year

*----------------------------------------------------------------------
* 3. Estimación MODELO REDUCIDO (solo crédito + PIB per cápita)
*----------------------------------------------------------------------
xtlogit crisis_banking L.d_credit L.accel_credit L.ln_rgdp_pc, fe
eststo modelo_reducido

*----------------------------------------------------------------------
* 4. Estimación MODELO COMPLETO (agrega controles macro)
*----------------------------------------------------------------------
xtlogit crisis_banking L.d_credit L.accel_credit L.ln_rgdp_pc L.inflation L.openness L.debt_gdp, fe
eststo modelo_completo

*----------------------------------------------------------------------
* 5. Comparar resultados
*----------------------------------------------------------------------
esttab modelo_reducido modelo_completo, ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    label compress title("Modelos Logit con efectos fijos: Crédito y crisis bancarias")

*-----------------------------------------------------------------------------------------------
* 6. Modelo PREDICTIVO (pooled logit con dummies país-año) → AUROC y matriz
*    Nota: usamos dummies de país y año para absorber efectos fijos; vce(cluster id)
*-----------------------------------------------------------------------------------------------

* Especificar controles (ya definidos arriba)
local ctrls ln_rgdp_pc inflation openness debt_gdp

* Estimación del modelo pooled logit con efectos fijos absorbidos por dummies
logit crisis_banking L1.d_credit L1.accel_credit `ctrls' i.id i.year, vce(cluster id)
est store Pooled_L1

* Predicciones para TODA la muestra; luego filtramos "test" por tiempo (fuera de muestra)
gen byte test = (year >= 2006)

predict double p_all, pr   // Probabilidades predichas para todo el panel

* Evaluar poder predictivo (solo en el período de test)
roctab crisis_banking p_all if test==1, graph

roctab crisis_banking p_all if test==1, graph


* Matrices de confusión para distintos umbrales de probabilidad
foreach c in 0.10 0.20 0.30 0.40 0.50 {
    disp as text "== Matriz de confusión (test, cutoff = `c') =="
    gen byte yhat_`=subinstr("`c'","0.","",.)' = (p_all >= `c') if test==1
    tab crisis_banking yhat_`=subinstr("`c'","0.","",.)' if test==1, row col
    drop yhat_`=subinstr("`c'","0.","",.)'
}

* (Referencia in-sample, si se requiere)
* lroc
* estat classification

*-----------------------------------------------------------------------------------------------
* 7. MODELO PRINCIPAL (inferencia): Panel Logit con Efectos Fijos por país
*    FE por país (condicional) + dummies de año
*-----------------------------------------------------------------------------------------------
xtlogit crisis_banking L1.d_credit L1.accel_credit `ctrls' i.year, fe
est store FE_L1

* Robustez temporal: t-2
xtlogit crisis_banking L2.d_credit L2.accel_credit `ctrls' i.year, fe
est store FE_L2

* Sensibilidad A: incluir nivel de crédito
xtlogit crisis_banking L1.credit_gdp L1.d_credit L1.accel_credit `ctrls' i.year, fe
est store FE_withLevel

* Sensibilidad B: foco en deuda pública
xtlogit crisis_banking L1.d_credit L1.accel_credit L1.debt_gdp ///
    `=subinstr("`ctrls'","debt_gdp","",.)' i.year, fe
est store FE_withDebt

*-----------------------------------------------------------------------------------------------
* 8. Comparativos (anexo): FE vs RE
*-----------------------------------------------------------------------------------------------

* 1️. Modelos lineales equivalentes (para poder aplicar Hausman formal)
xtreg crisis_banking L1.d_credit L1.accel_credit `ctrls' i.year, fe
est store FE_lin

xtreg crisis_banking L1.d_credit L1.accel_credit `ctrls' i.year, re
est store RE_lin

* 2️. Hausman clásico (sin opción sigmamore, que no aplica aquí)
hausman FE_lin RE_lin, sigmaless

* 3️. Si vuelve a salir "not positive definite", usar versión forzada (sigmamore o constant)
hausman FE_lin RE_lin, sigmamore constant


probit crisis_banking L1.d_credit L1.accel_credit `ctrls' i.id i.year, vce(cluster id)
est store Probit_L1

*-----------------------------------------------------------------------------------------------
* 9. Efectos marginales (sobre pooled logit con dummies)
*-----------------------------------------------------------------------------------------------
margins, dydx(L1.d_credit L1.accel_credit) post
est store Margins_pooled

*-----------------------------------------------------------------------------------------------
* 10. Diagnósticos rápidos
*-----------------------------------------------------------------------------------------------
pwcorr L1.d_credit L1.accel_credit `ctrls', sig star(0.05)

* Separación/rare-events (opcional; instalar si quieres)
* capture ssc install firthlogit
* firthlogit crisis_banking L1.d_credit L1.accel_credit `ctrls' i.ISO3 i.year, cluster(id)

*-----------------------------------------------------------------------------------------------
* 11. Exportes
*-----------------------------------------------------------------------------------------------
capture ssc install outreg2
outreg2 [Pooled_L1 FE_L1 FE_L2 FE_withLevel FE_withDebt RE_L1 Probit_L1] ///
    using "C:\Users\julla\Downloads\Datos\Resultados_credit_crisis.doc", replace ///
    ctitle(Pooled_L1 FE_L1 FE_L2 FE_Level FE_Debt RE_L1 Probit_L1) dec(3)

display "=== PARTE VII completada: Modelo principal FE (t-1), robustez (t-2), métricas predictivas (AUROC test) ==="
	
*-----------------------------------------------------------------------------------------------
* FIN DEL SCRIPT
*-----------------------------------------------------------------------------------------------
