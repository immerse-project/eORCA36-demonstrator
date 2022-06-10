#!/bin/bash
set -xv

module load cdo
module load nco

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
lbic=0
lbil=1

case $v in
'sowinu10' )g=BULKU10M ;
    lbic=1 ;
    lbil=0 ;
    zmin=-50. ;
    zmax=50. ;;
'sowinv10' )g=BULKV10M ;
    lbic=1 ;
    lbil=0 ;
    zmin=-50. ;
    zmax=50. ;;
'sotemair' )g=BULKTAIR ;
    zmin=200 ;
    zmax=330 ;;
'sohumspe' )g=BULKHUMI ;
    zmin=0. ;
    zmax=0.1 ;;
'somslpre' )g=PRES ;
    zmin=90000. ;
    zmax=102000. ;;
'sosudosw' )g=FLUXSSRD ;
    zmin=-1. ;
    zmax=2000. ;;
'sosudolw' )g=FLUXSTRD ;
    zmin=0. ;
    zmax=500. ;;
'sowaprec' )g=FLUXPRE ;
    zmin=0. ;
    zmax=0.05 ;;
'sosnowfa' )g=SNOWFALL ;
    zmin=0. ;
    zmax=0.05 ;;
esac

xin=lon
yin=lat
tin=time_counter
gin=$fin
vin=$v

MASK=${SCRATCH}/ORCA36-IN/MER-20160308-GAUSS1280-lsm_post_20160308.nc
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

   fin=${INDIR}/ECMWF_${g}_${cld}.nc
   fout=${OUTDIR}/ECMWF_${CONF}_${g}_${cld}.nc
   clfi=ECMWF_${g}_${cld}.nc
   clfo=ECMWF_${CONF}_${g}_${cld}.nc
   #-------------------------------------
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

   #-------------------------------------
   if [ $llnok -eq 1 ] ; then
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
      ncap2 -4 -L 0 -O -s 'dummy[y,x]=1b' $gout $MAINDIR/gout.nc
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
      #BIN=/home/ar5/UTILS/SOSIE/bin/corr_vect.x
      #
      #${BIN} -I -m ${mout} -G T
      #
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
      cdo -f nc4  -P 8 remap,$MAINDIR/gout.nc,${WGT} ${RUNDIR}/extrap.nc ${fout}
      if [ $? -ne 0 ] ; then
         touch ${SCRATCH}/FLAG_ORCA36-T424/CDOREMAP_${clfi}
      else
         rm -f ${RUNDIR}/extrap.nc
      fi
      #-------------------------------------
      case $v in
         'sowaprec' )ncap2 -4 -O -F -s 'where(sowaprec<=0.)sowaprec=0.' ${fout} ${fout} ;;
         'sosnowfa' )ncap2 -4 -O -F -s 'where(sosnowfa<=0.)sosnowfa=0.' ${fout} ${fout} ;;
         'sohumspe' )ncap2 -4 -O -F -s 'where(sohumspe<=0.)sohumspe=0.' ${fout} ${fout} ;;
         'sosudolw' )ncap2 -1 -O -F -s 'where(sosudolw<=0.)sosudolw=0.' ${fout} ${fout} ;;
      esac
      #-------------------------------------
      ncdump -h ${fout}
      if [ $? -ne 0 ] ; then
         touch ${SCRATCH}/FLAG_ORCA36-T424/CDONCDUMP_${clfo}
      else
         echo ${fout} OK
      fi
      #-------------------------------------
   else
      echo ALREADY THERE $clfo
   fi

   d=`date --date="${d} + 1days " +%Y%m%d`

done
cd $MAINDIR
rm -rf $RUNDIR

