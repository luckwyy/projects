#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Data::Dumper;
use Mojo::JSON qw(encode_json decode_json);
use Encode qw(decode_utf8 encode_utf8);
use Mojo::JSON qw(encode_json decode_json to_json);
# set request max limit size
BEGIN {
    $ENV{MOJO_MAX_MESSAGE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_BUFFER_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_LEFTOVER_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    $ENV{MOJO_MAX_LINE_SIZE} = 2 * 1024 * 1024 * 1024; # 2 GB
    
};
#######################################################################

my $datadir = './data';
my $account = "$datadir/account.txt";
my $data = {};
init();

sub init {
  `mkdir $datadir` unless -d "$datadir";
  unless (-e "$account") {
    `touch $account;`;
    `echo "admin,admin\nadmin2,admin2" > $account;`;
  }
  foreach my $line (split "\n", `cat $account`) {
    my $user = $1 if $line =~ m/^(.*),/; 
    my $userdir = "$datadir/$user";
    my $userdir_imgs = "$datadir/$user/imgs";
    `mkdir -p $userdir_imgs` unless -d "$userdir_imgs";
    my $userdir_txts = "$datadir/$user/txts";
    `mkdir -p $userdir_txts/ic` unless -d "$userdir_txts/ic";
    `mkdir -p $userdir_txts/oc` unless -d "$userdir_txts/oc";
    foreach (split "\n", `ls $userdir_txts/ic`) {
      my $key = $1 if $_ =~ m/(\d{4}-\d{2})/;
      $data->{$user}->{'ic'}->{$key} = decode_json(`cat $userdir_txts/ic/$_`);
    }
    foreach (split "\n", `ls $userdir_txts/oc`) {
      my $key = $1 if $_ =~ m/(\d{4}-\d{2}-\d{2})/;
      $data->{$user}->{'oc'}->{$key} = decode_json(`cat $userdir_txts/oc/$_`);
    }
    $data->{$user} = {} if !defined $data->{$user};
  }
}

sub datetime {
  my $datetime = `date +\%F\\ \%T`;
  chomp $datetime;
  return $datetime;
};

sub date {
  return $1 if datetime() =~ m/(.*) /;
};

sub uid8 {
  return $1 if `uuidgen` =~ m/(.*?)-/;
};

sub userdata {
  my ($user) = @_;
  return $data->{$user};
};

sub data_freeze {
  my ($user, $ic_oc, $key) = @_;
  my $json = encode_json($data->{$user}->{$ic_oc}->{$key});
  open(my $out, ">",  "$datadir/$user/txts/$ic_oc/$key.txt") or die "Can't open output.txt: $!";
  print $out $json;
  close $out or die "$out: $!";
};

sub check_pwd {
  my ($user, $pwd) = @_;
  foreach my $line (split "\n", `cat $account`) {
    if ($line eq "$user,$pwd") {
      return 1;
    }
  }
  return 0;
};

sub check {
  my ($c, $user) = @_;
  return 0 if !defined $user or $user eq '';
  return 0 if !defined $c->session('user');
  return 0 if $c->session('user') ne $user;
  return 0 if !defined userdata($c->session('user'));
  return 1;
};

sub check_balance {
  my $s = shift;
  return 0 unless defined $s;
  return 1 if $s =~ m/^[0-9]+([.]{1}[0-9]+){0,1}$/;
  return 0;
};

sub toFixed3 {
  my $number = shift;
  return sprintf("%.3f", $number);
};

sub month_days {
    my $yearmonth = shift;
    my $days = 1;
    my $date = "$yearmonth-02";
    while ($date !~ m/01$/) {
        $date = `date\ -d\ '$date +1day'\ +\%F`;
        chomp $date;
        $days += 1;
    }
    return $days;
};

sub month_start_end {
  my ($ym) = @_;
  $ym = `date +\%Y-\%m` if !defined $ym;
  chomp $ym;
  my $start = "$ym-01";
  my $end = `date -d "$start +1 month -1 day" +\%F`;
  chomp $end;
  return [$start, $end];
};

get '/' => sub ($c) {
  $c->render(text => 'error');
};

get '/login/:user/:pwd' => sub ($c) {
  my $user = $c->stash('user');
  my $pwd = $c->stash('pwd');
  if (check_pwd($user, $pwd)) {
    $c->session(user => $user);
    $c->session(date => date());
    $c->session(expiration => 24*60*1000);
    $c->redirect_to("/$user");
  } else {
    $c->redirect_to('/');
  }
};

get '/:user/recent_info' => sub ($c) {
  my $user = $c->stash('user');
  if (!check($c, $user)) {
    $c->session(expires => 1);
    $c->redirect_to('/');
    return;
  }
  my $oc = $data->{$user}{'oc'};
  my $recent_info = [];
  my @sort_keys = reverse sort keys %$oc;
  foreach (0..6) {
      if (defined $sort_keys[$_] and defined $oc->{$sort_keys[$_]}) {
          push @$recent_info, {$sort_keys[$_] => $oc->{$sort_keys[$_]}};
      }
  }

  $c->render(json => $recent_info);
};

get '/statistic' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->redirect_to('/');
    return;
  }

  my ($start, $end)  = @{month_start_end()};

  $c->stash(start => $start);
  $c->stash(end => $end);
  $c->render(template => 'statistic');
};

