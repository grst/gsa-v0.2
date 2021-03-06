library(ribiosPlot)
library(ribiosIO)
library(ribiosGSEA)
library(lattice)
library(latticeExtra)
library(Biobase)
figfile <- function(x) file.path("figures", x)

testSimulator <- function(tgSim, pFunc=pFuncCamera, ngsr=99, B=100) {
    bench <- newBenchmarker(tgSim, ngsr=ngsr, B=B, pFunc=pFunc)
    benchRes <- benchmark(bench)
    print(xyplot(benchRes))
    return(invisible(benchRes))
}
tt <- newTwoGroupExprsSimulator(tpGeneSetCor=0.1)


## quick tests
pFuncKS <- function(tgSim ,index) {
    fit <- ribiosGSEA:::tgSim2limmaFit(tgSim)
    tVals <- fit$t[, 1]
    ps <- sapply(index, function(x) ks.test(tVals[x], tVals[-x])$p.value)
    return(ps)
}
fastTestSimulator <- function(simulator, pFunc) testSimulator(simulator, pFunc, ngsr=2, B=5)
system.time(fastCameraTest <- fastTestSimulator(tt, pFunc=pFuncCamera))
system.time(fastBioQCTest <- fastTestSimulator(tt, pFunc=pFuncBioQCtStat))
system.time(fastCameraRankTest <- fastTestSimulator(tt, pFunc=pFuncCameraRank))
system.time(fastFisherMethod <- fastTestSimulator(tt, pFunc=pFuncFisherMethod))
system.time(fastMroastTest <- fastTestSimulator(tt, pFunc=pFuncMroast))
system.time(fastFisherExact <- fastTestSimulator(tt, pFunc=pFuncFisherExact))
system.time(fastGlobalTest <- fastTestSimulator(tt, pFunc=pFuncGlobaltest))
system.time(fastTstatZtest <- fastTestSimulator(tt, pFunc=pFuncTstatZtest))
system.time(fastTstatTtest <- fastTestSimulator(tt, pFunc=pFuncTstatTtest))
system.time(fastTstatWMW <- fastTestSimulator(tt, pFunc=pFuncTstatWMW))
system.time(fastKS <- fastTestSimulator(tt, pFunc=pFuncKS))
system.time(fastTstatChisq <- fastTestSimulator(tt, pFunc=pFuncTstatChisq))
system.time(fastRomer <- fastTestSimulator(tt, pFunc=pFuncRomer))

##----------------------------------------##
## Performance
##----------------------------------------##

cameraBenchmarkResult <- testSimulator(tt, pFuncCamera)
bioqcBenchmarkResult <- testSimulator(tt, pFuncBioQCtStat)
(rocCamera <- xyplot(cameraBenchmarkResult))
(rocBioQC <- xyplot(bioqcBenchmarkResult))



## ttCor
ttCor <-  newTwoGroupExprsSimulator(tpGeneSetCor=0.5)
bioqcCorBenchmarkResult <- testSimulator(ttCor, pFuncBioQCtStat)
xyplot(bioqcCorBenchmarkResult, col="red", lty=2, sub="rowScaleWMW. Solid/Dash line: rou=0.1/rou=0.5", main="Impact of intra-gene-set correlation") + update(rocBioQC, col="red")
ipdf(figfile("ROC-rowScaleWMW-cor.pdf"), width=5L, height=5L)
cat()
## tt2 <- cloneTwoGroupExprsSimulator(tt, randomSeed=1008)
## expect_equal(randomSeed(tt2), 1008)

## test
## set.seed(1887); twoGroupMvrnorm1887 <- twoGroupMvrnorm(20, c(3,3), 1, 0.1)
## stopifnot(all(tt@matrix[1:20,]-twoGroupMvrnorm1887==0))

## mutate backgroundground

## ttMut <- mutateBgByParams(tt, bgDgeInd=30:50,
##                          bgDgeDeltaMean=rnorm(21),
##                          bgCorInd=40:60,
##                          bgCorCluster=gl(7,3),
##                          bgCorSigma=0.95)

## ttMutRes <- testSimulator(ttMut)
## (rocMut <- xyplot(ttMutRes))

trellisLineCols <- trellis.par.get()$superpose.line$col

