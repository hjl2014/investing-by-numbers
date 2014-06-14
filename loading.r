
############################################
##                                        ##
##         Investing by numbers           ##
##   a quantitative trading strategy by   ##
##         Mathieu Bouville, PhD          ##
##      <mathieu.bouville@gmail.com>      ##
##                                        ##
##         loading.r loads data           ##
##       and initializes everything       ##
##                                        ##
############################################



setDefaultValues <- function(dataSplit, futureYears=10L, tradingCost=0.5/100, force=F) {
   if (!exists("def") | force) def <<- list()
   
   def$futureYears   <<- futureYears    # default value for the number of years over which future returns are calculated
   message("default futureYears: ", def$futureYears, " years")
   def$tradingCost   <<- tradingCost    # default value for the trading costs
   message("default tradingCost: ", def$tradingCost*100, "% / per year of turnover")
   if(dataSplit=="testing") {
      def$riskAsCost <<- 0
      message("default riskAsCost set to 0 for \'testing\' phase.")      
   } else {
      def$riskAsCost   <<- 0/100 # default value for the trading costs
      message("default riskAsCost: ", def$riskAsCost*100, "% / per year of turnover")
   }      
   
   def$dataStartYear <<- 1871
   def$startIndex    <<- round(10.5*12+1)
   def$plotStartYear <<- (def$startIndex-1)/12+def$dataStartYear
   
   def$CPUnumber     <<- 1 # Parallelization does not work
   
   ## coefficients to calculate the score
   def$coeffTR       <<- 0.6

   ## how many extra percentage points of return justify one extra percentage point of volatility.
   ## 0.05 means that we are indifferent if the volatility increases by 1%, 
   ## provided that the return increases by 0.05%
   def$coeffVol      <<- 0.05

   ## how many extra percentage points of return justify one extra unit of DD2.
   ## 1/8 means that we are indifferent if DD2 increases by 0.8, 
   ## provided that the return increases by at least 0.1%
   def$coeffDD2      <<- 1/8
   
   def$signalMin     <<- -0.2
   def$signalMax     <<-  1.2
   
   setPlottingDefaultValues()
   setCAPEdefaultValues()
   setDetrendedDefaultValues()
   setBollDefaultValues()
   setSMAdefaultValues()
   setReversalDefaultValues()
   setInflationDefaultValues()
   setCombinedDefaultValues()
   
   def$typicalStrategies <<- c(def$typicalBalanced, def$typicalTechnical, def$typicalValue, "stocks")
}

createStatsDF <- function(futureYears=def$futureYears) {
   stats <<- data.frame(strategy = character(), 
                        type = character(), # type: constant allocation, CAPE, SMA, mixed, etc.
                        subtype = character(), # especially for combinedstrategy
                        TR = numeric(),  # average real total return (exponential regression)
                        netTR0.5 = numeric(),  # average real total return net of 0.5% of trading costs
                        netTR2 = numeric(),  # average real total return net of 2% of costs (trading + risk)
                        netTR4 = numeric(),  # average real total return net of 4% of costs (trading + risk)
                        #                         eval(parse(text=paste0("median", futureYears))), 
                        #                         parse(text=paste0("five", futureYears)),
                        volatility = numeric(), 
                        avgStockAlloc = numeric(), # average allocation to stocks
                        latestStockAlloc = numeric(), # allocation to stocks as of the last date of the data
                        turnover = numeric(), # turnover of the portfolio (in years)
                        invTurnover = numeric(), # 1 / turnover
                        DD2 = numeric(), # sum of the squares of the drawdowns
                        score = numeric(), 
                        stringsAsFactors=F)
   stats[, paste0("median", futureYears)] <<- numeric()
   stats[, paste0("five", futureYears)] <<- numeric()
}

