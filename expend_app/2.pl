#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Data::Dumper;
use Encode qw(decode_utf8);

# set request max limit size
BEGIN {
    $ENV{MOJO_MAX_MESSAGE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_BUFFER_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_LEFTOVER_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_LINE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    
};
############## global var ################
my $app_data_path = './expenditure_record';
`mkdir $app_data_path` unless -d $app_data_path;
my $expenditure_dir = "$app_data_path/main";
my $valid_user_file = "$app_data_path/valid_user.rec";
my $new_line_sign = '<ENTER-POINT>';

sub convert_one_to_two_number {
    my $d = shift;
    return "0$d" if $d < 10 and $d !~ m/^0/;
    return $d;
};

sub get_unique_uuid_8 {
  my $uuid8 = $1 if `uuidgen` =~ m/(.*?)-/;
  return $uuid8;
};

sub get_datetime {
  my $command = 'date +%Y-%m-%d\ %H:%M:%S';
  my $linux_current_time = `$command`;
  chomp $linux_current_time;
  return $linux_current_time;
};

sub get_YmdMHS_hash {
  my $command = 'date +%Y-%m-%d\ %H:%M:%S';
  my $linux_current_time = `$command`;
  my ($y, $m, $d, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6) if $linux_current_time =~ m/(.*)-(.*)-(.*) (.*):(.*):(.*)/;
  my $hash = {'y' => $y, 'm' => $m, 'd' => $d, 'hh' => $hh, 'mm' => $mm, 'ss' => $ss, 'ymd' => "$y-$m-$d"};
  return $hash;
};

# get txt content and return array with line
sub get_txt_content_lines {
  my ($path) = @_;
  my @arrs = ();
  if (-e $path) {
    my $content = `cat $path`;
    @arrs = split '\n', $content;
  }
  return \@arrs;
};

sub append_line_info_to_txt {
  my ($content, $path) = @_;
  `touch $path` unless -e $path;
  $content =~ s/\n/$new_line_sign/g;
  open(my $log, ">>", $path) or die "Can't open $!";
  say $log $content;
  close $log or die "$log: $!";
  return 1;
};

# this sub will overflow the path with the content
sub write_all_info_to_txt {
  my ($content, $path) = @_;
  `touch $path` unless -e $path;
  open(my $log, ">", $path) or die "Can't open $!";
  print $log $content;
  close $log or die "$log: $!";
  return 1;
};

sub get_write_valid_user_line_info {
  my ($user, $pwd) = @_;
  my $time = get_datetime();
  my $uid8 = get_unique_uuid_8();
  my $res = "[uid8:$uid8:uid8]";
  $res .= "[user-$uid8:$user:user-$uid8]";
  $res .= "[pwd-$uid8:$pwd:pwd-$uid8]";
  $res .= "[create_time-$uid8:$time:create_time-$uid8]";
  $res .= "[update_time-$uid8:$time:update_time-$uid8]";
  return $res;
};

sub get_write_one_expend_record_line_info {
  my ($nice, $balance, $tags) = @_;
  my $time = get_datetime();
  my $uid8 = get_unique_uuid_8();
  my $is_deleted = 0;
  my $res = "[uid8:$uid8:uid8]";
  $res .= "[nice-$uid8:$nice:nice-$uid8]";
  $res .= "[balance-$uid8:$balance:balance-$uid8]";
  $res .= "[tags-$uid8:$tags:tags-$uid8]";
  $res .= "[create_time-$uid8:$time:create_time-$uid8]";
  $res .= "[update_time-$uid8:$time:update_time-$uid8]";
  $res .= "[is_deleted-$uid8:$is_deleted:is_deleted-$uid8]";
  return $res;
};

sub check_user_valid {
  my ($user) = @_;
  my $flag = 0;
  unless(-e $valid_user_file) {
    append_line_info_to_txt(get_write_valid_user_line_info('ywang', 'token_str'), $valid_user_file);
    append_line_info_to_txt(get_write_valid_user_line_info('moshan', 'moshan1'), $valid_user_file);
  }
  my $arrs = get_txt_content_lines($valid_user_file);
  foreach(@$arrs){
    my $tmp_uid8 = $1 if $_ =~ m/\[uid8:(.*?):uid8\]/;
    if ($_ =~ m/\[user-$tmp_uid8:$user:user-$tmp_uid8\]/) {
      $flag = 1;
      last;
    }
  }
  return $flag;
};

sub check_user_pwd {
  my ($user, $pwd) = @_;
  my $flag = 0;
  return $flag unless -e $valid_user_file;
  my $content_arrs = get_txt_content_lines($valid_user_file);
  foreach my $line (@$content_arrs) {
    my $tmp_uid8 = $1 if $line =~ m/\[uid8:(.*?):uid8\]/;
    if ($line =~ m/\[user-$tmp_uid8:$user:user-$tmp_uid8\]/) {
      if ($line =~ m/\[pwd-$tmp_uid8:$pwd:pwd-$tmp_uid8\]/) {
        $flag = 1;
        last;
      }
    }
  }
  return $flag;
};

sub check_login {
  my ($c) = @_;
  my $flag = 0;
  $flag = 1 if defined $c->session('login') and $c->session('login') == 1;
  return $flag;
};

sub check_user_session {
  my ($c, $user) = @_;
  my $flag = 0;
  $flag = 1 if defined $c->session('login') and $c->session('login') == 1 and $c->session('user') eq $user;
  return $flag;
};

sub check_nice_content {
  my $s = shift;
  my $tags = shift;
  my $flag = 0;
  $flag = 1 if $s !~ m/^ *$/;
  $flag = 1 if $s eq "" and $tags =~ m/.*,$/;
  return $flag;
};

sub check_nice_balance {
  my $s = shift;
  my $flag = 0;
  $flag = 1 if $s =~ m/^[0-9]+([.]{1}[0-9]+){0,1}$/;
  return $flag;
};

sub analysis_ic_oc_line_info {
  my $line = shift;
  my $hash = {};
  $hash->{'uid8'} = $1 if $line =~ m/\[uid8:(.*?):uid8\]/;
  my $tmp_uid8 = $1 if $line =~ m/\[uid8:(.*?):uid8\]/;
  $hash->{'nice'} = decode_utf8($1) if $line =~ m/\[nice-$tmp_uid8:(.*?):nice-$tmp_uid8\]/;
  $hash->{'balance'} = $1 if $line =~ m/\[balance-$tmp_uid8:(.*?):balance-$tmp_uid8\]/;
  $hash->{'tags'} = decode_utf8($1) if $line =~ m/\[tags-$tmp_uid8:(.*?):tags-$tmp_uid8\]/;
  $hash->{'create_time'} = $1 if $line =~ m/\[create_time-$tmp_uid8:(.*?):create_time-$tmp_uid8\]/;
  $hash->{'update_time'} = $1 if $line =~ m/\[update_time-$tmp_uid8:(.*?):update_time-$tmp_uid8\]/;
  $hash->{'is_deleted'} = $1 if $line =~ m/\[is_deleted-$tmp_uid8:(.*?):is_deleted-$tmp_uid8\]/;
  return $hash;
};

# input: expend_record file path output: [ { a=>aa, b=>bb}, {} ]
sub get_one_expend_record_file_hash {
  my ($user, $file) = @_;
  my $res = {};
  $res->{'detail'} = [];
  $res->{'analysis'} = {};

  if ($file =~ m/[io]c\d{0,2}\.rec$/) {
    my $arrs = get_txt_content_lines($file);
    foreach(@$arrs) {
      my $line_hash = analysis_ic_oc_line_info($_);
      push(@{$res->{'detail'}}, $line_hash) if $line_hash->{'is_deleted'} ne '1'; # only get not deleted line info
    }
    if(scalar @{$res->{'detail'}} != 0 ) {
      $res->{'analysis'} = get_one_expend_record_file_hash_analysis($user, $res->{'detail'});
    }
  }

  return $res;
};

sub get_one_expend_record_file_hash_analysis {
  my ($user, $arrs) = @_;
  my $res = {};

  my $total_balance = 0;
  foreach(@$arrs){
    $total_balance += $_->{'balance'};
    $res->{'ymd'} = $1 if $_->{'create_time'} =~ m/(.*) \d+:\d+:\d+/;
    # add the line epcs info
    $_->{'epcs'} = get_the_line_epcs_info($user, $res->{'ymd'}, $_->{'uid8'});
  }
  $res->{'total_balance'} = $total_balance;

  return $res;
};

sub get_the_line_epcs_info {
  my ($user, $ymd, $uid8) = @_;
  my ($y, $m, $d) = ($1, $2, $3) if $ymd =~ m/(.*)-(.*)-(.*)/;
  my $hash = {};
  my $epcs_dir = "$expenditure_dir/$user/$y/$m/epcs";

  if(-d $epcs_dir) {
    my $number = `ls $epcs_dir | grep '$uid8' | wc -l`;
    chomp $number;
    $hash->{'number'} = $number;
    if ($number != 0) {
      my $names = `ls $epcs_dir | grep '$uid8'`;
      my @names = split('\n', $names);
      $hash->{'names'} = \@names;
    }
    $hash->{'names'} = [] if $number == 0;
  } else {
    $hash->{'number'} = 0;
    $hash->{'names'} = [];
  }

  return $hash;
};

# write one record, param: user year month day content balance $nice_type
sub write_one_line_expend_record {
  my ($user, $y, $m, $d, $nice, $balance, $tags, $nice_type) = @_;

  my $day_content_path = "$expenditure_dir/$user/$y/$m";
  `mkdir -p $day_content_path` unless -d $day_content_path;
  my $record_file = "$day_content_path/oc$d.rec";
  $record_file = "$day_content_path/ic.rec" if $nice_type == 1;
  
  my $info = get_write_one_expend_record_line_info($nice, $balance, $tags);
  append_line_info_to_txt($info, $record_file);

  return;
};

sub get_input_month_expend_info {
  my ($user, $year, $month) = @_;

  my $res = {};
  $res->{'oc_month'} = {};

  my $days = 31;
  my $ic_file_path = "$expenditure_dir/$user/$year/$month/ic.rec";

  $res->{'ic'} = get_one_expend_record_file_hash($user, $ic_file_path);

  while($days > 0) {
    my $flag = `date -d $year-$month-$days +%s`;
    if ($flag =~ m/^\d+$/) {
      $days = convert_one_to_two_number($days);
      my $file_path = "$expenditure_dir/$user/$year/$month/oc$days.rec";
      my $hash = get_one_expend_record_file_hash($user, $file_path);
      $res->{'oc'}->{"$days"} = $hash;
      if(scalar @{$hash->{'detail'}} != 0) {
        $res->{'oc_month'}->{'total_balance'} += $hash->{'analysis'}->{'total_balance'};
      }
    }
    $days -= 1;
  }
  
  # say Dumper $res;
  return $res;
};

# get relative date interval
sub get_interval_date {
    my ($start, $end) = @_;
    if (defined $end) {
        if($start gt $end) {
            my $tmp = $start;
            $start = $end;
            $end = $tmp;
        }
        $end = `date -d "$end +1 day" +\%Y-\%m-\%d`;
        chomp $end;
    } else {
        # only year
        if ($start =~ m/^\d{4}$/) {
            my $next_year = int($start) + 1;
            $start = "$start-01-01";
            $end = "$next_year-01-01";
        } elsif ($start =~ m/^\d{4}-\d{2}$/) {
            $start = "$start-01";
            $end = `date -d "$start +1 month" +\%Y-\%m-\%d`;
            chomp $end;
        } elsif ($start =~ m/^\d{4}-\d{2}-\d{2}$/) {
            $end = `date -d "$start +1 day" +\%Y-\%m-\%d`;
            chomp $end;
        }
    }
    return $start, $end;
};
# common sub for get input date expend_info
sub get_input_self_adption_date_expend_info {
    my ($user, $start, $end) = @_;
    ($start, $end) = get_interval_date($start, $end);
    my $res = {};
    $res->{'oc_conclusion'} = {};
    $res->{'ic_conclusion'} = {};
    while($start ne $end){
        $end = `date -d "$end -1 day" +\%Y-\%m-\%d`;
        chomp $end;
        my ($year, $month, $day) = ($1, $2, $3) if $end =~ m/(.*)-(.*)-(.*)/;
        my $file_path = "$expenditure_dir/$user/$year/$month/oc$day.rec";
        my $hash = get_one_expend_record_file_hash($user, $file_path);
        $res->{$year}->{$month}->{'oc'}->{$day} = $hash;
        if(scalar @{$hash->{'detail'}} != 0) {
            $res->{'oc_conclusion'}->{'total_balance'} += $hash->{'analysis'}->{'total_balance'};
        }

        $file_path = "$expenditure_dir/$user/$year/$month/ic.rec";
        $hash = get_one_expend_record_file_hash($user, $file_path);
        $res->{$year}->{$month}->{'ic'} = $hash;
        # if(scalar @{$hash->{'detail'}} != 0) {
        #     $res->{'ic_conclusion'}->{'total_balance'} += $hash->{'analysis'}->{'total_balance'};
        # }
    }
    return $res;
};

sub clear_rec {
  my $path = shift;
  open(my $log, ">", $path) or die "Can't open $!";
  close $log or die "$log: $!";
};

# delete one line info
sub delete_expend_one_line {
  my ($user, $year, $month, $day, $file_type, $uid8) = @_;
  my $file_path = "$expenditure_dir/$user/$year/$month/oc$day.rec";
  $file_path = "$expenditure_dir/$user/$year/$month/ic.rec" if $file_type eq 'ic';
  return unless -e $file_path;

  my $content = `cat $file_path`;
  $content =~ s/\[is_deleted-$uid8:0:is_deleted-$uid8\]/\[is_deleted-$uid8:1:is_deleted-$uid8\]/;
  my $deleted_time = get_datetime();
  $content =~ s/\[update_time-$uid8:(.*?):update_time-$uid8\]/\[update_time-$uid8:$deleted_time:update_time-$uid8\]/;
  write_all_info_to_txt($content, $file_path);
};

######################################################################################
# author: y
# Ctrl D
######################################################################################

get '/' => sub ($c) {
  $c->render(template => 'index');
};

get '/:user' => sub ($c) {
  my $user = $c->stash('user');
  unless (check_user_valid($user) and check_user_session($c, $user)) {
    $c->redirect_to("/");
    return;
  }
  my $YmdHMS = get_YmdMHS_hash();

#   my $ic_oc = get_input_month_expend_info($user, $YmdHMS->{'y'}, $YmdHMS->{'m'});
  #   say Dumper $ic_oc;
  my $adption = get_input_self_adption_date_expend_info($user, "$YmdHMS->{'y'}-$YmdHMS->{'m'}");
#   say Dumper $adption;

#   $c->stash(ic_oc => $ic_oc);
  $c->stash(adption => $adption);
  $c->stash(YmdHMS => $YmdHMS);
  $c->render(template=>'user');
};

get '/:user/pwd/:token_str' => sub ($c) {
  my $user = $c->stash('user');
  my $token_str = $c->stash('token_str');
  if (check_user_pwd($user, $token_str)) {
    $c->session->{'login'} = 1;
    $c->session->{'user'} = $user;
    $c->session(expiration => 7*24*60*60);
    $c->redirect_to("/$user");
  } else {
    $c->redirect_to("/");
  }
};

post '/nice_record' => sub ($c) {
  unless (check_login($c)) {
    $c->redirect_to("/");
    return;
  }
  my $user = $c->session->{'user'};
  my $nice_type = $c->param('nice_type');
  my $nice_tags = $c->param('nice_tags');
  my $nice = $c->param('nice');

  if ($nice_type !~ m/^[01]$/) {
    $c->flash(msg_color => 'red', msg => 'nice_type illegal changed');
    $c->redirect_to("/$user");
    return;
  }
  my ($nice_content, $nice_balance) = ($1, $2) if $nice =~ m/(.*?)(\d+\.{0,1}\d*)$/;

  unless (check_nice_content($nice_content, $nice_tags) and check_nice_balance($nice_balance)) {
    $c->flash(msg_color => 'red', msg => 'nice illegal');
    $c->redirect_to("/$user");
    return;
  }
  my $YmdHMS = get_YmdMHS_hash();
  write_one_line_expend_record($user, $YmdHMS->{'y'}, $YmdHMS->{'m'}, $YmdHMS->{'d'}, $nice_content, $nice_balance, $nice_tags, $nice_type);
  # logic
  $c->flash(msg_color => 'blue', msg => 'sucess');
  $c->redirect_to("/$user");
};

get '/delete_one_line_record/:ymd/:file_type/:uid8' => sub ($c) {
  unless (check_login($c)) {
    $c->redirect_to("/");
    return;
  }
  my $user = $c->session->{'user'};
  my $ymd = $c->stash('ymd');
  my ($y, $m, $d) = ($1, $2, $3) if $ymd =~ m/(.*)-(.*)-(.*)/;
  my $file_type = $c->stash('file_type');
  my $uid8 = $c->stash('uid8');

  delete_expend_one_line($user, $y, $m, $d, $file_type, $uid8);
  
  $c->redirect_to("/$user");
};

post '/upload_file/:ymd/:uid8' => sub ($c) {
  unless (check_login($c)) {
    $c->redirect_to("/");
    return;
  }
  my $user = $c->session->{'user'};
  my $ymd = $c->stash('ymd');
  my ($y, $m, $d) = ($1, $2, $3) if $ymd =~ m/(.*)-(.*)-(.*)/;
  my $uid8 = $c->stash('uid8');

  my $epcs_dir = "$expenditure_dir/$user/$y/$m/epcs";
  `mkdir -p $epcs_dir` unless -d $epcs_dir;
  foreach my $file (@{$c->req->uploads}) {
		my $filename = $file->{'filename'};
		my $name = $file->{'name'};
    if ($filename ne '') {
      my $current_time = get_datetime();
      my $N = `date +%N`; # for the current upload file unique
      chomp $N;
      my $file_type = $1 if $filename =~ m/\.(.*?)$/;
      # say $files_number;
      my $fn1 = "$d\_$uid8\_$current_time\_$N\.$file_type";
      # save file
      $file->move_to("$epcs_dir/$fn1");
    }
	}

  $c->redirect_to("/$user");
};

get '/show_epcs/:ymd/:uid8' => sub ($c) {
  unless (check_login($c)) {
    $c->redirect_to("/");
    return;
  }
  my $user = $c->session->{'user'};
  my $ymd = $c->stash('ymd');
  my ($y, $m, $d) = ($1, $2, $3) if $ymd =~ m/(.*)-(.*)-(.*)/;
  my $uid8 = $c->stash('uid8');

  my $epcs_dir = "$expenditure_dir/$user/$y/$m/epcs";

  my $epcs = {};

  if(-d $epcs_dir) {
    my $number = `ls $epcs_dir | grep '$uid8' | wc -l`;
    chomp $number;
    $epcs->{'number'} = $number;
    if ($number != 0) {
      my $names = `ls $epcs_dir | grep '$uid8'`;
      my @names = split('\n', $names);
      $epcs->{'names'} = \@names;
    }
    $epcs->{'names'} = [] if $number == 0;
  } else {
    $epcs->{'number'} = 0;
    $epcs->{'names'} = [];
  }

  $c->stash(ymd => $ymd);
  $c->stash(epcs => $epcs);
  $c->render(template => 'epcs_display');
};

get '/download_file/:ymd/#name' => sub ($c) {
  unless (check_login($c)) {
    $c->redirect_to("/");
    return;
  }
  my $user = $c->session->{'user'};
  my $ymd = $c->stash('ymd');
  my ($y, $m, $d) = ($1, $2, $3) if $ymd =~ m/(.*)-(.*)-(.*)/;
  my $name = $c->stash('name');

  my $epcs_dir = "$expenditure_dir/$user/$y/$m/epcs";

  $c->reply->file("$epcs_dir/$name");
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Index';
<h1>Index</h1>

@@ epcs_display.html.ep
% layout 'default';
% title 'epcs';

% my $ymd = $c->stash('ymd');
% my $epcs = $c->stash('epcs');

% if ($epcs->{'number'} != 0) {
  % foreach (@{$epcs->{'names'}}) {
    <img src="/download_file/<%= $ymd %>/<%= $_ %>" width="100%"/>
    <hr style="width: 300px; margin: 0 auto; margin-top: 5px; margin-bottom: 5px;">
    <hr style="width: 300px; margin: 0 auto; margin-top: 5px; margin-bottom: 5px;">
  % }
% }

@@ user.html.ep
% layout 'default';
% title 'nice';

% my $msg_color = $c->flash('msg_color');
% my $msg = $c->flash('msg');
% my $user = $c->stash('user');
% # my $ic_oc = $c->stash('ic_oc');
% my $adption = $c->stash('adption');
% my $YmdHMS = $c->stash('YmdHMS');

<p style="text-align: center; font-size: 0.8rem; width: 300px; height: 50px; margin: 0 auto; line-height: 50px;">
  <span style="color: <%= $msg_color %>"><%= $msg %></span>
</p>

<p style="text-align: center; font-size: 0.8rem;">
  <b style="text-transform: uppercase;"><%= $user %></b>&nbsp;&nbsp;<span><%= $YmdHMS->{'ymd'} %></span>
</p>
<hr style="width: 300px; margin: 0 auto; margin-top: 5px; margin-bottom: 5px;">

<p style="text-align: center; font-size: 0.8rem;">
  <a onclick="history.back()" style="color: blue;">go back</a>
   | 
  <a href="/<%= $c->session('user') %>">home</a>
</p>
<hr style="width: 300px; margin: 0 auto; margin-top: 5px; margin-bottom: 5px;">

<div style="height: 70px; padding: 0.3rem;">
  <form action="/nice_record" method="post">
    <div style="position: relative;">
      <div style="position: absolute; width: 20%;">
        <label style="height: 2rem; line-height: 2rem;" for="email" onclick="change_nicetype(this)">输出:</label>
      </div>
      <div style="position: absolute; width: 80%; margin-left: 20%;">
        <input type="hidden" name="nice_type" id="nice_type" value="0">
        <input type="hidden" name="nice_tags" id="nice_tags" value="">
        <input style="width: 100%; height: 2rem; font-size: 0.9rem;" type="text" name="nice" id="nice" required>
      </div>
    </div>
    <div style="position: relative;">
      <div style="position: absolute; width: 100%; margin-top: 2.2rem;">
        <input style="width: 100%; height: 1.5rem; background-color: gray;" type="submit" value="确认">
      </div>
    </div>
  </form>
</div>
<hr style="width: 300px; margin: 0 auto; margin-top: 5px; margin-bottom: 15px;">

<p style="width: 300px; margin: 0 auto; text-align: center; font-size: 0.9rem;">
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">早饭</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">午饭</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">晚饭</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">吃饭</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">小吃</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">零食</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">饮料</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">永辉</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">超市</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">水果</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">天猫超市</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">京东</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">淘宝</span> |
  <span style="color: black; margin: 0px 5px 0px 5px;" onclick="add_tags(this)">拼多多</span> |
</p>
<hr style="width: 100%; margin: 0 auto; margin-top: 5px;">
<hr style="width: 100%; margin: 0 auto; margin-top: 3px; margin-bottom: 15px;">

<div style="padding: 5px 5px 5px 5px; margin: 0px 5px 0px 5px; border: 0.5px solid black;">
  <p style="margin: 0 auto; font-size: 0.8rem;">
    <b>month detail: </b> <br>
      <span style="margin-left: 5px; padding-left: 3px; font-size: 0.7rem; border-left: 1px solid gray;">
      total oc : <%= $adption->{'oc_conclusion'}->{'total_balance'} %>
      </span> <br>
      <span style="margin-left: 5px; padding-left: 3px; font-size: 0.7rem; border-left: 1px solid gray;">
      total ic : <%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'ic'}->{'analysis'}->{'total_balance'} %>
      </span> <br>
      <span style="margin-left: 5px; padding-left: 3px; font-size: 0.7rem; border-left: 1px solid gray;">
      avg (<%= $adption->{'oc_conclusion'}->{'total_balance'} %> / <%= $YmdHMS->{'d'} %>) : 
      <%= sprintf("%.3f", $adption->{'oc_conclusion'}->{'total_balance'} / $YmdHMS->{'d'} ) %>
      </span> <br>
      <span style="margin-left: 5px; padding-left: 3px; font-size: 0.7rem; border-left: 1px solid gray;">
      avg ((<%= $adption->{'oc_conclusion'}->{'total_balance'} %> - <%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'ic'}->{'analysis'}->{'total_balance'} %>) / <%= $YmdHMS->{'d'} %>) : 
      <%= sprintf("%.3f", ($adption->{'oc_conclusion'}->{'total_balance'} - $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'ic'}->{'analysis'}->{'total_balance'}) / $YmdHMS->{'d'} ) %>
      </span> <br>
  </p>
  <hr style="width: 100%; margin: 0 auto; margin-top: 5px; margin-bottom: 5px; color: gray;">
  <p style="margin: 0 auto;">
    <b style="font-size: 0.8rem;">ic ( <%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'ic'}->{'analysis'}->{'total_balance'} %> $):</b> <br>
    % foreach( @{$adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'ic'}->{'detail'}} ){
      <span style="margin-left: 5px; padding-left: 3px; font-size: 0.7rem; border-left: 1px solid gray;">
      <%= $_->{'nice'} %> [<%= $_->{'tags'} %>] : <%= $_->{'balance'} %> <%= $_->{'create_time'} %>
      </span> 
      <a href="/delete_one_line_record/<%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'ic'}->{'analysis'}->{'ymd'} %>/ic/<%= $_->{'uid8'} %>"
      onclick="return(confirm('confirm?'))"
      ><span style="color: darkred; font-size: 0.6rem;">delete</span></a>
      <hr style="width: 100%; margin: 0 auto; margin-top: 5px; margin-bottom: 5px; color: gray;">
    % }
  </p>
  <hr style="width: 100%; margin: 0 auto; margin-top: 5px; margin-bottom: 5px; color: gray;">
  % foreach my $oc_key (reverse sort keys %{$adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'oc'}}) {
    % if ($oc_key <= $YmdHMS->{'d'}) {
      <p style="margin: 0 auto;">
        % if (scalar @{$adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'oc'}->{$oc_key}->{'detail'}} != 0) {
          <b style="font-size: 0.8rem;"><%= $oc_key %> ( <%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'oc'}->{$oc_key}->{'analysis'}->{'total_balance'} %> $):</b> <br>
          % foreach( @{$adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'oc'}->{$oc_key}->{'detail'}} ){
            <span style="margin-left: 5px; padding-left: 3px; font-size: 0.7rem; border-left: 1px solid gray;">
              <%= $_->{'nice'} %> [<%= $_->{'tags'} %>] : <%= $_->{'balance'} %> <%= $_->{'create_time'} %>
            </span>
            <a href="/delete_one_line_record/<%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'oc'}->{$oc_key}->{'analysis'}->{'ymd'} %>/oc/<%= $_->{'uid8'} %>"
            onclick="return(confirm('confirm?'))"
            ><span style="color: darkred; font-size: 0.6rem;">delete</span></a>
            % if ($_->{'epcs'}->{'number'} != 0) {
              <a href="/show_epcs/<%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'oc'}->{$oc_key}->{'analysis'}->{'ymd'} %>/<%= $_->{'uid8'} %>"
              ><span style="color: darkblue; font-size: 0.6rem;">preview_epcs_<%= $_->{'epcs'}->{'number'} %></span></a>
            % }
            % if ($oc_key == $YmdHMS->{'d'}) {
              <form name="<%= $_->{'uid8'} %>" style="font-size: 0.6rem;" action="/upload_file/<%= $adption->{$YmdHMS->{'y'}}->{$YmdHMS->{'m'}}->{'oc'}->{$oc_key}->{'analysis'}->{'ymd'} %>/<%= $_->{'uid8'} %>" enctype="multipart/form-data" method="post">
                <input type="file" id="files" name="files">
                <input id="<%= $_->{'uid8'} %>" type="submit" value="EPC UP!">
              </form>
            % }
            <hr style="width: 100%; margin: 0 auto; margin-top: 5px; margin-bottom: 5px; color: gray;">
          % }
        % } else {
          <b style="font-size: 0.8rem;"><%= $oc_key %> ( 0 $):</b> <br>
          <span style="margin-left: 5px; padding-left: 3px; font-size: 0.7rem; border-left: 1px solid gray;">
            null record.
          </span>
          <hr style="width: 100%; margin: 0 auto; margin-top: 5px; margin-bottom: 5px; color: gray;">
        % }
      </p>
    % }
  % }
