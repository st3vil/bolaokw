#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
my $td = "tumb";

use WWW::Mechanize;
my $m = new WWW::Mechanize;
use YAML::Syck;

my $url = "http://st33v.tumblr.com/";
my @posts;
my $page = 1;
while ($page && 0) {
    say "getting page $page";
    my $url = "$url".($page>1?"page/$page":"");
    $m->get($url);
        my $next = $page + 1;
    push @posts, $m->content =~ /<a href="([^"]+\/post\/\d+)"/sg;
    last unless $m->content =~ m{<a href="(/page/$next)">};
    $page++;
}
@posts = @{LoadFile("posts.yml")};
my $i = 1;
my @photos = 1;
for my $post (@posts) {
    $m->get($post);
    push @photos, $m->content =~ m{"([^"]+?jpg)"}smg;
}
DumpFile("photos.yml", \@photos);
exit;
    for my $img (@photos) {
        $img =~ s{250\.jpg}{1280.jpg} || die;
        say $i .": ". $img;
        `wget $img -O tumb/$i.jpg`;
        $i++
    }

use WWW::Mechanize;
use File::Slurp;
my $email = 'nostrasteve@gmail.com';
my $password = (read_file('your workroom password here'))[0];

$m->get("http://workroom.tlcstudents.ac.nz/log-in/");
$m->submit_form(with_fields => {
    email => $email,
    password => $password,
});
die $m->content unless $m->content =~ /Certificate Hub/;
$m->get('http://workroom.tlcstudents.ac.nz/albums/edit/2229/');

