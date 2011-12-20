#!/usr/bin/perl
use strict;
use warnings;
use Git::Wrapper;
use YAML::Syck;
use File::Slurp;
use Scriptalicious;
use DateTime;
use WWW::Mechanize;
use feature 'say';

my $g = `pwd`; chomp $g;
$g = new Git::Wrapper($g);

exec "git status" if %{ $g->status };

start_timer();
our $VERBOSE = 1;
capture("prove");

my ($changelog) = grep { /change(s|log)/i } glob "*";
my @changelog = read_file($changelog);

my @fore;
push @fore, $_ until ($_ = shift @changelog) && /^\d+\.\d+/;
my @aft = ($_, @changelog);
my ($prefix) = $aft[1] =~ /^(.+?)\w/;
my ($last_version, $last_timestamp) = $aft[0] =~ /^([\d\.]+) (\d+-\d+-\d+)/;

my @log = $g->log();
my @recent_commits;
push @recent_commits, $_ until ($_ = shift @log) && $_->{message} =~ /changelog/;

my @new_log = ();
say "Commits since last changelog:";
for (@recent_commits) {
    push @new_log, $_->{message};
    say $_->{message} ."  ".
    $_->{attr}->{date} ."  ". $_->{attr}->{author};
}
say "";
say "Proposed changelog:";
for (@new_log) {
    chomp;
    say $_;
}
unless ("dont") {
    write_changelog: @new_log = ();
    say "Enter a blank line when done";
    while (1) {
        my $line = <>; chomp $line;
        last if $line eq "";
        push @new_log, $line;
    }
}
prompt_yN("Do-over?") && goto write_changelog;
@new_log = map { "$prefix$_" } @new_log;
say "Last version: $last_version $last_timestamp";
my $increment = (1 / 10 ** length(($last_version =~ /\.(\d+)$/)[0]));
my $new_version = sprintf('%.2f', $last_version + $increment);
my $new_timestamp = DateTime->now->strftime('%Y-%m-%d');
say "New version: $new_version $new_timestamp";

write_file($changelog,
    join "",
        @fore,
        join ("\n",
            "$new_version $new_timestamp",
            @new_log, "", "",
        ),
        @aft
);

my $makepl = read_file("Makefile.PL");
my ($version_from) = $makepl =~ /^version_from\s+\("(.+)"\);$/gsm;
my @code = read_file($version_from);
@code = map {
    unless (/^our \$VERSION = "(.+)";$/gsm) {
        $_
    }
    else {
        if ($1 ne $last_version) {
            prompt_yN("Weird: version in file is $1 (vs $last_version from changelog) bail?")
                && $g->reset("--hard") && exit;
        }
        s/"$1"/"$new_version"/;
        $_;
    }
} @code;
write_file($version_from, @code);

$g->add($version_from);
$g->add($changelog);
$g->commit({ all => 1, message => "changelog" });
$g->tag($new_version);

my ($distname) = `pwd` =~ /.+\/(.+?)$/sgm;
my $newdist = "$distname-$new_version";
`cd .. && git clone $distname $newdist && rm -rf $newdist/.git && tar cfz $newdist.tgz $newdist`;

my $m = new WWW::Mechanize(agent => "release-script-de-la-DRSTEVE/0.1");
my ($user, $pass) = reverse split /_/, readlink("../.pause-junk");
$m->credentials($user, $pass);
$m->get('https://pause.perl.org/pause/authenquery?ACTION=add_uri');
$m->content =~ /Upload a file to CPAN/ || barf "bad page";
$m->field("pause99_add_uri_httpupload", "../$newdist.tgz", 1);
$m->click("SUBMIT_pause99_add_uri_httpupload");
$m->content =~ /Thank you for your contribution/ || barf "bad upload";

say "$newdist.tgz";
