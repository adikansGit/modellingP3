################################
# DTmin optimisation
################################
# Sets & Parameters
reset;
set Time default {}; #your time set from the MILP part

param Irr{t in Time}; 
param Qpeople{t in Time};
param Qelec{t in Time};
param Text{t in Time};
param Area>=0.001; #defined .dat file.

param Tint := 21;
param Uenv := 3.4; # could be changed according to kth; (W/(m2.K))
param mair := 2.5; # m3/m2/h
param Cpair := 1.152; # J/m3K
param Uvent := 0.025; # air-air HEX
param ksun := 0.05; # ksun value

param EPFLMediumT:= 65; ##[degC] - desired temperature high temperature loop
param EPFLMediumOut := 30; # temperature of return low temperature loop
param top{Time}; #your operating time from the MILP part

param CarnotEff := 0.55; #assumption: carnot efficiency of heating heat pumps
param Cel := 0.15; #[CHF/kWh] operating cost for buying electricity from the grid

param THPhighin := 7; #[deg C] temperature of water coming from lake into the evaporator of the HP
param THPhighout := 3; #[deg C] temperature of water coming from lake into the evaporator of the HP

param i:= 0.06 ; #interest rate
param n := 20; #[y] life-time
param FBMHE := 4.74; #bare module factor of the heat exchanger
param INew := 605.7; #chemical engineering plant cost index (2015)
param IRef := 394.1; #chemical engineering plant cost index (2000)
param aHE := 1200; #HE cost parameter
param bHE := 0.6; #HE cost parameter

################################
# Variables

var E{Time} >= 0.0001; # kW] electricity consumed by the heat pump (using pre-heated lake water)
var E2{Time} >= 0.0001;#[kW] electricity consumed by the heat pump (not using pre-heated lake water)
var TLMCond{Time} >= 0.0001; #[K] logarithmic mean temperature in the condensor of the heating HP (using pre-heated lake water)

var Qevap{Time} >= 0.0001; #[kW] heat extracted in the evaporator of the heating HP (using pre-heated lake water)
var Qcond{Time} >= 0.0001; #[kW] heat delivered in the condensor of the heating HP (using pre-heated lake water)
var Qcond2{Time} >= 0.0001;
var COP{Time} >= 0.0001; #coefficient of performance of the heating HP 
var COP2{Time} >= 0.0001; #coefficient of performance of the 2nd HP 

var OPEX >= 0.0001; #[CHF/year] operating cost
var CAPEX >= 0.0001; #[CHF/year] annualized investment cost
var TC >= 0.0001; #[CHF/year] total cost

var Qheating{Time} >= 0; #..." a variable in the case of heat recovery from air ventilation"
var Text_new{Time}; #new temperature entering the building
var Trelease{Time}; #outlet temperature after Ventilation HEX
var TLMEvapHP{Time} >= 0.0001; #[K] logarithmic mean temperature in the evaporator of the heating HP (not using pre-heated lake water)
var TLMEvapHP2{Time} >= 0.0001; #[K] logarithmic mean temperature in the evaporator of the heating HP (not using pre-heated lake water)

var Heat_Vent{Time} >= 0.0001;
var DTLNVent{Time} >= 0.0001;
var Area_Vent >=0.1;
var DTminVent >= 0.1;

var Trelease2{Time} >=5;

################################
# Constraints
#######
subject to sure_temp {t in Time}: # condition to ensure that a certain temperature is higher than other.


subject to sure_temp2 {t in Time}: # condition to ensure that a certain temperature is higher than other.


subject to HeatingLoad1 {t in Time}: #The heating demand calculation; pay attention to the UNITS;


subject to Heat_Vent1 {t in Time}: # Ventilation heat provided by one side of the HEX


subject to Heat_Vent2 {t in Time}: # Ventilation heat provided by the other side of the HEX


subject to DTLNVent1 {t in Time}: #DTLN HEX - pay attention to this value


subject to Area_Vent1 {t in Time}: #the area of the heat recovery HE can be computed using the heat extracted, the heat transfer coefficient and the logarithmic mean temperature difference 


subject to DTminVent1 {t in Time}: #DTmin condition on one side;


subject to DTminVent2 {t in Time}: #DTmin condition on the other side of the HEX;



## MEETING HEATING DEMAND, ELECTRICAL CONSUMPTION

subject to Electricity1{t in Time}: #the electricity consumed in the HP can be computed using the heat delivered and the heat extracted


subject to Electricity{t in Time}: #the electricity consumed in the HP can be computed using the heat delivered and the COP


subject to Electricity2{t in Time}: #the electricity consumed in the 2nd HP can be computed using the heat delivered and the COP


subject to COPerformance{t in Time}: #the COP can be computed using the carnot efficiency and the logarithmic mean temperatures in the condensor and in the evaporator


subject to COPerformance2{t in Time}: #the COP of the 2nd HP can be computed using the carnot efficiency and the logarithmic mean temperatures in the condensor and in the evaporator


subject to dTLMCondensor{t in Time}: #the logarithmic mean temperature in the condenser. Note: should be in K


subject to dTLMEvaporatorHPhigh{t in Time}: #the logarithmic mean temperature (2nd HP) can be computed using the inlet and outlet temperatures, Note: should be in K


subject to dTLMEvaporatorHP{t in Time}: #the logarithmic mean temperature (HP) can be computed using the inlet and outlet temperatures, Note: should be in K


subject to QEPFLausanne{t in Time}: #the heat demand of EPFL should be the sum of the heat delivered by the 2 systems;


subject to OPEXcost: #the operating cost can be computed using the electricity consumed in the two heat pumps


subject to CAPEXcost: #the investment cost can be computed using the area of the heat recovery heat exchanegr


subject to TCost: #the total cost can be computed using the operating and investment cost


################################
minimize obj :
