#!/bin/bash
#SBATCH -J remapnn
#SBATCH --qos=nf
#SBATCH --time=01:00:00
#SBATCH --mem-per-cpu=50G
#SBATCH -o remapnn.err
#SBATCH -e remapnn.out
set -xv
export QSUB_WORKDIR=`/bin/pwd`
cd $QSUB_WORKDIR

module load cdo
module load nco

#########################################################################
GRIDIN=$SCRATCH/ORCA36-IN/potential_temperature_WOA13_A5B2_Reg1L75_clim.nc

CONF=eORCA_R36
GRIDOUT=$SCRATCH/ORCA36-IN/eORCA_R36_coordinates_v3.1.nc

EXP=WOA_to_${CONF}
RUNDIR=${SCRATCH}/${EXP}

COORD1=${RUNDIR}/gridin.nc
COORD2=${RUNDIR}/gridout.nc

FO=$SCRATCH/ORCA36-IN/${CONF}_potential_temperature_WOA13_A5B2_Reg1L75_clim.nc

mkdir -p $RUNDIR ; cd $RUNDIR

#--------------------------------------------------------------------------


VIN=votemper
ncatted -O -a coordinates,${VIN},c,c,'time_counter nav_lev lat lon ' -a units,time_counter,c,c,'s' ${GRIDIN} ${COORD1}
ncks -O -4 ${COORD1} ${COORD1}
#--------------------------------------------------------------------------
ncks  -O -v glamt,gphit     ${GRIDOUT} ${COORD2}
ncap2 -O -s 'dummy[y,x]=1b' ${COORD2}  ${COORD2}
ncatted -O -a coordinates,dummy,c,c,'glamt gphit' -a units,glamt,c,c,'degrees_east' -a units,gphit,c,c,'degrees_north' ${COORD2} ${COORD2}
ncwa -O -a time ${COORD2} ${COORD2}
ncwa -O -a z    ${COORD2} ${COORD2}

#--------------------------------------------------------------------------
cdo -P 32 remapnn,${COORD2} ${COORD1} ${RUNDIR}/fileout.nc

cp ${RUNDIR}/fileout.nc $FO

#--------------------------------------------------------------------------

