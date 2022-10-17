#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use utf8;
use Encode qw(decode_utf8);
use Time::Piece;
use Time::Seconds;

my $root_path = './kadata';
# morbo keepaccounts.pl -l http://127.0.0.1:3001
get '/' => sub ($c) {
  $c->render(template => 'index');
};

use POSIX qw(strftime);
# return year, month and day str
sub get_year_month_day () {
  # my $date = `date`;
  # say $date;
  # my ($month, $day, $year) = ($1, $2, $3) if $date =~ m/.* (.\w*)  (\d*).*(\d{4})/;
  # return $year, $month, $day;
  my $date = strftime "%m-%d-%Y", localtime;
  my ($month, $day, $year) = ($1, $2, $3) if $date =~ m/(.*)-(.*)-(.*)/;
  return $year, $month, $day;
};

# return date time, format: [2022-10-10 10:08:50]
sub get_date_time () {
  my $dt = strftime "[%Y-%m-%d %H:%M:%S]", localtime;
  return $dt;
};

# return user data path str
sub get_user_data_path {
  my $user = shift;
  my ($year, $month, $day) = get_year_month_day();
  my $userdata_path = "./kadata/$user/$year/$month";
  `mkdir -p $userdata_path` unless -d $userdata_path;
  return $userdata_path;
};

# return user ic data path str
sub get_user_ic_data_path {
  my $user = shift;
  return get_user_data_path($user) . '/ic.txt';
};

# return user oc data path str
sub get_user_today_oc_data_path {
  my $user = shift;
  my ($year, $month, $day) = get_year_month_day();
  return get_user_data_path($user) . "/oc$day.txt";
};

# return ic str with ic_str =~ s/\n/<br>/g;
sub get_ic_txt_content {
  my $user = shift;
  my $path = get_user_ic_data_path($user);
  return '' unless -e $path;
  my $content = `cat $path`;
  $content =~ s/\n/<br>/g;
  return decode_utf8($content);
  # return $content;
};

sub get_ic_txt_content_origin {
  my $user = shift;
  my $path = get_user_ic_data_path($user);
  return '' unless -e $path;
  my $content = `cat $path`;
  # open(my $in, "<", $path);
  # my @lines = <$in>;
  # my $content = join("\n", @lines);
  return decode_utf8($content);
  # return $content;
};

# return all ic number, e.g. 10 + 10 = 20
sub get_ic_all {
  my $user = shift;
  my $path = get_user_ic_data_path($user);
  return '0' unless -e $path;
  my $content = `cat $path`;
  my $total = 0;
  while($content =~ m/:(.*?) /gm){
    $total += $1;
  }
  return $total;
};

# get ic by year month
sub get_ic_txt_content_by_year_month {
  my $user = shift;
  my $year = shift;
  my $month = shift;

  my $path = "$root_path/$user/$year/$month/ic.txt";
  return '' unless -e $path;
  my $content = `cat $path`;
  $content =~ s/\n/<br>/g;
  return decode_utf8($content);
};

# get ic all by year month
sub get_ic_all_by_year_month {
  my $user = shift;
  my $year = shift;
  my $month = shift;

  my $path = "$root_path/$user/$year/$month/ic.txt";
  return '0' unless -e $path;
  my $content = `cat $path`;
  my $total = 0;
  while($content =~ m/:(.*?) /gm){
    $total += $1;
  }
  return $total;
};

# return user today oc txt content
sub get_today_oc_txt_content {
  my $user = shift;
  my $path = get_user_today_oc_data_path($user);
  return '' unless -e $path;
  my $content = `cat $path`;
  $content =~ s/\n/<br>/g;
  return decode_utf8($content);
};

# return oc content by year month day
sub get_day_oc_txt_content_by_year_month_day {
  my $user = shift;
  my $year = shift;
  my $month = shift;
  my $day = shift;

  my $path = "$root_path/$user/$year/$month/oc$day.txt";
  return '' unless -e $path;
  my $content = `cat $path`;
  $content =~ s/\n/<br>/g;
  return decode_utf8($content);
};

