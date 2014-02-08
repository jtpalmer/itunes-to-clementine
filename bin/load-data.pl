#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(:5.12);
use autodie qw(:all);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use Mac::iTunes::Library::XML;
use Try::Tiny;
use DBI;

main(@ARGV);

sub main {
    my ( $help, $verbose, $debug, $libraryFile, $databaseFile );

    GetOptionsFromArray(
        \@_,
        'help|h'      => \$help,
        'verbose|v'   => \$verbose,
        'debug|d'     => \$debug,
        'library|l=s' => \$libraryFile,
        'database=s'  => \$databaseFile,
    ) or pod2usage();

    pod2usage( -exitval => 0, -verbose => 2 ) if $help;

    defined $libraryFile or die "No input file specified\n";

    -f $libraryFile or die "Not a file '$libraryFile'\n";

    my $library = Mac::iTunes::Library::XML->parse($libraryFile);

    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $databaseFile );
    my $sql = 'UPDATE songs SET rating = ? WHERE artist = ? and title = ?';
    my $sth = $dbh->prepare($sql);

    say 'Track count: ' . $library->num();

    my %items = $library->items();
    while ( my ( $artistName, $songs ) = each %items ) {
        say 'Artist: ' . $artistName;
        while ( my ( $songName, $songItems ) = each %$songs ) {
            say 'Song: ' . $songName;
            my $rating;
            for my $item (@$songItems) {
                $rating = $item->rating() // 0;
                say 'Rating: ' . $rating;
            }

            $sth->execute( $rating / 100, $artistName, $songName );
        }
        say '-' x 76;
    }

    exit;
}

__END__