## if the background genes have random correlation structures, it's not a big problem for either camera or BioQC
ttMutRandCor <- randomlyMutateBg(tt, bgCorPerc=0.20)
ttMutRandCorCamera <- testSimulator(ttMutRandCor, pFunc=pFuncCamera)
ttMutRandCorBioQC <- testSimulator(ttMutRandCor, pFunc=pFuncBioQCtStat)
update(rocCamera, sub="CAMERA:Blue; rowScaleWMW: Red. Solid/Dash: iid/20% random cor", main="Random correlations in background genes") + update(rocBioQC, col="red") + xyplot(ttMutRandCorCamera,col=trellisLineCols[1], lty=2) + xyplot(ttMutRandCorBioQC, col="red", lty=2)
ipdf(figfile("ROC-randomCorrelation.pdf"), width=5L, height=5L)

## what happens if the background genes have increased expression?
ttMutPos <- randomlyMutateBg(tt, bgDgePerc=0.3,
                             bgDgeDeltaMeanFunc=function(n) rnorm(n, mean=1, sd=1))
ttMutPosCamera <- testSimulator(ttMutPos, pFunc=pFuncCamera)
ttMutPosBioQC <- testSimulator(ttMutPos, pFunc=pFuncBioQCtStat)
update(rocCamera, sub="CAMERA:Blue; rowScaleWMW: Red. Solid/Dash: iid/30% with logFC~N(1,1)", main="30% DE in background genes") + update(rocBioQC, col="red") + xyplot(ttMutPosCamera, lty=2, col=trellisLineCols[1]) + xyplot(ttMutPosBioQC, col="red", lty=2)
ipdf(figfile("ROC-randomDE.pdf"), width=5L, height=5L)

update(rocCamera, sub="CAMERA. Solid/Dash: iid/30% with logFC~N(1,1)", main="DE in background genes")+xyplot(ttMutPosCamera, lty=2, col=trellisLineCols[1])
ipdf(figfile("ROC-randomDE-cameraOnly.pdf"), width=5L, height=5L)

update(rocBioQC, sub="rowScaleWMW. Solid/Dash: iid/30% with logFC~N(1,1)", main="DE in background genes", col="red")+xyplot(ttMutPosBioQC, lty=2, col="red")
ipdf(figfile("ROC-randomDE-BioQConly.pdf"), width=5L, height=5L)

## a mild change?
ttMutMildPos <- randomlyMutateBg(tt, bgDgePerc=0.05,
                             bgDgeDeltaMeanFunc=function(n) rnorm(n, mean=1, sd=1))
ttMutMildPosCamera <- testSimulator(ttMutMildPos, pFunc=pFuncCamera)
xyplot(ttMutMildPosCamera)

## if random gene sets are correlated
testMutCor <- function(tgSim, pFunc=pFuncCamera, sigma=0.25) {
    bench <- newBenchmarker(tgSim, pFunc=pFunc)
    gsIndList <- bench@genesets[-1]
    gsInd <- unlist(gsIndList)
    gsFac <- factor(rep(seq(along=gsIndList), sapply(gsIndList,length)))
    tgSimMut <- mutateBgByParams(tgSim, bgCorInd=gsInd, bgCorCluster=gsFac, bgCorSigma=sigma)
    bench <- newBenchmarker(tgSimMut, pFunc=pFunc, geneSets=genesets(bench))
    benchRes <- benchmark(bench)
    print(xyplot(benchRes))
    return(invisible(benchRes))
}
rocMut3 <- testMutCor(tt, pFunc=pFuncCamera)
rocMut3bioqc <- testMutCor(tt, pFunc=pFuncBioQCtStat)
rocMut3ks <- testMutCor(tt, pFunc=pFuncKS)

xyplot(rocMut3, main="Moderate correlation (0.25) in GS_R", sub="CAMERA:Blue; rowScaleWMW: Red. Solid/Dash: iid/25% cor in GS_R", lty=2)+xyplot(rocMut3bioqc, col="red", lty=2)+update(rocBioQC, col="red")+rocCamera
ipdf(figfile("ROC-GS_Rcor.pdf"), width=5L, height=5L)

xyplot(rocMut3, main="Strong correlation (0.25) in GS_R", sub="CAMERA. Solid/Dash: iid/25% cor in GS_R", lty=2)+rocCamera
ipdf(figfile("ROC-GS_Rcor-cameraOnly.pdf"), width=5L, height=5L)

