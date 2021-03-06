
############################################
##                                        ##
##         Investing by numbers           ##
##   a quantitative trading strategy by   ##
##         Mathieu Bouville, PhD          ##
##      <mathieu.bouville@gmail.com>      ##
##                                        ##
##       SMA.r generates a strategy       ##
##        based on the crossing of        ##
##      simple moving averages (SMAs)     ##
##                                        ##
############################################


#default values of parameters:
setSMAdefaultValues <- function() {
   def$SMAinputDF    <<- "dat"
   def$SMAinputName  <<- "TR"

   def$SMA1_1       <<- 15L   # 14L # (optimized with costs = 2%)
   def$SMA2_1       <<-  2L   #  1L
   def$SMAbearish1  <<- 12.5  # 12
   def$SMAbullish1  <<- 12.5  # 12
   typical$SMA1     <<- paste0("SMA_", def$SMA1_1, "_", def$SMA2_1, "_", def$SMAbearish1, "_", def$SMAbullish1)

   def$SMA1_2       <<- 10L    # optimized with costs = 2%
   def$SMA2_2       <<-  5L
   def$SMAbearish2  <<- 19
   def$SMAbullish2  <<- 18.5
   typical$SMA2     <<- paste0("SMA_", def$SMA1_2, "_", def$SMA2_2, "_", def$SMAbearish2, "_", def$SMAbullish2)
}

## calculating simple moving average (SMA)
calcSMA <- function(inputDF, inputName, avgOver, SMAname) {
   if (inputDF=="dat")             input <- dat[, inputName]
   else if (inputDF=="signal")     input <- signal[, inputName]
   else if (inputDF=="alloc")      input <- alloc[, inputName]
   else if (inputDF=="TR")         input <- TR[, inputName]
   else if (inputDF=="next30yrs")  input <- next30yrs[, inputName]
   else stop("data frame ", inputDF, " not recognized")

   addNumColToDat(SMAname)
   dat[1:(avgOver-1), SMAname] <<- NA
   for(i in avgOver:numData) 
      dat[i, SMAname] <<- mean(input[(i-avgOver+1):i], na.rm=F)
}


calcSMAsignal <- function(SMAname1, SMAname2,
                          bearish=def$BollBearish, bullish=def$BollBullish, 
                          signalMin=def$signalMin, signalMax=def$signalMax,
                          strategyName, startIndex) {
   requireColInDat(SMAname1)
   requireColInDat(SMAname2)
   addNumColToSignal(strategyName)
   
   SMAratio <- dat[, SMAname1] / dat[, SMAname2] - 1
   
   calcSignalForStrategy(strategyName, input=SMAratio, bearish=bearish, bullish=bullish,
                         signalMin=signalMin, signalMax=signalMax, startIndex=startIndex ) 
}