get '/:user' => sub ($c) {
  my $user = $c->stash('user');
  if (!check($c, $user)) {
    $c->session(expires => 1);
    $c->redirect_to('/');
    return;
  }

  my $date = date();
  my $yearmonth = $1 if $date =~ m/^(.*)-\d{2}$/;
  my $month_days = month_days($yearmonth);
  my $day = $1 if $date =~ m/^.*-(\d{2})$/;
  my $month_info = {'all_oc'=>0, 'all_ic'=>0, 'avg'=>0, 'pre'=>0};
  my $oc = $data->{$user}{'oc'};
  my $ic = $data->{$user}{'ic'};
  foreach (keys %$oc) {
    if ($_ =~ m/^$yearmonth-\d{2}$/) {
      foreach my $uid8 (keys %{$oc->{$_}}) {
        $month_info->{'all_oc'} += $oc->{$_}{$uid8}{'balance'} if $oc->{$_}{$uid8}{'is_deleted'} == 0;
      }
    }
  }
  if (defined $ic->{$yearmonth}) {
    foreach my $uid8 (keys %{$ic->{$yearmonth}}) {
      $month_info->{'all_ic'} += $ic->{$yearmonth}{$uid8}{'balance'} if $ic->{$yearmonth}{$uid8}{'is_deleted'} == 0;
    }
  }
  my $avg = toFixed3($month_info->{'all_oc'}/$day);
  $month_info->{'avg'} = "($month_info->{'all_oc'}/$day=) $avg";
  $month_info->{'pre'} = "($avg*$month_days=) ".toFixed3($avg*$month_days);

  $c->stash(date => date());
  $c->stash(month_info => $month_info);
  $c->render(template => 'index');
};

post '/record' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->render(text=>404);
    return;
  }
  my $params = $c->req->params->to_hash;
  my $tags = $params->{'tags'};
  my $nice_balance = $params->{'nice'};
  my $type = $params->{'type'};

  my $date = date();
  my $date_without_day = $1 if $date =~ m/(.*)-\d{2}$/;
  my $ic_oc = $type == 1 ? 'oc' : 'ic';
  my $key = $type == 1 ? $date : $date_without_day;

  my ($nice, $balance) = ($1, $2) if $nice_balance =~ m/^(.*?)(\d+\.{0,1}\d*)$/;
  $nice = '' if !defined $nice or $nice =~ m/^ *$/;
  if (!check_balance($balance) or ($tags eq '' and $nice eq '')) {
    $c->redirect_to("/$user");
    return;
  }
  my $uid8 = uid8();
  my $hash = {
    'uid8' => $uid8,
    'nice' => $nice,
    'balance' => $balance,
    'tags' => $tags,
    'create_time' => datetime(),
    'update_time' => datetime(),
    'is_deleted' => 0
  };
  $data->{$user}->{$ic_oc}->{$key}->{$uid8} = $hash;
  data_freeze($user, $ic_oc, $key);

  $c->redirect_to("/$user");
  return;
};

post '/del' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->render(text=>404);
    return;
  }
  my $params = $c->req->params->to_hash;
  my $uid8 = $params->{'uid8'};
  my $date = $params->{'date'};

  my $ic_oc = 'ic';
  $ic_oc = 'oc' if defined $data->{$user}{'oc'}{$date}{$uid8};
  if (defined $data->{$user}{$ic_oc}{$date}{$uid8}) {
    $data->{$user}{$ic_oc}{$date}{$uid8}{'is_deleted'} = 1;
    $data->{$user}{$ic_oc}{$date}{$uid8}{'update_time'} = datetime();
    data_freeze($user, $ic_oc, $date);
  }
  $c->render(text=>1);
  return;
};