# return month oc content
sub get_month_oc_content {
  my $user = shift;
  my ($year, $month, $day) = get_year_month_day();
  my $all_content = '';
  for($day; $day > 0; $day--){
    $day = "0$day" if $day*$day < 100;
    my $tmp_day_path = get_user_data_path($user) . "/oc$day.txt";
    # $tmp_day_path = get_user_data_path($user) . "/oc0$day.txt" if $day*$day < 100;
    if (-e $tmp_day_path) {
      my $content_ = `cat $tmp_day_path`;
      my $total_ = 0;
      while($content_ =~ m/:(.*?) \[.*\]\n/g){
        $total_ += $1;
      }
      $content_ =~ s/\n/<br>/g;
      $all_content .= "<br>day-$day ($total_\$):<br>" . $content_;
    } else {
      $all_content .= "<br>day-$day : null record. <br>";
    }
  }
  return decode_utf8($all_content);
};

# return user today oc all
sub get_today_oc_all {
  my $user = shift;
  my $path = get_user_today_oc_data_path($user);
  return '0' unless -e $path;
  my $content = `cat $path`;
  my $total = 0;
  while($content =~ m/:(.*?) \[.*\]\n/g){
    $total += $1;
  }
  return $total;
};

# get by year month day
sub get_day_oc_all_by_year_month_day {
  my $user = shift;
  my $year = shift;
  my $month = shift;
  my $day = shift;

  my $path = "$root_path/$user/$year/$month/oc$day.txt";
  return '0' unless -e $path;
  my $content = `cat $path`;
  my $total = 0;
  while($content =~ m/:(.*?) \[.*\]\n/g){
    $total += $1;
  }
  return $total;
};

# return user month oc all
sub get_month_oc_all {
  my $user = shift;
  my ($year, $month, $day) = get_year_month_day();
  my $total = 0;
  for($day; $day > 0; $day--){
    $day = "0$day" if $day*$day < 100;
    my $tmp_day_path = get_user_data_path($user) . "/oc$day.txt";
    # $tmp_day_path = get_user_data_path($user) . "/oc0$day.txt" if $day*$day < 100;
    if (-e $tmp_day_path) {
      my $content_ = `cat $tmp_day_path`;
      my $total_ = 0;
      while($content_ =~ m/:(.*?) \[.*\]\n/g){
        $total_ += $1;
      }
      $total += $total_;
    } else {
      $total += 0;
    }
  }
  return $total;
};

# by y m d
sub get_month_oc_all_by_year_month {
  my $user = shift;
  my $year = shift;
  my $month = shift;
  my $day = 31; # from 31 to 1 if
  my $total = 0;
  for($day; $day > 0; $day--){
    $day = "0$day" if $day*$day < 100;
    my $tmp_day_path = "$root_path/$user/$year/$month/oc$day.txt";
    # my $tmp_day_path = "$root_path/$user/$year/$month/oc0$day.txt" if $day*$day < 100;
    if (-e $tmp_day_path) {
      my $content_ = `cat $tmp_day_path`;
      my $total_ = 0;
      while($content_ =~ m/:(.*?) \[.*\]\n/g){
        $total_ += $1;
      }
      $total += $total_;
    } else {
      $total += 0;
    }
  }
  return $total;
};

# coding
# design
# dev
# by ywang 862024320@qq.com
sub get_months_ic_all_by_date_start_end {
  my $user = shift;
  my $datestart = shift;
  my $dateend = shift;

  my $FORMAT = '%Y-%m-%d';
  my $start = $datestart;
  my $end   = $dateend;
  my $start_t = Time::Piece->strptime( $start, $FORMAT );
  my $end_t   = Time::Piece->strptime( $end,   $FORMAT );
  
  my $flag = 0;
  my $total_ic = 0;
  while ( $start_t <= $end_t ) {
    # say $start_t ->strftime($FORMAT), "\n";
    my $tmp_date = $end_t ->strftime($FORMAT);
    my ($y, $m, $d) = ($1, $2, $3) if $tmp_date =~ m/(.*)-(.*)-(.*)/;
    if ($d == 1 or $start_t eq $end_t) {
      $flag = 1;
    }
    if ($flag) {
      if (-d "$root_path/$user/$y/$m") {
        if (-e "$root_path/$user/$y/$m/ic.txt") {
          my $path = "$root_path/$user/$y/$m/ic.txt";
          my $content = `cat $path`;
          my $total = 0;
          while($content =~ m/:(.*?) /gm){
            $total += $1;
          }
          $total_ic += $total;
        }
      }
      $flag = 0;
    }
    $end_t -= ONE_DAY;
  }
  return $total_ic;
};