</div>

<script>
  function change_nicetype(obj) {
    if (obj.innerText == '输出:') {
      obj.innerText = '输入:'
      document.getElementById('nice_type').value = 1;
    } else {
      obj.innerText = '输出:'
      document.getElementById('nice_type').value = 0;
    }
  }
  function add_tags(obj) {
    obj.style.color == 'gray' ? obj.style.color = 'black' : obj.style.color = 'gray';
    document.getElementById('nice_tags').value = "";
    for (let e of obj.parentNode.childNodes) {
      if (e.nodeName == 'SPAN') {
        if (e.style.color == 'gray') {
          document.getElementById('nice_tags').value += e.innerText + ',';
        }
      }
    }
  }
</script>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="zh-CN">
<html>
  <head>
  <meta charset="UTF-8">
  <meta name="author" content="ywang, wybzd019@gmail.com"/>
  <meta name="format-detection" content="telphone=no, email=no, address=no"/>
  <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge,chrome=1">
  <title><%= title %></title>
  <style>
    * {
      margin: 0px;
      padding: 0px;
    }

    a:hover, a:visited, a:link, a:active {
      color:  blue;
      text-decoration: none;
    }

    html {
      font-size : 20px;
      font-family: '方正舒体','Times New Roman', simsun, 微软雅黑;
    }
    
    @media only screen and (min-width: 401px){
        html {
            font-size: 25px !important;
        }
    }
    @media only screen and (min-width: 428px){
        html {
            font-size: 26.75px !important;
        }
    }
    @media only screen and (min-width: 481px){
        html {
            font-size: 30px !important; 
        }
    }
    @media only screen and (min-width: 569px){
        html {
            font-size: 35px !important; 
        }
    }
    @media only screen and (min-width: 641px){
        html {
            font-size: 40px !important; 
        }
    }
  </style>
  </head>
  <body><%= content %></body>
</html>