post '/epc' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->redirect_to("/");
    return;
  }
  my $params = $c->req->params->to_hash;
  my $uid8 = $params->{'uid8'};
  foreach my $file (@{$c->req->uploads}) {
    my $filename = $file->{'filename'};
    my $name = $file->{'name'};
    if ($filename ne '') {
      my $current_time = datetime();
      my $N = `date +%N`; # for the current upload file unique
      chomp $N;
      my $file_type = $1 if $filename =~ m/\.(.*?)$/;
      my $fn1 = "$uid8\_$current_time\_$N\.$file_type";
      # save file
      $file->move_to("$datadir/$user/imgs/$fn1");
    }
  }
  $c->redirect_to("/$user");
};

get '/files/:uid8' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->redirect_to("/");
    return;
  }
  
  my $uid8 = $c->stash('uid8');
  my $files = `ls '$datadir/$user/imgs' | grep '$uid8'`;
  $files = [ split("\n", $files) ];

  if (@$files == 0) {
    $c->redirect_to("/$user");
    return;
  }
  
  $c->stash(files => $files);
  $c->render(template => 'files');
};

get '/files_number/:uid8' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->render(text => -1);
    return;
  }

  my $uid8 = $c->stash('uid8');
  my $files = `ls '$datadir/$user/imgs' | grep '$uid8'`;
  $files = [ split("\n", $files) ];

  $c->render(text => scalar @$files);
};

get '/watch/#name' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->redirect_to("/");
    return;
  }
  my $name = $c->stash('name');
  
  $c->reply->file("$datadir/$user/imgs/$name");
};

post '/find' => sub ($c) {
  my $user = $c->session('user');
  if (!check($c, $user)) {
    $c->render(json => {error => -1});
    return;
  }

  my $params = $c->req->params->to_hash;

  if ($params->{'start'} !~ m/\d{4}-\d{2}-\d{2}/ or 
  $params->{'end'} !~ m/\d{4}-\d{2}-\d{2}/ or !check_balance($params->{'limit'})) {
    $c->render(json => {error => 0});
    return;
  }

  if ($params->{'start'} gt $params->{'end'}) {
    my $tmp_ = $params->{'start'};
    $params->{'start'} = $params->{'end'};
    $params->{'end'} = $tmp_;
  }

  my $key = $params->{'key'};
  $key =~ s/ +/|/g;
  my $oc = $data->{$user}{'oc'};
  my $recent_info = [];
  my @sort_keys = reverse sort keys %$oc;
  foreach (0..(scalar @sort_keys - 1)) {
    if (defined $sort_keys[$_] and defined $oc->{$sort_keys[$_]}) {
      last if $sort_keys[$_] lt $params->{'start'};
      next if $sort_keys[$_] gt $params->{'end'};
      if ($sort_keys[$_] ge $params->{'start'} and $sort_keys[$_] le $params->{'end'}) {
        my $hash = {};
        $hash->{$sort_keys[$_]} = {};
        foreach my $uid8 (keys %{$oc->{$sort_keys[$_]}}) {
          if ($oc->{$sort_keys[$_]}->{$uid8}->{'balance'} >= $params->{'limit'}) {
            if ($key eq "" or $oc->{$sort_keys[$_]}->{$uid8}->{'nice'} =~ m/$key/ or 
            $oc->{$sort_keys[$_]}->{$uid8}->{'tags'} =~ m/$key/) {
              $hash->{$sort_keys[$_]}->{$uid8} = $oc->{$sort_keys[$_]}->{$uid8} 
              if $oc->{$sort_keys[$_]}->{$uid8}->{'is_deleted'} != 1;
            }
          }
        }
        push @$recent_info, $hash;
      }
    }
  }

  $c->render(json => $recent_info);
};

any '/*' => sub ($c) {
  $c->render(text => 'error');
};

app->start;
__DATA__

@@ files.html.ep
% layout 'default';
% title 'files';
% my $files = $c->stash('files');

% foreach (@{$files}) {
  <img style="width: 100%;" src="/watch/<%= $_ %>">
  <hr style="width: 20rem; margin: 0 auto; margin-top: .3rem; margin-bottom: .3rem;">
% }

@@ statistic.html.ep
% layout 'default';
% title 'statistic';
% my $date = $c->session('date');
% my $start = $c->stash('start');
% my $end = $c->stash('end');

