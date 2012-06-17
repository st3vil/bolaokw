use strict;
use warnings;
use lib "$ENV{HOME}/pquery-pm/lib";
#use pQuery;
use FindBin '$Bin';
use lib "$Bin/WebService-GData/lib";
use WebService::GData::YouTube;
use WebService::GData::ClientLogin;
use File::Slurp;

use Scriptalicious;

our $VERSION = 0;

our $url = "http://youtube.com";
our $key = "AI39si7cDeHorzIAWCMFQQHyYMfVeaqaoig7utoOr9pg1I_byl2S1KHoS1s3OhicpbKmuM4DLNuwnfK1wBd75ZdV3ETNhjB8uA";

my $auth = new WebService::GData::ClientLogin(
   email   =>'nostrasteve@gmail.com',
   password=>(read_file('your gmail password here'))[0],
   key     =>$key,
);

#give write access
my $yt = new WebService::GData::YouTube($auth);
my $v = $yt->get_user_favorite_videos;

use Data::Walk;
my @titles;
walk sub {
    ref $_ eq "WebService::GData::Node::Atom::Title"
        && push @titles, $_;
}, $v;

say anydump $@;
say anydump(\@titles);
say anydump($v);
exit;

