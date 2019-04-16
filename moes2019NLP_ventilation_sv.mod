################################
# DTmin optimisation
################################
# Sets & Parameters
reset;
set Time; #your time set from the MILP part
set Buildings;

param Irr{t in Time}; 
param Qpeople{t in Time};
param Qelec{b in Buildings};
param Text{t in Time};
param Area{b in Buildings}; #defined .dat file.
param totArea = 142982; #Sum of heated area of medium temperature buildings

param Tint := 21;
param Uenv{b in Buildings}; # could be changed according to kth; (kW/(m2.K))
param mair := 0.00069444; # m3/m2/s
param Cpair := 1.152; # kJ/m3K
param Uvent := 0.025; # air-air HEX
param ksun{b in Buildings}; # ksun value

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
#param Trelease2 = 13;

################################
# Variables

var E{Time} >= 0.0001; # kW] electricity consumed by the heat pump (using pre-heated lake water)
var E2{Time} >= 0.0001;#[kW] electricity consumed by the heat pump (not using pre-heated lake water)
var TLMCond >= 0.0001; #[K] logarithmic mean temperature in the condensor of the heating HP (using pre-heated lake water)
#var TLMCond2{Time} >= 0.0001; 

var Qevap{Time} >= 0.0001; #[kW] heat extracted in the evaporator of the heating HP (using pre-heated lake water)
var Qevap2{Time} >= 0.0001;
var Qcond{Time} >= 0.0001; #[kW] heat delivered in the condensor of the heating HP (using pre-heated lake water)
var Qcond2{Time} >= 0.0001; #[kW] heat delivered in the condensor of the heating HP (not using pre-heated lake water)
var COP >= 0.0001; #coefficient of performance of the heating HP 
var COP2{Time} >= 0.0001; #coefficient of performance of the 2nd HP 

var OPEX >= 0.0001; #[CHF/year] operating cost
var CAPEX >= 0.0001; #[CHF/year] annualized investment cost
var TC >= 0.0001; #[CHF/year] total cost

var Qheating{Time} >= 0; #..." a variable in the case of heat recovery from air ventilation"
var Text_new{Time}; #new temperature entering the building
var Trelease{Time}; #outlet temperature after Ventilation HEX
var TLMEvapHP >= 0.0001; #[K] logarithmic mean temperature in the evaporator of the heating HP (using pre-heated lake water)
var TLMEvapHP2{Time} >= 0.0001; #[K] logarithmic mean temperature in the evaporator of the heating HP (not using pre-heated lake water)

var Heat_Vent{Time} >= 0.0001;
var DTLNVent{Time} >= 0.0001;
var Area_Vent >=0.1, <= 500;
var DTminVent{Time} >= 0.1;	#Made this a variable in Time so the condition is satisfied separately in each time period.

var Trelease2 >=5, <= 15; #outlet temperature after air-water heat pump evaporator

################################
# Constraints
#######
subject to sure_temp {t in Time}: # condition to ensure that a certain temperature is higher than other.
Text_new[t] <= Tint;

#subject to sure_temp2 {t in Time}: # condition to ensure that a certain temperature is higher than other.
#Trelease[t] >= Text[t];

subject to sure_temp3 {t in Time}: # condition to ensure that a certain temperature is higher than other.
Trelease[t] >= Trelease2;

subject to HeatingLoad1 {t in Time}: #The heating demand calculation; pay attention to the UNITS;
Qheating[t] = sum{b in Buildings} max((Area[b]*((Uenv[b]*(Tint-Text[t]))+(mair*Cpair*(Tint-Text_new[t]))-(ksun[b]*Irr[t])-Qpeople[t])-Qelec[b]),0);

subject to Heat_Vent1 {t in Time}: # Ventilation heat provided by one side of the HEX
Heat_Vent[t] = totArea*Cpair*mair*(Text_new[t]-Text[t]);

subject to Heat_Vent2 {t in Time}: # Ventilation heat extracted (provided) by the other side of the HEX
Heat_Vent[t] = totArea*Cpair*mair*(Tint-Trelease[t]);