update(rocBioQC, col="red", main="Strong correlation (0.25) in GS_R", sub="rowScaleWMW. Solid/Dash: iid/25% cor in GS_R")+xyplot(rocMut3bioqc, col="red", lty=2)
ipdf(figfile("ROC-GS_Rcor-BioQConly.pdf"), width=5L, height=5L)

xyplot(rocMut3ks,col="black", sub="Strong correlation (0.25) in GS_R. Black/Red/Blue:GSEA-P/BioQC/camera")+xyplot(rocMut3bioqc, col="red")+xyplot(rocMut3)
ipdf(figfile("ROC-GS_Rcor-BioQC-camera-GSEA-P.pdf"), width=6L, height=6L)

AUC(rocMut3bioqc) ## AUC=.9
summary(ranks(rocMut3bioqc)<=5) ## in 88% case ranks highest
summary(ranks(rocMut3)<=5) ## in 92% case ranks highest

## as expected, if the expression of GS_R are also changed, the curve will look much worse
testMutDeltaMean <- function(tgSim, pFunc=pFuncCamera) {
    bench <- newBenchmarker(tgSim, pFunc=pFunc)
    gsIndList <- bench@genesets[-1]
    gsInd <- unlist(gsIndList)
    gsFac <- factor(rep(seq(along=gsIndList), sapply(gsIndList,length)))
    tgSimMut <- mutateBgByParams(tgSim, bgDgeInd=gsInd, bgDgeDeltaMean=0.5)
    bench <- newBenchmarker(tgSimMut, pFunc=pFunc, geneSets=genesets(bench))
    benchRes <- benchmark(bench)
    print(xyplot(benchRes))
    return(invisible(benchRes))
}
(rocMut4 <- testMutDeltaMean(tt))
(rocMut4bioqc <- testMutDeltaMean(tt, pFunc=pFuncBioQCtStat))

xyplot(rocMut4, lty=2)+xyplot(rocMut4bioqc, col="red", lty=2)+update(rocBioQC, col="red")+rocCamera

## background
testMutBgExprs <- function(tgSim, pFunc=pFuncCamera) {
    bench <- newBenchmarker(tgSim, pFunc=pFunc)
    gsIndList <- bench@genesets[-1]
    gsInd <- unlist(gsIndList)
    gsFac <- factor(rep(seq(along=gsIndList), sapply(gsIndList,length)))
    bench <- newBenchmarker(tgSim, pFunc=pFunc, geneSets=genesets(bench))
    for(i in seq(along=bench@simulators)) {
        cmat <- bench@simulators[[i]]@matrix
        bg <- rpois(nrow(cmat), 8L)+2L
        bench@simulators[[i]]@matrix <- cmat+bg
    }
    benchRes <- benchmark(bench)
    print(xyplot(benchRes))
    return(invisible(benchRes))
}
## ttShort <- tt; tpGeneSetInd(ttShort) <- 1:5
(rocMutBe <- testMutBgExprs(tt))
(rocMutBeBioQC <- testMutBgExprs(tt, pFunc=pFuncBioQCtStat))

xyplot(rocMutBe, lty=2, main="Effect of row-scaling", sub="CAMERA:Blue; rowScaleWMW: Red. Solid/Dash: w and w/o row scaling") + rocCamera + update(rocBioQC, col="red")+update(xyplot(rocMutBeBioQC), col="red", lty=2)
ipdf(figfile("ROC-rowScaling.pdf"), width=6L, height=6L)

