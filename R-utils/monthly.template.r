#==========================================================================================#
#==========================================================================================#
#     Create the monthly mean structure to be filled by plot_monthly.r                     #
#------------------------------------------------------------------------------------------#
create.monthly <<- function(ntimes,montha,yeara,inpref,slz.min){

   #----- Read the first HDF5 to grab some simulation-dependent dimensions. ---------------#
   cyear        = sprintf("%4.4i",yeara )
   cmonth       = sprintf("%2.2i",montha)
   h5first      = paste(inpref,"-Q-",cyear,"-",cmonth,"-00-000000-g01.h5"    ,sep="")
   h5first.bz2  = paste(inpref,"-Q-",cyear,"-",cmonth,"-00-000000-g01.h5.bz2",sep="")
   if ( file.exists(h5first) ){
      mymont    = hdf5load(file=h5first,load=FALSE,verbosity=0,tidy=TRUE)

   }else if ( file.exists(h5first.bz2) ){
      temp.file = file.path(tempdir(),basename(h5first))
      dummy     = bunzip2(filename=h5first.bz2,destname=temp.file,remove=FALSE)
      mymont    = hdf5load(file=temp.file,load=FALSE,verbosity=0,tidy=TRUE)
      dummy     = file.remove(temp.file)

   }else{
      cat (" Path: ",dirname (h5first),"\n")
      cat (" File: ",basename(h5first),"\n")
      stop(" File not found...")

   }#end if
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   #     Start up the list.                                                                #
   #---------------------------------------------------------------------------------------#
   ed      = list()
   #---------------------------------------------------------------------------------------#


   #----- Define the number of soil layers. -----------------------------------------------#
   ed$nzg        = mymont$NZG
   ed$nzs        = mymont$NZS
   ed$ndcycle    = mymont$NDCYCLE
   ed$ntimes     = ntimes
   #---------------------------------------------------------------------------------------#



   #----- Find which soil are we solving, and save properties into soil.prop. -------------#
   ed$isoilflg   = mymont$ISOILFLG
   ed$slz        = mymont$SLZ
   ed$slxsand    = mymont$SLXSAND
   ed$slxclay    = mymont$SLXCLAY
   ed$ntext      = mymont$NTEXT.SOIL[ed$nzg]
   #---------------------------------------------------------------------------------------#



   #----- Derive the soil properties. -----------------------------------------------------#
   ed$soil.prop  = soil.params(ed$ntext,ed$isoilflg,ed$slxsand,ed$slxclay)
   ed$dslz       = diff(c(ed$slz,0))
   ed$soil.depth = rev(cumsum(rev(ed$dslz)))
   ed$soil.dry   = rev(cumsum(rev(ed$soil.prop$soilcp * wdns * ed$dslz)))
   ed$soil.poro  = rev(cumsum(rev(ed$soil.prop$slmsts * wdns * ed$dslz)))
   #---------------------------------------------------------------------------------------#


   #----- Find the layers we care about. --------------------------------------------------#
   sel        = ed$slz < slz.min
   if (any(sel)){
      ed$ka      = which.max(ed$slz[sel])
   }else{
      ed$ka      = 1
   }#end if
   ed$kz         = ed$nzg
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   #     Find all time information.                                                        #
   #---------------------------------------------------------------------------------------#
   runmonths         = montha + sequence(ntimes) - 1
   ed$month         = 1 + (runmonths-1) %% 12
   ed$year          = yeara - 1 + ceiling(runmonths/12)
   ed$when          = chron(paste(ed$month,1,ed$year,sep="/"))
   ed$tomonth       = chron(ed$when,out.format=c(dates="day-mon-yr",times=NULL))
   ed$toyear        = sort(unique(ed$year))
   #----- Count the number of months for each month. --------------------------------------#
   ed$montable      = rep(0,times=12)
   montable            = table(ed$month)
   idx                 = as.numeric(names(montable))
   ed$montable[idx] = montable
   ed$moncnt        = matrix( data = rep(ed$montable,times=ed$ndcycle)
                               , ncol = ed$ndcycle
                               , nrow = 12
                               )#end matrix
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #     Find all the file names.                                                          #
   #---------------------------------------------------------------------------------------#
   cmonth   = sprintf("%2.2i",ed$month)
   cyear    = sprintf("%4.4i",ed$year )
   ed$input = paste(inpref,"-Q-",cyear,"-",cmonth,"-00-000000-g01.h5",sep="")
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #    Make a copy of the dimensions to avoid clutter.                                    #
   #---------------------------------------------------------------------------------------#
   ndcycle  = ed$ndcycle
   nzg      = ed$nzg
   nzs      = ed$nzs
   #---------------------------------------------------------------------------------------#



   #=======================================================================================#
   #=======================================================================================#
   #     Flush all variables that will hold the data.  For convenience they are split into #
   # multiple lists.                                                                       #
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   # emean -- variables that we can either compare directly with observations, or are      #
   #          or that may be used to draw time series.   They don't need to be really      #
   #          monthly means, but you should put only the variables that make sense to be   #
   #          plotted in simple time series (with no PFT or DBH information).              #
   #---------------------------------------------------------------------------------------#
   emean = list()
   emean$fast.soil.c             = rep(NA,times=ntimes)
   emean$slow.soil.c             = rep(NA,times=ntimes)
   emean$struct.soil.c           = rep(NA,times=ntimes)
   emean$het.resp                = rep(NA,times=ntimes)
   emean$cwd.resp                = rep(NA,times=ntimes)
   emean$gpp                     = rep(NA,times=ntimes)
   emean$npp                     = rep(NA,times=ntimes)
   emean$plant.resp              = rep(NA,times=ntimes)
   emean$leaf.resp               = rep(NA,times=ntimes)
   emean$root.resp               = rep(NA,times=ntimes)
   emean$growth.resp             = rep(NA,times=ntimes)
   emean$reco                    = rep(NA,times=ntimes)
   emean$mco                     = rep(NA,times=ntimes)
   emean$cba                     = rep(NA,times=ntimes)
   emean$cbamax                  = rep(NA,times=ntimes)
   emean$cbalight                = rep(NA,times=ntimes)
   emean$cbamoist                = rep(NA,times=ntimes)
   emean$cbarel                  = rep(NA,times=ntimes)
   emean$ldrop                   = rep(NA,times=ntimes)
   emean$nep                     = rep(NA,times=ntimes)
   emean$nee                     = rep(NA,times=ntimes)
   emean$cflxca                  = rep(NA,times=ntimes)
   emean$cflxst                  = rep(NA,times=ntimes)
   emean$ustar                   = rep(NA,times=ntimes)
   emean$atm.vels                = rep(NA,times=ntimes)
   emean$atm.prss                = rep(NA,times=ntimes)
   emean$atm.temp                = rep(NA,times=ntimes)
   emean$atm.shv                 = rep(NA,times=ntimes)
   emean$atm.vpd                 = rep(NA,times=ntimes)
   emean$atm.co2                 = rep(NA,times=ntimes)
   emean$can.prss                = rep(NA,times=ntimes)
   emean$can.temp                = rep(NA,times=ntimes)
   emean$can.co2                 = rep(NA,times=ntimes)
   emean$can.shv                 = rep(NA,times=ntimes)
   emean$can.vpd                 = rep(NA,times=ntimes)
   emean$gnd.temp                = rep(NA,times=ntimes)
   emean$gnd.shv                 = rep(NA,times=ntimes)
   emean$leaf.temp               = rep(NA,times=ntimes)
   emean$leaf.vpd                = rep(NA,times=ntimes)
   emean$wood.temp               = rep(NA,times=ntimes)
   emean$hflxca                  = rep(NA,times=ntimes)
   emean$qwflxca                 = rep(NA,times=ntimes)
   emean$hflxgc                  = rep(NA,times=ntimes)
   emean$hflxlc                  = rep(NA,times=ntimes)
   emean$hflxwc                  = rep(NA,times=ntimes)
   emean$wflxca                  = rep(NA,times=ntimes)
   emean$wflxgc                  = rep(NA,times=ntimes)
   emean$wflxlc                  = rep(NA,times=ntimes)
   emean$wflxwc                  = rep(NA,times=ntimes)
   emean$evap                    = rep(NA,times=ntimes)
   emean$transp                  = rep(NA,times=ntimes)
   emean$et                      = rep(NA,times=ntimes)
   emean$wue                     = rep(NA,times=ntimes)
   emean$rain                    = rep(NA,times=ntimes)
   emean$fs.open                 = rep(NA,times=ntimes)
   emean$rshort                  = rep(NA,times=ntimes)
   emean$rshort.beam             = rep(NA,times=ntimes)
   emean$rshort.diff             = rep(NA,times=ntimes)
   emean$rshortup                = rep(NA,times=ntimes)
   emean$rshort.gnd              = rep(NA,times=ntimes)
   emean$rlong                   = rep(NA,times=ntimes)
   emean$rlong.gnd               = rep(NA,times=ntimes)
   emean$rlongup                 = rep(NA,times=ntimes)
   emean$par.tot                 = rep(NA,times=ntimes)
   emean$par.beam                = rep(NA,times=ntimes)
   emean$par.diff                = rep(NA,times=ntimes)
   emean$par.gnd                 = rep(NA,times=ntimes)
   emean$parup                   = rep(NA,times=ntimes)
   emean$rnet                    = rep(NA,times=ntimes)
   emean$albedo                  = rep(NA,times=ntimes)
   emean$albedo.beam             = rep(NA,times=ntimes)
   emean$albedo.diff             = rep(NA,times=ntimes)
   emean$rlong.albedo            = rep(NA,times=ntimes)
   emean$nplant                  = rep(NA,times=ntimes)
   emean$agb                     = rep(NA,times=ntimes)
   emean$bgb                     = rep(NA,times=ntimes)
   emean$biomass                 = rep(NA,times=ntimes)
   emean$lai                     = rep(NA,times=ntimes)
   emean$wai                     = rep(NA,times=ntimes)
   emean$tai                     = rep(NA,times=ntimes)
   emean$area                    = rep(NA,times=ntimes)
   emean$workload                = rep(NA,times=ntimes)
   emean$specwork                = rep(NA,times=ntimes)
   emean$demand                  = rep(NA,times=ntimes)
   emean$supply                  = rep(NA,times=ntimes)
   emean$paw                     = rep(NA,times=ntimes)
   emean$smpot                   = rep(NA,times=ntimes)
   emean$npat.global             = rep(NA,times=ntimes)
   emean$ncoh.global             = rep(NA,times=ntimes)
   emean$water.deficit           = rep(NA,times=ntimes)
   emean$malhi.deficit           = rep(NA,times=ntimes)
   emean$leaf.gsw                = rep(NA,times=ntimes)
   emean$leaf.gbw                = rep(NA,times=ntimes)
   emean$wood.gbw                = rep(NA,times=ntimes)
   emean$i.gpp                   = rep(NA,times=ntimes)
   emean$i.npp                   = rep(NA,times=ntimes)
   emean$i.plant.resp            = rep(NA,times=ntimes)
   emean$i.mco                   = rep(NA,times=ntimes)
   emean$i.cba                   = rep(NA,times=ntimes)
   emean$i.cbamax                = rep(NA,times=ntimes)
   emean$i.cbalight              = rep(NA,times=ntimes)
   emean$i.cbamoist              = rep(NA,times=ntimes)
   emean$i.transp                = rep(NA,times=ntimes)
   emean$i.wflxlc                = rep(NA,times=ntimes)
   emean$i.hflxlc                = rep(NA,times=ntimes)
   emean$f.gpp                   = rep(NA,times=ntimes)
   emean$f.plant.resp            = rep(NA,times=ntimes)
   emean$f.npp                   = rep(NA,times=ntimes)
   emean$f.cba                   = rep(NA,times=ntimes)
   emean$f.bstorage              = rep(NA,times=ntimes)
   emean$f.bleaf                 = rep(NA,times=ntimes)
   emean$f.broot                 = rep(NA,times=ntimes)
   emean$f.bseeds                = rep(NA,times=ntimes)
   emean$leaf.par                = rep(NA,times=ntimes)
   emean$leaf.rshort             = rep(NA,times=ntimes)
   emean$leaf.rlong              = rep(NA,times=ntimes)
   #----- Soil variables. -----------------------------------------------------------------#
   emean$soil.water              = matrix(data=0,nrow=ntimes,ncol=nzg)
   emean$soil.temp               = matrix(data=0,nrow=ntimes,ncol=nzg)
   emean$soil.mstpot             = matrix(data=0,nrow=ntimes,ncol=nzg)
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   # emsqu -- mean sum of squares of polygon-level variable.                               #
   #---------------------------------------------------------------------------------------#
   emsqu                   = list()
   emsqu$gpp               = rep(NA,times=ntimes)
   emsqu$plant.resp        = rep(NA,times=ntimes)
   emsqu$leaf.resp         = rep(NA,times=ntimes)
   emsqu$root.resp         = rep(NA,times=ntimes)
   emsqu$het.resp          = rep(NA,times=ntimes)
   emsqu$cwd.resp          = rep(NA,times=ntimes)
   emsqu$reco              = rep(NA,times=ntimes)
   emsqu$cflxca            = rep(NA,times=ntimes)
   emsqu$cflxst            = rep(NA,times=ntimes)
   emsqu$hflxca            = rep(NA,times=ntimes)
   emsqu$hflxlc            = rep(NA,times=ntimes)
   emsqu$hflxwc            = rep(NA,times=ntimes)
   emsqu$hflxgc            = rep(NA,times=ntimes)
   emsqu$wflxca            = rep(NA,times=ntimes)
   emsqu$qwflxca           = rep(NA,times=ntimes)
   emsqu$wflxlc            = rep(NA,times=ntimes)
   emsqu$wflxwc            = rep(NA,times=ntimes)
   emsqu$wflxgc            = rep(NA,times=ntimes)
   emsqu$evap              = rep(NA,times=ntimes)
   emsqu$transp            = rep(NA,times=ntimes)
   emsqu$ustar             = rep(NA,times=ntimes)
   emsqu$albedo            = rep(NA,times=ntimes)
   emsqu$rshortup          = rep(NA,times=ntimes)
   emsqu$rlongup           = rep(NA,times=ntimes)
   emsqu$parup             = rep(NA,times=ntimes)
   emsqu$rnet              = rep(NA,times=ntimes)
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   # SZPFT -- Size (DBH) and plant functional type (PFT) array.  An extra level is         #
   #          appended to the end, which will hold the sum of all categories.              #
   #---------------------------------------------------------------------------------------#
   szpft = list()
   szpft$agb               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$bgb               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$biomass           = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$lai               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$wai               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$tai               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$ba                = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$gpp               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$npp               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$leaf.resp         = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$root.resp         = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$growth.resp       = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$plant.resp        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$mco               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$cba               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$cbamax            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$cbalight          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$cbamoist          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$cbarel            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$ldrop             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$fs.open           = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$leaf.gbw          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$leaf.gsw          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$wood.gbw          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$demand            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$supply            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$nplant            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$mort              = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$dimort            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$ncbmort           = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$growth            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$recr              = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$bdead             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$bleaf             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$broot             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$bsapwood          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$bstorage          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$bseeds            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$hflxlc            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$wflxlc            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$transp            = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$wue               = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$census.lai        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$census.wai        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$census.tai        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$census.agb        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$census.ba         = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.gpp             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.npp             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.plant.resp      = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.mco             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.cba             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.cbamax          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.cbalight        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.cbamoist        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.transp          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.wflxlc          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$i.hflxlc          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.gpp             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.plant.resp      = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.npp             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.cba             = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.bstorage        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.bleaf           = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.broot           = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$f.bseeds          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$leaf.par          = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$leaf.rshort       = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   szpft$leaf.rlong        = array(data=0.,dim=c(ntimes,ndbh+1,npft+1))
   #---------------------------------------------------------------------------------------#





   #---------------------------------------------------------------------------------------#
   # LU -- Polygon-level variables, split by land use type.  One extra dimension is        #
   #       appended to the end, which will hold the sum of all land use types.             #
   #---------------------------------------------------------------------------------------#
   lu          = list()
   lu$agb      = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$bgb      = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$biomass  = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$lai      = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$gpp      = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$npp      = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$area     = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$basarea  = matrix(data=0,nrow=ntimes,ncol=nlu+1)
   lu$dist     = array (data=NA,dim=c(ntimes,nlu,nlu))
   #---------------------------------------------------------------------------------------#









   #---------------------------------------------------------------------------------------#
   # QMEAN -- Polygon-level variables, containing the mean diel (diurnal cycle).           #
   #---------------------------------------------------------------------------------------#
   qmean                = list()
   qmean$gpp            = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$npp            = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$plant.resp     = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$leaf.resp      = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$root.resp      = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$growth.resp    = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$het.resp       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$cwd.resp       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$nep            = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$nee            = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$reco           = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$cflxca         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$cflxst         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$hflxca         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$hflxlc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$hflxwc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$hflxgc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$qwflxca        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$wflxca         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$wflxlc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$wflxwc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$wflxgc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$evap           = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$transp         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$atm.temp       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$can.temp       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$leaf.temp      = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$wood.temp      = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$gnd.temp       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$atm.shv        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$can.shv        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$gnd.shv        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$atm.vpd        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$can.vpd        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$leaf.vpd       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$atm.co2        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$can.co2        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$atm.prss       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$can.prss       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$atm.vels       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$ustar          = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$fs.open        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rain           = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rshort         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rshort.beam    = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rshort.diff    = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rshort.gnd     = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rshortup       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rlong          = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rlong.gnd      = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rlongup        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$par.tot        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$par.beam       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$par.diff       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$par.gnd        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$parup          = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rnet           = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$albedo         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$albedo.beam    = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$albedo.diff    = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$rlong.albedo   = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$leaf.gsw       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$leaf.gbw       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmean$wood.gbw       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   #---------------------------------------------------------------------------------------#









   #---------------------------------------------------------------------------------------#
   # QMSQU -- Polygon-level variables, containing the mean sum of squares for the diel     #
   #          (diurnal cycle).                                                             #
   #---------------------------------------------------------------------------------------#
   qmsqu                = list()
   qmsqu$gpp            = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$npp            = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$plant.resp     = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$leaf.resp      = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$root.resp      = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$het.resp       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$cwd.resp       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$nep            = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$reco           = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$cflxca         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$cflxst         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$hflxca         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$hflxlc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$hflxwc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$hflxgc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$qwflxca        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$wflxca         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$wflxlc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$wflxwc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$wflxgc         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$transp         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$ustar          = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$albedo         = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$rshortup       = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$rlongup        = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$parup          = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   qmsqu$rnet           = matrix(data=0,nrow=ntimes,ncol=ndcycle)
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   #  PATCH -- patch level variables, we save as lists because the dimensions vary.    #
   #---------------------------------------------------------------------------------------#
   patch               = list()
   patch$ipa           = list()
   patch$age           = list()
   patch$area          = list()
   patch$lu            = list()
   patch$nep           = list()
   patch$het.resp      = list()
   patch$can.temp      = list()
   patch$gnd.temp      = list()
   patch$can.shv       = list()
   patch$gnd.shv       = list()
   patch$can.vpd       = list()
   patch$can.co2       = list()
   patch$can.prss      = list()
   patch$cflxca        = list()
   patch$cflxst        = list()
   patch$nee           = list()
   patch$hflxca        = list()
   patch$hflxgc        = list()
   patch$qwflxca       = list()
   patch$wflxca        = list()
   patch$wflxgc        = list()
   patch$ustar         = list()
   patch$albedo        = list()
   patch$rshortup      = list()
   patch$rlongup       = list()
   patch$parup         = list()
   patch$rnet          = list()
   patch$lai           = list()
   patch$wai           = list()
   patch$tai           = list()
   patch$leaf.temp     = list()
   patch$leaf.vpd      = list()
   patch$wood.temp     = list()
   patch$gpp           = list()
   patch$npp           = list()
   patch$plant.resp    = list()
   patch$reco          = list()
   patch$hflxlc        = list()
   patch$hflxwc        = list()
   patch$wflxlc        = list()
   patch$wflxwc        = list()
   patch$transp        = list()
   #---------------------------------------------------------------------------------------#




   #----- Cohort level, we save as lists because the dimensions vary. ---------------------#
   cohort               = list()
   cohort$ipa           = list()
   cohort$ico           = list()
   cohort$area          = list()
   cohort$lu            = list()
   cohort$dbh           = list()
   cohort$age           = list()
   cohort$pft           = list()
   cohort$nplant        = list()
   cohort$height        = list()
   cohort$ba            = list()
   cohort$agb           = list()
   cohort$bgb           = list()
   cohort$biomass       = list()
   cohort$lai           = list()
   cohort$wai           = list()
   cohort$tai           = list()
   cohort$gpp           = list()
   cohort$leaf.resp     = list()
   cohort$root.resp     = list()
   cohort$growth.resp   = list()
   cohort$plant.resp    = list()
   cohort$npp           = list()
   cohort$cba           = list()
   cohort$cbamax        = list()
   cohort$cbalight      = list()
   cohort$cbamoist      = list()
   cohort$cbarel        = list()
   cohort$mcost         = list()
   cohort$ldrop         = list()
   cohort$fs.open       = list()
   cohort$light         = list()
   cohort$light.beam    = list()
   cohort$light.diff    = list()
   cohort$balive        = list()
   cohort$bdead         = list()
   cohort$bleaf         = list()
   cohort$broot         = list()
   cohort$bsapwood      = list()
   cohort$bstorage      = list()
   cohort$bseeds        = list()
   cohort$hflxlc        = list()
   cohort$wflxlc        = list()
   cohort$transp        = list()
   cohort$wue           = list()
   cohort$demand        = list()
   cohort$supply        = list()
   cohort$mort          = list()
   cohort$dimort        = list()
   cohort$ncbmort       = list()
   cohort$recruit       = list()
   cohort$growth        = list()
   cohort$f.gpp         = list()
   cohort$f.plant.resp  = list()
   cohort$f.npp         = list()
   cohort$f.cba         = list()
   cohort$f.bstorage    = list()
   cohort$f.bleaf       = list()
   cohort$f.broot       = list()
   cohort$f.bseeds      = list()
   cohort$leaf.par      = list()
   cohort$leaf.rshort   = list()
   cohort$leaf.rlong    = list()
   #---------------------------------------------------------------------------------------#





   #----- Copy the polygon-level variable to the main structure. --------------------------#
   ed$emean  = emean
   ed$emsqu  = emsqu
   ed$qmean  = qmean
   ed$qmsqu  = qmsqu
   ed$lu     = lu
   ed$szpft  = szpft
   ed$patch  = patch
   ed$cohort = cohort
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   return(ed)
   #---------------------------------------------------------------------------------------#

}#end create.monthly
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     Expand the monthly array so it fits the new times.                                   #
#------------------------------------------------------------------------------------------#
update.monthly <<- function(new.ntimes,old.datum,montha,yeara,inpref,slz.min){

   #----- Create the new data set. --------------------------------------------------------#
   new.datum = create.monthly(new.ntimes,montha,yeara,inpref,slz.min)
   #---------------------------------------------------------------------------------------#


   #----- Find out which times to copy. ---------------------------------------------------#
   idx = match(old.datum$when,new.datum$when)
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   # emean -- variables that we can either compare directly with observations, or are      #
   #          or that may be used to draw time series.   They don't need to be really      #
   #          monthly means, but you should put only the variables that make sense to be   #
   #          plotted in simple time series (with no PFT or DBH information).              #
   #---------------------------------------------------------------------------------------#
   new.datum$emean$fast.soil.c    [idx ] = old.datum$emean$fast.soil.c
   new.datum$emean$slow.soil.c    [idx ] = old.datum$emean$slow.soil.c
   new.datum$emean$struct.soil.c  [idx ] = old.datum$emean$struct.soil.c
   new.datum$emean$het.resp       [idx ] = old.datum$emean$het.resp
   new.datum$emean$cwd.resp       [idx ] = old.datum$emean$cwd.resp
   new.datum$emean$gpp            [idx ] = old.datum$emean$gpp
   new.datum$emean$npp            [idx ] = old.datum$emean$npp
   new.datum$emean$plant.resp     [idx ] = old.datum$emean$plant.resp
   new.datum$emean$leaf.resp      [idx ] = old.datum$emean$leaf.resp
   new.datum$emean$root.resp      [idx ] = old.datum$emean$root.resp
   new.datum$emean$growth.resp    [idx ] = old.datum$emean$growth.resp
   new.datum$emean$reco           [idx ] = old.datum$emean$reco
   new.datum$emean$mco            [idx ] = old.datum$emean$mco
   new.datum$emean$cba            [idx ] = old.datum$emean$cba
   new.datum$emean$cbamax         [idx ] = old.datum$emean$cbamax
   new.datum$emean$cbalight       [idx ] = old.datum$emean$cbalight
   new.datum$emean$cbamoist       [idx ] = old.datum$emean$cbamoist
   new.datum$emean$cbarel         [idx ] = old.datum$emean$cbarel
   new.datum$emean$ldrop          [idx ] = old.datum$emean$ldrop
   new.datum$emean$nep            [idx ] = old.datum$emean$nep
   new.datum$emean$nee            [idx ] = old.datum$emean$nee
   new.datum$emean$cflxca         [idx ] = old.datum$emean$cflxca
   new.datum$emean$cflxst         [idx ] = old.datum$emean$cflxst
   new.datum$emean$evap           [idx ] = old.datum$emean$evap
   new.datum$emean$transp         [idx ] = old.datum$emean$transp
   new.datum$emean$wue            [idx ] = old.datum$emean$wue
   new.datum$emean$ustar          [idx ] = old.datum$emean$ustar
   new.datum$emean$atm.vels       [idx ] = old.datum$emean$atm.vels
   new.datum$emean$atm.prss       [idx ] = old.datum$emean$atm.prss
   new.datum$emean$atm.temp       [idx ] = old.datum$emean$atm.temp
   new.datum$emean$can.prss       [idx ] = old.datum$emean$can.prss
   new.datum$emean$can.temp       [idx ] = old.datum$emean$can.temp
   new.datum$emean$atm.co2        [idx ] = old.datum$emean$atm.co2
   new.datum$emean$can.co2        [idx ] = old.datum$emean$can.co2
   new.datum$emean$leaf.temp      [idx ] = old.datum$emean$leaf.temp
   new.datum$emean$wood.temp      [idx ] = old.datum$emean$wood.temp
   new.datum$emean$atm.shv        [idx ] = old.datum$emean$atm.shv
   new.datum$emean$can.shv        [idx ] = old.datum$emean$can.shv
   new.datum$emean$atm.vpd        [idx ] = old.datum$emean$atm.vpd
   new.datum$emean$can.vpd        [idx ] = old.datum$emean$can.vpd
   new.datum$emean$leaf.vpd       [idx ] = old.datum$emean$leaf.vpd
   new.datum$emean$can.co2        [idx ] = old.datum$emean$can.co2
   new.datum$emean$hflxca         [idx ] = old.datum$emean$hflxca
   new.datum$emean$qwflxca        [idx ] = old.datum$emean$qwflxca
   new.datum$emean$wflxca         [idx ] = old.datum$emean$wflxca
   new.datum$emean$agb            [idx ] = old.datum$emean$agb
   new.datum$emean$bgb            [idx ] = old.datum$emean$bgb
   new.datum$emean$biomass        [idx ] = old.datum$emean$biomass
   new.datum$emean$nplant         [idx ] = old.datum$emean$nplant
   new.datum$emean$lai            [idx ] = old.datum$emean$lai
   new.datum$emean$wai            [idx ] = old.datum$emean$wai
   new.datum$emean$tai            [idx ] = old.datum$emean$tai
   new.datum$emean$area           [idx ] = old.datum$emean$area
   new.datum$emean$rain           [idx ] = old.datum$emean$rain
   new.datum$emean$gnd.temp       [idx ] = old.datum$emean$gnd.temp
   new.datum$emean$gnd.shv        [idx ] = old.datum$emean$gnd.shv
   new.datum$emean$workload       [idx ] = old.datum$emean$workload
   new.datum$emean$specwork       [idx ] = old.datum$emean$specwork
   new.datum$emean$fs.open        [idx ] = old.datum$emean$fs.open
   new.datum$emean$demand         [idx ] = old.datum$emean$demand
   new.datum$emean$supply         [idx ] = old.datum$emean$supply
   new.datum$emean$hflxgc         [idx ] = old.datum$emean$hflxgc
   new.datum$emean$hflxlc         [idx ] = old.datum$emean$hflxlc
   new.datum$emean$hflxwc         [idx ] = old.datum$emean$hflxwc
   new.datum$emean$wflxgc         [idx ] = old.datum$emean$wflxgc
   new.datum$emean$wflxlc         [idx ] = old.datum$emean$wflxlc
   new.datum$emean$wflxwc         [idx ] = old.datum$emean$wflxwc
   new.datum$emean$et             [idx ] = old.datum$emean$et
   new.datum$emean$rshort         [idx ] = old.datum$emean$rshort
   new.datum$emean$rshort.beam    [idx ] = old.datum$emean$rshort.beam
   new.datum$emean$rshort.diff    [idx ] = old.datum$emean$rshort.diff
   new.datum$emean$rshortup       [idx ] = old.datum$emean$rshortup
   new.datum$emean$rshort.gnd     [idx ] = old.datum$emean$rshort.gnd
   new.datum$emean$rlong          [idx ] = old.datum$emean$rlong
   new.datum$emean$rlong.gnd      [idx ] = old.datum$emean$rlong.gnd
   new.datum$emean$rlongup        [idx ] = old.datum$emean$rlongup
   new.datum$emean$par.tot        [idx ] = old.datum$emean$par.tot
   new.datum$emean$par.beam       [idx ] = old.datum$emean$par.beam
   new.datum$emean$par.diff       [idx ] = old.datum$emean$par.diff
   new.datum$emean$par.gnd        [idx ] = old.datum$emean$par.gnd
   new.datum$emean$parup          [idx ] = old.datum$emean$parup
   new.datum$emean$rnet           [idx ] = old.datum$emean$rnet
   new.datum$emean$albedo         [idx ] = old.datum$emean$albedo
   new.datum$emean$albedo.beam    [idx ] = old.datum$emean$albedo.beam
   new.datum$emean$albedo.diff    [idx ] = old.datum$emean$albedo.diff
   new.datum$emean$rlong.albedo   [idx ] = old.datum$emean$rlong.albedo
   new.datum$emean$paw            [idx ] = old.datum$emean$paw
   new.datum$emean$smpot          [idx ] = old.datum$emean$smpot
   new.datum$emean$npat.global    [idx ] = old.datum$emean$npat.global
   new.datum$emean$ncoh.global    [idx ] = old.datum$emean$ncoh.global
   new.datum$emean$water.deficit  [idx ] = old.datum$emean$water.deficit
   new.datum$emean$malhi.deficit  [idx ] = old.datum$emean$malhi.deficit
   new.datum$emean$i.gpp          [idx ] = old.datum$emean$i.gpp
   new.datum$emean$i.npp          [idx ] = old.datum$emean$i.npp
   new.datum$emean$i.plant.resp   [idx ] = old.datum$emean$i.plant.resp
   new.datum$emean$i.mco          [idx ] = old.datum$emean$i.mco
   new.datum$emean$i.cba          [idx ] = old.datum$emean$i.cba
   new.datum$emean$i.cbamax       [idx ] = old.datum$emean$i.cbamax
   new.datum$emean$i.cbalight     [idx ] = old.datum$emean$i.cbalight
   new.datum$emean$i.cbamoist     [idx ] = old.datum$emean$i.cbamoist
   new.datum$emean$i.transp       [idx ] = old.datum$emean$i.transp
   new.datum$emean$i.wflxlc       [idx ] = old.datum$emean$i.wflxlc
   new.datum$emean$i.hflxlc       [idx ] = old.datum$emean$i.hflxlc
   new.datum$emean$f.gpp          [idx ] = old.datum$emean$f.gpp
   new.datum$emean$f.plant.resp   [idx ] = old.datum$emean$f.plant.resp
   new.datum$emean$f.npp          [idx ] = old.datum$emean$f.npp
   new.datum$emean$f.cba          [idx ] = old.datum$emean$f.cba
   new.datum$emean$f.bstorage     [idx ] = old.datum$emean$f.bstorage
   new.datum$emean$f.bleaf        [idx ] = old.datum$emean$f.bleaf
   new.datum$emean$f.broot        [idx ] = old.datum$emean$f.broot
   new.datum$emean$f.bseeds       [idx ] = old.datum$emean$f.bseeds
   new.datum$emean$leaf.gsw       [idx ] = old.datum$emean$leaf.gsw
   new.datum$emean$leaf.gbw       [idx ] = old.datum$emean$leaf.gbw
   new.datum$emean$wood.gbw       [idx ] = old.datum$emean$wood.gbw
   new.datum$emean$leaf.par       [idx ] = old.datum$emean$leaf.par
   new.datum$emean$leaf.rshort    [idx ] = old.datum$emean$leaf.rshort
   new.datum$emean$leaf.rlong     [idx ] = old.datum$emean$leaf.rlong
   new.datum$emean$soil.water     [idx,] = old.datum$emean$soil.water
   new.datum$emean$soil.temp      [idx,] = old.datum$emean$soil.temp
   new.datum$emean$soil.mstpot    [idx,] = old.datum$emean$soil.mstpot
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   # emsqu -- mean sum of squares of polygon-level variable.                               #
   #---------------------------------------------------------------------------------------#
   new.datum$emsqu$gpp            [idx] = old.datum$emsqu$gpp
   new.datum$emsqu$plant.resp     [idx] = old.datum$emsqu$plant.resp
   new.datum$emsqu$het.resp       [idx] = old.datum$emsqu$het.resp
   new.datum$emsqu$cwd.resp       [idx] = old.datum$emsqu$cwd.resp
   new.datum$emsqu$cflxca         [idx] = old.datum$emsqu$cflxca
   new.datum$emsqu$cflxst         [idx] = old.datum$emsqu$cflxst
   new.datum$emsqu$hflxca         [idx] = old.datum$emsqu$hflxca
   new.datum$emsqu$hflxlc         [idx] = old.datum$emsqu$hflxlc
   new.datum$emsqu$hflxwc         [idx] = old.datum$emsqu$hflxwc
   new.datum$emsqu$hflxgc         [idx] = old.datum$emsqu$hflxgc
   new.datum$emsqu$wflxca         [idx] = old.datum$emsqu$wflxca
   new.datum$emsqu$qwflxca        [idx] = old.datum$emsqu$qwflxca
   new.datum$emsqu$wflxlc         [idx] = old.datum$emsqu$wflxlc
   new.datum$emsqu$wflxwc         [idx] = old.datum$emsqu$wflxwc
   new.datum$emsqu$wflxgc         [idx] = old.datum$emsqu$wflxgc
   new.datum$emsqu$transp         [idx] = old.datum$emsqu$transp
   new.datum$emsqu$ustar          [idx] = old.datum$emsqu$ustar
   new.datum$emsqu$albedo         [idx] = old.datum$emsqu$albedo
   new.datum$emsqu$rshortup       [idx] = old.datum$emsqu$rshortup
   new.datum$emsqu$rlongup        [idx] = old.datum$emsqu$rlongup
   new.datum$emsqu$parup          [idx] = old.datum$emsqu$parup
   new.datum$emsqu$rnet           [idx] = old.datum$emsqu$rnet
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   # SZPFT -- Size (DBH) and plant functional type (PFT) array.  An extra level is         #
   #          appended to the end, which will hold the sum of all categories.              #
   #---------------------------------------------------------------------------------------#
   new.datum$szpft$agb            [idx,,] = old.datum$szpft$agb
   new.datum$szpft$bgb            [idx,,] = old.datum$szpft$bgb
   new.datum$szpft$biomass        [idx,,] = old.datum$szpft$biomass
   new.datum$szpft$lai            [idx,,] = old.datum$szpft$lai
   new.datum$szpft$wai            [idx,,] = old.datum$szpft$wai
   new.datum$szpft$tai            [idx,,] = old.datum$szpft$tai
   new.datum$szpft$ba             [idx,,] = old.datum$szpft$ba
   new.datum$szpft$gpp            [idx,,] = old.datum$szpft$gpp
   new.datum$szpft$npp            [idx,,] = old.datum$szpft$npp
   new.datum$szpft$leaf.resp      [idx,,] = old.datum$szpft$leaf.resp
   new.datum$szpft$root.resp      [idx,,] = old.datum$szpft$root.resp
   new.datum$szpft$growth.resp    [idx,,] = old.datum$szpft$growth.resp
   new.datum$szpft$plant.resp     [idx,,] = old.datum$szpft$plant.resp
   new.datum$szpft$mco            [idx,,] = old.datum$szpft$mco
   new.datum$szpft$cba            [idx,,] = old.datum$szpft$cba
   new.datum$szpft$cbamax         [idx,,] = old.datum$szpft$cbamax
   new.datum$szpft$cbalight       [idx,,] = old.datum$szpft$cbalight
   new.datum$szpft$cbamoist       [idx,,] = old.datum$szpft$cbamoist
   new.datum$szpft$cbarel         [idx,,] = old.datum$szpft$cbarel
   new.datum$szpft$ldrop          [idx,,] = old.datum$szpft$ldrop
   new.datum$szpft$fs.open        [idx,,] = old.datum$szpft$fs.open
   new.datum$szpft$leaf.gbw       [idx,,] = old.datum$szpft$leaf.gbw
   new.datum$szpft$leaf.gsw       [idx,,] = old.datum$szpft$leaf.gsw
   new.datum$szpft$wood.gbw       [idx,,] = old.datum$szpft$wood.gbw
   new.datum$szpft$demand         [idx,,] = old.datum$szpft$demand
   new.datum$szpft$supply         [idx,,] = old.datum$szpft$supply
   new.datum$szpft$nplant         [idx,,] = old.datum$szpft$nplant
   new.datum$szpft$mort           [idx,,] = old.datum$szpft$mort
   new.datum$szpft$dimort         [idx,,] = old.datum$szpft$dimort
   new.datum$szpft$ncbmort        [idx,,] = old.datum$szpft$ncbmort
   new.datum$szpft$growth         [idx,,] = old.datum$szpft$growth
   new.datum$szpft$recr           [idx,,] = old.datum$szpft$recr
   new.datum$szpft$bdead          [idx,,] = old.datum$szpft$bdead
   new.datum$szpft$bleaf          [idx,,] = old.datum$szpft$bleaf
   new.datum$szpft$broot          [idx,,] = old.datum$szpft$broot
   new.datum$szpft$bsapwood       [idx,,] = old.datum$szpft$bsapwood
   new.datum$szpft$bstorage       [idx,,] = old.datum$szpft$bstorage
   new.datum$szpft$bseeds         [idx,,] = old.datum$szpft$bseeds
   new.datum$szpft$hflxlc         [idx,,] = old.datum$szpft$hflxlc
   new.datum$szpft$wflxlc         [idx,,] = old.datum$szpft$wflxlc
   new.datum$szpft$transp         [idx,,] = old.datum$szpft$transp
   new.datum$szpft$wue            [idx,,] = old.datum$szpft$wue
   new.datum$szpft$census.lai     [idx,,] = old.datum$szpft$census.lai
   new.datum$szpft$census.wai     [idx,,] = old.datum$szpft$census.wai
   new.datum$szpft$census.tai     [idx,,] = old.datum$szpft$census.tai
   new.datum$szpft$census.agb     [idx,,] = old.datum$szpft$census.agb
   new.datum$szpft$census.ba      [idx,,] = old.datum$szpft$census.ba 
   new.datum$szpft$i.gpp          [idx,,] = old.datum$szpft$i.gpp
   new.datum$szpft$i.npp          [idx,,] = old.datum$szpft$i.npp
   new.datum$szpft$i.plant.resp   [idx,,] = old.datum$szpft$i.plant.resp
   new.datum$szpft$i.mco          [idx,,] = old.datum$szpft$i.mco
   new.datum$szpft$i.cba          [idx,,] = old.datum$szpft$i.cba
   new.datum$szpft$i.cbamax       [idx,,] = old.datum$szpft$i.cbamax
   new.datum$szpft$i.cbalight     [idx,,] = old.datum$szpft$i.cbalight
   new.datum$szpft$i.cbamoist     [idx,,] = old.datum$szpft$i.cbamoist
   new.datum$szpft$i.transp       [idx,,] = old.datum$szpft$i.transp
   new.datum$szpft$i.wflxlc       [idx,,] = old.datum$szpft$i.wflxlc
   new.datum$szpft$i.hflxlc       [idx,,] = old.datum$szpft$i.hflxlc
   new.datum$szpft$f.gpp          [idx,,] = old.datum$szpft$f.gpp
   new.datum$szpft$f.plant.resp   [idx,,] = old.datum$szpft$f.plant.resp
   new.datum$szpft$f.npp          [idx,,] = old.datum$szpft$f.npp
   new.datum$szpft$f.cba          [idx,,] = old.datum$szpft$f.cba
   new.datum$szpft$f.bstorage     [idx,,] = old.datum$szpft$f.bstorage
   new.datum$szpft$f.bleaf        [idx,,] = old.datum$szpft$f.bleaf
   new.datum$szpft$f.broot        [idx,,] = old.datum$szpft$f.broot
   new.datum$szpft$f.bseeds       [idx,,] = old.datum$szpft$f.bseeds
   new.datum$szpft$leaf.par       [idx,,] = old.datum$szpft$leaf.par
   new.datum$szpft$leaf.rshort    [idx,,] = old.datum$szpft$leaf.rshort
   new.datum$szpft$leaf.rlong     [idx,,] = old.datum$szpft$leaf.rlong
   #---------------------------------------------------------------------------------------#





   #---------------------------------------------------------------------------------------#
   # LU -- Polygon-level variables, split by land use type.  One extra dimension is        #
   #       appended to the end, which will hold the sum of all land use types.             #
   #---------------------------------------------------------------------------------------#
   new.datum$lu$agb               [idx, ] = old.datum$lu$agb
   new.datum$lu$bgb               [idx, ] = old.datum$lu$bgb
   new.datum$lu$biomass           [idx, ] = old.datum$lu$biomass
   new.datum$lu$lai               [idx, ] = old.datum$lu$lai
   new.datum$lu$gpp               [idx, ] = old.datum$lu$gpp
   new.datum$lu$npp               [idx, ] = old.datum$lu$npp
   new.datum$lu$area              [idx, ] = old.datum$lu$area
   new.datum$lu$basarea           [idx, ] = old.datum$lu$basarea
   new.datum$lu$dist              [idx,,] = old.datum$lu$dist
   #---------------------------------------------------------------------------------------#









   #---------------------------------------------------------------------------------------#
   # QMEAN -- Polygon-level variables, containing the mean diel (diurnal cycle).           #
   #---------------------------------------------------------------------------------------#
   new.datum$qmean$gpp           [idx,] = old.datum$qmean$gpp
   new.datum$qmean$npp           [idx,] = old.datum$qmean$npp
   new.datum$qmean$plant.resp    [idx,] = old.datum$qmean$plant.resp
   new.datum$qmean$leaf.resp     [idx,] = old.datum$qmean$leaf.resp
   new.datum$qmean$root.resp     [idx,] = old.datum$qmean$root.resp
   new.datum$qmean$growth.resp   [idx,] = old.datum$qmean$growth.resp
   new.datum$qmean$het.resp      [idx,] = old.datum$qmean$het.resp
   new.datum$qmean$cwd.resp      [idx,] = old.datum$qmean$cwd.resp
   new.datum$qmean$nep           [idx,] = old.datum$qmean$nep
   new.datum$qmean$nee           [idx,] = old.datum$qmean$nee
   new.datum$qmean$reco          [idx,] = old.datum$qmean$reco
   new.datum$qmean$cflxca        [idx,] = old.datum$qmean$cflxca
   new.datum$qmean$cflxst        [idx,] = old.datum$qmean$cflxst
   new.datum$qmean$hflxca        [idx,] = old.datum$qmean$hflxca
   new.datum$qmean$hflxlc        [idx,] = old.datum$qmean$hflxlc
   new.datum$qmean$hflxwc        [idx,] = old.datum$qmean$hflxwc
   new.datum$qmean$hflxgc        [idx,] = old.datum$qmean$hflxgc
   new.datum$qmean$qwflxca       [idx,] = old.datum$qmean$qwflxca
   new.datum$qmean$wflxca        [idx,] = old.datum$qmean$wflxca
   new.datum$qmean$wflxlc        [idx,] = old.datum$qmean$wflxlc
   new.datum$qmean$wflxwc        [idx,] = old.datum$qmean$wflxwc
   new.datum$qmean$wflxgc        [idx,] = old.datum$qmean$wflxgc
   new.datum$qmean$evap          [idx,] = old.datum$qmean$evap
   new.datum$qmean$transp        [idx,] = old.datum$qmean$transp
   new.datum$qmean$atm.temp      [idx,] = old.datum$qmean$atm.temp
   new.datum$qmean$can.temp      [idx,] = old.datum$qmean$can.temp
   new.datum$qmean$leaf.temp     [idx,] = old.datum$qmean$leaf.temp
   new.datum$qmean$wood.temp     [idx,] = old.datum$qmean$wood.temp
   new.datum$qmean$gnd.temp      [idx,] = old.datum$qmean$gnd.temp
   new.datum$qmean$atm.shv       [idx,] = old.datum$qmean$atm.shv
   new.datum$qmean$can.shv       [idx,] = old.datum$qmean$can.shv
   new.datum$qmean$gnd.shv       [idx,] = old.datum$qmean$gnd.shv
   new.datum$qmean$atm.vpd       [idx,] = old.datum$qmean$atm.vpd
   new.datum$qmean$can.vpd       [idx,] = old.datum$qmean$can.vpd
   new.datum$qmean$leaf.vpd      [idx,] = old.datum$qmean$leaf.vpd
   new.datum$qmean$atm.co2       [idx,] = old.datum$qmean$atm.co2
   new.datum$qmean$can.co2       [idx,] = old.datum$qmean$can.co2
   new.datum$qmean$atm.prss      [idx,] = old.datum$qmean$atm.prss
   new.datum$qmean$can.prss      [idx,] = old.datum$qmean$can.prss
   new.datum$qmean$atm.vels      [idx,] = old.datum$qmean$atm.vels
   new.datum$qmean$ustar         [idx,] = old.datum$qmean$ustar
   new.datum$qmean$fs.open       [idx,] = old.datum$qmean$fs.open
   new.datum$qmean$rain          [idx,] = old.datum$qmean$rain
   new.datum$qmean$rshort        [idx,] = old.datum$qmean$rshort
   new.datum$qmean$rshort.beam   [idx,] = old.datum$qmean$rshort.beam
   new.datum$qmean$rshort.diff   [idx,] = old.datum$qmean$rshort.diff
   new.datum$qmean$rshort.gnd    [idx,] = old.datum$qmean$rshort.gnd
   new.datum$qmean$rshortup      [idx,] = old.datum$qmean$rshortup
   new.datum$qmean$rlong         [idx,] = old.datum$qmean$rlong
   new.datum$qmean$rlong.gnd     [idx,] = old.datum$qmean$rlong.gnd
   new.datum$qmean$rlongup       [idx,] = old.datum$qmean$rlongup
   new.datum$qmean$par.tot       [idx,] = old.datum$qmean$par.tot
   new.datum$qmean$par.beam      [idx,] = old.datum$qmean$par.beam
   new.datum$qmean$par.diff      [idx,] = old.datum$qmean$par.diff
   new.datum$qmean$par.gnd       [idx,] = old.datum$qmean$par.gnd
   new.datum$qmean$parup         [idx,] = old.datum$qmean$parup
   new.datum$qmean$rnet          [idx,] = old.datum$qmean$rnet
   new.datum$qmean$albedo        [idx,] = old.datum$qmean$albedo
   new.datum$qmean$albedo.beam   [idx,] = old.datum$qmean$albedo.beam
   new.datum$qmean$albedo.diff   [idx,] = old.datum$qmean$albedo.diff
   new.datum$qmean$rlong.albedo  [idx,] = old.datum$qmean$rlong.albedo
   new.datum$qmean$leaf.gsw      [idx,] = old.datum$qmean$leaf.gsw
   new.datum$qmean$leaf.gbw      [idx,] = old.datum$qmean$leaf.gbw
   new.datum$qmean$wood.gbw      [idx,] = old.datum$qmean$wood.gbw
   #---------------------------------------------------------------------------------------#









   #---------------------------------------------------------------------------------------#
   # QMSQU -- Polygon-level variables, containing the mean sum of squares for the diel     #
   #          (diurnal cycle).                                                             #
   #---------------------------------------------------------------------------------------#
   new.datum$qmsqu$gpp           [idx,] = old.datum$qmsqu$gpp
   new.datum$qmsqu$npp           [idx,] = old.datum$qmsqu$npp
   new.datum$qmsqu$plant.resp    [idx,] = old.datum$qmsqu$plant.resp
   new.datum$qmsqu$het.resp      [idx,] = old.datum$qmsqu$het.resp
   new.datum$qmsqu$cwd.resp      [idx,] = old.datum$qmsqu$cwd.resp
   new.datum$qmsqu$nep           [idx,] = old.datum$qmsqu$nep
   new.datum$qmsqu$cflxca        [idx,] = old.datum$qmsqu$cflxca
   new.datum$qmsqu$cflxst        [idx,] = old.datum$qmsqu$cflxst
   new.datum$qmsqu$hflxca        [idx,] = old.datum$qmsqu$hflxca
   new.datum$qmsqu$hflxlc        [idx,] = old.datum$qmsqu$hflxlc
   new.datum$qmsqu$hflxwc        [idx,] = old.datum$qmsqu$hflxwc
   new.datum$qmsqu$hflxgc        [idx,] = old.datum$qmsqu$hflxgc
   new.datum$qmsqu$qwflxca       [idx,] = old.datum$qmsqu$qwflxca
   new.datum$qmsqu$wflxca        [idx,] = old.datum$qmsqu$wflxca
   new.datum$qmsqu$wflxlc        [idx,] = old.datum$qmsqu$wflxlc
   new.datum$qmsqu$wflxwc        [idx,] = old.datum$qmsqu$wflxwc
   new.datum$qmsqu$wflxgc        [idx,] = old.datum$qmsqu$wflxgc
   new.datum$qmsqu$transp        [idx,] = old.datum$qmsqu$transp
   new.datum$qmsqu$ustar         [idx,] = old.datum$qmsqu$ustar
   new.datum$qmsqu$albedo        [idx,] = old.datum$qmsqu$albedo
   new.datum$qmsqu$rshortup      [idx,] = old.datum$qmsqu$rshortup
   new.datum$qmsqu$rlongup       [idx,] = old.datum$qmsqu$rlongup
   new.datum$qmsqu$parup         [idx,] = old.datum$qmsqu$parup
   new.datum$qmsqu$rnet          [idx,] = old.datum$qmsqu$rnet
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   #  PATCH -- patch level variables, we save as lists because the dimensions vary.    #
   #---------------------------------------------------------------------------------------#
   new.datum$patch$ipa           = old.datum$patch$ipa
   new.datum$patch$age           = old.datum$patch$age
   new.datum$patch$area          = old.datum$patch$area
   new.datum$patch$lu            = old.datum$patch$lu
   new.datum$patch$nep           = old.datum$patch$nep
   new.datum$patch$het.resp      = old.datum$patch$het.resp
   new.datum$patch$can.temp      = old.datum$patch$can.temp
   new.datum$patch$gnd.temp      = old.datum$patch$gnd.temp
   new.datum$patch$can.shv       = old.datum$patch$can.shv
   new.datum$patch$gnd.shv       = old.datum$patch$gnd.shv
   new.datum$patch$can.vpd       = old.datum$patch$can.vpd
   new.datum$patch$can.co2       = old.datum$patch$can.co2
   new.datum$patch$can.prss      = old.datum$patch$can.prss
   new.datum$patch$cflxca        = old.datum$patch$cflxca
   new.datum$patch$cflxst        = old.datum$patch$cflxst
   new.datum$patch$nee           = old.datum$patch$nee
   new.datum$patch$hflxca        = old.datum$patch$hflxca
   new.datum$patch$hflxgc        = old.datum$patch$hflxgc
   new.datum$patch$qwflxca       = old.datum$patch$qwflxca
   new.datum$patch$wflxca        = old.datum$patch$wflxca
   new.datum$patch$wflxgc        = old.datum$patch$wflxgc
   new.datum$patch$ustar         = old.datum$patch$ustar
   new.datum$patch$albedo        = old.datum$patch$albedo
   new.datum$patch$rshortup      = old.datum$patch$rshortup
   new.datum$patch$rlongup       = old.datum$patch$rlongup
   new.datum$patch$parup         = old.datum$patch$parup
   new.datum$patch$rnet          = old.datum$patch$rnet
   new.datum$patch$lai           = old.datum$patch$lai
   new.datum$patch$wai           = old.datum$patch$wai
   new.datum$patch$tai           = old.datum$patch$tai
   new.datum$patch$leaf.temp     = old.datum$patch$leaf.temp
   new.datum$patch$leaf.vpd      = old.datum$patch$leaf.vpd
   new.datum$patch$wood.temp     = old.datum$patch$wood.temp
   new.datum$patch$gpp           = old.datum$patch$gpp
   new.datum$patch$npp           = old.datum$patch$npp
   new.datum$patch$plant.resp    = old.datum$patch$plant.resp
   new.datum$patch$reco          = old.datum$patch$reco
   new.datum$patch$hflxlc        = old.datum$patch$hflxlc
   new.datum$patch$hflxwc        = old.datum$patch$hflxwc
   new.datum$patch$wflxlc        = old.datum$patch$wflxlc
   new.datum$patch$wflxwc        = old.datum$patch$wflxwc
   new.datum$patch$transp        = old.datum$patch$transp
   #---------------------------------------------------------------------------------------#




   #----- Cohort level, we save as lists because the dimensions vary. ---------------------#
   new.datum$cohort$ipa          = old.datum$cohort$ipa
   new.datum$cohort$ico          = old.datum$cohort$ico
   new.datum$cohort$area         = old.datum$cohort$area
   new.datum$cohort$lu           = old.datum$cohort$lu
   new.datum$cohort$dbh          = old.datum$cohort$dbh
   new.datum$cohort$age          = old.datum$cohort$age
   new.datum$cohort$pft          = old.datum$cohort$pft
   new.datum$cohort$nplant       = old.datum$cohort$nplant
   new.datum$cohort$height       = old.datum$cohort$height
   new.datum$cohort$ba           = old.datum$cohort$ba
   new.datum$cohort$agb          = old.datum$cohort$agb
   new.datum$cohort$bgb          = old.datum$cohort$bgb
   new.datum$cohort$biomass      = old.datum$cohort$biomass
   new.datum$cohort$lai          = old.datum$cohort$lai
   new.datum$cohort$wai          = old.datum$cohort$wai
   new.datum$cohort$tai          = old.datum$cohort$tai
   new.datum$cohort$gpp          = old.datum$cohort$gpp
   new.datum$cohort$leaf.resp    = old.datum$cohort$leaf.resp
   new.datum$cohort$root.resp    = old.datum$cohort$root.resp
   new.datum$cohort$growth.resp  = old.datum$cohort$growth.resp
   new.datum$cohort$plant.resp   = old.datum$cohort$plant.resp
   new.datum$cohort$npp          = old.datum$cohort$npp
   new.datum$cohort$cba          = old.datum$cohort$cba
   new.datum$cohort$cbamax       = old.datum$cohort$cbamax
   new.datum$cohort$cbalight     = old.datum$cohort$cbalight
   new.datum$cohort$cbamoist     = old.datum$cohort$cbamoist
   new.datum$cohort$cbarel       = old.datum$cohort$cbarel
   new.datum$cohort$mcost        = old.datum$cohort$mcost
   new.datum$cohort$ldrop        = old.datum$cohort$ldrop
   new.datum$cohort$fs.open      = old.datum$cohort$fs.open
   new.datum$cohort$light        = old.datum$cohort$light
   new.datum$cohort$lightbeam    = old.datum$cohort$lightbeam
   new.datum$cohort$lightdiff    = old.datum$cohort$lightdiff
   new.datum$cohort$balive       = old.datum$cohort$balive
   new.datum$cohort$bdead        = old.datum$cohort$bdead
   new.datum$cohort$bleaf        = old.datum$cohort$bleaf
   new.datum$cohort$broot        = old.datum$cohort$broot
   new.datum$cohort$bsapwood     = old.datum$cohort$bsapwood
   new.datum$cohort$bstorage     = old.datum$cohort$bstorage
   new.datum$cohort$bseeds       = old.datum$cohort$bseeds
   new.datum$cohort$hflxlc       = old.datum$cohort$hflxlc
   new.datum$cohort$wflxlc       = old.datum$cohort$wflxlc
   new.datum$cohort$transp       = old.datum$cohort$transp
   new.datum$cohort$wue          = old.datum$cohort$wue
   new.datum$cohort$demand       = old.datum$cohort$demand
   new.datum$cohort$supply       = old.datum$cohort$supply
   new.datum$cohort$mort         = old.datum$cohort$mort
   new.datum$cohort$dimort       = old.datum$cohort$dimort
   new.datum$cohort$ncbmort      = old.datum$cohort$ncbmort
   new.datum$cohort$recruit      = old.datum$cohort$recruit
   new.datum$cohort$growth       = old.datum$cohort$growth
   new.datum$cohort$f.gpp        = old.datum$cohort$f.gpp
   new.datum$cohort$f.plant.resp = old.datum$cohort$f.plant.resp
   new.datum$cohort$f.npp        = old.datum$cohort$f.npp
   new.datum$cohort$f.cba        = old.datum$cohort$f.cba
   new.datum$cohort$f.bstorage   = old.datum$cohort$f.bstorage
   new.datum$cohort$f.bleaf      = old.datum$cohort$f.bleaf
   new.datum$cohort$f.broot      = old.datum$cohort$f.broot
   new.datum$cohort$f.bseeds     = old.datum$cohort$f.bseeds
   new.datum$cohort$leaf.par     = old.datum$cohort$leaf.par
   new.datum$cohort$leaf.rshort  = old.datum$cohort$leaf.rshort
   new.datum$cohort$leaf.rlong   = old.datum$cohort$leaf.rlong
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #     Send the data back.                                                               #
   #---------------------------------------------------------------------------------------#
   return(new.datum)
   #---------------------------------------------------------------------------------------#
}#end update
#==========================================================================================#
#==========================================================================================#