createSMAstrategy <- function(inputDF="dat", inputName="TR", SMA1=def$SMA1, SMA2=def$SMA2, 
                              bearish=def$detrendedBearish, bullish=def$detrendedBullish, 
                              signalMin=def$signalMin, signalMax=def$signalMax,
                              strategyName="", type="", futureYears=def$futureYears, costs=def$tradingCost, 
                              coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=F) {
   
   if(strategyName=="") {
      if (inputName=="TR")
         strategyName <- paste0("SMA_", SMA1, "_", SMA2, "_", bearish, "_", bullish)
      else
         strategyName <- paste0("SMA_", SMA1, "_", SMA2, "_", bearish, "_", bullish, "__", inputName)
   }
   
   ## Calculating startIndex
   if (inputDF=="dat")             input <- dat[, inputName]
   else if (inputDF=="signal")     input <- signal[, inputName]
   else if (inputDF=="alloc")      input <- alloc[, inputName]
   else if (inputDF=="TR")         input <- TR[, inputName]
   else if (inputDF=="next30yrs")  input <- next30yrs[, inputName]
   else stop("data frame ", inputDF, " not recognized")
   startIndex <- sum(is.na(input)) + max(SMA1, SMA2) + 1
   
   if (bullish == bearish) 
      bullish = bearish - 1e-3 # bearish=bullish creates problems
   bearish <- bearish/1000
   bullish <- bullish/1000
   
   SMAname1 <- paste0("SMA_", inputName, "_", SMA1)
   if (!(SMAname1 %in% colnames(dat)) | force)
      calcSMA(inputDF, inputName, SMA1, SMAname1)      
   SMAname2 <- paste0("SMA_", inputName, "_", SMA2)   
   if (!(SMAname2 %in% colnames(dat)) | force)
      calcSMA(inputDF, inputName, SMA2, SMAname2)   
   
   if (!(strategyName %in% colnames(TR)) | force) { # if data do not exist yet or we force recalculation:   
      calcSMAsignal(SMAname1, SMAname2, bearish=bearish, bullish=bullish, 
                    signalMin=signalMin, signalMax=signalMax, 
                    strategyName=strategyName, startIndex=startIndex)
      calcAllocFromSignal(strategyName)
#       calcSMAallocation(SMA1, SMA2, offset, ratioLow, ratioHigh, allocLow, allocHigh, strategyName=strategyName)
      addNumColToTR(strategyName)
      calcStrategyReturn(strategyName, startIndex=startIndex)
   }
   
   if ( !(strategyName %in% parameters$strategy) | force) {
      if ( !(strategyName %in% parameters$strategy) ) {
         parameters[nrow(parameters)+1, ] <<- NA
         parameters$strategy[nrow(parameters)] <<- strategyName
      }
      index <- which(parameters$strategy == strategyName)
      
      parameters$strategy[index] <<- strategyName
      if(inputName=="TR")
         if (type=="training") {
            parameters$type[index]    <<- "training"
            parameters$subtype[index] <<- "SMA"        
         } else {
            parameters$type[index]    <<- "SMA"
            parameters$subtype[index] <<- inputName
         }
      else if(substr(inputName, 1, 4)=="CAPE")
         if (type=="training") {
            parameters$type[index]    <<- "training"
            parameters$subtype[index] <<- paste0("SMA_CAPE")
         } else {
            parameters$type[index]    <<- paste0("SMA_CAPE")
            parameters$subtype[index] <<- inputName
         } 
      else if(substr(inputName, 1, 9)=="detrended")
         if (type=="training") {
            parameters$type[index]    <<- "training"
            parameters$subtype[index] <<- paste0("SMA_detrended")
         } else {
            parameters$type[index]    <<- paste0("SMA_detrended")
            parameters$subtype[index] <<- inputName
         }
      parameters$startIndex[index] <<- startIndex
      parameters$inputDF[index]    <<- inputDF
      parameters$inputName[index]  <<- inputName
      parameters$bearish[index]    <<- bearish
      parameters$bullish[index]    <<- bullish      
      
       parameters$name1[index] <<- "SMA1"
      parameters$value1[index] <<-  SMA1
       parameters$name2[index] <<- "SMA2"
      parameters$value2[index] <<-  SMA2
   }
   calcStatisticsForStrategy(strategyName=strategyName, futureYears=futureYears, costs=costs,
                             coeffTR=coeffTR, coeffVol=coeffVol, coeffDD2=coeffDD2, force=force)
   stats$type[which(stats$strategy == strategyName)] <<- parameters$type[which(parameters$strategy == strategyName)]
   stats$subtype[which(stats$strategy == strategyName)] <<- parameters$subtype[which(parameters$strategy == strategyName)]
}



