use Encode;
$MAX_DEFAULT=-10000;
print "Loading gram\n";
ReadIdxedDat("idx.dat");
InitTable("invert.txt");

$PY="da jia hao ma";

@Sent=();
while(1){
    # system("clear");
    $str=join("",@Sent);
    myPrint("$str\n");
    print "pls input Pinyin(q to exit!)\n";
    $str=<stdin>;
    chomp($str);
    if ( $str eq 'q' ){
        last;
    }
    @Sent = ();
    @Sent=@{IME($str)};
}

sub IME
{
    my($PY)=@_;
    @Lattcie=();
    BuildLattice($PY,\@Lattcie);
    CalUnit(\@Lattcie);
    $Ret=Backward(\@Lattcie);
    return $Ret;
}

sub BuildLattice
{
    my($PY,$Ref)=@_;
    @Pys=split(" ",$PY);
    push(@Pys,"END");
    unshift(@Pys,"BEG");
    foreach $PY(@Pys){
        $RefTmp=GetHZByPY($PY);
        my @Culumn=();
        foreach $HZ(@{$RefTmp}){
            my @Item=();
            push(@Item,$PY);
            push(@Item,$HZ);
            push(@Item,0);
            push(@Item,0);
            push(@Item,0);  # Store pre two word
            push(@Culumn,\@Item);

        }
        push(@{$Ref},\@Culumn);
    }
}



sub CalUnit
{
    my($Ref)=@_;
    for($i=1;$i<2;$i++){
        $RefCulumn=${$Ref}[$i];
        $RefCulumn_Prev=${$Ref}[$i - 1];
        foreach $RefItem(@{$RefCulumn}){
            ${$RefItem}[2]=GetBiProb("BEG", $RefItem[1]);
            ${$RefItem}[3]=${$RefCulumn_Prev}[0]; # "BEG" node
            ${$RefItem}[4]=${$RefItem}[1]; # Pre Pre word _ Pre word
        }
    }
    for($i=2;$i<@{$Ref};$i++){
        $RefCulumn=${$Ref}[$i];
        foreach $RefItem(@{$RefCulumn}){
            $RefCulumn_Prev=${$Ref}[$i-1]; # Pre word
            $RefCulumn_Prev_Prev=${$Ref}[$i-2]; 
            $Max=$MAX_DEFAULT;
            $j=0;
            foreach $RefItem_Prev(@{$RefCulumn_Prev}){
                $k = 0;
                foreach $RefItem_Prev_Prev(@{$RefCulumn_Prev_Prev}){
                    $Val=GetCombine($RefItem_Prev_Prev, $RefItem_Prev, $RefItem);  # Pre max + Trans(pre, cur)
                    if ($Val >= $Max){
                        $Max=$Val;
                        $MaxNode_Pre=$j;
                        $MaxNode_Pre_Pre = $k;
                    }
                    $k++;
                }
                $j++;
            }
            ${$RefItem}[2]=$Max;
            ${$RefItem}[3]=${$RefCulumn_Prev_Prev}[$MaxNode_Pre_Pre];
            ${$RefItem}[4]=${$RefCulumn_Prev}[$MaxNode_Pre][1]."_".${$RefItem}[1]; # Pre Pre word _ Pre word
            # myPrint("${$RefItem}[4] $Max");
        }
    }
}

sub Backward
{
    my($Ref)=@_;
    $num=@{$Ref};
    my @Rets = ();
    $lastCulumn = ${$Ref}[@{$Ref}-1];
    $RefItm = ${$lastCulumn}[0];
    while( ${$RefItm}[3] != 0 ){
        unshift(@Rets,${$RefItm}[4]);
        $RefItm=${$RefItm}[3];
    }
    # $Ret=join(" ",@Rets);
    return \@Rets;
}



sub GetCombine
{
    my($Ref_Prev_Prev, $Ref_Prev, $Ref)=@_;
    $Val=${$Ref_Prev_Prev}[2]+GetTriProb(${$Ref_Prev_Prev}[1],${$Ref_Prev}[1], ${$Ref}[1]);
    # myPrint("${$Ref_Prev_Prev}[1],${$Ref_Prev}[1], ${$Ref}[1] ${$Ref_Prev_Prev}[2] $Val");
    return $Val;
}


sub GetTriProb
{
    my($H1, $H2, $H3)=@_;
    if ( defined $HashProb{$H1."_".$H2."_".$H3} ) {
        $Val=$HashProb{$H1."_".$H2."_".$H3};
        return $Val;
    }
    return GetBiProb($H1, $H2) + GetBiProb($H2, $H3);
}

sub GetBiProb
{
    my($H1,$H2)=@_;

    if ( $H1 eq "BEG" ) {
        $Val=$HashProb{$H2};
    }elsif ( $H2 eq "END" ) {
        $Val=0;
    }else{
        if ( defined $HashProb{$H1."_".$H2} ) {
            $Val=$HashProb{$H1."_".$H2};
        }else{
            return -99999;
        }
    }
    return $Val;

}


sub InitTable
{
    my($File)=@_;
    open(In,"$File");
    while(<In>){
        chomp;
        my @HZs=();
        ($PY,@HZs)=split(" ");
        $HashTable{$PY}=\@HZs;

    }
    close(In);
}


sub GetHZByPY
{
    my($PY)=@_;
    $Ref=$HashTable{$PY};
    return $Ref;

}


sub ReadIdxedDat
{
    my($Idxed)=@_;
    open (DAT, "$Idxed");
    binmode (DAT, ":raw");

    $MinHZ=RetHZIdx("°¡");
    $MaxHZ=RetHZIdx("×ù");

    for($i=$MinHZ;$i<=$MaxHZ;$i++){
        read(DAT,$Str,4);
        $Offset=unpack("l",$Str);

        read(DAT,$Str,4);
        $Prob=unpack("f",$Str);

        $HashProb{RetHZByIdx($i)}=$Prob;
        $HashOffset{RetHZByIdx($i)}=$Offset;
    }


    foreach $HZ1(sort keys %HashOffset){
        if ($HashOffset{$HZ1} <= 0){
            next;
        }
        seek(DAT,$HashOffset{$HZ1},0);
        read(DAT,$Str,4);
        $Num=unpack("l",$Str);

        for($i=0;$i<$Num;$i++){
            read(DAT,$Str,4);
            $HZ2=unpack("l",$Str);
            $HZ2 = RetHZByIdx($HZ2); # Get the word by the idx

            read(DAT,$Str,4);
            $Prob=unpack("f",$Str);
            $HashProb{$HZ1."_".$HZ2}=$Prob;

            read(DAT,$Str,4);
            $Offset=unpack("l",$Str);

            if ($Offset <= 0){
                next;
            }

            $pre_OffSet = tell(DAT);

            seek(DAT,$Offset,0);

            read(DAT,$Str,4);
            $total=unpack("l",$Str);

            for ($j = 0; $j < $total; $j++){
                read(DAT,$Str,4);
                $HZ3=unpack("l",$Str);
                $HZ3 = RetHZByIdx($HZ3); # Get the word by the idx
                # myPrint("$Offset| $j / $total       $HZ1 $HZ2 $HZ3 \n");
                # <stdin>;
                read(DAT,$Str,4);
                $Prob=unpack("f",$Str);
                $HashProb{$HZ1."_".$HZ2."_".$HZ3}=$Prob;
            }

            seek(DAT,$pre_OffSet,0); # Jump back 
        }
    }
    close(DAT);
}


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
sub myPrint{
    my($S)=@_;
    print encode("utf8", decode("gbk", "$S\n"));
}