subject to DTLNVent1 {t in Time}: #DTLN HEX - pay attention to this value
DTLNVent[t] = (((Tint-Text_new[t])*(Trelease[t]-Text[t])^2+(Trelease[t]-Text[t])*(Tint-Text_new[t])^2)/2)^(1/3);

subject to Area_Vent1 {t in Time}: #the area of the heat recovery HE can be computed using the heat extracted, the heat transfer coefficient and the logarithmic mean temperature difference 
Area_Vent >= Heat_Vent[t]/(Uvent*DTLNVent[t]);

subject to DTminVent1 {t in Time}: #DTmin condition on one side;
DTminVent[t] = Tint-Text_new[t];

subject to DTminVent2 {t in Time}: #DTmin condition on the other side of the HEX;
DTminVent[t] = Trelease[t]-Text[t];


## MEETING HEATING DEMAND, ELECTRICAL CONSUMPTION

subject to Electricity1{t in Time}: #the electricity consumed in the HP can be computed using the heat delivered and the heat extracted
E[t] = Qcond[t] - Qevap[t];

subject to Electricity{t in Time}: #the electricity consumed in the HP can be computed using the heat delivered and the COP
E[t] = Qcond[t]/COP;

subject to Electricity2{t in Time}: #the electricity consumed in the 2nd HP can be computed using the heat delivered and the COP
E2[t] = Qcond2[t]/COP2[t];

subject to Electricity3{t in Time}: #the electricity consumed in the 2nd HP can be computed using the heat delivered and the COP
E2[t] = Qcond2[t] - Qevap2[t];

subject to COPerformance: #the COP can be computed using the carnot efficiency and the logarithmic mean temperatures in the condensor and in the evaporator
COP = CarnotEff*(TLMCond/(TLMCond-TLMEvapHP));

subject to COPerformance2{t in Time}: #the COP of the 2nd HP can be computed using the carnot efficiency and the logarithmic mean temperatures in the condensor and in the evaporator
COP2[t] = CarnotEff*(TLMCond/(TLMCond - TLMEvapHP2[t]));

subject to dTLMCondensor: #the logarithmic mean temperature in the condenser. Note: should be in K
TLMCond = (EPFLMediumT - EPFLMediumOut)/log((EPFLMediumT + 273)/(EPFLMediumOut + 273));

#subject to dTLMCondensor2: #the logarithmic mean temperature in the condenser for air-water heat pump. Note: should be in K
#TLMCond2[t] = (EPFLMediumT - EPFLMediumOut)/log((EPFLMediumT + 273)/(EPFLMediumOut + 273));

subject to HeatMax{t in Time}: #the electricity consumed in the 2nd HP can be computed using the heat delivered and the COP
Qevap2[t] = totArea*mair*Cpair*(Trelease[t] - Trelease2);


subject to dTLMEvaporatorHPhigh{t in Time}: #the logarithmic mean temperature (2nd HP) can be computed using the inlet and outlet temperatures, Note: should be in K
TLMEvapHP2[t] = ((((Trelease[t]+273)*(Trelease2+273)^2) + ((Trelease2+273)*(Trelease[t]+273)^2))/2)^(1/3);
#(Trelease[t] - Trelease2)/log((Trelease[t] + 273)/(Trelease2 + 273));


subject to dTLMEvaporatorHP: #the logarithmic mean temperature (HP) can be computed using the inlet and outlet temperatures, Note: should be in K
TLMEvapHP = (THPhighin - THPhighout)/log((THPhighin + 273)/(THPhighout + 273));


subject to QEPFLausanne{t in Time}: #the heat demand of EPFL should be the sum of the heat delivered by the 2 systems;
Qheating[t] = Qcond[t] + Qcond2[t];

subject to OPEXcost: #the operating cost can be computed using the electricity consumed in the two heat pumps
OPEX = sum{t in Time}(top[t]*(E[t] + E2[t])*Cel);

subject to CAPEXcost: #the investment cost can be computed using the area of the heat recovery heat exchanegr
CAPEX = (INew/IRef)*aHE*(Area_Vent^bHE)*FBMHE* (i*(1+i)^n)/((1+i)^n - 1);

subject to TCost: #the total cost can be computed using the operating and investment cost
TC = OPEX + CAPEX;

################################
minimize obj :
TC;