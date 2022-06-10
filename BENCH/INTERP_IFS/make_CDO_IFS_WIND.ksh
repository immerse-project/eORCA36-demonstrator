#!/bin/bash
set -xv

CTLDIR=`pwd`


module load cdo
module load nco
##################################################################################


#########################################################################
#
#########################################################################
v=$1
d1=$2
d2=$3
CONF=$4
#########################################################################
MAINDIR=$SCRATCH/WORK_IFS
RUNDIR=${MAINDIR}/WORK_CDO_${CONF}_${v}_${d1}_${d2}

INDIR=$SCRATCH/IFS
OUTDIR=$SCRATCH/IFS

ARCDIR=ec:/MERCATOR/DATA/ECMWF_GAUSS1280/1h
#-----------------------------------------------------------------------
#INPUT GRID
#-----------------------------------------------------------------------
MASK=${SCRATCH}/ORCA36-IN/MER-20160308-GAUSS1280-lsm_post_20160308.nc
lbil=0
lbic=1
zmin=-50.
zmax=50.

#case $v in
#'sowinu10' )g=BULKU10M ;
#'sowinv10' )g=BULKV10M ;
#esac

xin=lon
yin=lat
tin=time_counter
gin=$fin
vin=$v

#-----------------------------------------------------------------------
#OUTPUT GRID: eORCA36
#-----------------------------------------------------------------------
gout=${SCRATCH}/ORCA36-IN/eORCA_R36_coordinates_v3.1.nc
xout=glamt
yout=gphit
mout=${SCRATCH}/ORCA36-IN/eORCA_R36_meshmask_v3.1.nc
#########################################################################
#
#########################################################################
mkdir -p $RUNDIR
d=$d1
while [ $d -le $d2 ] ; do

   yy=`echo $d | cut -c1-4`
   mm=`echo $d | cut -c5-6`
   dd=`echo $d | cut -c7-8`
   cld=y${yy}m${mm}d${dd}

   #---------------------------------------------------
   #check U file
   #---------------------------------------------------
   fout=${OUTDIR}/ECMWF_${CONF}_BULKU10M_${cld}.nc

   llnok=0
   if [ ! -f $fout ] ; then
      llnok=1
   else
      ncdump -h ${fout}
      if [ $? -ne 0 ] ; then
         llnok=1
      else
         nt=`ncdump -h $fout | grep UNLIMITED | awk -F "(" '{print $2}' | awk -F "c" '{print $1}'`
         if [ $nt -ne 24 ] ; then
            llnok=1
         fi
      fi
   fi
   lu_nok=$llnok

   #---------------------------------------------------
   #check V file
   #---------------------------------------------------
   fout=${OUTDIR}/ECMWF_${CONF}_BULKV10M_${cld}.nc
   
   llnok=0
   if [ ! -f $fout ] ; then
      llnok=1
   else
      ncdump -h ${fout}
      if [ $? -ne 0 ] ; then
         llnok=1
      else
         nt=`ncdump -h $fout | grep UNLIMITED | awk -F "(" '{print $2}' | awk -F "c" '{print $1}'`
         if [ $nt -ne 24 ] ; then
            llnok=1
         fi
      fi
   fi
   lv_nok=$llnok

   #---------------------------------------------------
   #
   #---------------------------------------------------
   llnok=0
   if [ $lu_nok -eq 1 ] || [ $lv_nok -eq 1 ]  ; then
      llnok=1	    
   fi

   if [ $llnok -eq 1 ] ; then

      for v in sowinu10 sowinv10 ; do 

         case $v in
            'sowinu10' )g=BULKU10M ;;
            'sowinv10' )g=BULKV10M ;
         esac

         fin=${INDIR}/ECMWF_${g}_${cld}.nc
         #fout=${OUTDIR}/ECMWF_${CONF}_${g}_${cld}.nc
         fout=${RUNDIR}/ECMWF_${CONF}_${g}_${cld}_unrot.nc
	 clfi=ECMWF_${g}_${cld}.nc
         clfo=ECMWF_${CONF}_${g}_${cld}.nc

       	 #-------------------------------------
         if [ ! -f $fin ] ; then
            ecp ${ARCDIR}/${clfi} ${INDIR}
         fi
         #-------------------------------------
         echo INTERPOLATE $clfi $clfo
         cd $RUNDIR 
         gin=$fin

         #-------------------------------------
         #format input file for CDO
         ncatted -O -a units,lon,c,c,'degrees_east' -a units,lat,c,c,'degrees_north'  -a units,'time_counter',c,c,'seconds since 1900-01-01 00:00:00' $fin $RUNDIR/fin.nc

       	 #format output file for CDO
         if [ ! -f $MAINDIR/gout.nc ] ; then
            ncap2 -O -s 'dummy[y,x]=1b' $gout $MAINDIR/gout.nc
            ncatted -O -a coordinates,dummy,c,c,'gphit glamt' -a units,glamt,c,c,'degrees_east' -a units,gphit,c,c,'degrees_north' $MAINDIR/gout.nc $MAINDIR/gout.nc
            ncwa -O -a z     $MAINDIR/gout.nc $MAINDIR/gout.nc
            ncwa -O -a time  $MAINDIR/gout.nc $MAINDIR/gout.nc
         fi
         #-------------------------------------
         #weights
         if [ $lbic -eq 1 ] ; then
            WGT=$MAINDIR/ECMWFto${CONF}_cdo_bicwgt.nc
            if [ ! -f $WGT ] ; then
               cdo -P 8 genbic,$MAINDIR/gout.nc $fin ${WGT}
            fi
         fi
         if [ $lbil -eq 1 ] ; then
            WGT=$MAINDIR/ECMWFto${CONF}_cdo_bilwgt.nc
            if [ ! -f $WGT ] ; then
               cdo -P 8 genbil,$MAINDIR/gout.nc $fin ${WGT}
            fi
         fi
         #-------------------------------------
         cdo -O -P 8 div $RUNDIR/fin.nc ${MASK} ${RUNDIR}/masked.nc
         if [ $? -ne 0 ] ; then
            touch ${SCRATCH}/FLAG_ORCA36-T424/CDOMASK_${clfi}
         else
            rm -f $RUNDIR/fin.nc
         fi

         cdo -O -P 8 setmisstonn  ${RUNDIR}/masked.nc  ${RUNDIR}/extrap.nc
         if [ $? -ne 0 ] ; then
            touch ${SCRATCH}/FLAG_ORCA36-T424/CDOMISS_${clfi}
         else
            rm -f ${RUNDIR}/masked.nc
         fi

         #-------------------------------------
         #cdo -f nc4  -P 8 remap,$MAINDIR/gout.nc,${WGT} ${RUNDIR}/extrap.nc ${RUNDIR}/ECMWF_${CONF}_${g}_${cld}_unrot.nc
         cdo -f nc4  -P 8 remap,$MAINDIR/gout.nc,${WGT} ${RUNDIR}/extrap.nc ${fout}
         if [ $? -ne 0 ] ; then
            touch ${SCRATCH}/FLAG_ORCA36-T424/CDOREMAP_${clfi}
         else
            rm -f ${RUNDIR}/extrap.nc
         fi
         #-------------------------------------
         ncdump -h ${fout}
         if [ $? -ne 0 ] ; then
            touch ${SCRATCH}/FLAG_ORCA36-T424/CDONCDUMP_${clfo}
         else
            echo ${fout} OK
         fi
         #-------------------------------------
      done #v

      #-------------------------------------
      fu=${RUNDIR}/ECMWF_${CONF}_BULKU10M_${cld}_unrot.nc
      fv=${RUNDIR}/ECMWF_${CONF}_BULKV10M_${cld}_unrot.nc
      vu=sowinu10
      vv=sowinv10

      mv ${fu} ${RUNDIR}/uraw_GAUSS1280-eORCA36_.nc 
      mv ${fv} ${RUNDIR}/vraw_GAUSS1280-eORCA36_.nc 
      ncrename -O -v sowinu10,uraw ${RUNDIR}/uraw_GAUSS1280-eORCA36_.nc ${RUNDIR}/uraw_GAUSS1280-eORCA36_.nc
      ncrename -O -v sowinv10,vraw ${RUNDIR}/vraw_GAUSS1280-eORCA36_.nc ${RUNDIR}/vraw_GAUSS1280-eORCA36_.nc
      #-------------------------------------
      BIN=/home/ar5/UTILS/SOSIE/bin/corr_vect.x
      NAMLST=${CTLDIR}/PAR_IFS/namelist_corrvect

      #if [ ! -f ${OUTDIR}/ECMWF_${CONF}_BULKU10M_${cld}.nc ]  && [ ! -f ${OUTDIR}/ECMWF_${CONF}_BULKU10M_${cld}.nc ] ; then

         sed -e "s%CFIN%${fu}%" -e "s%CVIN%${vu}%" -e "s%CGOUT%${mout}%" ${NAMLST} > ${RUNDIR}/namelist_corrvect_x
         sed -e "s%CFIN%${fv}%" -e "s%CVIN%${vv}%" -e "s%CGOUT%${mout}%" ${NAMLST} > ${RUNDIR}/namelist_corrvect_y

         ${BIN} -f namelist_corrvect -m $mout -G T

         mv ${RUNDIR}/sowinu10_GAUSS1280-eORCA36_grid_T.nc ${OUTDIR}/ECMWF_${CONF}_BULKU10M_${cld}.nc
         mv ${RUNDIR}/sowinv10_GAUSS1280-eORCA36_grid_T.nc ${OUTDIR}/ECMWF_${CONF}_BULKV10M_${cld}.nc

      #fi   
      #-------------------------------------
   fi  #llnok
 
   d=`date --date="${d} + 1days " +%Y%m%d`

done
cd $MAINDIR
rm -rf $RUNDIR