##----------------------------------------##
## benchmarks
##----------------------------------------##
outfile <- function(x) file.path("output", x)
cameraBenchmarkFile <- outfile("cameraBenchmark.RData")
if(!loadFile(cameraBenchmarkFile)) {
    ## correlation
    testCors <- c(seq(0, 0.5, 0.1), seq(0.6, 1, 0.2))
    cameraCorPerformance <- varParPerformance(varPar="tpGeneSetCor", varParList=testCors, pFunc=pFuncCamera)

    testSampleSizes <- lapply(c(seq(2,5), seq(6,12, 2), seq(15,30,5)), function(x) rep(x,2))
    testSampleSizeHalf <- sapply(testSampleSizes, "[[", 1L)
    cameraSamplePerformance <- varParPerformance(varPar="nSample",
                                                 varParList=testSampleSizes, pFunc=pFuncCamera, tpGeneSetCor=0.1)

    testGeneSetSize <- c(2,5,10,15,20,30,50,100,200,300,400, 500,1000)
    cameraGSsizePerformance <- varParPerformance(varPar="tpGeneSetInd",
                                             varParList=lapply(testGeneSetSize, function(x) 1:x),
                                             pFunc=pFuncCamera, tpGeneSetCor=0)

    testDeltaMean <- c(seq(-3, -0.5, 0.5), 0, seq(0.5, 3, 0.5))
    cameraESPerformance <- varParPerformance(varPar="deltaMean",
                                             varParList=testDeltaMean, 
                                             pFunc=pFuncCamera, tpGeneSetCor=0.1)

    testOppDeltaMeanVal <- seq(0.1, 0.5, 0.1)

    testOppDeltaMean <- lapply(testOppDeltaMeanVal,
                               function(x) {
                                   negs <- rep(-1.5, as.integer(20*x))
                                   pos <- rep(1.5, 20-length(negs))
                                   return(c(negs, pos))
                               })
    cameraOppESPerformance <- varParPerformance(varPar="deltaMean",
                                                varParList=testOppDeltaMean, 
                                                pFunc=pFuncCamera, tpGeneSetCor=0)
    
    testPartDeltaMeanVal <- seq(0.1, 0.9, 0.1)
    testPartDeltaMean <- lapply(testPartDeltaMeanVal,
                                function(x) {
                                    noneff <- rep(0, as.integer(20*x))
                                    pos <- rep(1.5, 20-length(noneff))
                                    return(c(noneff, pos))
                               })
    cameraPartESPerformance <- varParPerformance(varPar="deltaMean",
                                                varParList=testPartDeltaMean, 
                                                pFunc=pFuncCamera, tpGeneSetCor=0.1)

    save(testCors, cameraCorPerformance,
         testSampleSizes,testSampleSizeHalf, cameraSamplePerformance,
         testGeneSetSize,cameraGSsizePerformance,
         testDeltaMean,cameraESPerformance,
         testOppDeltaMeanVal, testOppDeltaMean,cameraOppESPerformance,
         testPartDeltaMeanVal, testPartDeltaMean,cameraPartESPerformance,
         file=cameraBenchmarkFile)
}

plotROC(cameraCorPerformance, main="Camera's performance", key.title="Correlation", values=testCors)
ipdf(figfile("camera-ROC-cor.pdf"), width=6.5, height=6L)
plotAUC(cameraCorPerformance, main="Camera's performance", key.title="Correlation", values=testCors)
ipdf(figfile("camera-AUC-cor.pdf"), width=6, height=6L)
plotRanks(cameraCorPerformance, main="Camera's performance", key.title="Correlation", values=testCors)
ipdf(figfile("camera-Ranks-cor.pdf"), width=6, height=6L)


## test sample sizes: under the simulation scenario the sample number does not make a difference
plotROC(cameraSamplePerformance, main="Camera's performance", key.title="nSample", values=testSampleSizeHalf)
ipdf(figfile("camera-ROC-sampleSize.pdf"), width=6.5, height=6L)
plotAUC(cameraSamplePerformance, main="Camera's performance", key.title="nSample", values=testSampleSizeHalf)
ipdf(figfile("camera-AUC-sampleSize.pdf"), width=6, height=6L)
plotRanks(cameraSamplePerformance, main="Camera's performance", key.title="nSample", values=testSampleSizeHalf)
ipdf(figfile("camera-Ranks-sampleSize.pdf"), width=6, height=6L)

## test gene set size
plotROC(cameraGSsizePerformance, 
        main="Camera's performance", key.title="Gene set size", values=testGeneSetSize)
ipdf(figfile("camera-ROC-geneSetSize.pdf"), width=6.5, height=6L)
plotAUC(cameraGSsizePerformance, main="Camera's performance", key.title="Gene set size", values=testGeneSetSize,
        scales=list(tck=c(1,0), alternating=1L, x=list(at=testGeneSetSize, log=2)))
ipdf(figfile("camera-AUC-geneSetSize.pdf"), width=6, height=6L)
plotRanks(cameraGSsizePerformance, main="Camera's performance", key.title="Gene set size", values=testGeneSetSize)
ipdf(figfile("camera-Ranks-geneSetSize.pdf"), width=5, height=5)