# get between datestart and dateend oc all
sub get_days_oc_all_by_date_start_end {
  my $user = shift;
  my $datestart = shift;
  my $dateend = shift;

  my $FORMAT = '%Y-%m-%d';
  my $start = $datestart;
  my $end   = $dateend;
  my $start_t = Time::Piece->strptime( $start, $FORMAT );
  my $end_t   = Time::Piece->strptime( $end,   $FORMAT );
  
  my $total_oc = 0;
  while ( $start_t <= $end_t ) {
    # say $start_t ->strftime($FORMAT), "\n";
    my $tmp_date = $end_t ->strftime($FORMAT);
    # say "$tmp_date";
    my ($y, $m, $d) = ($1, $2, $3) if $tmp_date =~ m/(.*)-(.*)-(.*)/;

    if (-d "$root_path/$user/$y/$m") {
      my $tmp_day_path = "$root_path/$user/$y/$m/oc$d.txt";
      if (-e $tmp_day_path) {
        my $content_ = `cat $tmp_day_path`;
        my $total_ = 0;
        while($content_ =~ m/:(.*?) \[.*\]\n/g){
          $total_ += $1;
        }
        $total_oc += $total_;
      }
    }
    
    # $end_t -= ONE_MONTH;
    $end_t -= ONE_DAY;
  }

  return $total_oc;
};

# coding
# design
# dev
# by ywang 862024320@qq.com
use Data::Dumper;
# get a person all oc.txt path
# return person->year->month->[./kadata/ywang/2022/10/oc01.txt,./kadata/ywang/2022/10/oc12.txt]
sub get_user_all_txts_path {
  my $user = shift;
  my $txts = {};
  return $txts unless -d "$root_path/$user";
  my $years = `ls $root_path/$user`;

  foreach my $y (split m/\n/,$years){
    foreach my $m (split m/\n/,`ls $root_path/$user/$y`){
      if (`ls $root_path/$user/$y/$m` ne '') {
        $txts->{$user}->{$y}->{$m} = [];
        foreach my $txt (split m/\n/,`ls $root_path/$user/$y/$m`){
          # my $tmp_txt_path = "$root_path/$user/$y/$m/$txt";
          push(@{$txts->{$user}->{$y}->{$m}}, $txt)
        }
      }
    }
  }

  return $txts;
};

# set a ic line data in ic.txt
sub set_ic_txt_line_data {
  my $user = shift;
  my $ic_name = shift;
  my $ic_number = shift;
  my $path = get_user_ic_data_path($user);
  `touch $path` unless -e $path;
  open(my $out, ">>", "$path");
  say $out "$ic_name:$ic_number " . get_date_time();
  # close $out;
};

# set a oc line data in oc$day.txt
sub set_oc_txt_line_data {
  my $user = shift;
  my $oc_name = shift;
  my $oc_number = shift;
  my $path = get_user_today_oc_data_path($user);
  `touch $path` unless -e $path;
  open(my $out, ">>", "$path");
  say $out "$oc_name:$oc_number " . get_date_time();
  # close $out;
};

# get txt_content then convert to a array
sub get_txt_content_to_array {
  my $user = shift;
  my $y = shift;
  my $m = shift;
  my $txt = shift;
  
  my @txts_content_arrs = ();
  if (-e "$root_path/$user/$y/$m/$txt") {
    open(my $in,  "<",  "$root_path/$user/$y/$m/$txt")  or die "Can't open input.txt: $!";
    while (<$in>) {     # assigns each line in turn to $_
      chomp;
      push(@txts_content_arrs, $_);
    }
    close $in or die "$in: $!";
  }

  return \@txts_content_arrs;
};

# check number
sub check_number {
  my $n = shift;
  if ($n =~ m/^\d/ and $n =~ m/\d$/) {
    if ($n =~ m/^[0-9]+([.]{1}[0-9]+){0,1}$/) {
      return 1;
    } else {
      return 0;
    }
  } else {
    return 0;
  }
};