<div>
  <label>从（包含）</label>
  <input style="width: 100%;" type="date" id="start" value="<%= $start %>"><br>
  <label>至（包含）</label>
  <input style="width: 100%;" type="date" id="end" value="<%= $end %>"><br>
  <label>关键词（多关键字空格分隔）</label>
  <input style="width: 100%;" type="text" id="key" value=""><br>
  <label>金额限制</label>
  <input style="width: 100%;" type="text" id="limit" value="0"><br>
  <button id="find" style="margin-top: .3rem; width: 100%; height: 2rem;" type="button" onclick="find()">查询</button>
</div>

<div style="margin: .5rem 0rem 0rem .3rem;">
  <p>查询总：<span id="find-all"></span>$</p>
</div>

<div id="main" style="margin: .5rem 0rem 0rem .3rem;">
</div>

<script>
  $(document).ready(function() {
    $('#find').trigger('click');
  });
</script>

<script>
  function find() {
    $('#main').empty();
    $.ajax({
      url: '/find',
      type: "POST",
      data: {
        'start': $('#start').val(),
        'end': $('#end').val(),
        'key': $('#key').val(),
        'limit': $('#limit').val(),
      },
      success: function(res) {
        $('#main').empty();
        if (res['error'] == 0) $('#main').append("参数错误");
        if (res['error'] == -1) location.href="/";
        if (!res['error'] && res['error'] != 0) {
          let ocall = 0;
          $.each(res, function(idx, data2) {
            $.each(data2, function(day, data3) {
              let div = $('<div></div>');
              let content_arr = [];
              $.each(data3, function(uid8, content) { // 这里是遍历hash uid8是key content是对应的内容
                content_arr.push(content);
              });
              content_arr = sortByKey(content_arr, 'create_time');
              let day_oc = 0;
              $.each(content_arr, function(i, content) {
                let text = content['nice']+'['+content['tags']+'] : '+content['balance']+' $, '+content['create_time'].substring(11);
                text += '<span class="recent-watch-files" onclick="watch(`'+content['uid8']+'`)">查看</span>';
                let p = $('<p class="recent-content"></p>');
                if (i == content_arr.length-1) p = $('<p class="recent-content last-recent-content"></p>');
                p.append(text);
                div.append(p);
                day_oc += parseFloat(content['balance']);
              });
              day_oc = day_oc.toFixed(3);
              ocall += parseFloat(day_oc);
              if (day_oc != 0) {
                div.prepend('<p class="recent-title">'+day+' ['+day_oc+'$]:</p>');
                $('#main').append(div);
              }
            });
          });
          ocall = ocall.toFixed(3);
          $('#find-all').text(ocall);
        }
      }
    });
  }
</script>

@@ index.html.ep
% layout 'default';
% title 'e2';
% my $month_info = $c->stash('month_info');

<!-- input -->
<div id="input-div" style="margin: 1rem .3rem 0rem .3rem;">
  <label class="expend-label" style="background-color: lightgray; padding: 0 .3rem 0 .3rem;"><span id="type">支出</span>:&nbsp;</label>
  <form action="/record" method="POST" >
    <p style="overflow: hidden; background-color: gray;">
      <input id="expend" name="nice" class="nice" type="text" required>
      <input id="type-input" name="type" type="text" value="1" style="display: none;">
      <input id="tags-input" name="tags" type="text" value="" style="display: none;">
    </p>
    <button class="submit" type="submit">提交</button>
  </form>
  <div id="tags-div" style="margin-top: .3rem;">
  </div>
  <div style="clear: both;"></div>
</div>

<!-- msg -->
<div style="margin: 1rem .3rem 0rem .3rem; background-color: rgb(240, 240, 240);">
  <div style="box-sizing: border-box; border-bottom: 1px dotted black; width: 100%; height: 9rem; padding: .3rem 0 0 .3rem;">
    <p style="font-size: 1.2rem; font-weight: bold; margin-bottom: .2rem;">当月:</p>
    <p style="border-left: 1px solid black; padding-left: .3rem; margin-bottom: .1rem;">总支出:&nbsp;<span><%= $month_info->{'all_oc'} %></span>$</p>
    <p style="border-left: 1px solid black; padding-left: .3rem; margin-bottom: .1rem;">总退入:&nbsp;<span><%= $month_info->{'all_ic'} %></span>$</p>
    <p style="border-left: 1px solid black; padding-left: .3rem; margin-bottom: .1rem;">每日平均:&nbsp;<span><%= $month_info->{'avg'} %></span>$</p>
    <p style="border-left: 1px solid black; padding-left: .3rem; margin-bottom: .1rem;">总支预计:&nbsp;<span><%= $month_info->{'pre'} %></span>$</p>
  </div>
  <div style="box-sizing: border-box; width: 100%; padding: .3rem 0 0 .3rem;">
    <p style="font-size: 1.2rem; font-weight: bold; margin-bottom: .2rem;">最近记录:</p>
    <div id="index-recent">
      <div>
        <p class="recent-title">03-22(200$):</p>
        <p class="recent-content">nice content[tags] : 123$ yyyy-mm-dd]</p>
      </div>
    </div>
  </div>
