#****************************************************************************
#* simscripts set_env.sh
#****************************************************************************

# set -x

rootdir=`pwd`

while test "x$rootdir" != "x"; do
  synth=`find $rootdir -maxdepth 4 -name synth.pl` 
  if test "x$synth" != "x"; then
    break;
  fi
  rootdir=`dirname $rootdir`
done


if test "x$synth" = "x"; then
  echo "Error: Failed to find root directory"
else

 # Found multiple synth.pl scripts. Take the shortest one
  n_synth=`echo $synth | wc -w`
  if test $n_synth -gt 1; then
    echo "Note: found multiple synth.pl scripts: $synth"
    pl_min=1000000000
    for rt in $synth; do
    	pl=`echo $rt | wc -c`
    	if test $pl -lt $pl_min; then
    		pl_min=$pl
    		real_rt=$rt
    	fi
    done
    synth=$real_rt
  fi
   
  if test "x$synth" = "x"; then
    echo "Error: Failed to disambiguate synth.pl"
  else
    SYNTHSCRIPTS_DIR=`dirname $synth`
    export SYNTHSCRIPTS_DIR=`dirname $SYNTHSCRIPTS_DIR`
    if test `uname -o` = "Cygwin"; then
   	    export SYNTHSCRIPTS_DIR_A=`cygpath -w $SYNTHSCRIPTS_DIR | sed -e 's%\\\\%/%g'`
	else
   	    export SYNTHSCRIPTS_DIR_A=$SYNTHSCRIPTS_DIR
	fi
    echo "SYNTHSCRIPTS_DIR=$SYNTHSCRIPTS_DIR"
    # TODO: check whether the PATH already contains the in directory
    PATH=${SYNTHSCRIPTS_DIR}/bin:$PATH


    # Environment-specific variables
	export SYNTHSCRIPTS_PROJECT_ENV=true
    if test -f $SYNTHSCRIPTS_DIR/../env/env.sh; then
    	echo "Note: sourcing environment-specific env.sh"
        . $SYNTHSCRIPTS_DIR/../env/env.sh
    fi
    unset SYNTHSCRIPTS_PROJECT_ENV
  fi
fi