# check name
sub check_name {
  my $n = shift;
  if ($n =~ m/[\:\.\,\-\_\[\]\+\=\#\*\$\%\^\\\/\!\`\'\"\;\?\>\<\|]/ or $n =~ m/ /) {
    return 0;
  } else {
    return 1;
  }
};

# replace_name, check and replace special char
sub replace_name {
  my $n = shift;
  # ${$n} =~ s/ /SPACE/g;
  # ${$n} =~ s/\:/COLON/g;
  # ${$n} =~ s/\./DOT/g;
  return ${$n} =~ s/[ \:\.\,\-\_\[\]\+\=\#\*\$\%\^\\\/\!\`\'\"\;\?\>\<\|]/SPCHAR/g;
};

# check enter route legal
sub check_user_route_legal {
  my $user = shift;
  my $path = './kadata/legal_name.txt';
  `mkdir ./kadata; touch $path; echo user:ywang >> $path` unless -e $path;
  `echo user:ywang01 >> $path` unless -e $path;
  `echo user:ywang02 >> $path` unless -e $path;
  `echo user:ywang03 >> $path` unless -e $path;
  my $content = `cat $path`;
  if ($content =~ m/user:$user\n/){
    return 1;
  } else {
    return 0;
  }
};

# coding
# design
# dev
# by ywang 862024320@qq.com
post '/set_ic' => sub ($c) {
  my $icname = $c->param('icname');
  my $ic = $c->param('ic');
  my $user = $c->param('user');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  set_ic_txt_line_data($user, $icname, $ic) if check_number($ic) and replace_name(\$icname);
 
  $c->redirect_to($user);
};

post '/set_oc' => sub ($c) {
  my $ocname = $c->param('ocname');
  my $oc = $c->param('oc');
  my $user = $c->param('user');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  set_oc_txt_line_data($user, $ocname, $oc) if check_number($oc) and replace_name(\$ocname);

  $c->redirect_to($user);
};

get '/:user' => sub ($c) {
  my $user = $c->stash('user');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }
  my ($year, $month, $day) = get_year_month_day();

  my $user_today_oc_content = get_today_oc_txt_content($user);
  my $user_today_oc_all = get_today_oc_all($user);
  my $user_month_oc_all = get_month_oc_all($user);
  my $user_month_ic_all = get_ic_all($user);
  my $user_month_oc_content = get_month_oc_content($user);
  my $user_month_ic_content = get_ic_txt_content($user);
  my $user_month_remain_ic = $user_month_ic_all - $user_month_oc_all;

  $c->stash(
    year => $year,
    month => $month,
    day => $day,
    user_today_oc_content => $user_today_oc_content,
    user_today_oc_all => $user_today_oc_all,
    user_month_oc_all => $user_month_oc_all,
    user_month_ic_all => $user_month_ic_all,
    user_month_ic_content => $user_month_ic_content,
    user_month_oc_content => $user_month_oc_content,
    user_month_remain_ic => $user_month_remain_ic
  );

  $c->render(template => 'user');
};

# coding
# design
# dev
# by ywang 862024320@qq.com

post '/set_txt_content' => sub ($c) {
  my $content = $c->param('content');
  my $oper = $c->param('oper');
  my $user = $c->param('user');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }
  if ($oper eq 'ic') {
    my $path = get_user_ic_data_path($user);
    `rm -f $path`;
    `touch $path`;
    open(my $out, ">", $path);
    say $out $content;
    close $out;
    $c->redirect_to($user);
    return;
  } else {
    $c->redirect_to($user);
    return;
  }
};

