#!/usr/bin/perl -w
#Define the inst_opt dir
#my $opt_path = "~/git/config/inst_opt";
my $opt_path = "/usr/share/qa/virtautolib/data/inst_opt";
my $def_tcf = "/tmp/qa_virtualization-virt_install.tcf";
my $target_tcf= "/usr/share/qa/tcf/qa_virtualization-virt_install_withopt.tcf";
my @opts;

#Verify the dir and file
exit 1 if ! -d $opt_path;
exit 1 if ! -e $def_tcf;

#Get the options from dir
my @opt_files=glob("$opt_path/*");

#Build the hash

my $sed_cmd=q"sed '/^[ \t]*$/d;/^[ \t]*#/d'";
my $opt_vf;
my @opt_key;

my $kernel_release = `uname -r ` =~ /xen/i;

for my $file ( @opt_files ) {
	#For xen , we remove some options which is not supported
	if($kernel_release){
		next if $file =~ /machine/;  #machine option not supported
	}
	my $value=`cat $file|$sed_cmd`;
	chomp($value);
	$file=~s/.*\///;
	$file=~s/^/--/;
	my @option_with_arg = map { s/^/$file /;$_ } split(/\n/,$value);
	push @opt_key,[ @option_with_arg ] if($value);

}

sub permute {

    my $last = pop @_;

    unless(@_) {
           return map([$_], @$last);
    }
    return map {
       my $left = $_;
       map([@$left, $_], @$last)
    } permute(@_);
}

print join(" ", @$_), "\n" for permute(@opt_key);

print " ***|Above options combination will add to the new tcf:\n ***|$target_tcf \n ***\n" ;
push @opts,"@$_" for permute(@opt_key);

#generate the test cases


open(my $o_tcf,$def_tcf) or die "Open $def_tcf Failed";
open(my $n_tcf,">",$target_tcf) or die "Open $def_tcf Failed";


while(<$o_tcf>){


	if( $_ =~ /^bg / ) {
		chomp;
		my @field = split(/\s+/,$_);
		map { my $opt_case="@field $_\n"; my $fix_name=$_;$fix_name=~s/\s+//g;$opt_case=~s/\s+\//$fix_name \//;print $n_tcf $opt_case ; } @opts;
	}else{
		print $n_tcf $_;
	}
}
close ($o_tcf);
close ($n_tcf);

system("cp","$target_tcf","$def_tcf");

exit 0;


