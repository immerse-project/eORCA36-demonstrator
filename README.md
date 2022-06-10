# eORCA36-demonstrator

This page describe the way to build the extended 1/36° global configuration (eORCA36) based on  [NEMO OGCM](https://www.nemo-ocean.eu/).

This bench represents the milestone MS35 "global 1/36 configuration upgrade following" for [IMMERSE](http://immerse-ocean.eu/) H2020 project.

Compare to the the previous 1/36° global [demonstrator](https://github.com/immerse-project/ORCA36-demonstrator/), the domain has been extended southward to include the Under Ice Shelf Seas and the NEMO code has been upgraded to the [4.2 release](https://forge.nemo-ocean.eu/nemo/nemo/-/blob/4.2.0/README.rst).

![plot](https://github.com/immerse-project/eORCA36-demonstrator/blob/main/figs/socurloverf_ORCA36-T426_ALL_2016-10-08_00_seismic_1.png)<br>


## Installation

- Download XIOS:

```svn co -r 2311 http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk XIOS ```

- Downlaod NEMO:

```git clone -- branch 4.2.0 git@forge.nemo-ocean.eu:nemo/nemo.git nemo_4.2.0```


## Compiling:

example of module list used on ECMWF/ATOS/AA computer : ```intel/2021.4.0  prgenv/intel openmpi/4.1.1.1 netcdf4-parallel/4.7.4```

create the configuration                      : ``` ./makenemo -m your_archfile -r ORCA2_ICE_PISCES -n ORCA36 -j 20 ```

change ORCA36 cpp keys by                     : ```  key_si3 key_xios key_qco key_isf ```

and recompile                                 : ``` ./makenemo -m your_archfile -r ORCA36 -j 20 ```

## Execution

example of script to launche the model        : [script](SCRIPT/NEMO.sub)

ORCA36 Namelists                              : [namelist](NAMLST/)

XIOS files                                    : [XIOS files](XML/)

Configuration files: ``` ftp://ftp.mercator-ocean.fr/download/users/cbricaud/BENCH-eORCA36-INPUT.tar.gz ```

Forcing files      : ``` ftp://ftp.mercator-ocean.fr/download/users/cbricaud/BENCH-eORCA36-INPUT.tar.gz ```