# get data between date from start to end
post '/get_date_statistic' => sub ($c) {
  my $datestart = $c->param('datestart');
  my $dateend = $c->param('dateend');
  my $oper = $c->param('oper');
  my $user = $c->param('user');
  my $msg = '';
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }
  if ($datestart eq '' or $dateend eq '' ) {
    $c->redirect_to("/$user/$oper");
    return;
  }
  # if start ge end swap two date
  if ($datestart ge $dateend) {
    my $tmp = $dateend;
    $dateend = $datestart;
    $datestart = $tmp;
  }
  # my ($startyear, $startmonth, $startday) = ($1, $2, $3) if $datestart =~ m/(.*)-(.*)-(.*)/;
  # my ($endyear, $endmonth, $endday) = ($1, $2, $3) if $dateend =~ m/(.*)-(.*)-(.*)/;
  
  # varible for calculate date from start to end oc all
  # point_1 <= point_2;
  my $date_point_1 = '';
  my $date_point_2 = '';
  my $date_point_flag = 0;

  my $FORMAT = '%Y-%m-%d';
  my $start = $datestart;
  my $end   = $dateend;
  my $start_t = Time::Piece->strptime( $start, $FORMAT );
  my $end_t   = Time::Piece->strptime( $end,   $FORMAT );
  $date_point_2 = $end_t ->strftime($FORMAT);
  while ( $start_t <= $end_t ) {
    if ($date_point_flag == 1) {
      $date_point_2 = $end_t ->strftime($FORMAT);
      # say $date_point_2;
    }
    $date_point_flag = 0;
    # say $start_t ->strftime($FORMAT), "\n";
    my $tmp_date = $end_t ->strftime($FORMAT);
    # say "$tmp_date";
    my ($y, $m, $d) = ($1, $2, $3) if $tmp_date =~ m/(.*)-(.*)-(.*)/;
    # $msg .= "$tmp_date: null record. <br>" unless -d "$root_path/$user/$y/$m";
    if (-d "$root_path/$user/$y/$m") {
      unless (get_day_oc_txt_content_by_year_month_day($user, $y, $m, $d) eq '') {
        $msg = "$tmp_date: <br>" . get_day_oc_txt_content_by_year_month_day($user, $y, $m, $d) . 
        "- day total oc: " . get_day_oc_all_by_year_month_day($user, $y, $m, $d) . "<br><br>" . $msg;
      }
      if ($d == 1 or $start_t eq $end_t) {
        $date_point_flag = 1;
        $date_point_1 = $tmp_date;
        unless (get_ic_txt_content_by_year_month($user, $y, $m) eq '') {
          $msg = "<br><br> month total ic content: <br>". get_ic_txt_content_by_year_month($user, $y, $m) . "<br>" . $msg;
          $msg = "<br> month total oc: ". get_month_oc_all_by_year_month($user, $y, $m) . "\$" . $msg;
          $msg = "<br> ic without oc: ". (get_ic_all_by_year_month($user, $y, $m) - get_month_oc_all_by_year_month($user, $y, $m)) . "\$" . $msg;
          $msg = "<br> start to month end total oc: ". get_days_oc_all_by_date_start_end($user, $date_point_1, $date_point_2) . "\$" . $msg;
          $msg = "<br> ic without start-end oc: ". (get_ic_all_by_year_month($user, $y, $m) - get_days_oc_all_by_date_start_end($user, $date_point_1, $date_point_2)) . "\$" . $msg;
          $msg = "<span style='font-weight: bold;'>$y-$m</span> <br> month total ic : ". get_ic_all_by_year_month($user, $y, $m) . "\$" . $msg;
          
        }
      }
    } else {
      $msg .= '';
    }
    # $end_t -= ONE_MONTH;
    $end_t -= ONE_DAY;
  }

  # get ic and oc all from date start to end
  my $months_ic_all_from_date_start_end = get_months_ic_all_by_date_start_end($user, $datestart, $dateend);
  my $days_oc_all_from_date_start_end = get_days_oc_all_by_date_start_end($user, $datestart, $dateend);

  $c->flash(datestart => $datestart);
  $c->flash(dateend => $dateend);
  $c->flash(msg => $msg);
  $c->flash(months_ic_all_from_date_start_end => $months_ic_all_from_date_start_end);
  $c->flash(days_oc_all_from_date_start_end => $days_oc_all_from_date_start_end);
  $c->redirect_to("/$user/$oper");
};

# danger route
get '/:user/:oper' => sub ($c) {
  my $user = $c->stash('user');
  my $oper = $c->stash('oper');
  unless(check_user_route_legal($user)){
    $c->render(text => 'danger!!!');
    return;
  }
  if ($oper eq 'removealldata') {
    `rm -rf ./kadata/$user`;
    $c->render(text => 'ok');
    return;
  } elsif ($oper eq 'ic') {
    $c->stash(content => get_ic_txt_content_origin($user));
    $c->render(template => 'modifytxtcontent');
    return;
  } elsif ($oper eq 'txtsdeleteline') {
    $c->stash(txts => get_user_all_txts_path($user));
    $c->render(template => 'choosetxt');
    return;
  } elsif ($oper eq 'datestatistic') {
    $c->render(template => 'datestatistic');
    return;
  } else {
    $c->render(text => 'no oper');
    return;
  }

  $c->render(text => 'null');
  return;

};

get '/txtmodify/:user/:y/:m/#txt' => sub ($c) {
  my $user = $c->stash('user');
  my $y = $c->stash('y');
  my $m = $c->stash('m');
  my $txt = $c->stash('txt');

  # say $user, $y, $m, $txt;

  my $txt_content_array = get_txt_content_to_array($user, $y, $m, $txt);
  # say Dumper $txt_content_array;
  if (scalar @$txt_content_array != 0) {
    $c->stash(txt_content_array => $txt_content_array);
    $c->render(template => 'txtcontentarraydisplay');
    return;
  }

  $c->redirect_to("/$user/txtsdeleteline");
  return;
};

