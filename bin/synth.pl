#!/usr/bin/perl
#*****************************************************************************
#*                             synth.pl
#*
#* Synthesize a design
#*****************************************************************************

use Cwd;
use Cwd 'abs_path';
use POSIX ":sys_wait_h";
use File::Basename;

# Parameters
# $SCRIPT=abs_path($0);
# $SCRIPT_DIR=dirname($SCRIPT);

$argfile_utils_pm="$ENV{SIMSCRIPTS_DIR}/lib/argfile_utils.pm";

use lib '$argfile_utils_pm';

$SYNTH_DIR=getcwd();
$ENV{SYNTH_DIR}=$SYNTH_DIR;

$max_par=2;
$clean=0;
$build=1;
$cmd="";
$quiet="";
$debug="false";
$builddir="";
$device="cyclonev";
$mk_sim="false";

# Global PID list
@pid_list;

if ($ENV{RUNDIR} eq "") {
  $run_root=getcwd();
  $run_root .= "/rundir";
} else {
  $run_root=$ENV{RUNDIR};
}

# Figure out maxpar first
if (-f "/proc/cpuinfo") {
	open (my $fh, "cat /proc/cpuinfo | grep processor | wc -l|");
	while (<$fh>) {
		chomp;
		$max_par=$_;
	}
} else {
	print "no cpuinfo\n";
}

for ($i=0; $i <= $#ARGV; $i++) {
  $arg=$ARGV[$i];
  if ($arg =~ /^-/) {
    if ($arg eq "-j") {
      $i++;
      $max_par=$ARGV[$i];
    } elsif ($arg eq "-rundir") {
       $i++;
       $run_root=$ARGV[$i];
    } elsif ($arg eq "-device") {
    	$i++;
    	$device=$ARGV[$i];
    } elsif ($arg eq "-mksim") {
    	$mksim = true;
    } else {
      print "[ERROR] Unknown option $arg\n";
      printhelp();
      exit 1;
    }
  }
}


$project=basename(dirname($SYNTH_DIR));
$run_root="${run_root}/${project}";
print "run_root=$run_root\n";
$ENV{RUN_ROOT}=$run_root;

if (! -d $run_root) {
	print "run_root=$run_root\n";
	system("mkdir -p $run_root");
}

if ($builddir eq "") {
  $builddir=$ENV{RUN_ROOT};
}

$builddir = $builddir . "/synth";
$ENV{BUILD_DIR}=$builddir;

if ($quiet eq "") {
  $quiet=0;
}

$SIG{'INT'} = 'cleanup';

@mkfiles = glob("$SYNTH_DIR/scripts/*.mk");

system("mkdir -p ${builddir}") && die;

system("make",
		"-C", "${builddir}",
       	"-f" ,
       	"$SYNTH_DIR/scripts/Makefile",
                    	"SIM=${sim}",
                    	"SEED=${seed}",
                    	"TESTNAME=${test}", 
                    	"INTERACTIVE=${interactive}",
                    	"DEBUG=${debug}",
                    	"img"
                    	);
if ($mksim eq "true") {
	print "Note: Creating simulation image\n";
	system("make",
		"-C", "${builddir}",
       	"-f" ,
       	"$SYNTH_DIR/scripts/Makefile",
                    	"SIM=${sim}",
                    	"SEED=${seed}",
                    	"TESTNAME=${test}", 
                    	"INTERACTIVE=${interactive}",
                    	"DEBUG=${debug}",
                    	"sim"
                    	);	
}

exit 0;

sub printhelp {
  print "runtest [options]\n";
  print "    -test <testname>    -- Name of the test to run\n";
  print "    -count <count>      -- Number of simulations to run\n";
  print "    -max_par <n>        -- Number of runs to issue in parallel\n";
  print "    -rundir  <path>     -- Specifies the root of the run directory\n";
  print "    -builddir <path>   -- Specifies the root of the build directory\n";
  print "    -clean              -- Remove contents of the run directory\n";
  print "    -nobuild            -- Do not automatically build the bench\n";
  print "    -i                  -- Run simulation in GUI mode\n";
  print "    -quiet              -- Suppress console output from simulation\n";
  print "\n";
  print "Example:\n";
  print "    runtest -test ethmac_simple_rxtx_test\n";
}

sub cleanup {
    print "CLEANUP\n";
    for ($i=0; $i<=$#pid_list; $i++) {
        printf("KILL %d\n", $pid_list[$i]);
        kill -9, $pid_list[$i];
    }
    exit(1);
}



