#!/usr/bin/perl

use POSIX qw(strtoul);

$cnt=0;

$infile="";
$outfile="";
$offset=0;
$fill=0;

for ($i=0; $i<=$#ARGV; $i++) {
	if ($ARGV[$i] =~ /^-/) {
		if ($ARGV[$i] eq "-offset") {
			$i++;
			$offset = strtoul($ARGV[$i], 0);
		} elsif ($ARGV[$i] eq "-fill") {
			$i++;
			$fill = strtoul($ARGV[$i], 0)
		} else {
			die "Error: unknown option $ARGV[$i]";
		}
	} elsif ($infile eq "") {
		$infile=$ARGV[$i];
	} elsif ($outfile eq "") {
		$outfile=$ARGV[$i];
	} else {
		die "Error: unknown argument $ARGV[$i]";
	}
}


open(FH, "<", $infile) || die "cannot open file";

$out="";
$line="";
$record="";
$address=0;
$length=0;
$bytesperword=4;
$wordaddr=0;
$checksum=0;
$dataidx=0;
$addr_base=0;
$addr_off=0;

print "fill=$fill\n";
if ($fill > 0) {
	for ($x=0; $x<$fill; $x+=$bytesperword) {
		$checksum = $bytesperword + ($wordaddr >> 8) + ($wordaddr & 0xFF);
		$out .= sprintf(":%02x%04x00", ${bytesperword}, ${wordaddr});
		for ($j=0; $j<$bytesperword; $j++) {
			$out .= "00";
		}
			
		$out .= sprintf("%02x\n", ((0x100 - ($checksum & 0xFF)) & 0xFF));
		$wordaddr++;
	}
}

while (<FH>) {
	$line = $_;
	
	unless ($line =~ /^:/) {
		die "Unknown record: $line";
		last;
	}

	$length_s=substr($line, 1, 2);	
	$length=hex($length_s);
	$address_1=hex(substr($line, 3, 2));
	$address_2=hex(substr($line, 5, 2));
	$addr_off=hex(substr($line, 3,4));
	$record=substr($line, 7,2);
	$record_i=hex($record);

	$address = $addr_base + $addr_off - $offset;

    if ($record eq "01") {
    	$out .= ":00000001FF\n";
    	last;
    } elsif ($record eq "02") {
    	# ignore
    } elsif ($record eq "03") {
    	# ignore
    } elsif ($record eq "04") {
    	# ignore
    	$addr_base = hex(substr($line, 9, 4)) << 16;
    } elsif ($record eq "05") {
    	# ignore
    } elsif ($record eq "00") {
		$wordaddr = ($address & 0xFFFF) / $bytesperword;
		
		$dataidx=9;
#		$checksum=(($address >> 8) & 0xFF) + ($address & 0xFF) + $record_i + $length;
		for ($i=0; $i<$length; $i++) {
			$checksum = $bytesperword + ($wordaddr >> 8) + ($wordaddr & 0xFF);
			$out .= sprintf(":%02x%04x%s", ${bytesperword}, ${wordaddr}, ${record});
			for ($j=0; $j<$bytesperword; $j++,$i++) {
				$byte_s=substr($line, $dataidx, 2);
				$byte=hex($byte_s);
				$bytes[$j] = $byte;
				$checksum += $byte;
				
				$dataidx += 2;
			}
			
			for ($j=0; $j<$bytesperword; $j++) {
				$out .= sprintf("%02x", $bytes[$j]);
			}
			$out .= sprintf("%02x\n", ((0x100 - ($checksum & 0xFF)) & 0xFF));
			$wordaddr++;
		}
    } else {
    	die "Record type $record unsupported";
    }
}

#print "out=$out\n";

close(FH);

open(FH, ">", $outfile) || die "cannot open file $outfile";
print FH "$out";
close(FH);