use MIME::Base64;
get '/delete_txt_line/:user/:y/:m/#txt/:content' => sub ($c) {
  my $user = $c->stash('user');
  my $y = $c->stash('y');
  my $m = $c->stash('m');
  my $txt = $c->stash('txt');
  my $content = $c->stash('content');

  # my $decode_content = decode_base64($content);
  
  my @txts_content_arrs = ();
  if (-e "$root_path/$user/$y/$m/$txt") {
    open(my $in,  "<",  "$root_path/$user/$y/$m/$txt")  or die "Can't open input.txt: $!";
    while (<$in>) {     # assigns each line in turn to $_
      chomp;
      push(@txts_content_arrs, $_) if $_ ne decode_base64($content);
    }
    close $in or die "$in: $!";
  }

  if (scalar @txts_content_arrs == 0) {
    `rm -f $root_path/$user/$y/$m/$txt`;
    $c->redirect_to("/$user/txtsdeleteline");
  } else {
    open(my $out,  ">",  "$root_path/$user/$y/$m/$txt")  or die "Can't open input.txt: $!";
    foreach (@txts_content_arrs) {
      say $out $_;
    }

    close $out or die "$out: $!";

    $c->redirect_to("/txtmodify/$user/$y/$m/$txt");
    return;
  }

};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Connact Admin and add your account.</h1>

@@ txtcontentarraydisplay.html.ep
% layout 'default';
% title 'txt content array display';
% my $txt_content_array = $c->stash('txt_content_array');
% use MIME::Base64;
% use Encode qw(decode_utf8);

<p style="text-align: center;">delete line your want.</p>
<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">back home</a>
</p>
<div style="font-size: 1.0em; border: 1px solid #333; padding: 5px;">
  <p style="text-align: center;">
    <%= $c->stash('user') %>, <%= $c->stash('y') %>, <%= $c->stash('m') %>, <%= $c->stash('txt') %>
  </p>
  % foreach (@$txt_content_array) {
    <p>
    <a href="/delete_txt_line/<%= $c->stash('user') %>/<%= $c->stash('y') %>/<%= $c->stash('m') %>/<%= $c->stash('txt') %>/<%= encode_base64("$_") %>">
    <%= decode_utf8($_) %> <span style="color: red;">click will delete</span></a>
    </p>
  % }
</div>



@@ choosetxt.html.ep
% layout 'default';
% title 'choose wang to modify day';

% my $txts = $c->stash('txts');
<p style="text-align: center;">modified day select</p>
<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">back home</a>
</p>
<div style="font-size: 1.5em; border: 1px solid #333; padding: 5px;">
% foreach my $user_ (keys %$txts) {
  <p style="display: inline;"><%= $user_ %></p>
  % foreach my $y_ (reverse sort keys %{$txts->{$user_}}) {
    <p style="display: inline;"><%= $y_ %></p>
    % foreach my $m_ (reverse sort keys %{$txts->{$user_}->{$y_}}) {
      <hr>
      <p style="display: inline;"><%= $m_ %> : </p>
      % foreach my $txt_ (@{$txts->{$user_}->{$y_}->{$m_}}) {
        <a style="margin: 0 10px 0px 0px;" href="/txtmodify/<%= $user %>/<%= $y_ %>/<%= $m_ %>/<%= $txt_ %>"><%= $txt_ %></a>
      % }
      <hr>
    % }
  % }
% }
</div>


@@ datestatistic.html.ep
% layout 'default';
% title 'date statistic';
<p style="text-align: center; font-size: 1.5em;">
  statistic
</p>
<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">back home</a>
</p>
<form action="/get_date_statistic" method="post" style="font-size: 1.5em">
  <div style="display: none">
    <input type="text" name="user" value="<%= $c->stash('user') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $c->stash('oper') %>">
  </div>
  <fieldset>
    <legend>date selected</legend>
    <label for="datestart">start:</label>
    <input id="datestart" type="date" name="datestart" value="<%= $c->flash('datestart') eq '' ? '2022-10-01' : $c->flash('datestart') %>">
    <br>
    <label for="dateend">end:</label>
    <input id="dateend" type="date" name="dateend" value="<%= $c->flash('dateend') eq '' ? '2022-12-31' : $c->flash('dateend') %>">
  </fieldset>
  <div style="float: right;">
    <!--input type="button" value="Year!" onclick="setYearToForm()"-->
    <input type="button" value="Month!" onclick="setMonthToForm()">
    <input type="button" value="Week!" onclick="
    document.getElementById('datestart').value=getCurrentWeekFirstDay(new Date()); document.getElementById('dateend').value=getCurrentWeekLastDay(new Date());
    ">
    <input type="button" value="Today!" onclick="
    document.getElementById('datestart').value=new Date().format('yyyy-MM-dd'); document.getElementById('dateend').value=new Date().format('yyyy-MM-dd');
    ">
    <input type="submit" value="submit!">
  </div>