calcOptimalSMA <- function(inputDF, inputName=CAPEname, minSMA1, maxSMA1, bySMA1, minSMA2, maxSMA2, bySMA2, 
                            minBear, maxBear, byBear,  minDelta, maxDelta, byDelta, 
                            futureYears, costs, minTR, maxVol, maxDD2, minTO, minScore, 
                            xMinVol, xMaxVol, xMinDD2, xMaxDD2, countOnly,
                            type, col, plotType, nameLength, plotEvery, 
                            referenceStrategies, force) {
   
   counterTot <- 0; counterNew <- 0
   lastTimePlotted <- proc.time()
   
   # creating ranges that allow to sample the parameter space broadly initially
   rangeSMA1  <- createRange(minSMA1,  maxSMA1,  bySMA1)
   rangeSMA2  <- createRange(minSMA2,  maxSMA2,  bySMA2)
   rangeBear  <- createRange(minBear,  maxBear,  byBear)
   rangeDelta <- createRange(minDelta, maxDelta, byDelta)   
   
   for (SMA1 in rangeSMA1) 
      for (SMA2 in rangeSMA2)       
         for (bear in rangeBear) {     
            for (delta in rangeDelta) {
               bull = bear - delta 
               
               if (inputName=="TR")
                  strategyName <- paste0("SMA_", SMA1, "_", SMA2, "_", bear, "_", bull)
               else
                  strategyName <- paste0("SMA_", SMA1, "_", SMA2, "_", bear, "_", bull, "__", inputName)
               
               if (delta==0) bull = bear - 1e-3 # bear=bull creates problems
               
               counterTot <- counterTot + 1 
               if(countOnly) {
                  if ( !(strategyName %in% colnames(TR)) | !(strategyName %in% colnames(alloc)) )
                     counterNew <- counterNew + 1                  
               } else {
                  createSMAstrategy(inputDF=inputDF, inputName=inputName, SMA1=SMA1, SMA2=SMA2,
                                    bearish=bear, bullish=bull, signalMin=def$signalMin, signalMax=def$signalMax,
                                    strategyName=strategyName, force=force)                  
                  showSummaryForStrategy(strategyName, futureYears=futureYears, costs=costs, 
                                         minTR=minTR, maxVol=maxVol, maxDD2=maxDD2, minTO=minTO, minScore=minScore, 
                                         nameLength=nameLength, force=F)
               }
            }
            if ( !countOnly && (summary(proc.time())[[1]] - lastTimePlotted[[1]] ) > plotEvery ) { 
               # we replot only if it's been a while
               plotAllReturnsVsTwo(col=col, trainingPlotType=plotType,
                                   xMinVol=xMinVol, xMaxVol=xMaxVol, xMinDD2=xMinDD2, xMaxDD2=xMaxDD2)
               lastTimePlotted <- proc.time()
            }
         }
   if(countOnly)
      print (paste0("Running ", counterTot, " parameter sets (", counterNew, " new)"))
}


