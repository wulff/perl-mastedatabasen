#!/usr/bin/env perl

=pod

=head1 NAME

master.pl - Clean up output from "Mastedatabasen"

=head1 SYNOPSIS

./master.pl

=head1 DESCRIPTION

=cut

use Modern::Perl;
use JSON;

# define commissioning dates for the various technologies
my $technology = {
  GSM  => '1991-11',
  UMTS => '2003-10',
  LTE  => '2010-12',
  ALL  => '',
};

# slurp and decode the json data downloaded from mastedatabasen
open my $json, '<', './master.json' or die $!;
my $masts;
{
  local $\ = undef;
  $masts = decode_json(<$json>);
}
close $json;

# create a geojson file for each of the technologies
foreach my $tech (keys %$technology) {
  my %type = ();
  my %date = ();

  # initialize geojson data structure
  my $result = {
    type     => 'FeatureCollection',
    features => [],
  };

  foreach my $mast (@$masts) {
    # we are only interested in cellular masts
    next unless $mast->{tjenesteart}->{id} == 2;

    # ignore masts with no commissioning date
    next if $mast->{idriftsaettelsesdato} eq '';

    # grab yyyy-mm from commissioning date
    my $date = substr $mast->{idriftsaettelsesdato}, 0, 7;

    # filter by tech and commisssioning date
    if ($tech ne 'ALL') {
      next unless $mast->{teknologi}->{navn} eq $tech;
      next unless $date ge $technology->{$tech};
    }

    # grab longitude and latitude
    my $lon = $mast->{wgs84koordinat}->{laengde} + 0;
    my $lat = $mast->{wgs84koordinat}->{bredde} + 0;

    # add a subset of the available data to the geojson data structure
    push @{$result->{features}}, {
      type => 'Feature',
      geometry => {
        type => 'Point',
        coordinates => [$lon, $lat]
      },
      properties => {
        id      => $mast->{unik_station_navn},
        date    => $date . '-01 00:00:00', # aggregate masts per month
        end     => '2015-01-01 00:00:00', # necessary for qgis rendering
        muni    => $mast->{kommune}->{kode},
        type    => $mast->{tjenesteart}->{navn},
        type_id => $mast->{tjenesteart}->{id},
        tech    => $mast->{teknologi}->{navn},
        tech_id => $mast->{teknologi}->{id},
        freq    => $mast->{frekvensbaand},
      }
    };
  }

  my $filename = './geojson/master-' . lc($tech) . '.geojson';

  open my $out, '>', $filename or die $!;
  print $out encode_json($result);
  close $out;
}

=pod

=head1 AUTHOR

Morten Wulff, <wulff@ratatosk.net>

=head1 COPYRIGHT

Copyright (c) 2014, Morten Wulff. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL MICHAEL BOSTOCK BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