</form>

<p>Detail: </p>

% if ($c->flash('months_ic_all_from_date_start_end') != 0) {
  <div style="border: 1px solid #333; padding: 5px;">
  <p>from <%= $c->flash('datestart') %> to <%= $c->flash('dateend') %> all ic and oc.</p>
  <p> sub detail: </p>
  <p> all ic: <%= $c->flash('months_ic_all_from_date_start_end') %> $</p>
  <p> all oc: <%= $c->flash('days_oc_all_from_date_start_end') %> $</p>
  </div>
% }

% if ($c->flash('msg') ne '') {
  <div style="border: 1px solid #333; padding: 5px;">
    <p>
      <%== $c->flash('msg') %>
    </p>
  </div>
% }

<!-- coding and design and dev by ywang, 862024320@qq.com, 2022-10-14 -->
<script type="text/javascript">

  function setMonthToForm() {
    var now_date = new Date() // 当前日期
    var now_year = now_date.getFullYear() //当前年
    var now_month = now_date.getMonth() //当前月 （值为0~11）
    var month_first_day = new Date(now_year,now_month,1)  // 本月开始时间
    var month_last_day = new Date(now_year, now_month+1,0); // 本月结束时间
    //如果想获取本月第一天00：00和最后一天23：59
    //var firstDay = new Date(now_year,now_month,1,00,00)
    //var LastDay = new Date(now_year, now_month+1,0, 23,59);
    document.getElementById('datestart').value= month_first_day.format('yyyy-MM-dd'); 
    document.getElementById('dateend').value= month_last_day.format('yyyy-MM-dd');
  }

  Date.prototype.format = function(fmt) { 
    var o = { 
      "M+" : this.getMonth()+1,                 //月份 
      "d+" : this.getDate(),                    //日 
      "h+" : this.getHours(),                   //小时 
      "m+" : this.getMinutes(),                 //分 
      "s+" : this.getSeconds(),                 //秒 
      "q+" : Math.floor((this.getMonth()+3)/3), //季度 
      "S"  : this.getMilliseconds()             //毫秒 
    }; 
    if(/(y+)/.test(fmt)) {
            fmt=fmt.replace(RegExp.$1, (this.getFullYear()+"").substr(4 - RegExp.$1.length)); 
    }
    for(var k in o) {
        if(new RegExp("("+ k +")").test(fmt)){
            fmt = fmt.replace(RegExp.$1, (RegExp.$1.length==1) ? (o[k]) : (("00"+ o[k]).substr((""+ o[k]).length)));
        }
    }
    return fmt; 
  }

  /**
    * 获取本周的first
    * 返回格式: YYYY-mm-dd
    */
  function getCurrentWeekFirstDay(date) {
    var days=date.getDay();
    days=days==0?7:days;
    
      let weekFirstDay = new Date(date - (days - 1) * 86400000 );
      //console.log('===', weekFirstDay);
      let firstMonth = Number(weekFirstDay.getMonth()) + 1;
      if (firstMonth < 10) {
          firstMonth = '0' + firstMonth;
      }
      let weekFirstDays = weekFirstDay.getDate();
      if (weekFirstDays < 10) {
          weekFirstDays = '0' + weekFirstDays;
      }
      return weekFirstDay.getFullYear() + '-' + firstMonth + '-' + weekFirstDays;
  }
  /**
    * 获取本周的最后一天
    * 返回格式: YYYY-mm-dd
    */
  function getCurrentWeekLastDay(date) {
    var days=date.getDay();
    days=days==0?7:days;
      let weekFirstDay = new Date(date - (days - 1) * 86400000);
      let weekLastDay = new Date((weekFirstDay / 1000 + 6 * 86400) * 1000);
      let lastMonth = Number(weekLastDay.getMonth()) + 1;
      if (lastMonth < 10) {
          lastMonth = '0' + lastMonth;
      }
      let weekLastDays = weekLastDay.getDate();
      if (weekLastDays < 10) {
          weekLastDays = '0' + weekLastDays;
      }
      return weekLastDay.getFullYear() + '-' + lastMonth + '-' + weekLastDays;
  }

</script>

