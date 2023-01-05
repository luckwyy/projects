#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Data::Dumper;use utf8;
use Encode qw(decode_utf8);
use Time::Piece;
use Time::Seconds;

# input format: 2022-12-12
sub calc_tgdz {
  my $date = shift;

  my ($y, $m, $d) = ($1, $2, $3) if $date =~ m/(.*)-(.*)-(.*)/;

  my @tg = ('甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸');
  my @dz = ('子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥');

  my $y_tg = $tg[(($y-3) % 10) - 1];
  my $y_dz = $dz[(($y-3) % 12) - 1];

  return {
    tgdz => $y_tg . $y_dz,
    };
};

# input format: 2022-12-11 2022-12-12
sub calc_main {
  my $fir = shift;
  my $sec = shift;
  
  # say $fir, $sec;
  my $total_days = 0;

  my $FORMAT = '%Y-%m-%d';
  my $start = $fir;
  my $end   = $sec;
  my $start_t = Time::Piece->strptime( $start, $FORMAT );
  my $end_t   = Time::Piece->strptime( $end,   $FORMAT );
  
  while ( $start_t <= $end_t ) {
    $total_days += 1;
    $end_t -= ONE_DAY;
  }

  my $fir_UTC_secs = `date -d '$fir' +%s`;
  my $sec_UTC_secs = `date -d '$sec' +%s`;
  chomp $fir_UTC_secs;
  chomp $sec_UTC_secs;

  my ($fir_week_idx_inyear, $fir_day_idx_inweek, $fir_day_idx_inyear) = ($1, $2, $3) if `date -d '$fir' +%W-%u-%j` =~ m/(.*)-(.*)-(.*)/;
  my ($sec_week_idx_inyear, $sec_day_idx_inweek, $sec_day_idx_inyear) = ($1, $2, $3) if `date -d '$sec' +%W-%u-%j` =~ m/(.*)-(.*)-(.*)/;

  return {
    inter_days => $total_days,
    fir_UTC_secs => $fir_UTC_secs,
    sec_UTC_secs => $sec_UTC_secs,
    fir_week_idx_inyear => $fir_week_idx_inyear,
    fir_day_idx_inweek => $fir_day_idx_inweek,
    fir_day_idx_inyear => $fir_day_idx_inyear,
    sec_week_idx_inyear => $sec_week_idx_inyear,
    sec_day_idx_inweek => $sec_day_idx_inweek,
    sec_day_idx_inyear => $sec_day_idx_inyear,
  };
};

get '/' => sub ($c) {
  $c->render(template => 'index');
};

get '/date' => sub ($c) {
  $c->render(template => 'date');
};

