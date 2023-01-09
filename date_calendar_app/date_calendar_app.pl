#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Data::Dumper;use utf8;
use Encode qw(decode_utf8);
use Time::Piece;
use Time::Seconds;




my $note_dir = './day_note';

sub get_datetime {
  my $datetime = `date +%Y-%m-%d,%H:%M:%S`;
  $datetime =~ s/,/ /g;
  chomp $datetime;
  return $datetime;
};

sub calc_today_relative {
  my $date = shift;
  my ($y, $m, $d) = ($1, $2, $3) if $date =~ m/(.*)-(.*)-(.*)/;

  my @month_days = ();

  my $prev_date = $date;
  while($d != 1) {
    $prev_date = `date -d "$prev_date -1 day" +%y-%m-%d`;
    chomp $prev_date;
    $d = $1 if $prev_date =~ m/.*-.*-(.*)/;
  }
  # push(@month_days, '01');
  $prev_date = `date -d "$prev_date -1 day" +%y-%m-%d`;
  while(1) {
    $prev_date = `date -d "$prev_date +1 day" +%y-%m-%d`;
    chomp $prev_date;
    $d = $1 if $prev_date =~ m/.*-.*-(.*)/;
    my $week_day = `date -d "$prev_date" +%W`;
    chomp $week_day;

    my $tmp_y = `date -d "$prev_date" +%Y`;
    chomp $tmp_y;
    my $tmp_m = `date -d "$prev_date" +%m`;
    chomp $tmp_m;
    my $tmp_d = `date -d "$prev_date" +%d`;
    chomp $tmp_d;
    my $file_path = "$note_dir/$tmp_y-$tmp_m-$tmp_d.txt";

    my $content_flag = 0;
    $content_flag = 1 if -e $file_path;

    my $flag_m = $1 if $prev_date =~ m/.*-(.*)-.*/;
    if ($flag_m != $m) {
      last;
    }
    push(@month_days, [$d, $week_day, $content_flag]);
  }
  # @month_days = sort @month_days;

  return {
    month_days => \@month_days,
  };
};

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

# calculate 
sub calc_secs_from_now_to_goal {
  my $date = shift;

  my $now_utc_secs = `date +%s`;
  chomp $now_utc_secs;
  
  my $date_utc_secs = `date -d "$date" +%s`;
  chomp $date_utc_secs;

  return $date_utc_secs - $now_utc_secs;
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

  my $today_relative = calc_today_relative($fir_date);

  my $to_goal_utc_secs = calc_secs_from_now_to_goal($sec_date);

  $c->flash(fir_date => $fir_date);
  $c->flash(fir_date_info_hash => $fir_date_info_hash);
  $c->flash(sec_date => $sec_date);
  $c->flash(sec_date_info_hash => $sec_date_info_hash);
  $c->flash(single_date_flag => $single_date_flag);
  $c->flash(msg => $msg);
  $c->flash(main_info => $main_info);
  $c->flash(today_relative => $today_relative);
  $c->flash(to_goal_utc_secs => $to_goal_utc_secs);

  $c->redirect_to('date');
};

post '/query/:y/:m/:d' => sub ($c) {
  my $y = $c->stash('y');
  my $m = $c->stash('m');
  my $d = $c->stash('d');

  `mkdir $note_dir` unless -d $note_dir;

  my $file_path = "$note_dir/$y-$m-$d.txt";
  `touch $file_path` unless -e $file_path;

  my $content = "no note";
  $content = `cat $file_path`;
  chomp $content;

  my $content_ = '';
  my $dt_ = '';
  if ($content eq '') {
    $content = 'no note';
  } else {
    my @content = split('\[br:/br\]', $content);
    $content_ = decode_utf8($1) if $content[-1] =~ m/\[note:(.*)\/note\]/;
    $dt_ = $1 if $content[-1] =~ m/\[datetime:(.*)\/datetime\]/;
  }

  $c->render(json => {content => $content_, dt => $dt_});
};

