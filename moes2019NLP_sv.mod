################################
# DTmin optimisation
################################
# Sets & Parameters
reset;
set Time default {1, 2, 3, 4, 6}; #your time set from the MILP part

param EPFLMediumT:= 65; #[degC] - desired temperature high temperature loop
param EPFLMediumOut := 30; # temperature of return low temperature loop
param Qheating{Time}; #your heat demand from the MILP part, will become a variable in the case of heat recovery from air ventilation
param top{Time}; #your operating time from the MILP part

param TDCin := 60; #[deg C] temperature of air coming from data center into the heat recovery HE
param UDC := 0.15; #[kW/(m2 K)] air-water heat transfer coefficient

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
param lower_TDCout := 30; #

param MassWater{Time}; # [KJ/(s degC)] MCp of water in the heat exchanger;

################################
# Variables
var dTminDC_1{Time} >= 0.1; #[deg C] minimum temperature difference in the heat recovery heat exchanger
#var dTminDC_2{Time} >= 0.1; #[deg C] minimum temperature difference in the heat recovery heat exchanger

var TDCout{Time} >= lower_TDCout, <= 59.999; #[deg C] temperature of air coming from data center out of the heat recovery HE
var AHEDC >= 0.0001; #[m2] area of heat recovery heat exchanger
var dTLMDC{Time} >= 0.01, <= 50; #logarithmic mean temperature difference in the heat recovery heat exchanger
var TRadin{Time} >= 30, <=60; #Outlet temperature of the HEX and entering the condenser.

var E{Time} >= 0.0001; # kW] electricity consumed by the heat pump (using pre-heated lake water)
var TLMCond{Time} >= 0.0001; #[K] logarithmic mean temperature in the condensor of the heating HP (using pre-heated lake water)
var Qevap{Time} >= 0.001; #[kW] heat extracted in the evaporator of the heating HP (using pre-heated lake water)
var Qcond{Time} >= 0.001; #[kW] heat delivered in the condensor of the heating HP (using pre-heated lake water)
var COP{Time} >= 0.001; #coefficient of performance of the heating HP (using pre-heated lake water)

var OPEX >= 0.001; #[CHF/year] operating cost
var CAPEX >= 0.001; #[CHF/year] annualized investment cost
var TC >= 0.001; #[CHF/year] total cost

var TLMEvapHP >= 0.0001; #[K] logarithmic mean temperature in the evaporator of the heating HP

var Qrad{Time} >=0, <=574; # Direct heat exchange heat amount; limited for the maximum amount of heat it could supply.

param MassDC := 19.1; # [KJ/(s degC)] MCp of air coming out of DC;


################################
# Constraints
####### Direct Heat Exchanger;

#subject to Tcontrol1{t in Time}: # condition to ensure that a certain temperature is higher than other.
	

#subject to Tcontrol2 {t in Time}: # condition to ensure that a certain temperature is higher than other.


subject to dTminDataCenter_1 {t in Time}: # DTmin counter-current heat exchanger
	TDCout[t] = EPFLMediumOut + dTminDC_1[t];

subject to dTminDataCenter_2 {t in Time}: #DTmin counter-current heat exchanger
	TRadin[t] = (MassDC*(TDCin - TDCout[t]))/MassWater[t] + EPFLMediumOut;

subject to dTLMDataCenter {t in Time}: #the logarithmic mean temperature difference in the heat recovery HE can be computed
	dTLMDC[t] = ((TDCin - TRadin[t]) - (TDCout[t] - EPFLMediumOut))/(log((TDCin - TRadin[t])/(TDCout[t] - EPFLMediumOut)));

subject to HeatBalance1{t in Time}: # Heat provided by the DC computed as a function of temperatures and flow.
	Qrad[t] = MassDC*(TDCin - TDCout[t]);

subject to AreaHEDC{t in Time}: #the area of the heat recovery HE can be computed using the heat extracted, the heat transfer coefficient and the logarithmic mean temperature difference 
	AHEDC >= Qrad[t]/(UDC*dTLMDC[t]);

subject to balancemax{t in Time}: # the maximum heat extracted is for sure lower than the total heating demand; pay attention to the units!
	Qrad[t] <= Qheating[t];


## MEETING HEATING DEMAND, ELECTRICAL CONSUMPTION


subject to Electricity{t in Time}: #the electricity consumed in the HP can be computed using the heat delivered and the heat extracted
	E[t] = Qcond[t] - Qevap[t];

subject to Electricity1{t in Time}: #the electricity consumed in the HP can be computed using the heat delivered and the COP
	E[t] = (Qheating[t]-Qrad[t])/COP[t];

subject to COPerformance{t in Time}: #the COP can be computed using the carnot efficiency and the logarithmic mean temperatures in the condensor and in the evaporator.
	COP[t] = CarnotEff*(TLMCond[t]/(TLMCond[t] - TLMEvapHP));

subject to TLMCondensor{t in Time}: #the logarithmic mean temperature in the condenser. Note: should be in K
	TLMCond[t] = (EPFLMediumT - TRadin[t])/log(EPFLMediumT/TRadin[t]);

subject to TLMEvaporatorHPhigh: #the logarithmic mean temperature in the evaporator can be computed using the inlet and outlet temperatures, Note: should be in K
	TLMEvapHP = (THPhighin - THPhighout)/log(THPhighin/THPhighout);

subject to QEPFLausanne{t in Time}: #the heat demand of EPFL should be the sum of the heat delivered by the 2 systems;
	Qheating[t] = Qrad[t] + Qcond[t];	

subject to OPEXcost: #the operating cost can be computed using the electricity consumed in the heat pump.
	OPEX = sum{t in Time}(top[t]*Qcond[t]*Cel/COP[t]);

subject to CAPEXcost: #the investment cost can be computed using the area of the heat recovery heat exchanegr
	CAPEX = (INew/IRef)*aHE*(AHEDC^bHE)*FBMHE* (i*(1+i)^n)/((1+i)^n - 1);

subject to TCost: #the total cost can be computed using the operating and investment cost
	TC = OPEX + CAPEX;

################################
minimize obj :  # TC or OPEX or CAPEX.
	TC;