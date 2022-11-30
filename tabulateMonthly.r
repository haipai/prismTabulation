tabulateMonthly<-function(prismfold,wvars,spatialid,interfile,filterfile='',timespan) {
  ### load packages
  require(data.table)
  require(raster)
  require(foreign)
  require(readstata13) 
  require(digest) 
  require(stringr)
  
  # ## test arguments  
  # prismfold <- file.path('r:/prism/monthly/')   
  # wvars     <- c('ppt','tdmean','tmean','tmin','tmax','vpdmin','vpdmax')  
  # spatialid <- 'geoid' 
  # interfile <- file.path('d:/git/prismTabulation/data/','cb_2020_us_county_prism.csv')  
  # #filterfile<- file.path('d:/git/prismTabulation/data/','prism_nlcd2001.csv') 
  # timespan  <- c(2020:2020) 
  # 
  
  
  outfile1  <- paste(wvars,collapse='_')  
  region    <- fread(interfile,header=TRUE,stringsAsFactors = FALSE)  
  names(region) <- str_to_lower(names(region)) 
  
  
  if (filterfile != '') { 
    region <- merge(region,agflag,by='pid',all.x=1) 
    agflag    <- fread(filterfile,header=TRUE,stringsAsFactors = FALSE) 
  } else {
    region$flag = 1
  }
  
  
  fields <- c(spatialid,'pid','area') 
  
  region0 <- region[flag==1,..fields]
  
  ## mkdir a temp direcotry 
  tempfoldname <- paste0('temp',digest(Sys.time(),algo='md5')) 
  dir.create(tempfoldname) 
  oldpath <- getwd()
  setwd(tempfoldname) 
  
  
  tryCatch({
    t1 <- proc.time()
    for (yr in timespan) {
      outfile2 <- toString(yr) 
      outfile  <- paste0('prismMonthly_',outfile1,'_',outfile2,'.csv')  
      cat(sprintf('Tabulated weather variables in %d are saved into %s\n',yr,file.path(oldpath,outfile)))      
      initialwrite <- 1 
      months <- str_pad(c(1:12),2,pad='0') 
      cat(sprintf('Start the year of %d\n',yr))
      for (mon in months) { 
        #mon = '01'
        
        dtstr = paste0(toString(yr),mon) 
        for (wvar in wvars) {
          #unzip ppt 
          file_wvar  <- paste0(prismfold,'/',wvar,'/',yr,'/','PRISM_',wvar,'_stable_4kmM3_',dtstr,'_bil.zip',sep='') 
          zip_wvar   <- paste('PRISM_',wvar,'_stable_4kmM3_',dtstr,'_bil.bil',sep='') 
          cat(sprintf('%s  ',wvar))
          unzip(file_wvar)
          
          # read in raster files 
          wdata   <- raster(zip_wvar)
          
          #convert to data.frame 
          wdata    <- as.data.frame(wdata)
          wdata$id <- c(1:dim(wdata)[1])
          names(wdata) <- c(wvar,'id')
          
          # convert to data.table class 
          wdata   <- data.table(wdata) 
          
          #set keys 
          setkey(wdata,"id")
          
          #ppt 
          tmp <- wdata[.(region0$pid)] 
          eval(parse(text=paste0('region <- cbind(region0,',wvar,'=tmp[,c(',wvar,')])'))) 
          
          # remove NA from the dataframe
          eval(parse(text=paste0('region<- region[is.na(',wvar,')==FALSE,]'))) 
          
          #calculate area weights
          region[,totarea :=sum(area),by=c(spatialid)] 
          region[,w:=area/totarea] 
          
          #mean
          eval(parse(text=paste0('sum_mean <- region[,.(',wvar,'=sum(',wvar,'*w)),by=spatialid]')))  
          
          if (wvar == wvars[1]) {
            result <- sum_mean
            result$date <- dtstr 
          } else {
            result <- merge(result,sum_mean,by=c(spatialid)) 
          }
          #write.csv(result,file=paste(outpath,yr,'/',outname,'_',dtstr,'.csv',sep=''),row.names = FALSE)
          
          unlink(dir(file.path('../',tempfoldname)))      
        }
        
        # save 
        if (initialwrite ==1) {
          fwrite(result,file=file.path(oldpath,outfile))
          initialwrite = 0
        } else {
          fwrite(result,file=file.path(oldpath,outfile),append=TRUE)
        }
        # report process 
        cat(sprintf('    The month of %s is completed\n',dtstr)) 

      }
      
    }
  },
  error=function(cond){
    setwd(oldpath)
    unlink(tempfoldname,recursive=TRUE) 
    message(cond)
  }, 
  finally={
    setwd(oldpath)
    unlink(tempfoldname,recursive=TRUE) 
    t2 <- proc.time() - t1
    message(sprintf('The tabulation job is done and takes %6.2f minutes',t2[3]/60)) 
  }
  )
  
}