</div>

<script>
  $(document).ready(function() {
    set_tags();
    type_click();
    recent_info();
  });

  function recent_info() {
    $.get('/<%= $user %>/recent_info', function(data) {
      $('#index-recent').empty();
      $.each(data, function(idx, data2) {
        $.each(data2, function(day, data3) {
          let div = $('<div></div>');
          let content_arr = [];
          $.each(data3, function(uid8, content) {
            if (content['is_deleted'] != 1) content_arr.push(content);
          });
          content_arr = sortByKey(content_arr, 'create_time');
          let day_oc = 0;
          $.each(content_arr, function(i, content) {
            let text = content['nice']+'['+content['tags']+'] : '+content['balance']+' $, '+content['create_time'].substring(11);
            if (recent_3day(content['create_time'])) text += '<span class="recent-delete" onclick="del(`'+day+'`,`'+content['uid8']+'`,`'+text+'`)">删除</span>';
            text += '<span class="recent-watch-files" onclick="watch(`'+content['uid8']+'`)">查看</span>';
            if (recent_1month(content['create_time'])) {
              text += `<form action="/epc" method="POST" enctype="multipart/form-data">
              <input style="width: 10rem;" type="file" name="file">
              <input type="hidden" name="uid8" value="`+content['uid8']+`">
              <button style="float: right;" type="submit">上传</button>
              </form>`;
            }
            let p = $('<p class="recent-content"></p>');
            if (i == content_arr.length-1) p = $('<p class="recent-content last-recent-content"></p>');
            p.append(text);
            div.append(p);
            day_oc += parseFloat(content['balance']);
          });
          day_oc = day_oc.toFixed(3);
          if (idx == 0) {
            if ('<%= $date %>' == day) {
              div.prepend('<p class="recent-title" style="font-size: 1.2rem;">今日 ['+day_oc+'$]:</p>');
            } else {
              div.prepend('<p class="recent-title">'+day+' ['+day_oc+'$]:</p>');
              div.prepend('<p class="recent-title" style="font-size: 1.2rem;">今日暂无记录</p>');
            }
          } else {
            div.prepend('<p class="recent-title">'+day+' ['+day_oc+'$]:</p>');
          }
          $('#index-recent').append(div);
        });
      });
    });
  }

  function del(date, uid8, text) {
    let r = confirm("确定删除?： \n"+text);
    if (r) {
      let r2 = confirm("再次确认");
      if (r2) {
        $.ajax({
          url: '/del',
          type: "POST",
          data: {
            'date': date,
            'uid8': uid8
          },
          success: function(response) {
            if (response == 1) {
              location.href="/<%= $user %>";
            } else {
              location.href="/";
            }
          }
        });
      }
    }
  }

  function get_tags() {
    let tags = '';
    $("#tags-div").children().each(function() {
      if ($(this).hasClass('color-gray')) tags += $(this).text()+',';
    });
    $('#tags-input').val(tags);
  }

  function tag_click(id) {
    if ($('#'+id).hasClass('color-gray')) {
      $('#'+id).addClass('color-black');
      $('#'+id).removeClass('color-gray');
      get_tags();
    } else {
      $('#'+id).addClass('color-gray');
      $('#'+id).removeClass('color-black');
      get_tags();
    }
  }

  function type_click() {
    $('#type').parent().click(function() {
      if ($('#type').text() == '支出') {
        $('#type').text('退入');
        $('#type-input').val('0');
      } else {
        $('#type').text('支出');
        $('#type-input').val('1');
      }
    });
  }

  function set_tags() {
    let str = '早饭 午饭 晚饭 吃饭 小吃 零食 饮料 永辉 超市 水果 天猫超市 京东 淘宝 拼多多 加油 中石油 中石化 加油卡 信用卡 农行';
    let arr = str.split(' ');
    $.each(arr, function(idx, e){
      $('#tags-div').append('<div id="tag-'+idx+'" class="tag-div color-black" onclick="tag_click(`tag-'+idx+'`)"><p>'+e+'</p></div>');
    });
  }
  
  function recent_1month(date) {
    if (dateToTimestamp(date) > (Math.floor(Date.now() / 1000)-31*24*60*60)) {
      return true;
    }
    return false;
  }

  function recent_3day(date) {
    if (dateToTimestamp(date) > (Math.floor(Date.now() / 1000)-3*24*60*60)) {
      return true;
    }
    return false;
  }

  function dateToTimestamp(dateString) {
    var timestamp = Date.parse(dateString);
    return timestamp / 1000;
  }