@@ modifytxtcontent.html.ep
% layout 'default';
% title 'accounts record';
<p style="text-align: center; font-size: 1.5em;">
  danger oper, cccccheck
</p>
<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">back home</a>
</p>

<!-- coding and design and dev by ywang, 862024320@qq.com, 2022-10-14 -->

<form action="/set_txt_content" method="post" style="position: absolute; font-size: 1.5em;">
  <div style="display: none">
    <input type="text" name="user" value="<%= $c->stash('user') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $c->stash('oper') %>">
  </div>
  <div>
    <label for="content">txt content:</label>
    <textarea id="content" name="content" rows="29" cols="39"><%= $c->stash('content') %></textarea>
  </div>
  <div style="float: right;">
    <input type="submit" value="submit!">
  </div>
</form>


@@ user.html.ep
% layout 'default';
% title 'accounts record';

<!-- coding and design and dev by ywang, 862024320@qq.com, 2022-10-14 -->

<p style="text-align: center; font-size: 1.5em;">
  <%= $c->stash('user') %>&nbsp;&nbsp;
  <%== $c->stash('year') %>-
  <%== $c->stash('month') %>-
  <span style="font-weight: bold;"><%== $c->stash('day') %></span>
</p>

<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">home</a>
  <br>
  <a href="/<%= $c->stash('user') %>/ic" style="pointer-events: none; color: gray;">ic</a>
   | 
  <a href="/<%= $c->stash('user') %>/datestatistic">datestatistic</a>
   | 
  <a href="/<%= $c->stash('user') %>/txtsdeleteline">txtsdeleteline</a>
</p>

<div style="position: relative; margin: 5px; padding: 5px; border: 1px solid #333; height: 100px;">
  <!--fieldset>
    <legend>Title</legend>
  </fieldset-->
  <form action="/set_ic" method="post" style="position: absolute; font-size: 1.5em;">
    <div style="display: none">
      <input type="text" name="user" value="<%= $c->stash('user') %>">
    </div>
    <div>
      <label for="icname">ic name: </label>
      <input type="text" name="icname" id="icname" required>
    </div>
    <div>
      <label for="ic">Enter ic: </label>
      <input type="text" name="ic" id="ic" value="<%= $c->stash('ic') %>" required>
    </div>
    <div style="float: right;">
      <input type="submit" value="submit ic!">
    </div>
  </form>

  <script type="text/javascript">
  </script>
</div>


<div style="position: relative; margin: 5px; padding: 5px; border: 1px solid #333; height: 100px;">
  <form action="/set_oc" method="post" style="position: absolute; font-size: 1.5em;">
    <div style="display: none">
      <input type="text" name="user" value="<%= $c->stash('user') %>">
    </div>
    <div>
      <label for="ocname">oc name: </label>
      <input type="text" name="ocname" id="ocname" required>
    </div>
    <div>
      <label for="oc">Enter oc: </label>
      <input type="text" name="oc" id="oc" required>
    </div>
    <div style="float: right;">
      <input type="submit" value="submit oc!">
    </div>
  </form>
  <script type="text/javascript">
  </script>
</div>

<div style="position: relative; margin: 5px; padding: 5px; border: 1px solid #333;">
  <p style="font-size: 1.5em;"><span style="font-weight: bold;">today record:</span><br>
  <%== $c->stash('user_today_oc_content') %>

  today oc: <%== $c->stash('user_today_oc_all') %>
  </p>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">month all oc:</span><br>
  <%== $c->stash('user_month_oc_all') %>
  </p>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">all ic:</span><br>
  <%== $c->stash('user_month_ic_all') %>
  </p>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">remain ic:</span><br>
  <%== $c->stash('user_month_remain_ic') %>
  </p>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">ic detail:</span><br>
  <%== $c->stash('user_month_ic_content') %>
  </p>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">month detail:</span><br>
  <%== $c->stash('user_month_oc_content') %>
  </p>
</div>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>

    <style>
      html {
        font-size:16px;
      }
      /* 可一次性设置样式*/
      a:hover, a:visited, a:link, a:active {
          color:  blue;
          text-decoration: none;
      }
    </style>
</head>

<body>
<%= content %>
</body>

</html>


<!--
2022-10-10 xiufule checknamewenjian wuxian xieru wenti 
2022-10-10 zengjia jilu de shijian
2022-10-11 gengxinle datestatistic de xianshi wenti
2022-10-11 gengxinle datestatistic moreng date shuju
# coding
# design
# dev
# by ywang 862024320@qq.com
-->
