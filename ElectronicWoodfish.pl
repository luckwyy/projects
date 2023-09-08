#!/usr/bin/perl

my $who = 'y';
my $dir = '~';
my $path = "$dir/woodfish.txt";
`mkdir -p $dir` unless -d $dir;
`touch $path` unless -e $path;
my @log = reverse split("\n", `cat $path`);
my $idx = $log[0] =~ m/^(\d+),/ ? $1 : 0;
my $time = `date +\%Y-\%m-\%d\\ \%H:\%M:\%S.\%N`;
chomp $time;
`echo '$idx, $time reset --$who' >> $path`;
while (1) {
    my $input = <STDIN>;
    chomp($input);
    $idx += 1;
    my $time = `date +\%Y-\%m-\%d\\ \%H:\%M:\%S.\%N`;
    chomp $time;
    my $info = "$idx, $time --$who";
    `echo '$info' >> $path`;
    system('clear');
    print $idx;
}
