use Encode;
system("time /t");
$g_MaxBiNum=1000000;
TriCount("train");
MergeTri(\@TmpFiles,"tri.txt");
foreach (@TmpFiles){
		unlink($_);
}
system("time /t");

sub TriCount{
	my($File)=@_;
	$TmpFile="tmp";
    open(In,"$File");
	$ZiNum=0;
	$ID=0;
	@TmpFiles=();
	while(<In>){
		chomp;	
		s/\s+//g;
		$Line=$_;
		while( $Line ne "" ){
			$Len=1;
			if ( ord($Line) & 0x80 ){
				$Len=2;
			}
			$H3=substr($Line,0,$Len);
			if ( $H1 ne  "" and $H2 ne ""){
				$Tri=$H1."_".$H2."_".$H3;
                $hashTri{$Tri}++;
			}
			$H1=$H2;
			$H2=$H3;
			$ZiNum++;
		
			if ( $ZiNum > $g_MaxBiNum ){
				$FileTmp=$TmpFile."_".$ID;
				push(@TmpFiles,$FileTmp);
				open(Out,">$FileTmp");
				print "$FileTmp done!\n";
				foreach (sort keys %hashTri){
					print Out "$_\t$hashTri{$_}\n";
				}
				%hashTri=();
				$ZiNum=0;
				close(Out);
				$ID++;
			}
			
			$Line=substr($Line,$Len,length($Line)-$Len);
		}
	}
	close(In);
}
sub MergeTri
{
	my($RefBiFileList,$Merged)=@_;
	
	open(Out,">$Merged");

	foreach (@{$RefBiFileList}){
		my $H="F".$_;
		open($H,"$_");
		if ( <$H>=~/(\S+)\t(\d+)/ ){
			${$hash{$1}}{$H}=$2;		
		}
	}
	@BiStr=sort keys %hash;
	while( @BiStr > 0 ){
		$Num=0;
		@Fhandle=();
		foreach $Handle(keys %{$hash{$BiStr[0]}} ){
			$Num+=${$hash{$BiStr[0]}}{$Handle};
			push(@Fhandle,$Handle);
		}
		print Out "$BiStr[0]\t$Num\n";
		
		delete $hash{$BiStr[0]};
		foreach $Handle(@Fhandle){
			
			if ( <$Handle>=~/(\S+)\t(\d+)/ ){
				${$hash{$1}}{$Handle}=$2;		
			}
		}
		@BiStr=sort keys %hash;
	}
	
	
	foreach (@{$RefBiFileList}){
		my $H="F".$_;
		close($H);
	}
	
}
