### "http://mathieu.bouville.name/finance/CAPE/"

source("plotting.r")
source("utils.r")
source("DD.r")

source("CAPE.r")
source("Bollinger.r")
source("SMA.r")
source("momentum.r")



start()


# showSummaries(years=years, tradingCost=tradingCost, detailed=T, force=F)
#  showSummaries(years=years, tradingCost=2/100, detailed=F, force=F)

# calcMultiStrategyReturn("SMA12_1Unbound", "BollTR21_0.6_-0.5Unbound", "momentum12_15_25Unbound", "", 0.6, 0.2, 0.2, 0, 
#                         outputName="hiFreqUB", 12, delta="", force=F)
# #   showSummaryStrategy("hiFreq60_20_20", years=years, tradingCost=tradingCost, force = F)
# #   showSummaryStrategy("hiFreqUB", years=years, tradingCost=tradingCost, force = T)
# 
# calcSMAofStrategy("hiFreqUBUnbound", 4, outputName="hiFreqUB_SMA4", force=F)
# calcMultiStrategyReturn("hiFreqUBUnbound", "hiFreq_SMA4", "CAPE10avg24", "CAPE10avg24Unbound", .3, .25, .15, .3,
#                         outputName="balancedUB", 10*12, delta="", force=T)
# calcMultiStrategyReturn("hiFreqUBUnbound", "hiFreq_SMA4", "CAPE10avg24", "CAPE10avg24Unbound", .3, .25, .15, .3,
#                         outputName="balancedUB2", 10*12, delta="", force=T)
# showSummaryStrategy("balanced40_25_10_25", displayName="balanced ", years=years, tradingCost=tradingCost, force=T)
#   showSummaryStrategy("balancedUB", years=years, tradingCost=tradingCost, force=T)
#   showSummaryStrategy("balancedUB2", years=years, tradingCost=tradingCost, force=T)

ptm <- proc.time()

thr <- -.1/100
# print( round(CalcAllDrawdowns("stocks")*100,1) )

# print(paste0("DD such that stocks did worse than ", thr*100, "%, in chronological order:"))
# print( round(showMajorDrawdowns("stocks", thr)*100,0) )
# print( sapply(c("BollTR21_0.6_-0.5", "SMA12_1", "momentum12_15_25", "hiFreq60_20_20", "CAPE10avg24", "balanced40_25_10_25"), 
#        function(x) round(showMajorDrawdownsWithReference(x, "stocks", thr)*100,0) ) )


# lapply(c("CAPE10avg24", "hiFreq60_20_20", "balanced40_25_10_25"), 
#        function(x) print( round(CalcMajorDrawdowns("stocks", -.2)/CalcMajorDrawdownsWithReference(x, "stocks", thr),1) ) )
#print( round((CalcMajorDrawdownsWithReference("balanced40_25_10_25", "stocks", -.2)-CalcMajorDrawdowns("stocks", thr))*100,1) )

# print(paste0("DD worse than ", thr*100, "%, in decreasing order:"))
# print( round(showWorstDrawdowns("stocks", thr)*100,0) )
# print( c("CAPE10avg24", "hiFreq60_20_20", "balanced40_25_10_25") )
# sapply(c("CAPE10avg24", "hiFreq60_20_20", "balanced40_25_10_25"), 
#        function(x) print( round(showWorstDrawdowns(x, thr, na.rm=F)*100,0) ) )

# print(paste0("DD such that stocks did worse than ", thr*100, "%, in chronological order:"))
# stratList <- c("dates", "inflation", "stocks", "BollTR21_0.6_-0.5", "SMA12_1", "momentum12_15_25", "hiFreq60_20_20", "CAPE10avg24", "balanced40_25_10_25")
# temp <- sapply(stratList, function(x) showWorstDrawdownsWithReference(x, "stocks", thr, na.rm=F) )
# temp[, 2:9] <- as.numeric(temp[, 2:9])





# print( proc.time() - ptm)

# plotReturn("hiFreq60_20_20", "balUB_30_10_10(3)_50", "balanced40_25_10_25", "stocks", startYear=1884, endYear=2015, maxTR=100000)
# 
# plotFutureReturn("", "balUB_30_10_10(3)_50", "balanced40_25_10_25", "stocks", 
#                               years=years, startYear=1880, endYear=(2015-years), minTR=.03, maxTR=.15)
                
if (!(paste0("hiFreq60_20_20Future",defFutureYears) %in% colnames(strategy))) 
   calcStrategyFutureReturn("hiFreq60_20_20", defFutureYears)
if (!(paste0("balanced40_25_10_25Future",defFutureYears) %in% colnames(strategy))) 
   calcStrategyFutureReturn("balanced40_25_10_25", defFutureYears)
# if (!(paste0("stocksFuture",defFutureYears) %in% colnames(strategy))) 
#    calcStrategyFutureReturn("stocks", defFutureYears)
# if (!(paste0("alloc70_30Future",defFutureYears) %in% colnames(strategy))) 
#    calcStrategyFutureReturn("alloc70_30", defFutureYears)
#calcStocksFutureReturn(defFutureYears)


# plotReturn("hiFreq60_20_20", "CAPE10avg24", "balanced40_25_10_25", "stocks", startYear=1884, endYear=2015, maxTR=100000)
# plotFutureReturn("hiFreq60_20_20", "CAPE10avg24", "balanced40_25_10_25", "stocks", 
#              years=years, startYear=1880, endYear=(2015-years), minTR=.03, maxTR=.15)
# plotFutureReturn("hiFreq60_20_20", "CAPE10avg24", "balanced40_25_10_25", "stocks", 
#                  years=years, startYear=1880, endYear=(2015-years), minTR=-.02, maxTR=.24)