## test effect size
esCol <- c(royalbluered(3)[1],"lightgray", royalbluered(3)[3])
plotROC(cameraESPerformance, main="Camera's performance", key.title="Effect size", values=testDeltaMean, cols=esCol)
ipdf(figfile("camera-ROC-effectSize.pdf"), width=6.5, height=6L)
plotAUC(cameraESPerformance, main="Camera's performance", key.title="Effect size", values=testDeltaMean, cols=esCol,
        ylim=c(0.45,1.05))
ipdf(figfile("camera-AUC-effectSize.pdf"), width=6, height=6)
plotRanks(cameraESPerformance, main="Camera's performance", key.title="Effect size", values=testDeltaMean, cols=esCol)
ipdf(figfile("camera-Ranks-effectSize.pdf"), width=5, height=5)

## test opposite effect size

plotROC(cameraOppESPerformance, 
        main="Camera's performance", key.title="Opp. effect", values=testOppDeltaMeanVal)
ipdf(figfile("camera-ROC-OppositeEffectSize.pdf"), width=6.5, height=6L)
plotAUC(cameraOppESPerformance, main="Camera's performance", key.title="Opp. effect", values=testOppDeltaMeanVal, 
        ylim=c(0.45,1.05))
ipdf(figfile("camera-AUC-OppositeEffectSize.pdf"), width=6, height=6)
plotRanks(cameraOppESPerformance, main="Camera's performance", key.title="Opp. effect", values=testOppDeltaMeanVal)
ipdf(figfile("camera-Ranks-OppositeEffectSize.pdf"), width=5, height=5)

## test partsite effect size

plotROC(cameraPartESPerformance, 
        main="Camera's performance", key.title="Part. effect", values=testPartDeltaMeanVal)
ipdf(figfile("camera-ROC-PartEffectSize.pdf"), width=6.5, height=6L)
plotAUC(cameraPartESPerformance, main="Camera's performance", key.title="Part. effect", values=testPartDeltaMeanVal, 
        ylim=c(0.45,1.05))
ipdf(figfile("camera-AUC-PartEffectSize.pdf"), width=6, height=6)
plotRanks(cameraPartESPerformance, main="Camera's performance", key.title="Part. effect", values=testPartDeltaMeanVal)
ipdf(figfile("camera-Ranks-PartEffectSize.pdf"), width=5, height=5)


##----------------------------------------##
## Other methods
##----------------------------------------##
bioqcTstat <- newBenchmarker(tt, pFunc=pFuncBioQCtStat)
bioqcTstatResult <- benchmark(bioqcTstat)
(rocBioQCTstat <- xyplot(bioqcTstatResult))

bioqcTstatCorPerformance <- varParPerformance(varPar="tpGeneSetCor", varParList=testCors, pFunc=pFuncBioQCtStat)

plotROC(bioqcTstatCorPerformance, key.title="Cor", values=testCors)
ipdf(figfile("BioQC.log10P.Tstat-ROC-cor.pdf"), width=6.5, height=6L)
xyplot(sapply(bioqcTstatCorPerformance, AUC)~sapply(cameraCorPerformance, AUC), type="b", abline=c(0,1))
ipdf(figfile("ROC-correlation-BioQC.log10P.Tstat-Camera.pdf"), width=6.5, height=6L)

## 100 runs' time
## cameraRank ~ 75s
## fisher's method ~ 99s
## mroast ~ 126s 
## fisher: 131s
## globaltest 290s
## one-sample z-test of t-statistic: 122s
## two-sample t-test of t-statistic: 144s
## WMW of t-statistic: 112s
## Chisq^test of t-statistic: 110s

## test pFuncLimmaAggregated ~ 180s

## romer ~ 336s


##----------------------------------------##
## simulate data
##----------------------------------------##
nSamples <- c(2:6,8,10)
delta <- c(0.5, 1, 1.5, 2, 3)
rou <- c(0, 0.1, 0.2, 0.5)
theta <- c(2,5,10,20,50,100, 200, 300, 500, 1000)
epsilon <- c(0.005, 0.01, 0.05, 0.15)