</script>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="zh-CN">
<html>
  <head>
  <meta charset="UTF-8">
  <meta name="author" content="whileu1@gmail.com"/>
  <meta name="format-detection" content="telphone=no, email=no, address=no"/>
  <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge,chrome=1">
  <link rel="icon" type="image/png" href="/icon.png">
  <link rel="stylesheet" href="" />
  <title><%= title %></title>
  <style>
    * {
      margin: 0px;
      padding: 0px;
    }

    html {
      font-size : 14px;
      font-family: 'Times New Roman';
    }

    .title {
      box-sizing: border-box;
      position: fixed;
      background-color: rgb(240, 240, 240);
      width: 100%;
      height: 5rem;
      line-height: 5rem;
      top: 0rem; 
      border-bottom: 1px solid rgb(235, 235, 235);
    }
    .title-span-1 {
      font-size: 1.3rem;
      margin-left: .5rem;
      text-transform: uppercase;
    }
    .title-span-2 {
      margin-left: .1rem;
      font-size: 0.9rem;
    }
    .title a {
      float: right;
      margin-left: .5rem;
      margin-right: .5rem;
      font-size: 1.1rem;
    }

    .tag-div {
      box-sizing: border-box;
      float: left;
      width: 25%; 
      height: 2rem;
      line-height: 2rem;
      text-align: center; 
      background-color: rgb(240, 240, 240);
      margin-top: .1rem;
      border: .1rem solid white;
      border-radius: 0.1rem;
    }
    .tag-div p {
      light-height: 2rem;
    }
    .submit {
      width: 100%; 
      height: 2rem; 
      border: none; 
      font-weight: bold;
      font-size: 1rem;
      margin-top: .3rem;
    }

    .float-left {
      float: left;
    }

    .nice {
      box-sizing: border-box;
      display: inline-box;
      width: 100%;
      height: 2rem;
      border-left: none;
      border-radius: 0px;
      font-size: 1.1rem;
    }
    .expend-label {
      float: left;
      font-size: 1.2rem;
      line-height: 2rem;
    }

    .color-gray {
      color: gray;
    }

    .color-black {
      color: black;
    }

    .border-error {
        border: 1px solid red;
    }
    .recent-title{
      font-size: 1.1rem; 
      font-weight: bold; 
      margin-bottom: .1rem; 
      margin-left: .2rem;
    }
    .recent-content{
      margin-bottom: .1rem; 
      margin-left: .3rem; 
      border-left: 1px dotted black; 
      border-bottom: 1px dotted black; 
      padding-left: .2rem;
      color: rgb(20, 20, 20);
    }
    .last-recent-content {
      border-bottom: 1px solid black; 
    }
    .recent-delete {
      color: #C42B1E;
      font-size: .9rem;
      margin-left: .3rem; 
    }
    .recent-watch-files {
      color: rgb(0, 0, 210);
      font-size: .9rem;
      margin-left: .3rem;
      text-decoration: none;
    }

  </style>

  
  </head>
  <body>
  <script src="jquery-3.6.0.min.js"></script>
  <script>
    function sortByKey(array , key){
      return array.sort(function(a, b){
        var x = a[key];
        var y = b[key];
        return ((x<y) ? -1 : ((x>y) ? 1 : 0));
      });
    }

    function watch(uid8) {
      $.get('/files_number/'+uid8, function(data) {
        if (data == -1) location.href="/";
        if (data == 0) alert('没有文件');
        if (data > 0) location.href="/files/"+uid8;
      });
    }
  </script>

  % my $user = $c->session('user');
  % my $date = $c->session('date');
  <!-- head -->
  <p class="title" style="">
    <span class="title-span-1"><%= $user %></span>
    <span class="title-span-2"><%= $date %></span>
    <a href="/<%= $user %>">主页</a>
    <a href="/statistic">统计</a>
    <a onclick="history.back()">返回</a>
  </p>
  <div style="margin-top: 5.2rem;">
  </div>
  <%= content %>
  </body>
</html>