post '/add/:y/:m/:d' => sub ($c) {
  my $y = $c->stash('y');
  my $m = $c->stash('m');
  my $d = $c->stash('d');

  my $note = decode_utf8($c->req->body_params->{'string'});

  `mkdir $note_dir` unless -d $note_dir;

  my $file_path = "$note_dir/$y-$m-$d.txt";
  `touch $file_path` unless -e $file_path;

  my $datetime = get_datetime();
  `echo '[note:$note/note]' [datetime:$datetime/datetime] [br:/br] >> $file_path`; #使用 ' ' 单引号 ， linux中单引号会当成字符串

  $c->render(text => '1');
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
% my $today_relative = $c->flash('today_relative');
% my $to_goal_utc_secs = $c->flash('to_goal_utc_secs');

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
    <hr>
      <p style="text-align: center;">
      <%= $fir_date_info_hash->{fir_y} . '-' . $fir_date_info_hash->{fir_m} %>
      </p>
      % my $day_idx = 0;
      % foreach my $day(@{$today_relative->{month_days}}) {
        % $day_idx += 1;
        % my $background_color = 'white';
        % $background_color = 'LightSkyBlue' if $day->[0] == $fir_date_info_hash->{fir_d};
        <span style="margin-left: 3.3rem; background-color: <%= $background_color %>" onclick="set_note('<%= $fir_date_info_hash->{fir_y} %>', '<%= $fir_date_info_hash->{fir_m} %>', this.innerText)">
          % if ($day->[2]) {
              <b><%= $day->[0] %></b>
          % } else {
              <%= $day->[0] %>
          % }
        </span>
        % if ($day_idx % 7 == 0) {
          <hr style="width: 80%; height: 1rem;">
        % }
      % }
  % }
  % if (defined $single_date_flag and !$single_date_flag) {
    <p style="text-align: center;">
    <%= $fir_date %>至<%= $sec_date %>间隔<%= $main_info->{'inter_days'} %>天（包括<%= $fir_date_info_hash->{fir_d} %>号和<%= $sec_date_info_hash->{sec_d} %>号）
    </p>
    <hr>
    <p style="text-align: center;">
      <span>距<%= $sec_date %> 0时<span id="utc_count_flag"></span></span>
      <br>
      <b style="font-size: 3rem;" id="utc_count_day">
      10
      </b>天
      <span style="font-size: 3rem;" id="utc_count_hh">
      10
      </span>小时
      <span style="font-size: 3rem;" id="utc_count_mm">
      10
      </span>分钟
      <span style="font-size: 3rem;" id="utc_count_ss">
      10
      </span>秒
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

<script src="./jquery-3.6.3.min.js"></script>
<script src="./lunarFun.js"></script>
<script type="text/javascript">

  $(document).ready(function() {
    % if (defined $single_date_flag and !$single_date_flag) {
        let secs = '<%= $to_goal_utc_secs %>';
        setInterval(function(){
          secs -= 1;
          let day = parseInt(secs / (24*60*60));
          let hh = parseInt((secs - day * 24*60*60) / (60*60));
          let mm = parseInt((secs - day * 24*60*60 - hh*60*60) / (60));
          let ss = parseInt((secs - day * 24*60*60 - hh*60*60 - mm*60));

          if (secs < 0) {
            $('#utc_count_flag')[0].innerText = '已过';
            $('#utc_count_day')[0].innerText = Math.abs(day);
            $('#utc_count_hh')[0].innerText = Math.abs(hh);
            $('#utc_count_mm')[0].innerText = Math.abs(mm);
            $('#utc_count_ss')[0].innerText = Math.abs(ss);
            document.getElementById('utc_count_day').style = "font-size: 3rem; color: green;";
            document.getElementById('utc_count_hh').style = "font-size: 3rem; color: green;";
            document.getElementById('utc_count_mm').style = "font-size: 3rem; color: green;";
            document.getElementById('utc_count_ss').style = "font-size: 3rem; color: green;";
          } else {
            $('#utc_count_flag')[0].innerText = '还有';
            $('#utc_count_day')[0].innerText = day;
            $('#utc_count_hh')[0].innerText = hh;
            $('#utc_count_mm')[0].innerText = mm;
            $('#utc_count_ss')[0].innerText = ss;
          }
        }, 1000);
    % }
  });

  $(document).ready(function() {
    if (document.getElementById('sec_date').value == '') {
      $('#submit').click(); // when document loaded, auto submit once.
    }
  });

  function set_note(y, m, day) {
    // query
    const xhr = new XMLHttpRequest();
    xhr.open("POST", '/query/'+y+'/'+m+'/'+day, false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = () => {
      if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
        //let data = xhr.responseText;
        eval("var data="+xhr.responseText);
        let note=prompt(data.dt, data.content);
        if (note!=null && note!="")
        {
          // send set note
          const xhr2 = new XMLHttpRequest();
          xhr2.open("POST", '/add/'+y+'/'+m+'/'+day, false);
          xhr2.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
          
          xhr2.send(note);
        }
      }
    }
    xhr.send();

  }


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