#   showSummaryStrategy("balanced40_30_30", years=years, tradingCost=tradingCost, force=F)
# #calcSMAstrategy("hiFreq60_20_20", 36, outputName="hiFreq_SMA36", force=F)
# calcMultiStrategyReturn(paste0("hiFreq_SMA",SMAnum), "CAPE10avg24", "CAPE10avg24Unbound", "", frac, frac2, frac2, 0, 
#                         outputName="balanced2", 10*12, delta="", force=T)
#   showSummaryStrategy("balanced2", years=years, tradingCost=tradingCost, force=T)
# showSummaryStrategy("balanced3", years=years, tradingCost=tradingCost, force=T)
# 



# lapply(c(1, 2, 3, 6, 9, 12, 15, 18, 21, 24, 36, 48, 60), calcSMA)

# for(months in seq(12, 12, by=3)) 
#    for(mLow in seq(10, 20, by=5))       
#       for(mHigh in seq(25, 30, by=5))
#          if ((mHigh-mLow > 5-1e-6)) 
#       {
#          name=paste0("m", months, "_", mLow, "_", mHigh)
#          
#          calcMomentumStrategyReturn(months, offset="mean", momentumLow=mLow/100, momentumHigh=mHigh/100, 
#                                     allocLow=1, allocHigh=0, outputName=name, force=F) 
#          #showSummaryStrategy(name, years=years, tradingCost=2/100, refReturn=7, refMedian=7, refFive=4.5, force=T)
#          showSummaryStrategy(name, years=years, tradingCost=4/100, refReturn=6, refMedian=5.5, refFive=3.5)
#       }  }



# SMAnum <- 4
# calcSMAofStrategy("hiFreq60_20_20Unbound", SMAnum, outputName=paste0("hiFreqUB_SMA",SMAnum), force=F)
# 
# for(SMAnum in seq(3, 4, by=1)) 
#    for(f1 in seq(70, 100, by=10)) 
#       for(f2 in seq(0, 60, by=10)) 
#          for(f3 in seq(0, 30, by=10)) {
#             f4 <- round(100 - f1 - f2 - f3)
#             name = paste0("bal", "_", f1, "_", f2, "_", f3, "(", SMAnum, ")_",  f4)
#             #print(name)
#             if ((f4 > 0-1e-6) & (f4 < 40+1e-6)) {
#                calcMultiStrategyReturn("balanced40_25_10_25", "hiFreq60_20_20", paste0("hiFreqUB_SMA",SMAnum), "CAPE10avg24Unbound", 
#                                        f1/100, f2/100, f3/100, f4/100, outputName=name, 10*12, delta="", force=F)
#                #showSummaryStrategy(name, years=years, tradingCost=2/100, refReturn=7.5, refMedian=6., refFive=3.5, cutoffScore="", force=T)
#                showSummaryStrategy(name, years=years, tradingCost=4/100, refReturn=5.9, refMedian=5.2, refFive=2.2, cutoffScore=1.5, force=T)
#             }
#          }
# showSummaryStrategy("balanced40_25_10_25", years=years, tradingCost=4/100, refReturn=6, refMedian=5.2, refFive=2.2, force=T)


# calcMultiStrategyReturn("multiHiFreq", "CAPE10avg24", "CAPE10avg24Unbound", "", 0.25, 0.65, 0.1, 0, 
#                         outputName="multiBalanced", 10*12, delta=0., force=T)
# showSummaryStrategy("multiBalanced", years=years, tradingCost=2.5/100, force=T)
# 
# calcMultiStrategyReturn("multiHiFreq", "CAPE10avg24", "CAPE10avg24Unbound", "", 0.3, 0.6, 0.1, 0, 
#                         outputName="multiBalanced", 10*12, delta=0.0, force=T)
# showSummaryStrategy("multiBalanced", years=years, tradingCost=2.5/100, force=T)
# 
# calcMultiStrategyReturn("multiHiFreq", "CAPE10avg24", "CAPE10avg24Unbound", "", 0.35, 0.55, 0.1, 0, 
#                         outputName="multiBalanced", 10*12, delta=0.05, force=T)
# showSummaryStrategy("multiBalanced", years=years, tradingCost=2.5/100, force=T)


# calcCAPEstrategyReturn(CAPEname="CAPE10avg24", offset=144, CAPElow=14.6, CAPEhigh=16.7, allocLow=1, allocHigh=0, force=T)
# calcMultiStrategyReturn("multiHiFreq", "CAPE10avg24Unbound", 0.75, outputName="multiBalanced", 12*12, delta=.02)
# showSummaryStrategy("multiBalanced")


# calcMomentumStrategyReturn(60, offset="mean", momentumLow=.15, momentumHigh=-.15, allocLow=1, allocHigh=0, force=T) 
# plotReturn("BollTR12_1_1", "momentum12", "multiHiFreq", "stocks", startYear=1885)

# plotFutureReturnVsCAPE(futureReturnYears=20, CAPEname1="CAPE10", CAPEname2="CAPE10avg24", CAPEmax=30)

# name1 <- "BollTR12_1_1"
# name2 <- "CAPE10avg24"
# calcBollTRstrategyReturn(avgOver=12, factorLow=1, factorHigh=1, "BollTR12_1_1")
# calcCAPEstrategyReturn(CAPEname=name2, offset=144, CAPElow=11.6, CAPEhigh=19.7, allocLow=1, allocHigh=0)
# plotFutureReturnVsAlloc(futureReturnYears=20, name1=name1, name2=name2) 
   
# calcBollCAPEstrategyReturn(avgOver=12, factorLow=.1, factorHigh=.1, "temp", years=10)
# showSummaryStrategy("temp")