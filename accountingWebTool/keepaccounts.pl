#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use utf8;
use Encode qw(decode_utf8);
use Time::Piece;
use Time::Seconds;

# set request max limit size
BEGIN {
    $ENV{MOJO_MAX_MESSAGE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_BUFFER_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_LEFTOVER_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_LINE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    
};

my $root_path = './kadata';
# morbo keepaccounts.pl -l http://127.0.0.1:3001
get '/' => sub ($c) {
  $c->render(template => 'index');
};

# generate a uuid with eight numbers like '9bcn20kq'
sub get_uuid_8 {
  my $uuid_8 = $1 if `uuidgen` =~ m/(.*?)-/;
  return $uuid_8;
};

# decode txt line format and return a hash
sub decode_txt_line {
  my $s = shift;
  my $a = $1 if $s =~ m/\[content:(.*?)\]/;
  my $b = $1 if $s =~ m/\[price:(.*?)\]/;
  my $c = $1 if $s =~ m/\[time:(.*?)\]/;
  my $d = $1 if $s =~ m/\[uuid8:(.*?)\]/;

  return {'content' => $a, 'price' => $b, 'time' => $c, 'uuid8' => $d};
}

# add span tag to a string
sub add_str_start_end_span_tag {
  my $s = shift;
  return '<span>' . $s . '</span>';
};

# add b tag to a string
sub add_str_start_end_b_tag {
  my $s = shift;
  return '<b>' . $s . '</b>';
};

# 
sub get_user_calendar_txt_path {
  my $user = shift;
  return "$root_path/$user.calendar";
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
  my $dt = strftime "[time:%Y-%m-%d %H:%M:%S]", localtime;
  return $dt;
};

# return date time, format: 2022-10-10-10-08-50]
sub get_date_time_all_number () {
  my $dt = strftime "%Y-%m-%d-%H-%M-%S", localtime;
  return $dt;
};

# return user data path str
sub get_user_data_path {
  my $user = shift;
  my ($year, $month, $day) = get_year_month_day();
  my $userdata_path = "$root_path/$user/$year/$month";
  `mkdir -p $userdata_path` unless -d $userdata_path;
  return $userdata_path;
};

# return user ic data path str
sub get_user_ic_data_path {
  my $user = shift;
  # say get_user_data_path($user) . '/ic.txt';
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
  my @arrs = ();
  foreach(split /\n/, $content){
    my $line_h = decode_txt_line($_);
    push(@arrs, $line_h->{'content'} . ' : ' . $line_h->{'price'} . ' ' . $line_h->{'time'});
  }
  return join('<br>', @arrs);
  # return $content;
};

sub get_ic_txt_content_to_arrs {
  my $user = shift;
  my $path = get_user_ic_data_path($user);
  return [] unless -e $path;
  my $content = `cat $path`;
  my @arrs = ();
  foreach(split /\n/, $content){
    my $line_h = decode_txt_line($_);
    push(@arrs, $line_h->{'content'} . ' : ' . $line_h->{'price'} . ' ' . $line_h->{'time'});
  }
  return \@arrs;
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
  while($content =~ m/\[price:(.*?)\] /gm){
    $total += $1;
  }
  return $total;
};

# get ic by year month arrs ref
sub get_ic_txt_content_arrs_by_year_month {
  my $user = shift;
  my $year = shift;
  my $month = shift;

  my $path = "$root_path/$user/$year/$month/ic.txt";
  return '' unless -e $path;
  my $content = `cat $path`;
  my @arrs = ();
  foreach(split /\n/, $content){
    # my $line_h = decode_txt_line($_);
    # push(@arrs, decode_utf8 ($line_h->{'content'} ) . ' ' . $line_h->{'time'});
    push(@arrs, decode_txt_line($_));
  }
  return \@arrs;
};

# get ic by year month
sub get_ic_txt_content_by_year_month {
  my $user = shift;
  my $year = shift;
  my $month = shift;

  my $path = "$root_path/$user/$year/$month/ic.txt";
  return '' unless -e $path;
  my $content = `cat $path`;
  my @arrs = ();
  foreach(split /\n/, $content){
    my $line_h = decode_txt_line($_);
    push(@arrs, decode_utf8($line_h->{'content'}) . ' : ' . $line_h->{'price'} . ' ' . $line_h->{'time'});
  }
  return join('<br>', @arrs);
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
  while($content =~ m/\[price:(.*?)\] /gm){
    $total += $1;
  }
  return $total;
};

# return user today oc txt content
sub get_today_oc_txt_content_to_arrs {
  my $user = shift;
  my $path = get_user_today_oc_data_path($user);
  return [] unless -e $path;
  my $content = `cat $path`;
  my @arrs = ();
  foreach(split /\n/, $content){
    my $line_h = decode_txt_line($_);
    push(@arrs, $line_h);
  }

  return \@arrs;
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
  my @arrs = ();
  foreach(split /\n/, $content){
    my $line_h = decode_txt_line($_);
    push(@arrs, decode_utf8($line_h->{'content'}) . ' : ' . $line_h->{'price'} . ' ' . $line_h->{'time'});
  }
  return join('<br>', @arrs);
};

# return a line oc content by y m d uuid
sub get_day_oc_txt_content_by_year_month_day_uuid8 {
  my $user = shift;
  my $year = shift;
  my $month = shift;
  my $day = shift;
  my $uuid8 = shift;

  my $path = "$root_path/$user/$year/$month/oc$day.txt";
  return {} unless -e $path;
  my $content = `cat $path`;
  my $ref = {};
  foreach(split /\n/, $content){
    my $line_h = decode_txt_line($_);
    if ($line_h->{'uuid8'} eq $uuid8) {
      $line_h->{'content'} = decode_utf8($line_h->{'content'});
      $ref = $line_h;
    }
  }
  return $ref;
};

# return oc content by year month day with preview alink
sub get_day_oc_txt_content_by_year_month_day_with_preview_alink {
  my $user = shift;
  my $year = shift;
  my $month = shift;
  my $day = shift;

  my $path = "$root_path/$user/$year/$month/oc$day.txt";
  return '' unless -e $path;
  my $content = `cat $path`;
  my @arrs = ();
  foreach(split /\n/, $content){
    my $EPC_dir = "$root_path/$user/$year/$month/oc$day\_EPC";
    if(-d $EPC_dir) {
      my $tmp_uuid8 = decode_txt_line($_)->{'uuid8'};
      my $files_number = 0;
      $files_number = `ls ./kadata/$user/$year/$month/oc$day\_EPC | grep '$tmp_uuid8' | wc -l`;
      chomp($files_number);
      if ($files_number != 0){
        push(@arrs, decode_utf8( decode_txt_line($_)->{'content'} ) . ' : ' . decode_txt_line($_)->{'price'} . ' ' . decode_txt_line($_)->{'time'} . ' <span style="color: pink;">' . $files_number . '</span> ' . 
        "<a href='/show_record_files/$user/$year/$month/$day/oc$day\_EPC/$tmp_uuid8'>Preview</a>");
      }else{
        push(@arrs, decode_utf8( decode_txt_line($_)->{'content'} ) . ' : ' . decode_txt_line($_)->{'price'} . ' ' . decode_txt_line($_)->{'time'});
      }
    } else {
      push(@arrs, decode_utf8( decode_txt_line($_)->{'content'} ) . ' : ' . decode_txt_line($_)->{'price'} . ' ' . decode_txt_line($_)->{'time'});
    }
  }
  return join('<hr>', @arrs);
};

sub get_day_oc_txt_content_by_year_month_day_with_uuid8 {
  my $user = shift;
  my $year = shift;
  my $month = shift;
  my $day = shift;
  my $uuid8 = shift;

  my $path = "$root_path/$user/$year/$month/oc$day.txt";
  return '' unless -e $path;
  my $content = `cat $path`;
  my @arrs = ();
  foreach(split /\n/, $content){
    my $line_h = decode_txt_line($_);
    if ($line_h->{'uuid8'} eq $uuid8){
      push(@arrs, decode_utf8( $line_h->{'content'} ) . ' : ' . $line_h->{'price'} . ' ' . $line_h->{'time'});
    }
  }
  return join('<br>', @arrs);
};

# return month oc content
sub get_month_oc_content_to_arrs {
  my $user = shift;

  my ($year, $month, $day) = get_year_month_day();
  my @all_content = ();
  for($day; $day > 0; $day--){
    $day = $day*$day/$day if ($day*$day < 100);
    $day = "0$day" if ($day*$day < 100);
    my $tmp_day_path = get_user_data_path($user) . "/oc$day.txt";
    # $tmp_day_path = get_user_data_path($user) . "/oc0$day.txt" if $day*$day < 100;
    if (-e $tmp_day_path) {
      my $content_ = `cat $tmp_day_path`;
      my $total_ = 0;
      while($content_ =~ m/\[price:(.*?)\] \[.*\]\n/g){
        $total_ += $1;
      }
      # $content_ =~ s/\n/<br>/g;
      push(@all_content, "<b>day-$day ($total_\$):</b>");
      my @arrs = split /\n/, $content_;
      foreach(@arrs) {
        push(@all_content, decode_txt_line($_)->{'content'} . ' : ' . decode_txt_line($_)->{'price'} . ' ' . decode_txt_line($_)->{'time'});
      }
      # $all_content .= "<br>day-$day ($total_\$):<br>" . $content_;
    } else {
      # $all_content .= "<br>day-$day : null record. <br>";
      push(@all_content, "<b>day-$day : null record. </b>");
    }
  }
  return \@all_content;
};

# return month oc content with files preview alink
sub get_month_oc_content_to_arrs_with_preview_alink_editlink {
  my $user = shift;

  my ($year, $month, $day) = get_year_month_day();
  my @all_content = ();
  for($day; $day > 0; $day--){
    $day = $day*$day/$day if ($day*$day < 100);
    $day = "0$day" if ($day*$day < 100);
    my $tmp_day_path = get_user_data_path($user) . "/oc$day.txt";
    # $tmp_day_path = get_user_data_path($user) . "/oc0$day.txt" if $day*$day < 100;
    if (-e $tmp_day_path) {
      my $content_ = `cat $tmp_day_path`;
      my $total_ = 0;
      while($content_ =~ m/\[price:(.*?)\] \[.*\]\n/g){
        $total_ += $1;
      }

      my $alink = '';
      # $content_ =~ s/\n/<br>/g;
      push(@all_content, "<b>day-$day ($total_\$):</b>");
      my @arrs = split /\n/, $content_;
      foreach(@arrs) {
        my $EPC_dir = "$root_path/$user/$year/$month/oc$day\_EPC";
        if(-d $EPC_dir) {
          my $tmp_uuid8 = decode_txt_line($_)->{'uuid8'};
          my $files_number = 0;
          $files_number = `ls ./kadata/$user/$year/$month/oc$day\_EPC | grep '$tmp_uuid8' | wc -l`;
          chomp($files_number);
          if ($files_number != 0){
            my $content_edit_link = decode_txt_line($_)->{'content'};
            $content_edit_link =  "<a style='pointer-events: none; color: gray;' href='/line_content_modify/$user/$year/$month/$day/$tmp_uuid8'>" . $content_edit_link . '</a>';
            push(@all_content, $content_edit_link . ' : ' . decode_txt_line($_)->{'price'} . ' ' . decode_txt_line($_)->{'time'} . ' <span style="color: pink;">' . $files_number . '</span> ' . 
            "<a href='/show_record_files/$user/$year/$month/$day/oc$day\_EPC/$tmp_uuid8'>Preview</a>");
          }else{
            my $content_edit_link = decode_txt_line($_)->{'content'};
            $content_edit_link =  "<a style='pointer-events: none; color: gray;' href='/line_content_modify/$user/$year/$month/$day/$tmp_uuid8'>" . $content_edit_link . '</a>';
            push(@all_content, $content_edit_link . ' : ' . decode_txt_line($_)->{'price'} . ' ' . decode_txt_line($_)->{'time'});
          }
        } else {
          my $tmp_uuid8 = decode_txt_line($_)->{'uuid8'};
          my $content_edit_link = decode_txt_line($_)->{'content'};
          $content_edit_link =  "<a style='pointer-events: none; color: gray;' href='/line_content_modify/$user/$year/$month/$day/$tmp_uuid8'>" . $content_edit_link . '</a>';
          push(@all_content, $content_edit_link . ' : ' . decode_txt_line($_)->{'price'} . ' ' . decode_txt_line($_)->{'time'});
        }
      }
      # $all_content .= "<br>day-$day ($total_\$):<br>" . $content_;
    } else {
      # $all_content .= "<br>day-$day : null record. <br>";
      push(@all_content, "<b>day-$day : null record. </b>");
    }
  }
  return \@all_content;
};

# return user today oc all
sub get_today_oc_all {
  my $user = shift;
  my $path = get_user_today_oc_data_path($user);
  return '0' unless -e $path;
  my $content = `cat $path`;
  my $total = 0;
  while($content =~ m/\[price:(.*?)\] \[.*\]\n/g){
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
  while($content =~ m/\[price:(.*?)\] \[.*\]\n/g){
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
    $day = $day*$day/$day if ($day*$day < 100);
    $day = "0$day" if ($day*$day < 100);
    my $tmp_day_path = get_user_data_path($user) . "/oc$day.txt";
    # $tmp_day_path = get_user_data_path($user) . "/oc0$day.txt" if $day*$day < 100;
    if (-e $tmp_day_path) {
      my $content_ = `cat $tmp_day_path`;
      my $total_ = 0;
      while($content_ =~ m/\[price:(.*?)\] \[.*\]\n/g){
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
      while($content_ =~ m/\[price:(.*?)\] \[.*\]\n/g){
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
          while($content =~ m/\[price:(.*?)\] /gm){
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
        while($content_ =~ m/\[price:(.*?)\] \[.*\]\n/g){
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
# return person->year->month->[$root_path/ywang/2022/10/oc01.txt,$root_path/ywang/2022/10/oc12.txt]
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
          push(@{$txts->{$user}->{$y}->{$m}}, $txt) unless -d "$root_path/$user/$y/$m/$txt";
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
  say $out "[content:$ic_name] " . "[price:$ic_number] " . get_date_time() . ' [uuid8:' . get_uuid_8() . ']';
  close $out;
};

# set a oc line data in oc$day.txt
sub set_oc_txt_line_data {
  my $user = shift;
  my $oc_name = shift;
  my $oc_number = shift;

  my $path = get_user_today_oc_data_path($user);
  `touch $path` unless -e $path;
  open(my $out, ">>", "$path");
  say $out "[content:$oc_name] " . "[price:$oc_number] " . get_date_time() . ' [uuid8:' . get_uuid_8() . ']';
  close $out;
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

sub get_txt_uuid_to_array {
  my $user = shift;
  my $y = shift;
  my $m = shift;
  my $txt = shift;
  
  my @txts_uuid_arrs = ();
  if (-e "$root_path/$user/$y/$m/$txt") {
    open(my $in,  "<",  "$root_path/$user/$y/$m/$txt")  or die "Can't open input.txt: $!";
    while (<$in>) {     # assigns each line in turn to $_
      chomp;
      my $uuid =  $1 if $_ =~ m/\[uuid8:(.*?)\]/;
      push(@txts_uuid_arrs, $uuid);
    }
    close $in or die "$in: $!";
  }

  return \@txts_uuid_arrs;
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
  if ($n =~ m/[\:\.\,\-\_\[\]\+\=\#\*\$\%\^\\\/\!\`\'\"\;\?\>\<\|]/ or $n =~ m/^(SPA)*$/) {
    return 0;
  } else {
    return 1;
  }
};

# replace_name, check and replace special char
sub replace_name {
  my $n = shift;
  $n =~ s/ /SPA/g;
  $n =~ s/\:/COL/g;
  $n =~ s/\./DOT/g;
  $n =~ s/\\/SST/g; # shilling-stroke;
  $n =~ s/\//AST/g; # Anticlinal stroke
  $n =~ s/\[/LBR/g; # brackets
  $n =~ s/\]/RBR/g;
  $n =~ s/\_/UND/g; # underline
  $n =~ s/\~/WAV/g; # wave
  $n =~ s/\`/TIC/g; # tick
  $n =~ s/\*/STA/g; # Star
  $n =~ s/\$/DOL/g; # dollar 
  $n =~ s/\!/EMA/g; # exclamation mark 
  $n =~ s/\'/SQM/g; # single quotation marks
  $n =~ s/\"/DQM/g; # double quotation marks 
  $n =~ s/\</LAB/g; # angle brackets
  $n =~ s/\>/RAB/g; # angle brackets
  $n =~ s/\|/PIP/g; # pipe operator;
  $n =~ s/\;/SEM/g; # semicolon
  $n =~ s/[\,\-\+\=\#\%\^\?]/CHR/g;
  return $n;
};

# check enter route legal
sub check_user_route_legal {
  my $user = shift;
  my $path = "$root_path/legal_name.txt";
  `mkdir $root_path; touch $path; echo user:ywang >> $path` unless -e $path;
  my $content = `cat $path`;
  if ($content =~ m/user:$user\n/){
    return 1;
  } else {
    return 0;
  }
};

# check user pwd legal 
sub check_user_pwd_legal {
  return 0;
};

#
sub get_user_timeleft_str {
  my $user = shift;

  my $path = get_user_calendar_txt_path($user);
  `touch $path` unless -e $path;
  my $content = `cat $path`;
  chomp $content;
  `echo 2022-12-23 > $path` if $content !~ m/\d{4}-/;

  my $goal = $content;
  my $local = localtime;

  my $t = localtime; # until $t eq $goal
  if ($t->ymd ge $goal) {
    while ($t->ymd ge $goal) {
      $t -= ONE_DAY;
    }

    # get diff from $t and $local
    my $s = $local - $t;
    my $days = $s->days - 1;
    my ($hh, $mm, $ss) = ($1, $2, $3) if $local->datetime =~ m/(\d{2}):(\d{2}):(\d{2})/;
    $hh = $days * 24 + $hh;
    $mm = $hh * 60 + $mm;
    $ss = $mm * 60 + $ss;

    return "past;$goal;$days;$hh;$mm;$ss";

  } else {
    while ($t->ymd lt $goal) {
      $t += ONE_DAY;
    }

    # get diff from $t and $local
    my $s = $t - $local;
    my $days = $s->days - 1;
    my ($hh, $mm, $ss) = ($1, $2, $3) if $local->datetime =~ m/(\d{2}):(\d{2}):(\d{2})/;
    $hh = $days * 24 + 24 - $hh - 1;
    $mm = $hh * 60 + 60 - $mm - 1;
    $ss = $mm * 60 + 60 - $ss;

    return "remain;$goal;$days;$hh;$mm;$ss";
  }
}

sub check_session {
    my $c = shift;
    if (defined $c->session->{'login'} and $c->session->{'login'} == 1) {
        return 1;
    }
    return 0;
}

# coding
# design
# dev
# by ywang 862024320@qq.com
post '/set_ic' => sub ($c) {
  my $icname = $c->param('icname');
  my $ic = 'legal';
  ($icname, $ic) = ($1, $2) if $icname =~ m/(.*?)(\d+\.{0,1}\d*)$/;
  $icname = replace_name($icname);
#   my $ic = $c->param('ic');
  my $user = $c->param('user');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  set_ic_txt_line_data($user, $icname, $ic) if check_number($ic) and check_name($icname);
 
  $c->redirect_to($user);
};

post '/set_oc' => sub ($c) {
  my $ocname = $c->param('ocname');
  my $oc = 'legal';
  ($ocname, $oc) = ($1, $2) if $ocname =~ m/(.*?)(\d+\.{0,1}\d*)$/;
  $ocname = replace_name($ocname);
#   my $oc = $c->param('oc');
  my $user = $c->param('user');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  set_oc_txt_line_data($user, $ocname, $oc) if check_number($oc) and check_name($ocname);

  $c->redirect_to($user);
};

post '/upload_file' => sub ($c) {
  my $year = $c->param('year');
  my $month = $c->param('month');
  my $day = $c->param('day');
  my $user = $c->param('user');
  my $uuid8 = $c->param('uuid8');
  my $content_as_file_name = $c->param('content_as_file_name');
  # $content_as_file_name =~ s///;
  # my $record_str_origin = $c->param('record_str');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  # check dir
  `mkdir -p $root_path/$user/$year/$month/oc$day\_EPC` unless -d "$root_path/$user/$year/$month/oc$day\_EPC";
  foreach my $file (@{$c->req->uploads}) {
		my $filename = $file->{'filename'};
		my $name = $file->{'name'};
    if ($filename ne '') {
      my $current_time = get_date_time_all_number();
      my $file_type = $1 if $filename =~ m/\.(.*?)$/;
      my $files_number = `ls -l $root_path/$user/$year/$month/oc$day\_EPC | grep "^-" | wc -l`;
      chomp($files_number);
      # say $files_number;
      my $fn1 = "$files_number\_$current_time\_$filename";
      my $fn2 = "$files_number\_$uuid8\.$file_type";
      my $fn3 = "$files_number\_$content_as_file_name\.$file_type";
      # save file
      $file->move_to("$root_path/$user/$year/$month/oc$day\_EPC/$fn1");
      `cp $root_path/$user/$year/$month/oc$day\_EPC/$fn1 $root_path/$user/$year/$month/oc$day\_EPC/$fn2`;
      `cp $root_path/$user/$year/$month/oc$day\_EPC/$fn1 $root_path/$user/$year/$month/oc$day\_EPC/$fn3`;
      # $file->move_to("$root_path/$user/$year/$month/oc$day\_EPC/$record_str\.$file_type") unless -e "$root_path/$user/$year/$month/oc$day\_EPC/$record_str\.$file_type";
    }
	}

  $c->redirect_to($user);
};

get '/:user/pwd/:token' => sub ($c) {
  my $user = $c->stash('user');
  my $token = $c->stash('token');
  
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  if ($user ne 'moshan' and $user ne 'ywang' and $token eq "$user\2") {
    $c->session->{'login'} = 1;
    $c->session(expiration => 7*24*60*60);
    $c->redirect_to("/$user");
    return;
  }elsif ($user eq 'moshan' and $token eq 'moshan1') {
    $c->session->{'login'} = 1;
    $c->session(expiration => 10);
    $c->redirect_to("/$user");
    return;
  }elsif ($user eq 'ywang' and $token eq "ywang9789a") {
    $c->session->{'login'} = 1;
    $c->session(expiration => 14*24*60*60);
    $c->redirect_to("/$user");
    return;
  } else {
    $c->session->{'login'} = 0;
    $c->session(expiration => 1);
    $c->render(template => 'nosession');
    return;
  }
};

get '/:user' => sub ($c) {
  my $user = $c->stash('user');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }
  my ($year, $month, $day) = get_year_month_day();

  my $user_today_oc_content = decode_utf8( join( '<hr>', map( add_str_start_end_span_tag($_), @{get_today_oc_txt_content_to_arrs($user)} ) ) );
  my $user_today_oc_content_arrs_ref = get_today_oc_txt_content_to_arrs($user);
  my $user_today_oc_all = get_today_oc_all($user);
  my $user_month_oc_all = get_month_oc_all($user);
  my $user_month_ic_all = get_ic_all($user);
  my $user_month_oc_content = decode_utf8( join('<hr>', map( add_str_start_end_span_tag($_), @{get_month_oc_content_to_arrs_with_preview_alink_editlink($user)} ) ) );
  my $user_month_ic_content = decode_utf8( join('<hr>', map( add_str_start_end_span_tag($_), @{get_ic_txt_content_to_arrs($user)} ) ) );
  my $user_month_remain_ic = $user_month_ic_all - $user_month_oc_all;
  my $user_month_oc_without_ic = $user_month_oc_all - $user_month_ic_all;

  $c->stash(
    year => $year,
    month => $month,
    day => $day,
    user_today_oc_content => $user_today_oc_content,
    user_today_oc_content_arrs_ref => $user_today_oc_content_arrs_ref,
    user_today_oc_all => $user_today_oc_all,
    user_month_oc_all => $user_month_oc_all,
    user_month_ic_all => $user_month_ic_all,
    user_month_ic_content => $user_month_ic_content,
    user_month_oc_content => $user_month_oc_content,
    user_month_remain_ic => $user_month_remain_ic,
    user_month_oc_without_ic => $user_month_oc_without_ic
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

  unless(check_session($c)){
    $c->render(template => 'nosession');
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
post '/:user/get_date_statistic' => sub ($c) {
  my $datestart = $c->param('datestart');
  my $dateend = $c->param('dateend');
  my $oper = $c->param('oper');
  my $user = $c->stash('user');
  my $msg = '';
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
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
  
  my $oc_all_by_start_end_day = get_days_oc_all_by_date_start_end($user, $datestart, $dateend);
  $msg .= add_str_start_end_b_tag( '<br> from ' . $datestart . ' to ' . $dateend . '<br>' );
  $msg .= '<br> all ic: <br>';
  $msg .= '<br> ic details: <br>';
  $msg .= add_str_start_end_b_tag( '<br> all oc: ' ) . $oc_all_by_start_end_day . '<br>';
  $msg .= '<br> avg oc: <br>';
  $msg .= 'zhangweizhangwei';
  $msg .= '<br> day avg oc: <br>';
  $msg .= '<br> ic - oc = : <br>';
  $msg .= add_str_start_end_b_tag( '<br> days detail: <br>' );

  my $ic_all_between_days = 0;
  my $ic_details_between_days = '';
  my $days_count = 0;
  my $avg_days_count = 0;

  my $FORMAT = '%Y-%m-%d';
  my $start_t = Time::Piece->strptime($datestart, $FORMAT );
  my $end_t   = Time::Piece->strptime($dateend, $FORMAT );
  while ( $start_t <= $end_t ) {
    my $tmp_date = $end_t->strftime($FORMAT);
    my ($tmp_year, $tmp_month, $tmp_day) = ($1, $2, $3) if $tmp_date =~ m/(.*)-(.*)-(.*)/;
    my $month_end_flag = 0;
    if ($tmp_day == 1 or $start_t == $end_t) {
        $month_end_flag = 1;

        my $ic_arrs = get_ic_txt_content_arrs_by_year_month($user, $tmp_year, $tmp_month);
        if ($ic_arrs ne '') {
          foreach my $ic_line (@$ic_arrs) {
            my $ic_line_date = $1 if $ic_line->{'time'} =~ m/(.*) /;
            my $ic_line_price = $ic_line->{'price'};
            my $ic_line_content = decode_utf8($ic_line->{'content'});

            if($ic_line_date ge $datestart and $ic_line_date le $dateend) {
              $ic_details_between_days .= "<br> $ic_line_content : $ic_line_price " . $ic_line->{'time'};
              $ic_all_between_days = $ic_all_between_days + $ic_line_price;
            }
          }
        }
    }
    my $day_oc_all = get_day_oc_all_by_year_month_day($user, $tmp_year, $tmp_month, $tmp_day);
    if ($day_oc_all != 0) {
      $msg .= add_str_start_end_b_tag( '<br>' . $tmp_date . '( '. $day_oc_all .' $): <br>' );
      my $day_oc_content_with_preview_alink = get_day_oc_txt_content_by_year_month_day_with_preview_alink($user, $tmp_year, $tmp_month, $tmp_day);
      $msg .= $day_oc_content_with_preview_alink . '<hr>';

      $days_count = $days_count + 1;
    }
    # 
    $avg_days_count = $avg_days_count + 1;
    $end_t -= ONE_DAY;
  }
  $msg =~ s/<br> all ic: <br>/<br> <b>all ic:<\/b> $ic_all_between_days<br>/g;
  $msg =~ s/<br> ic details: <br>/<br> <b>ic details:<\/b> $ic_details_between_days<br>/g;
  my $avg_oc = 0;
  $avg_oc = sprintf("%.3f", $oc_all_by_start_end_day / $days_count) if $days_count != 0;
  $msg =~ s/<br> avg oc: <br>/<br> <b>oc days:<\/b> $days_count , <b>avg oc:<\/b> $avg_oc<br>/g;
  $avg_oc = 0;
  $avg_oc = sprintf("%.3f", $oc_all_by_start_end_day / $avg_days_count) if $avg_days_count != 0;
  $msg =~ s/<br> day avg oc: <br>/<br> <b>all days:<\/b> $avg_days_count , <b>avg oc:<\/b> $avg_oc<br>/g;
  my $diff = $oc_all_by_start_end_day - $ic_all_between_days;
  $msg =~ s/<br> ic - oc = : <br>/<br> <b>ic - oc:<\/b> $oc_all_by_start_end_day - $ic_all_between_days = $diff <br>/g;
  my $avg_oc_without_ic = 0;
  $avg_oc_without_ic = sprintf("%.3f", $diff / $avg_days_count) if $avg_days_count != 0;
  $msg =~ s/zhangweizhangwei/<br> <b>avg oc (without ic):<\/b> $avg_oc_without_ic <br>/g;


  $c->stash(datestart => $datestart);
  $c->stash(dateend => $dateend);
  $c->stash(msg => $msg);
  $c->render(template => 'datestatistic');
  # return;
};

# danger route
get '/:user/:oper' => sub ($c) {
  my $user = $c->stash('user');
  my $oper = $c->stash('oper');
  unless(check_user_route_legal($user)){
    $c->render(text => 'danger!!!');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  if ($oper eq 'removealldata') {
    # `rm -rf $root_path/$user`;
    # $c->render(text => 'ok');
    $c->render(text => 'removealldata oper BAN!!!!!!!');
    return;
  } elsif ($oper eq 'ic') {
    # $c->stash(content => get_ic_txt_content_origin($user));
    # $c->render(template => 'modifytxtcontent');
    $c->render(text => 'update ic func ban now.');
    return;
  } elsif ($oper eq 'txtsdeleteline') {
    $c->stash(txts => get_user_all_txts_path($user));
    $c->render(template => 'choosetxt');
    return;
  } elsif ($oper eq 'datestatistic') {
    $c->render(template => 'datestatistic');
    return;
  } elsif ($oper eq 'adduser') {
    $c->render(template => 'adduser');
    return;
  } elsif ($oper eq 'timeleft') {
    my $timeleft_str = get_user_timeleft_str($user);
    $c->render(text => $timeleft_str);
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
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }
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
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }
  # my $decode_content = decode_base64($content);
  
  my @txts_content_arrs = ();
  if (-e "$root_path/$user/$y/$m/$txt") {
    open(my $in,  "<",  "$root_path/$user/$y/$m/$txt")  or die "Can't open input.txt: $!";
    while (<$in>) {     # assigns each line in turn to $_
      chomp;
      # my $tmp_md5 = `echo '$_' | md5sum | cut -d ' ' -f1`;
      # chomp($tmp_md5); # remove '\n', it is important
      my $tmp_uuid8 = $1 if $_ =~ m/\[uuid8:(.*?)\]/;
      push(@txts_content_arrs, $_) if $tmp_uuid8 ne $content;
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

post '/set_new_user' => sub ($c) {
  my $newuser = $c->param('newuser');
  my $pwd = $c->param('pwd');
  my $oper = $c->param('oper');
  my $user = $c->param('user');
  $c->stash(user => $user);
  $c->stash(oper => $oper);
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  if ($user ne 'ywang') {
    $c->stash(back_msg => 'not administrator, oper denied.');
    $c->render(template => 'adduser');
    return;
  }
  if ($pwd ne '9820') {
    $c->stash(back_msg => 'pwd error, oper denied.');
    $c->render(template => 'adduser');
    return;
  }
  if ($newuser !~ m/^[a-z]{4,6}$/) {
    $c->stash(back_msg => 'new user format error, oper denied. ([a-z]{4,6})');
    $c->render(template => 'adduser');
    return;
  }

  my $path = "$root_path/legal_name.txt";
  open(my $out, ">>", $path);
  say $out "user:$newuser";
  close $out;

  $c->stash(user => $user);
  $c->stash(oper => $oper);
  $c->stash(back_msg => "add success. (http://112.124.14.71:8080/$newuser)");
  $c->render(template => 'adduser');
};

# show all files about current record
get '/show_record_files/:user/:y/:m/:d/:dir/:uuid8' => sub ($c) {
  my $user = $c->stash('user');
  my $y = $c->stash('y');
  my $m = $c->stash('m');
  my $d = $c->stash('d');
  my $dir = $c->stash('dir');
  my $uuid8 = $c->stash('uuid8');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  my $path = "$root_path/$user/$y/$m/$dir";
  unless (-d $path) {
    $c->redirect_to("/$user");
    return;
  }
  
  my $files = `ls $path | grep '$uuid8'`;
  if ($files eq '') {
    $c->redirect_to("/$user");
    return;
  }
  
  my @files_arrs = split('\n', $files);
  $c->stash(files_arrs_ref => \@files_arrs);
  my $oc_contents = 
  $c->stash(oc_contents => get_day_oc_txt_content_by_year_month_day_with_uuid8($user, $y, $m, $d, $uuid8));
  
  $c->render(template => 'files_display');
};

# return a file static resource
get '/get_files_img/:user/:y/:m/:dir/#file' => sub ($c) {
  my $user = $c->stash('user');
  my $y = $c->stash('y');
  my $m = $c->stash('m');
  my $dir = $c->stash('dir');
  my $file = $c->stash('file');
  unless(check_user_route_legal($user)){
    $c->render(template => 'index');
    return;
  }

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }
  $c->reply->file("$root_path/$user/$y/$m/$dir/$file");
};

get '/line_content_modify/:user/:y/:m/:d/:uuid8' => sub ($c) {
  my $user = $c->stash('user');
  my $y = $c->stash('y');
  my $m = $c->stash('m');
  my $d = $c->stash('d');
  my $uuid8 = $c->stash('uuid8');

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  my $oc_line_ref = get_day_oc_txt_content_by_year_month_day_uuid8($user,$y,$m,$d,$uuid8);

  $c->stash(oc_line_ref => $oc_line_ref);

  $c->render(template => 'oc_line_modify');
};

get '/:user/timeleft/set/:date' => sub ($c) {
  my $user = $c->stash('user');
  my $date = $c->stash('date');

  unless(check_session($c)){
    $c->render(template => 'nosession');
    return;
  }

  my $path = get_user_calendar_txt_path($user);
  `echo $date > $path`;

  $c->render(text => '1');
};

app->start;
__DATA__

@@ nosession.html.ep
% layout 'default';
% title 'not login';
<h1>Please login</h1>

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Connact Admin and add your account.</h1>

@@ oc_line_modify.html.ep
% layout 'default';
% title 'oc line modify';

<p style="text-align: center;">danger oper, please input pwd legally</p>
<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">back home</a>
</p>

% my $oc_line_ref = $c->stash('oc_line_ref');

<form action="/oc_line_modify" method="post" style="position: absolute; font-size: 1.5em; text-align: center;">
  <div style="display: none">
    <input type="text" name="user" value="<%= $c->stash('user') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $c->stash('y') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $c->stash('m') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $c->stash('d') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $oc_line_ref->{'uuid8'} %>">
  </div>
  <div>
    <label for="content"><%= $oc_line_ref->{'content'} %></label>
    <input type="text" name="modify_content" value="<%= $oc_line_ref->{'content'} %>" style="width: calc(100% - 10px);">
  </div>
  <div style="float: right;">
    <input type="submit" value="submit!">
  </div>
</form>

@@ files_display.html.ep
% layout 'default';
% title 'record relative files';
<p style="text-align: center;">danger oper, please input pwd legally</p>
<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">back home</a>
</p>

% my $files_arrs_ref = $c->stash('files_arrs_ref');

<div style="font-size: 1.0em; border: 1px solid #333; padding: 5px;">
  <p style="text-align: center;">
    <%= $c->stash('user') %>, <%= $c->stash('y') %>, <%= $c->stash('m') %>, <%= $c->stash('dir') %>, <%= $c->stash('uuid8') %>
  </p>
  <p style="text-align: center;">
    <%== $c->stash('oc_contents') %>
  </p>
  <hr>
  % foreach (@$files_arrs_ref) {
    <p style="text-align: center;">
    <b onclick="showImg('/get_files_img/<%= $c->stash('user') %>/<%= $c->stash('y') %>/<%= $c->stash('m') %>/<%= $c->stash('dir') %>/<%= $_ %>')"><%= $_ %></b>
    <hr>
    </p>
  % }
  <p style="text-align: center;">
    <b onclick="showImg('#')">Refresh</b>
    <hr>
  </p>
  <img id="img" src="" width="100%">
  <script type="text/javascript">
    function showImg(path){
      document.getElementById('img').src = path;
    }
  </script>
</div>

@@ adduser.html.ep
% layout 'default';
% title 'add account user';
<p style="text-align: center;">danger oper, please input pwd legally</p>
<p style="text-align: center;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->stash('user') %>">back home</a>
</p>

<form action="/set_new_user" method="post" style="font-size: 1.5em">
  <div style="display: none">
    <input type="text" name="user" value="<%= $c->stash('user') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $c->stash('oper') %>">
  </div>
  <div>
    <label for="newuser">newuser: </label>
    <input type="text" name="newuser_fake" id="newuser_fake" disabled>
    <input type="hidden" name="newuser" id="newuser" autocomplete="off" required>
    <div>
    % foreach('a'..'z') {
      <em style="display: inline-block; border: 1px solid #333; width: 20px; height: 20px; padding: 10px; margin: 5px;" onclick="set_new_user_text('<%= $_ %>')"><%= $_ %></em>
    % }
      <em style="display: inline-block; border: 1px solid #333; width: 50px; height: 20px; padding: 10px; margin: 5px;" onclick="set_new_user_text('clear')">clear</em>
    </div>
  </div>
  <div>
    <hr>
    <label for="pwd">ppwwdd: </label>
    <input type="text" name="pwd_fake" id="pwd_fake" disabled>
    <input type="hidden" name="pwd" id="pwd" autocomplete="off" required>
    <div>
    % foreach(0..9) {
      <em style="display: inline-block; border: 1px solid #333; width: 20px; height: 20px; padding: 10px; margin: 5px;" onclick="set_pwd_text('<%= $_ %>')"><%= $_ %></em>
    % }
      <em style="display: inline-block; border: 1px solid #333; width: 50px; height: 20px; padding: 10px; margin: 5px;" onclick="set_pwd_text('clear')">clear</em>
    </div>
  </div>
  <script type="text/javascript">
      function set_new_user_text(c) {
        if (c != 'clear') {
          document.getElementById('newuser_fake').value = document.getElementById('newuser_fake').value + c;
          document.getElementById('newuser').value = document.getElementById('newuser').value + c;
        } else {
          document.getElementById('newuser_fake').value = '';
          document.getElementById('newuser').value = '';
        }
      }
      function set_pwd_text(c) {
        if (c != 'clear') {
          document.getElementById('pwd_fake').value = document.getElementById('pwd_fake').value + '*';
          document.getElementById('pwd').value = document.getElementById('pwd').value + c;
        } else {
          document.getElementById('pwd_fake').value = '';
          document.getElementById('pwd').value = '';
        }
      }
    </script>
  <div style="float: right;">
    <input type="submit" value="submit!">
  </div>
</form>
<br>
<p style="text-align: center;"><%= $c->stash('back_msg') %></p>


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
    <!-- %= `echo '$_' | md5sum | cut -d ' ' -f1` % -->
    <a href="/delete_txt_line/<%= $c->stash('user') %>/<%= $c->stash('y') %>/<%= $c->stash('m') %>/<%= $c->stash('txt') %>/<%= $1 if $_ =~ m/\[uuid8:(.*?)\]/ %>"
    onclick="return(confirm('confirm?'))"
    >
    <%= decode_utf8( $_ ) %> <span style="color: red;">click will delete</span></a>
    <hr>
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
<form action="/<%= $c->stash('user') %>/get_date_statistic" method="post" style="font-size: 1.5em">
  <div style="display: none">
    <input type="text" name="user" value="<%= $c->stash('user') %>">
  </div>
  <div style="display: none">
    <input type="text" name="oper" value="<%= $c->stash('oper') %>">
  </div>
  <fieldset>
    <legend>date selected</legend>
    <label for="datestart">start:</label>
    <input id="datestart" type="date" name="datestart" value="<%= $c->stash('datestart') eq '' ? '2022-11-01' : $c->stash('datestart') %>" style="width: calc(100% - 20px);">
    <br>
    <label for="dateend">end:</label>
    <input id="dateend" type="date" name="dateend" value="<%= $c->stash('dateend') eq '' ? '2022-11-30' : $c->stash('dateend') %>" style="width: calc(100% - 20px);">
  </fieldset>
  <div style="float: right;">
    <input type="button" value="back back M!" onclick="getbackMonthByClick()">
    <input type="button" value="back back W!" onclick="getbackWeekByClick()">
    <input type="button" value="Prev M!" onclick="getMonthStartAndEnd(-1)">
    <input type="button" value="Prev W!" onclick="getWeekStartAndEnd(-1)">
    <input type="button" value="Month!" onclick="setMonthToForm()">
    <input type="button" value="Week!" onclick="
    document.getElementById('datestart').value=getCurrentWeekFirstDay(new Date()); document.getElementById('dateend').value=getCurrentWeekLastDay(new Date());
    ">
    <input type="button" value="Today!" onclick="
    document.getElementById('datestart').value=new Date().format('yyyy-MM-dd'); document.getElementById('dateend').value=new Date().format('yyyy-MM-dd');
    ">
    <div style="float: right;">
      <input type="submit" value="submit!">
    </div>
  </div>
</form>

<p>Detail: </p>

% if ($c->stash('msg') ne '') {
  <div style="border: 1px solid #333; padding: 5px;">
    <p>
      <%== $c->stash('msg') %>
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

  let back_back_m = -1;
  function getbackMonthByClick() {
    getMonthStartAndEnd(back_back_m);
    back_back_m = back_back_m - 1;
  }

  // 0 current -1 up 1 next month
  function getMonthStartAndEnd(AddMonthCount) { 
    //起止日期数组  
    let startStop = new Array(); 
    //获取当前时间  
    let currentDate = new Date();
    let month=currentDate.getMonth()+AddMonthCount;
    if(month<0){
      let n = parseInt((-month)/12);
      month += n*12;
      currentDate.setFullYear(currentDate.getFullYear()-n);
    }
    currentDate = new Date(currentDate.setMonth(month));
    //获得当前月份0-11  
    let currentMonth = currentDate.getMonth(); 
    //获得当前年份4位年  
    let currentYear = currentDate.getFullYear(); 
    //获得上一个月的第一天  
    let currentMonthFirstDay = new Date(currentYear, currentMonth,1); 
    //获得上一月的最后一天  
    let currentMonthLastDay = new Date(currentYear, currentMonth+1, 0); 
    let a = currentMonthFirstDay.format('yyyy-MM-dd');
    let b = currentMonthLastDay.format('yyyy-MM-dd');

    document.getElementById('datestart').value= a; 
    document.getElementById('dateend').value=b;
  }

  let back_back_w = -1;
  function getbackWeekByClick() {
    getWeekStartAndEnd(back_back_w);
    back_back_w = back_back_w - 1;
  }

  // 0 current -1 up 1 next week
  function getWeekStartAndEnd(AddWeekCount) { 
  //起止日期数组  
    let startStop = new Array(); 
    //一天的毫秒数  
    let millisecond = 1000 * 60 * 60 * 24; 
    //获取当前时间  
    let currentDate = new Date();
    //相对于当前日期AddWeekCount个周的日期
    currentDate = new Date(currentDate.getTime() + (millisecond * 7*AddWeekCount));
    //返回date是一周中的某一天
    let week = currentDate.getDay(); 
    //返回date是一个月中的某一天  
    let month = currentDate.getDate();
    //减去的天数  
    let minusDay = week != 0 ? week - 1 : 6; 
    //获得当前周的第一天  
    let currentWeekFirstDay = new Date(currentDate.getTime() - (millisecond * minusDay)); 
    //获得当前周的最后一天
    let currentWeekLastDay = new Date(currentWeekFirstDay.getTime() + (millisecond * 6));
    let a = currentWeekFirstDay.format('yyyy-MM-dd');
    let b = currentWeekLastDay.format('yyyy-MM-dd');

    document.getElementById('datestart').value= a; 
    document.getElementById('dateend').value=b;
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
% use Encode qw(decode_utf8);

<!-- coding and design and dev by ywang, 862024320@qq.com, 2022-10-14 -->
<!--div>
    <form action="/testupload" enctype="multipart/form-data" method="post">
    <input type="file" id="files" name="files">
        <input type="submit" value="up">
    </form>
</div-->

<p style="text-align: center; font-size: 1.5em; color: red;">
  <h4 id="tmp_alert" style="text-align: center; font-weight: bold; color: red;"></h4>
</p>

% my $user = $c->stash('user');
% my $year = $c->stash('year');
% my $month = $c->stash('month');
% my $day = $c->stash('day');

<p style="text-align: center; font-size: 0.8em;">
  <button type="button" style="margin: 0px; padding:0px; border: 0px; background-color: white;" onclick="change_goal_time(document.getElementById('timeleft_goal').value)">
    to
  </button>
  <input type="date" id="timeleft_goal" value="2022-12-23"/>
  <span id="timeleft_status">x</span>
  : 
  <span id="timeleft_day" style="color: #EED711;">0</span> d 
  <span id="timeleft_hour" style="color: #3366FF;">0</span> h 
  <span id="timeleft_min" style="color: #44BFFC;">0</span> m 
  <span id="timeleft_sec" style="color: #FFD711;">0</span> s 
</p>
<script type='text/javascript'>
  var status = '';
  function get_timeleft() {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", '/<%= $user %>/timeleft', true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = () => {
      if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
        let data = xhr.responseText;
        if (data != "0") {
          let timeleft_arrs = data.split(";");
          status = timeleft_arrs[0];
          document.getElementById('timeleft_status').innerText = timeleft_arrs[0];
          document.getElementById('timeleft_goal').value = timeleft_arrs[1];
          document.getElementById('timeleft_day').innerText = timeleft_arrs[2];
          document.getElementById('timeleft_hour').innerText = timeleft_arrs[3];
          document.getElementById('timeleft_min').innerText = timeleft_arrs[4];
          document.getElementById('timeleft_sec').innerText = timeleft_arrs[5];
        }
      }
    }
    xhr.send();

  }

  window.onload = function() {
    get_timeleft();
    setInterval(function(){
      get_timeleft();
    }, 10*1000);

    setInterval(function(){
      if (document.getElementById('timeleft_sec').innerText != '0'){
        if(status == 'remain'){
          document.getElementById('timeleft_sec').innerText = document.getElementById('timeleft_sec').innerText - 1;
        }
        if(status == 'past'){
          document.getElementById('timeleft_sec').innerText = parseInt(document.getElementById('timeleft_sec').innerText) + 1;
        }
      }
    }, 1000);
  }

  function change_goal_time(date) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", '/<%= $user %>/timeleft/set/'+date, true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = () => {
      if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
        location.reload();
      }
    }
    xhr.send();
  }
</script>

<p style="text-align: center; font-size: 1.5em;">
  <span style="font-weight: bold;">
  <%= $c->stash('user') %>&nbsp;&nbsp;
  </span>
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
  <br>
  % if ($c->stash('user') eq 'ywang') {
    <a href="/<%= $c->stash('user') %>/adduser">adduser</a>
  % }
</p>

<div style="margin: 5px; padding: 5px; border: 1px solid #333; height: 70px;">
  <!--fieldset>
    <legend>Title</legend>
  </fieldset-->
  <form action="/set_ic" method="post" style="font-size: 1.5em;">
    <div style="display: none">
      <input type="text" name="user" value="<%= $c->stash('user') %>">
    </div>
    <div>
      <label for="icname" style="width: 100px;">ic : </label>
      <input type="text" name="icname" id="icname" required style="width: calc(100% - 55px);">
    </div>
    <!--div>
      <label for="ic" style="width: 100px;">Enter ic: </label>
      <input type="text" name="ic" id="ic" value="<%= $c->stash('ic') %>" required style="width: calc(100% - 110px);">
    </div-->
    <div style="float: right;">
      <input type="submit" value="submit ic!">
    </div>
  </form>

  <script type="text/javascript">
  </script>
</div>


<div style="margin: 5px; padding: 5px; border: 1px solid #333; height: 100px;">
  <form action="/set_oc" method="post" style="font-size: 1.5em;">
    <div style="display: none">
      <input type="text" name="user" value="<%= $c->stash('user') %>">
    </div>
    <div>
      <label for="ocname" style="width: 100px;">oc : </label>
      <input type="text" name="ocname" id="ocname" required style="width: calc(100% - 55px);">
    </div>
    <div>
    <span style="font-size: 0.8em; color: gray;" onclick="document.getElementById('ocname').value = '早饭'">早饭</span>
    <span style="font-size: 0.8em; color: gray;">|</span>
    <span style="font-size: 0.8em; color: gray;" onclick="document.getElementById('ocname').value = '午饭'">午饭</span>
    <span style="font-size: 0.8em; color: gray;">|</span>
    <span style="font-size: 0.8em; color: gray;" onclick="document.getElementById('ocname').value = '晚饭'">晚饭</span>
    <span style="font-size: 0.8em; color: gray;">|</span>
    <span style="font-size: 0.8em; color: gray;" onclick="document.getElementById('ocname').value = '零食饮料'">零食饮料</span>
    <span style="font-size: 0.8em; color: gray;">|</span>
    <span style="font-size: 0.8em; color: gray;" onclick="document.getElementById('ocname').value = '永辉'">永辉</span>
    <span style="font-size: 0.8em; color: gray;">|</span>
    <span style="font-size: 0.8em; color: gray;" onclick="document.getElementById('ocname').value = '水果'">水果</span>
    </div>
    <!--div>
      <label for="oc" style="width: 100px;">Enter oc: </label>
      <input type="text" name="oc" id="oc" required style="width: calc(100% - 110px);">
    </div-->
    <div style="float: right;">
      <input type="submit" value="submit oc!">
    </div>
  </form>
  <script type="text/javascript">
  </script>
</div>

<div style="position: relative; margin: 5px; padding: 5px; border: 1px solid #333;">
  <p style="font-size: 1.5em;"><span style="font-weight: bold;">today record:</span><br>
  </p>
  <!--%== $c->stash('user_today_oc_content') %-->
  % foreach(@{$c->stash('user_today_oc_content_arrs_ref')}) {
    % my $uuid_8 = $_->{'uuid8'};
    <span id="<%= $uuid_8 %>"><%== decode_utf8( $_->{'content'} ) . ' : ' . $_->{'price'} . ' ' . $_->{'time'} %></span>
    % my $upload_files_number = `ls ./kadata/$user/$year/$month/oc$day\_EPC | grep '$uuid_8' | wc -l`;
    % chomp($upload_files_number);
    <span style="color: pink;"><%= $upload_files_number == 0 ? $upload_files_number : $upload_files_number %></span>
    <div>
      <form name="<%= $uuid_8 %>" action="/upload_file" enctype="multipart/form-data" method="post" onsubmit="setDisabled('<%= $uuid_8 %>')">
        <div style="display: none">
          <input type="text" name="user" value="<%= $c->stash('user') %>">
        </div>
        <div style="display: none">
          <input type="text" name="year" value="<%= $c->stash('year') %>">
        </div>
        <div style="display: none">
          <input type="text" name="month" value="<%= $c->stash('month') %>">
        </div>
        <div style="display: none">
          <input type="text" name="day" value="<%= $c->stash('day') %>">
        </div>
        <div style="display: none">
          <input type="text" name="uuid8" value="<%= $uuid_8 %>">
        </div>
        <div style="display: none">
          <input type="text" name="content_as_file_name" value="<%= decode_utf8( $_->{'content'} ) %>">
        </div>
        <div>
          <label for="ocname">EPC: </label>
          <input type="file" id="files" name="files">
        </div>
        <div style="float: right;">
          <input id="<%= $uuid_8 %>" type="submit" value="up!">
          % if ($upload_files_number != 0) {
            <a href="/show_record_files/<%= $user %>/<%= $year %>/<%= $month %>/<%= $c->stash('day') %>/oc<%= $day %>_EPC/<%= $uuid_8 %>">Preview</a>
          % }
        </div>
      </form>
    </div>
    <hr>
  % }
  <script type="text/javascript">
    function setDisabled(name) {
      for (let element of document.getElementsByTagName('input')) {
        element.style.display = 'none';
      }
      for (let element of document.getElementsByTagName('a')) {
        element.style.pointerEvents = 'none';
        element.style.color = 'gray';
        //element.disabled = true;
      }
      document.getElementById('tmp_alert').innerText = 'wait...files uploading.';
      document.getElementById(name).innerText = document.getElementById(name).innerText + '<uploading...>';
      document.getElementById(name).style.color = 'red';
    }
  </script>
  <br>
  today oc: <%== $c->stash('user_today_oc_all') %>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">month all oc:</span><br>
  </p>
  <%== $c->stash('user_month_oc_all') . ' , avg: ' . sprintf("%.3f", $c->stash('user_month_oc_all') / $day) . ' $' %>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">ic&nbsp;-&nbsp;oc&nbsp;=&nbsp;:</span><br>
  </p>
  <%== $c->stash('user_month_ic_all') .' - '. $c->stash('user_month_oc_all') . ' = ' . $c->stash('user_month_remain_ic') %>
  <br>
  <%== 'oc without ic avg: ' . sprintf("%.3f", $c->stash('user_month_oc_without_ic') / $day) . ' $' %>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">ic detail:</span><br>
  </p>
  <%== $c->stash('user_month_ic_content') %>

  <p style="font-size: 1.5em;"><span style="font-weight: bold;">month oc detail:</span><br>
  </p>
  <%== $c->stash('user_month_oc_content') %>
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
      p {
        margin: 0px;
        margin-bottom: 3px;
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
2022-10-17 zengjia le xing zeng yonghu de dongneng
2022-10-19 jiang base64 encode change to md5 encode
2022-10-24 method and style
2022-10-25 zengjia wenjian shagnchuan EPC(Electronic Payment Voucher)
2022-10-31 zengjia lishi oc jilu de preview alink
2022-11-03 file format update[price tag]
2023-01-12 session check added
# coding
# design
# dev
# by ywang 862024320@qq.com
-->
