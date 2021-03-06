rm(list=ls())
### ---------------
###
### Create: Jianming Zeng
### Date: 2018-07-09 20:11:07
### Email: jmzeng1314@163.com
### Blog: http://www.bio-info-trainee.com/
### Forum:  http://www.biotrainee.com/thread-1376-1-1.html
### CAFS/SUSTC/Eli Lilly/University of Macau
### Update Log: 2018-07-09  First version
###
### ---------------


load(file='GSE42872_DEG.Rdata')
source('functions.R')
source('functions.R') 
library(ggplot2)
library(clusterProfiler)
library(org.Hs.eg.db)
library(GSVA)
 

X=new_exprSet
X[1:4,1:4]

## Molecular Signatures Database (MSigDb) 
d='~/biosoft/MSigDB/symbols//'
gmts=list.files(d,pattern = 'all')
gmts
if(T){
  es_max <- lapply(gmts, function(gmtfile){ 
    geneset <- getGmt(file.path(d,gmtfile))  
    es.max <- gsva(X, geneset, mx.diff=FALSE, verbose=FALSE, parallel.sz=1)
    return(es.max)
  })
  adjPvalueCutoff <- 0.001
  logFCcutoff <- log2(2)
  es_deg <- lapply(es_max, function(es.max){
    dim(es.max)
    design <- model.matrix(~0+factor(group_list))
    colnames(design)=levels(factor(group_list))
    rownames(design)=colnames(es.max)
    design
    library(limma)
    contrast.matrix<-makeContrasts(paste0(unique(group_list),collapse = "-"),
                                   levels = design)
    contrast.matrix<-makeContrasts("case-control",
                                   levels = design)
    
    contrast.matrix ##这个矩阵声明，我们要把progres.组跟stable进行差异分析比较
    
    deg = function(es.max,design,contrast.matrix){
      ##step1
      fit <- lmFit(es.max,design)
      ##step2
      fit2 <- contrasts.fit(fit, contrast.matrix) 
      ##这一步很重要，大家可以自行看看效果
      
      fit2 <- eBayes(fit2)  ## default no trend !!!
      ##eBayes() with trend=TRUE
      ##step3
      res <- decideTests(fit2, p.value=adjPvalueCutoff)
      summary(res)
      tempOutput = topTable(fit2, coef=1, n=Inf)
      nrDEG = na.omit(tempOutput) 
      #write.csv(nrDEG2,"limma_notrend.results.csv",quote = F)
      head(nrDEG)
      return(nrDEG)
    }
    
    re = deg(es.max,design,contrast.matrix)
    nrDEG=re
    head(nrDEG) 
    return(nrDEG)
  })
} 
 
gmts

save(es_max,es_deg,file='gsva_msigdb.Rdata')

load(file='gsva_msigdb.Rdata')

library(pheatmap)
lapply(1:length(es_deg), function(i){
  # i=2
  print(i)
  dat=es_max[[i]]
  df=es_deg[[i]]
  df=df[df$P.Value<0.01 & abs(df$logFC) > 0.5,]
  n=rownames(df)
  dat=dat[match(n,rownames(dat)),]
  rownames(dat)=substring(rownames(dat),1,50)
  pheatmap::pheatmap(dat, fontsize_row = 8,height = 11,
                     filename = paste0('gsva_',strsplit(gmts[i],'[.]')[[1]][1],'.pdf'))
})

adjPvalueCutoff <- 0.001
logFCcutoff <- log2(2)
df=do.call(rbind ,es_deg)
es_matrix=do.call(rbind ,es_max)
df=df[df$P.Value<0.01 & abs(df$logFC) > 0.5,]
write.csv(df,file = 'GSVA_DEG.csv')