dim(parameters <- expand.grid(nSample=nSamples, delta=delta, rou=rou, theta=theta, epsilon=epsilon))
outdir <- "/data64/bi/data/gsea"
outfileBases <- with(parameters, sprintf("n_%d_delta_%1.1f_rou_%1.1f_theta_%d_epsilon_%1.3f",
                                         nSamples, delta, rou, theta, epsilon))

comm <- with(parameters,
             sprintf("/homebasel/biocomp/zhangj83/projects/2016-01-NEWS-ScienceAtTTB/gsa-v0.2/gsa-benchmark.Rscript -nSamples %d -deltaMean %.2f -tpGeneSetCor %.2f -tpGeneSetLength %d -bgDgePerc %.2f -outfile %s -statOutfile %s -nGSr 149 -B 100 -log %s",
                     nSample, delta, rou, theta, epsilon,
                     file.path(outdir,paste(outfileBases, ".RData", sep="")),
                     file.path(outdir, paste(outfileBases, ".stat.txt", sep="")),
                     file.path(outdir, paste(outfileBases, ".log", sep=""))))

jobs <- sprintf("/apps64/bi/jobsubmitter/submit_job -command \"%s\" -name %s -dir %s -qsubFile qsub-GSEsimulation.bash",
                comm, outfileBases, outdir)
file.remove(c("prepareGSEsimulationJobs.bash", "qsub-GSEsimulation.bash"))
writeLines(jobs, "prepareGSEsimulationJobs.bash")
system("bash prepareGSEsimulationJobs.bash")
system("ssh zhangj83@rbalhpc05 ~/projects//2016-01-NEWS-ScienceAtTTB/gsa-v0.2/qsub-GSEsimulation.bash")



##----------------------------------------##
## why intra-geneset-correlation is so problematic?
##----------------------------------------##
ttLarge <- newTwoGroupExprsSimulator(nSample=10, tpGeneSetCor=0.1, deltaMean=1.5)
ttLargeCor <- newTwoGroupExprsSimulator(nSample=10, tpGeneSetCor=0.5, deltaMean=1.5)

## cameraLargeBenchmarkResult <- testSimulator(ttLarge, pFuncCamera)
## cameraLargeCorBenchmarkResult <- testSimulator(ttLargeCor, pFuncCamera)
bioqcLargeBenchmarkResult <- testSimulator(ttLarge, pFuncBioQCtStat)
bioqcLargeCorBenchmarkResult <- testSimulator(ttLargeCor, pFuncBioQCtStat)


## step by step
ttLargeCorBench <- newBenchmarker(ttLargeCor, ngsr=99, B=100, pFuncBioQCtStat)
ttLargeCorBenchRes <- benchmark(ttLargeCorBench)
xyplot(ttLargeCorBenchRes)

## the effect size is indeed smaller
mean(tpDiff(ttLargeCorBench@simulators[[which.max(ttLargeCorBenchRes@ranks)]]))

mean(tpDiff(ttLargeCorBench@simulators[[which.min(ttLargeCorBenchRes@ranks)]]))

compCol <- rep(c("black", "red"), each=10)
biosHeatmap(exprs(ttLargeCorBench@simulators[[2]])[1:20,], Rowv=FALSE, Colv=FALSE, scale="row", zlim=c(-2,2), ColSideCol=compCol, main="Strong correlation", cexCol=1.5, cexRow=1.5, color.key.title="Exprs")
ipdf(figfile("heatmap-strongCor.pdf"), width=5L, height=5L)
     
biosHeatmap(exprs(ttLarge)[1:20,], Rowv=FALSE, Colv=FALSE, scale="row", zlim=c(-2,2), ColSideCol=compCol, main="No correlation", cexCol=1.5, cexRow=1.5, color.key.title="Exprs")
ipdf(figfile("heatmap-noCor.pdf"), width=5L, height=5L)


biosHeatmap(exprs(ttLargeCorBench@simulators[[which.max(ttLargeCorBenchRes@ranks)]])[1:20,], Rowv=FALSE, Colv=FALSE, scale="row", zlim=c(-2,2))

##----------------------------------------##
## try GSEA-P
##----------------------------------------##

## KS
ksBenchmarkResult <- testSimulator(tt, pFuncKS)
(rocKS <- xyplot(ksBenchmarkResult)
 
rocCamera + update(rocBioQC, col="red") + update(rocKS, col="blue")
