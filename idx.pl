use Encode;
$THREOLD=0;
$MinHZ=RetHZIdx("°¡");
$MaxHZ=RetHZIdx("×ù");
$TRI_FILE = "tri.txt";
#
# Format: bi_offset,uni_log,bi_offset,uni_log,......,bi_second,tri_offset,bi_log,......,tri_third,tri_log
#
	
open(In,"bi.txt");

open (DAT, "+>idx.dat");
binmode (DAT, ":raw");

sub myPrint{
	my($S)=@_;
    print encode("utf8", decode("gbk", "$S\n"));
}

for($i=$MinHZ;$i<=$MaxHZ;$i++){
	print DAT pack("l",-1); # bi_offset
	print DAT pack("f",0.0); # uni_log
}


while(<In>){
	chomp;
	if( /(\S+)_(\S+)\s+(\d+)/){
		$W1=$1;
		$W2=$2;	
		$Count=$3;
		if ( $W1 ne $PreW1 ){
			if( $PreW1 ne "" and $TotalBiCount >0 ){
				$HashOffset{$Idx1}=tell(DAT);
				$HashUni{$Idx1}=$TotalBiCount;
				$TotalCount+=$TotalBiCount;
				$Total=keys %HashBi;
				print DAT pack("l",$Total);
				foreach $hz(sort keys %HashBi){
					$Val=log($HashBi{$hz}/$TotalBiCount);
					print DAT pack("l",$hz); #hz 
					print DAT pack("f",$Val); # bi_log
                    print DAT pack("l",-1); # tri_offset
				}

			}
			$PreW1=$W1;
			$TotalBiCount=0;
			%HashBi=();
		}
		
		$Idx1=RetHZIdx($W1);
		$Idx2=RetHZIdx($W2);
		
		if ( $Idx1 >= $MinHZ and $Idx2 >= $MinHZ and $Idx1 <= $MaxHZ and $Idx2 <= $MaxHZ){
			if ( $Count > $THREOLD ){
				$HashBi{$Idx2}=$Count;
				$TotalBiCount+=$Count;
			}
		}
	}
}
close(In);

$Pos_Record = tell(DAT);

seek(DAT,0,0);  # Write unigram section info

for($i=$MinHZ;$i<=$MaxHZ;$i++){
	$offset=-1;
	$Val=0.0;
	if ( defined $HashOffset{$i} ){
		$offset=$HashOffset{$i};
		$Val=log($HashUni{$i}/$TotalCount);
	}
	print DAT pack("l",$offset);
	print DAT pack("f",$Val);
}


seek(DAT,$Pos_Record,0);  # Write Trigram section after bigram section

open(In,"$TRI_FILE");
while(<In>){
	chomp;
	if( /(\S+)_(\S+)_(\S+)\s+(\d+)/){
		$W1=$1;
		$W2=$2;	
		$W3=$3;	
		$Count=$4;
		if ( $W1."_".$W2 ne $PreW1 ){
			if( $PreW1 ne "" and $TotalTriCount >0 ){
				$HashOffset{$Idx1."_".$Idx2}=tell(DAT);  # A_B to C
				$Total=keys %HashTri;
				print DAT pack("l",$Total);
				foreach $hz(sort keys %HashTri){
					$Val=log($HashTri{$hz}/$TotalTriCount);
                    print DAT pack("l",$hz);
					print DAT pack("f",$Val);
				}
			}
			$PreW1=$W1."_".$W2;
			$TotalTriCount=0;
			%HashTri=();
		}
		$Idx1=RetHZIdx($W1);
		$Idx2=RetHZIdx($W2);
		$Idx3=RetHZIdx($W3);
		if ( $Idx1 >= $MinHZ and $Idx2 >= $MinHZ and $Idx1 <= $MaxHZ and $Idx2 <= $MaxHZ and $Idx3 >= $MinHZ and $Idx3 <= $MaxHZ){
			if ( $Count > $THREOLD ){
				$HashTri{$Idx3}=$Count;
				$TotalTriCount+=$Count;
			}
		}
	}
}
close(In);


for($i=$MinHZ;$i<=$MaxHZ;$i++){
	$offset=-1;
    $HZ1 = $i;
	if ( defined $HashOffset{$i} ){
		$offset=$HashOffset{$i}; # bi_offset
        if($offset < 0){
            next;
        }
        seek(DAT, $offset, 0);  # Jump to bigram offset
		read(DAT,$Str,4);
		$Num=unpack("l",$Str);
		for($j=0; $j<$Num;$j++){
			read(DAT,$Str,4);
            $HZ2=unpack("l",$Str);
			read(DAT,$Str,4);
			$Prob=unpack("f",$Str);
            if (not defined $HashOffset{$HZ1."_".$HZ2}){
                print DAT pack("l", -1); # Write trigram offset
            }else{
                print DAT pack("l", $HashOffset{$HZ1."_".$HZ2}); # Write trigram offset
            }
		}
	}
}

close(DAT);

sub RetHZIdx
{
	my($HZ)=@_;
	my @HZs=unpack("C*",$HZ);
	$HZIdx=($HZs[0]-0xb0)*94+($HZs[1]-0xa1);
	return $HZIdx;
}

sub RetHZByIdx
{
    my($ID)=@_;
    my $HZ=pack("C*",int($ID/94)+0xb0,0xa1+$ID%94);
    return $HZ;
}