searchForOptimalSMA <- function(inputDF="dat", inputName="TR", 
                                minSMA1= 13L, maxSMA1= 15L, bySMA1= 1L,
                                minSMA2=  1L, maxSMA2=  2L, bySMA2= 1L, 
                                minBear= 11,  maxBear= 14,  byBear= 0.5, 
                                minDelta= 0,  maxDelta= 3,  byDelta=0.5,
                                futureYears=def$futureYears, costs=def$tradingCost+def$riskAsCostTechnical, 
                                minTR=0, maxVol=def$maxVol, maxDD2=def$maxDD2, minTO=0.7, minScore=13, 
                                xMinVol=14., xMaxVol=18., xMinDD2=6, xMaxDD2=10,
                                type="training", col=F, plotType="symbols", 
                                nameLength=22, plotEvery=def$plotEvery, countOnly=F,
                                referenceStrategies=c(typical$SMA1, typical$SMA2), force=F) {
   
   if (dataSplit != "training") 
      warning("Doing training in '", dataSplit, "' mode.", immediate.=T)
   
   cleanUpStrategies()
   
   # calculate how many parameters sets will be run
   calcOptimalSMA(inputDF, inputName, minSMA1, maxSMA1, bySMA1, minSMA2, maxSMA2, bySMA2, 
                  minBear, maxBear, byBear,  minDelta, maxDelta, byDelta, 
                  futureYears, costs, minTR, maxVol, maxDD2, minTO, minScore, 
                  xMinVol=xMinVol, xMaxVol=xMaxVol, xMinDD2=xMinDD2, xMaxDD2=xMaxDD2, 
                  type, col, plotType, nameLength, plotEvery, countOnly=T, 
                  referenceStrategies=referenceStrategies, force)
   
   dashes <- displaySummaryHeader(futureYears=futureYears, nameLength=nameLength)
   
   # actually calculating
   calcOptimalSMA(inputDF, inputName, minSMA1, maxSMA1, bySMA1, minSMA2, maxSMA2, bySMA2, 
                  minBear, maxBear, byBear,  minDelta, maxDelta, byDelta, 
                  futureYears, costs, minTR, maxVol, maxDD2, minTO, minScore, 
                  xMinVol=xMinVol, xMaxVol=xMaxVol, xMinDD2=xMinDD2, xMaxDD2=xMaxDD2, 
                  type, col, plotType, nameLength, plotEvery, countOnly=F,
                  referenceStrategies=referenceStrategies, force)
      
   print(dashes)
   for ( i in 1:length(referenceStrategies) )
      showSummaryForStrategy(referenceStrategies[i], nameLength=nameLength, costs=costs)
   plotAllReturnsVsTwo(col=col, costs=costs, trainingPlotType=plotType,
                       xMinVol=xMinVol, xMaxVol=xMaxVol, xMinDD2=xMinDD2, xMaxDD2=xMaxDD2)
}



searchForTwoOptimalSMA <-function(minScore1=13.5, minScore2=14.55, do1=T, do2=T,
                                  lotType="symbols", force=F) {
   if(do1) {
      print("SMA1")
      searchForOptimalSMA(minSMA1= 13L, maxSMA1= 16L, bySMA1= 1L,
                          minSMA2=  1L, maxSMA2=  3L, bySMA2= 1L, 
                          minBear= 11,  maxBear= 14,  byBear= 0.5, 
                          minDelta= 0,  maxDelta= 2,  byDelta=0.5, 
                          referenceStrategies=typical$SMA1, minScore=minScore1)
   }
   if(do1 && do2) { # needed only if we do both
      print("")
      print("*********************************************************************")
      print("")
   }
   if(do2) {   
      print("SMA2")
      searchForOptimalSMA(minSMA1= 9L, maxSMA1=11L, bySMA1= 1L,
                          minSMA2= 4L, maxSMA2= 6L, bySMA2= 1L, 
                          minBear=18,  maxBear=21,  byBear= 0.5, 
                          minDelta=0,  maxDelta=4,  byDelta=0.5, 
                          referenceStrategies=typical$SMA2, minScore=minScore2)
   }
}


## OBSOLETE
plotSMA <- function(SMA1=def$SMA1, SMA2=def$SMA2, futureYears=def$FutureYears, startYear=1885) {
   futureReturnName <- paste0("future", futureYears)
#    if (!futureReturnName %in% colnames(dat)) calcStocksFutureReturn(futureYears)
#    SMAname1 <- paste0("SMA", SMA1)
#    SMAname2 <- paste0("SMA", SMA2)
#    
#    par(mar=c(2.5, 4, 1.5, 1.5))
#    par(mfrow = c(2, 1))
#    temp <- numeric(numData)
#    
#    temp <- dat[, SMAname1] / dat[, SMAname2] - 1
#    
#    plot(dat$date, temp, type="l", xlim=c(dat$date[(startYear-1871)*12], dat$date[numData]), xlab="SMA ratio", 
#         ylab=paste0(SMAname1," / ",SMAname2," - ", 1+round(m,2)), ylim=c(-.5,.5))
#    plot(temp, dat[, futureReturnName], xlab="SMA ratio", ylab="future return", xlim=c(-.5,.5))
#    mod <- lm( dat[, futureReturnName] ~ temp)
#    abline(mod)
}