createParametersDF <- function() {
   parameters <<- data.frame(strategy = character(), 
                             type = character(), # type: constant allocation, CAPE, SMA, mixed, etc.
                             subtype = character(), # especially for Bollinger and mixed

                             startIndex = numeric(), # the first index that is not NA
                             inputDF = character(),
                             inputName = character(),
                             avgOver = numeric(),
                             bearish = numeric(),
                             bullish = numeric(),

                             name1 = character(), # other parameters used to create the strategy
                             value1 = numeric(), # values of these parameters
                             name2 = character(), 
                             value2 = numeric(), 
                             name3 = character(), 
                             value3 = numeric(), 
                             
                             inputStrategyName1 = character(), # for combined strategies: name of strategy used as input
                             fraction1 = numeric(), # for combined strategies: fraction (between 0 and 100)
                             inputStrategyName2 = character(),
                             fraction2 = numeric(), 
                             inputStrategyName3 = character(),
                             fraction3 = numeric(),
                             stringsAsFactors=F)
}


splitData <- function(dataSplit, force) {
   if (dataSplit == "search") {
      numData <<- numData %/% 2
      dat <<- dat[1:numData, ] # we keep only the first half
      def$plotEndYear <<- round( (numData-1)/12 + def$dataStartYear )
      
      def$maxTR  <<- 400
      def$yTRmin <<- 7.5
      def$yTRmax <<- 10.2
      def$maxVol <<- 20
      def$minDD2 <<- 0.6
      def$maxDD2 <<- 1.8
      def$coeffDD2 <<- def$coeffDD2 * 2 # DD2 is half as big with half as many years, hence the rescaling
 
      DD <<- DD[1:28, ]
      numDD <<- dim(DD)[[1]]
      
      if (!force)
         warning("When switching to \'search\' from a complete data set or from \'testing\', 
              it is recommended to run \'start\' with \'force=T\'.")
   } else if (dataSplit == "testing") {
      ## we subtract 10 years to start in 1932, so that the first strategies can be got around 1942
      startIndex <- ( numData %/% 24 - 10) * 12 + 1 
      dat <<- dat[startIndex:numData, ] # we keep only the second half
      numData <<- numData - startIndex + 1
      def$dataStartYear  <<- (startIndex-1)/12 + def$dataStartYear 
      def$plotStartYear  <<- def$dataStartYear + def$startIndex %/% 12 + 1 
      
      def$maxTR  <<- 400
      def$yTRmin <<- 4.4
      def$yTRmax <<- 9
      def$minVol <<- 11
      def$maxVol <<- 17.5
      def$minDD2 <<- 0
      def$maxDD2 <<- 1.2
      def$coeffDD2 <<- def$coeffDD2 * 2 # DD2 is half as big with half as many years, hence the rescaling

      DD <<- DD[28:numDD, ]
      numDD <<- dim(DD)[[1]]
      
      if (!force)
         warning("When switching to \'testing\' from a complete data set or from \'search\', 
              it is recommended to run \'start\' with \'force=T\'.")
   } else if (dataSplit != "none") 
      warning(dataSplit, " is not a valid value for \'dataSplit\': choose one of \'none\', \'search\' or \'testing\'.")
}

addFutureReturnsToDat <- function(force=F) {
   if ( (def$futureYears==5) & (!exists("next5yrs") | force) ) 
      next5yrs  <<- data.frame(date = dat$date, numericDate = dat$numericDate)
   else if ( (def$futureYears==10) & (!exists("next10yrs") | force) ) 
      next10yrs <<- data.frame(date = dat$date, numericDate = dat$numericDate)
   else if ( (def$futureYears==20) & (!exists("next20yrs") | force) ) 
      next20yrs <<- data.frame(date = dat$date, numericDate = dat$numericDate)
   else if ( (def$futureYears==30) & (!exists("next30yrs") | force) ) 
      next30yrs <<- data.frame(date = dat$date, numericDate = dat$numericDate)
}

addInflationToDat <- function() {
   addNumColToDat("inflation1yr")
   addNumColToDat("inflation2yr")
   addNumColToDat("inflation5yr")
   addNumColToDat("inflation10yr")
   
   dat$inflation1yr[1:12]       <<- NA
   dat$inflation2yr[1:(12*2)]   <<- NA
   dat$inflation5yr[1:(12*5)]   <<- NA
   dat$inflation10yr[1:(12*10)] <<- NA
   
   dat$inflation1yr[(12+1):numData]   <<- ( dat$CPI[(12+1):numData]   / 
                                               dat$CPI[((12+1):numData)  -12]   ) ^ (1/1) - 1
   dat$inflation2yr[(12*2+1):numData] <<- ( dat$CPI[(12*2+1):numData] / 
                                               dat$CPI[((12*2+1):numData)-12*2] ) ^ (1/2) - 1
   dat$inflation5yr[(12*5+1):numData] <<- ( dat$CPI[(12*5+1):numData] / 
                                               dat$CPI[((12*5+1):numData)-12*5] ) ^ (1/5) - 1
   dat$inflation10yr[(12*10+1):numData]<<-( dat$CPI[(12*10+1):numData] / 
                                               dat$CPI[((12*10+1):numData)-12*10]) ^ (1/10) - 1
}

addConstAllocToDat <- function(smoothConstantAlloc, force=F) {
   time0 <- proc.time()
   message("Creating constant-allocation stock-bond strategies.") 
   if(smoothConstantAlloc)
      constAllocList <- seq(100, 0, by=-5)
   else 
      constAllocList <- c(100, 80, 60, 45, 30, 0)
   invisible ( lapply( constAllocList, function(alloc) createConstAllocStrategy(
      alloc, futureYears=def$futureYears, force=force) ) )
   print( c( "constant allocation time:", round(summary(proc.time())[[1]] - time0[[1]] , 1) ) )
}


## Loading data from xls file
## the xls file has *nominal* values, the "dat" data frame has *real* values
loadData <- function(extrapolateDividends=T, downloadAndCheckAllFiles=F) {  
     library(XLConnect) # to handle xls file
   if(!file.exists("data/ie_data.xls")) # download file if not already locally available
      download.file("http://www.econ.yale.edu/~shiller/data/ie_data.xls", "data/ie_data.xls", mode = "wb")
   else if(downloadAndCheckAllFiles) # We check whether the local file is up to date (if we have time)
      checkXlsFileIsUpToDate()
   
   wk <- loadWorkbook("data/ie_data.xls") 
   rawDat <- readWorksheet(wk, sheet="Data", startRow=8)
   
   numData <<- dim(rawDat)[1]-2 # number of rows
   message(paste0("According to the xls file, \'", rawDat$P[numData+2], "\'")) # displaying information given in xls file
   message(paste0("According to the xls file, \'", rawDat$CPI[numData+2], "\'"))
   rawDat <- rawDat[-(numData+2), ] # removing the row containing the information just displayed
   rawDat <- rawDat[-(numData+1), ] # removing the current month, as it is not data for the end of month
   
   # either we extrapolate the missing dividends (too soon for data to be available) or we remove the rows
   if (extrapolateDividends) { 
      lastIndex <- numData # last index where dividends are valid
      while( is.na(rawDat$D[lastIndex]) )  lastIndex <- lastIndex-1
      
      fitPara <- regression( (lastIndex-12):lastIndex, rawDat$D[(lastIndex-12):lastIndex] )
      a <- fitPara[[1]]
      b <- fitPara[[2]]
      rawDat$D[ (lastIndex+1) : numData ] <- a + b*( (lastIndex+1) : numData) # extrapolate dividend from past year
   } else # remove rows where dividend is NA (cannot calculate total return)
      while( is.na(rawDat$D[numData] ) ) { # remove rows where dividend is NA (cannot calculate total return)
         rawDat <- rawDat[-numData, ]
         numData <<- numData-1      
      }   
   
   # data are for the last (business) day of each month, 28th is close enough
   dat <<- data.frame(date       = ISOdate( floor(rawDat$Date), round((rawDat$Date%%1)*100,0), 28 ),
                      numericDate= as.numeric(rawDat$Fraction),
                      CPI        = as.numeric(rawDat$CPI), # reference for inflation
                      dividend   = as.numeric(rawDat$D), # loads nominal dividend (real dividend will be calculated below)
                      price      = as.numeric(rawDat$P), # loads nominal S&P price (real price will be calculated below)
                      earnings   = as.numeric(rawDat$E), # loads nominal earnings (real earnings will be calculated below)
                      TR= numeric(numData),
                      bonds      = numeric(numData)
   )
   
   refCPI       <<- dat$CPI[numData] # reference for inflation
   dat$price    <<- dat$price    / dat$CPI * refCPI # calculating real price
   dat$dividend <<- dat$dividend / dat$CPI * refCPI # calculating real dividend
   dat$earnings <<- dat$earnings / dat$CPI * refCPI # calculating real earnings
   
   dat$TR[1] <<- 1
   for(i in 2:numData)
      dat$TR[i] <<- dat$TR[i-1] * dat$price[i]/dat$price[i-1] * (1 + dat$dividend[i]/dat$price[i]/12)
   
   dat$bonds <<- read.csv("data/bonds.csv", header=T)[1:numData, 1]
   message("Real bond prices were imported from an Excel calculation.")
   
   message("Shiller's xls file has *nominal* values, the \'dat\' data frame has *real* values.")
}

checkXlsFileIsUpToDate <- function(fileName="data/ie_data.xls") {
   if(!file.exists(fileName)) 
      stop(fileName, " is not on the local disk.")
   
   library(XLConnect) # to handle xls file
   wk <- loadWorkbook(fileName) # this is the local file
   localVersion <- readWorksheet(wk, sheet="Data", startRow=8)
   
   lastLine <- dim(localVersion)[1] 
   localMessage1 <- as.character(localVersion$P[lastLine])
   localMessage2 <- as.character(localVersion$CPI[lastLine])
   localMessage3 <- as.character(localVersion$Rate.GS10[lastLine])
   
   download.file("http://www.econ.yale.edu/~shiller/data/ie_data.xls", "ie_data-remote.xls", mode = "wb")
   library(XLConnect) # to handle xls file
   wk <- loadWorkbook("ie_data-remote.xls")  # this is the local file
   remoteVersion <- readWorksheet(wk, sheet="Data", startRow=8)
   
   lastLine <- dim(remoteVersion)[1] 
   remoteMessage1 <- as.character(remoteVersion$P[lastLine])
   remoteMessage2 <- as.character(remoteVersion$CPI[lastLine])
   remoteMessage3 <- as.character(remoteVersion$Rate.GS10[lastLine])
   
   if (localMessage1 == remoteMessage1 & localMessage2 == remoteMessage2 & localMessage3 == remoteMessage3)
      print(paste("The file", fileName, "is up to date.") )
   else {
      file.copy("ie_data-remote.xls", fileName, overwrite=T)
      print(paste("The file", fileName, "has been updated.") )
#       if (localMessage1 != remoteMessage1)
#          print(paste0("On the remote xls file \'", remoteMessage1, 
#                       "\', whereas on the local file \'", localMessage1, "\'."))
#       if (localMessage2 != remoteMessage2)
#          print(paste0("On the remote xls file \'", remoteMessage2, 
#                       "\', whereas on the local file \'", localMessage2, "\'."))
   }
   file.remove("ie_data-remote.xls") 
}

## for some columns in 'parameters' and 'stats', there are only a handful of possible values
makeStringsFactors <- function() {
   parameters$type    <<- as.factor(parameters$type) 
   parameters$subtype <<- as.factor(parameters$subtype)
   parameters$inputDF <<- as.factor(parameters$inputDF)
   levels(parameters$inputDF) <<- c( "dat", "signal", "alloc", "TR", "next10yrs", "next20yrs", "next30yrs" ) 
   
   stats$type         <<- as.factor(stats$type) 
   stats$subtype      <<- as.factor(stats$subtype)
   
   ## To handle searches:
   levels(parameters$subtype) <<- c(levels(parameters$type), levels(parameters$subtype))
   levels(parameters$type) <<- c(levels(parameters$type), "search")   
   levels(stats$type)      <<- c(levels(stats$type), levels(parameters$type))
   levels(stats$subtype)   <<- c(levels(stats$subtype), levels(parameters$subtype))
}

# Generating typical strategies
createTypicalStrategies <- function(extrapolateDividends=T, force=F) {
   message("Creating entries for the typical strategies")
   
   createCAPEstrategy(years=def$CAPEyears, cheat=def$CAPEcheat, avgOver=def$CAPEavgOver1, 
                      hysteresis=F, bearish=def$CAPEbearish1, bullish=def$CAPEbullish1, 
                      signalMin=def$signalMin, signalMax=def$signalMax,
                      futureYears=def$futureYears, costs=def$tradingCost, 
                      coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)
   
   createCAPEstrategy(years=def$CAPEyears, cheat=def$CAPEcheat, avgOver=def$CAPEavgOver2, 
                      hysteresis=T, hystLoopWidthMidpoint=def$hystLoopWidthMidpoint2,
                      hystLoopWidth=def$hystLoopWidth2, slope=def$slope2,
                      signalMin=def$signalMin, signalMax=def$signalMax,
                      futureYears=def$futureYears, costs=def$tradingCost, 
                      coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)
   
   createDetrendedStrategy(inputDF=def$detrendedInputDF, inputName=def$detrendedInputName, 
                           avgOver=def$detrendedAvgOver1, 
                           bearish=def$detrendedBearish1, bullish=def$detrendedBullish1, 
                           signalMin=def$signalMin, signalMax=def$signalMax,
                           futureYears=def$futureYears, costs=def$tradingCost, 
                           coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)
   
   createDetrendedStrategy(inputDF=def$detrendedInputDF, inputName=def$detrendedInputName, 
                           avgOver=def$detrendedAvgOver2, 
                           bearish=def$detrendedBearish2, bullish=def$detrendedBullish2, 
                           signalMin=def$signalMin, signalMax=def$signalMax,
                           futureYears=def$futureYears, costs=def$tradingCost, 
                           coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)
   
   createSMAstrategy(inputDF=def$SMAinputDF, inputName=def$SMAinputName, SMA1=def$SMA1, SMA2=def$SMA2, 
                     bearish=def$SMAbearish, bullish=def$SMAbullish, 
                     signalMin=def$signalMin, signalMax=def$signalMax,
                     futureYears=def$futureYears, costs=def$tradingCost, 
                     coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)   
   
   createBollStrategy(inputDF=def$BollInputDF, inputName=def$BollInputName, avgOver=def$BollAvgOver, 
                      bearish=def$BollBearish, bullish=def$BollBullish, 
                      signalMin=def$signalMin, signalMax=def$signalMax,
                      futureYears=def$futureYears, costs=def$tradingCost, 
                      coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)   
   
   createReversalStrategy(inputDF=def$reversalInputDF, inputName=def$reversalInputName, 
                          avgOver=def$reversalAvgOver, returnToMean=def$reversalReturnToMean, 
                          bearish=def$reversalBearish, bullish=def$reversalBullish, 
                          signalMin=def$signalMin, signalMax=def$signalMax,
                          futureYears=def$futureYears, costs=def$tradingCost, 
                          coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force) 
   
#    createInflationStrategy(avgOver=def$inflationAvgOver,  
#                           bearish=def$inflationBearish, bullish=def$inflationBullish, 
#                           signalMin=def$signalMin, signalMax=def$signalMax,
#                           futureYears=def$futureYears, costs=def$tradingCost, 
#                           coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force) 
   
   combineStrategies(def$typicalSMA, def$typicalBoll, def$typicalReversal, "",
                     def$technicalFractionSMA, def$technicalFractionBoll, 
                     def$technicalFractionReversal, 0, 
                     type="combined", subtype="technical", combineMode="weighted",
                     costs=def$tradingCost, 
                     coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)
   
   combineStrategies(inputStrategyName1=def$typicalCAPE1, inputStrategyName2=def$typicalCAPE2, 
                     inputStrategyName3=def$typicalDetrended1, inputStrategyName4=def$typicalDetrended2,
                     def$valueFractionCAPE1, def$valueFractionCAPE2, 
                     def$valueFractionDetrended1, def$valueFractionDetrended2,
                     type="combined", subtype="value", combineMode="weighted", costs=def$tradingCost, 
                     coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)
   
   combineStrategies(def$typicalTechnical, def$typicalValue, "", "",
                     def$balancedFractionTechnical, def$balancedFractionValue, 0, 0,
                     type="combined", subtype="balanced", combineMode=def$balancedCombineMode,
                     costs=def$tradingCost, 
                     coeffTR=def$coeffTR, coeffVol=def$coeffVol, coeffDD2=def$coeffDD2, force=force)
}