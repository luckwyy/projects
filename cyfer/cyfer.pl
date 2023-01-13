#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Data::Dumper;
use utf8;
use Encode qw(decode_utf8);

sub get_all_musics {
  my $content = `ls ./listen`;
  my @musics = split( "\n", decode_utf8($content) );

  my $hash = {};
  my $idx = 1;
  foreach(@musics) {
    if($_ =~ m/mp3$/) {
      my $key = $1 if $_ =~ m/陈一发儿 - (.*).mp3/;
      $hash->{$key}->{'music_url'} = $_;
      $hash->{$key}->{'music_name'} = $key;
      $hash->{$key}->{'music_artist'} = '陈一发儿';
      $hash->{$key}->{'music_lrc'} = "陈一发儿 - $key.lrc";
    }
  }

  return $hash;

};

get '/' => sub ($c) {
  $c->render(template => 'index');
};

get '/link/#filename' => sub ($c) {
  my $filename = $c->stash('filename');
  $c->reply->file("./listen/$filename");
};

get '/listen' => sub ($c) {
  $c->stash(musics => get_all_musics());
  $c->render(template => 'listen');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome to the Mojolicious real-time web framework!</h1>
<a href="/listen">go to station</a>

@@ listen.html.ep
% layout 'default';
% title 'cyfer 67373';

% my $musics = $c->stash('musics');

<div>
  <p style="text-align: center; font-size: 1.5rem;">Cyfer music station</p>
</div>
<br>
<div id="aplayer"></div>

<div style="position: fixed; bottom: 0px; right: 0px; font-size: 0.627rem;">
  <a>dev @112.124.14.71</a> <br>
  <a href="#">supported by Aplayer</a>
</div>

<script src="./jquery-3.6.3.min.js"></script>
<script src="./APlayer.min.js"></script>
<script>
console.log('email to 862024320@qq.com')
</script>
<script>
  $(document).ready(function() {
    const ap = new APlayer({
    container: document.getElementById('aplayer'),
    mini: false,
    autoplay: false,
    theme: '#FADFA3',
    loop: 'all',
    order: 'random',
    preload: 'auto',
    volume: 0.5,
    mutex: true,
    listFolded: false,
    lrcType: 3,
    audio: [
      % foreach(keys %{$musics}) {
          {
            name: '<%= $musics->{$_}->{'music_name'} %>',
            artist: '<%= $musics->{$_}->{'music_artist'} %>',
            url: '<%= "./link/" . $musics->{$_}->{'music_url'} %>',
            cover: '1.jpg',
            % #lrc: '<%= $musics->{$_}->{'music_lrc'} %>',
            theme: '#ebd0c2'
          },
      % }

    ]
    });
  });
</script>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="./APlayer.min.css">
  <title><%= title %></title>
  <style>
    html {
      font-size: 24px;
    }
    * {
      margin: 0px;
      padding: 0px;
    }
  </style>
  </head>
  <body><%= content %>
  </body>
</html>