post '/api/calc_date' => sub ($c) {
  my $fir_date = $c->param('fir_date');
  my $sec_date = $c->param('sec_date');

  if($sec_date eq '') {
    $sec_date = `date +%Y-%m-%d`;
    chomp $sec_date;
  }
  
  if ($fir_date gt $sec_date) {
    my $tmp = $fir_date;
    $fir_date = $sec_date;
    $sec_date = $tmp;
  }

  my $single_date_flag = 0;
  $single_date_flag = 1 if $fir_date eq $sec_date;

  my $msg = 'no msg';
  my $fir_date_info_hash = {};
  my $sec_date_info_hash = {};
  my $main_info = {};

  my $tgdz = calc_tgdz($fir_date);
  $main_info = calc_main($fir_date, $sec_date);
  $main_info->{tgdz} = $tgdz->{tgdz};

  my ($fir_y, $fir_m, $fir_d) = ($1, $2, $3) if $fir_date =~ m/(.*)-(.*)-(.*)/;
  my ($sec_y, $sec_m, $sec_d) = ($1, $2, $3) if $sec_date =~ m/(.*)-(.*)-(.*)/;
  $fir_date_info_hash->{fir_y} = $fir_y;
  $fir_date_info_hash->{fir_m} = $fir_m;
  $fir_date_info_hash->{fir_d} = $fir_d;
  $sec_date_info_hash->{sec_y} = $sec_y;
  $sec_date_info_hash->{sec_m} = $sec_m;
  $sec_date_info_hash->{sec_d} = $sec_d;

  $c->flash(fir_date => $fir_date);
  $c->flash(fir_date_info_hash => $fir_date_info_hash);
  $c->flash(sec_date => $sec_date);
  $c->flash(sec_date_info_hash => $sec_date_info_hash);
  $c->flash(single_date_flag => $single_date_flag);
  $c->flash(msg => $msg);
  $c->flash(main_info => $main_info);

  $c->redirect_to('date');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1 style="font-size: 2rem; height: 4rem;">Welcome to the Mojolicious real-time web framework1!</h1>

@@ date.html.ep
% layout 'default';
% title 'calc date';

% my $fir_date = $c->flash('fir_date');
% $fir_date = `date +%Y-%m-%d` if !defined $fir_date; chomp($fir_date);
% my $fir_date_info_hash = $c->flash('fir_date_info_hash');
% my $sec_date = $c->flash('sec_date');
% my $sec_date_info_hash = $c->flash('sec_date_info_hash');
% my $msg = $c->flash('msg');
% my $single_date_flag = $c->flash('single_date_flag');
% my $main_info = $c->flash('main_info');

<div style="position: relative; width: 100%; height: 300px; border: 1px solid gray; border-radius: 5px;">
  <form action="/api/calc_date" method="post">
    <div style="margin-bottom: 32px;">
      <label for="name" style="font-size: 2rem;">First date: </label>
      <input type="date" name="fir_date" id="fir_date" style="position: absolute; right: 0px; font-size: 2rem;" value="<%= $fir_date %>" required>
    </div>
    <div style="margin-bottom: 32px;">
      <label for="name" style="font-size: 2rem;">Second date: </label>
      <input type="date" name="sec_date" id="sec_date" style="position: absolute; right: 0px; font-size: 2rem;" value="<%= $sec_date %>">
    </div>
    <div class="div_mt_20 div_mb_20" style="position: absolute; right: 0px;">
      <input id="submit" type="submit" value="submit!" style="font-size: 2rem;">
    </div>
  </form>
</div>
<hr>
<hr>
<hr>

% if (defined $msg) {
  <div style="width: 100%; height: 100%; border: 1px solid gray; border-radius: 5px; font-size: 1.5rem;">
  % if (defined $single_date_flag and $single_date_flag) {
    <p style="text-align: center;">
    <%= $main_info->{tgdz} %><span id="single_lunal"></span><br>
    是<%= $fir_date_info_hash->{fir_y} %>年第<%= $main_info->{'fir_week_idx_inyear'} %>周，周<%= $main_info->{'fir_day_idx_inweek'} %>，本年第<%= $main_info->{'fir_day_idx_inyear'} %>天（周一为起始计）
    </p>
    </p>
    <hr>
    <p style="text-align: center;">
    <%= $fir_date %> 0时UTC秒数为<%= $main_info->{'fir_UTC_secs'} %>
    </p>
  % }
  % if (defined $single_date_flag and !$single_date_flag) {
    <p style="text-align: center;">
    <%= $fir_date %>至<%= $sec_date %>间隔<%= $main_info->{'inter_days'} %>天（包括<%= $fir_date_info_hash->{fir_d} %>号和<%= $sec_date_info_hash->{sec_d} %>号）
    </p>
    <hr>
    <p style="text-align: center;">
    <%= $fir_date %>是<span id="fir_date_lunal"></span>
    <br>
    是<%= $fir_date_info_hash->{fir_y} %>年第<%= $main_info->{'fir_week_idx_inyear'} %>周，周<%= $main_info->{'fir_day_idx_inweek'} %>，本年第<%= $main_info->{'fir_day_idx_inyear'} %>天（周一为起始计）
    </p>
    <hr>
    <p style="text-align: center;">
    <%= $sec_date %>是<span id="sec_date_lunal"></span><br>
    是<%= $sec_date_info_hash->{sec_y} %>年第<%= $main_info->{'sec_week_idx_inyear'} %>周，周<%= $main_info->{'sec_day_idx_inweek'} %>，本年第<%= $main_info->{'sec_day_idx_inyear'} %>天（周一为起始计）
    </p>
    <hr>
    <p style="text-align: center;">
    <%= $fir_date %> 0时UTC秒数为<%= $main_info->{'fir_UTC_secs'} %>
    </p>
    <hr>
    <p style="text-align: center;">
    <%= $sec_date %> 0时UTC秒数为<%= $main_info->{'sec_UTC_secs'} %>
    <br>
    相差<%= $main_info->{'sec_UTC_secs'} - $main_info->{'fir_UTC_secs'} %>
    </p>
    <hr>
  % }
  </div>
% }

<script src="./lunarFun.js"></script>
<script type="text/javascript">
  let fir_y = '<%= $fir_date_info_hash->{fir_y} %>';
  let fir_m = '<%= $fir_date_info_hash->{fir_m} %>';
  let fir_d = '<%= $fir_date_info_hash->{fir_d} %>';

  let sec_y = '<%= $sec_date_info_hash->{sec_y} %>';
  let sec_m = '<%= $sec_date_info_hash->{sec_m} %>';
  let sec_d = '<%= $sec_date_info_hash->{sec_d} %>';

  % if (defined $single_date_flag and $single_date_flag) {
      if (fir_y) {
        window.onload = function() {
          let tmp = lunarFun.gregorianToLunal(fir_y, fir_m, fir_d);
          if (tmp[2] < 10) {
            tmp[2] = '初' + tmp[2];
          }
          document.getElementById('single_lunal').innerText = '农历'+tmp[0]+'年'+tmp[1]+'月'+tmp[2];
        }
      }
  % }

  % if (defined $single_date_flag and !$single_date_flag) {
      if (fir_y && sec_y) {
        window.onload = function() {
          let tmp = lunarFun.gregorianToLunal(fir_y, fir_m, fir_d);
          let tmp2 = lunarFun.gregorianToLunal(sec_y, sec_m, sec_d);
          if (tmp[2] < 10) {
            tmp[2] = '初' + tmp[2];
          }
          document.getElementById('fir_date_lunal').innerText = '农历'+tmp[0]+'年'+tmp[1]+'月'+tmp[2];
          if (tmp2[2] < 10) {
            tmp2[2] = '初' + tmp2[2];
          }
          document.getElementById('sec_date_lunal').innerText = '农历'+tmp2[0]+'年'+tmp2[1]+'月'+tmp2[2];
        }
      }
  % }
</script>





@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
  <title><%= title %></title>
  <style>
  html {
    font-size: 24px;
    width: 100%;
    height: 100%;
  }

  .div_mt_20 {
    margin-top: 20px;
  }

  .div_mb_20 {
    margin-bottom: 20px;
  }

  .float_right {
    float: right;
  }
  </style>
  </head>
  <body><%= content %></body>
</html>
