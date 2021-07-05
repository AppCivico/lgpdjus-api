package Lgpdjus::ImageUtils;
# copied from https://metacpan.org/dist/Imager-ExifOrientation/source/lib/Imager/ExifOrientation.pm
use strict;
use warnings;

use Image::ExifTool 'ImageInfo';
use Image::ExifTool::Exif;

my $orientation_revers = {};
while (my($k, $v) = each %Image::ExifTool::Exif::orientation) {
    $orientation_revers->{$v} = $k;
}

sub get_orientation_by_exiftool {
    my($exif) = @_;
    return 1 unless $exif->{Orientation};
    return $orientation_revers->{$exif->{Orientation}} || 1;
}

my $rotate_maps = {
    1 => { right => 0,   mirror => undef }, # Horizontal (normal)
    2 => { right => 0,   mirror => 'h'   }, # Mirror horizontal
    3 => { right => 0,   mirror => 'hv'  }, # Rotate 180 (rotate is too noisy)
    4 => { right => 0,   mirror => 'v'   }, # Mirror vertical
    5 => { right => 270, mirror => 'h'   }, # Mirror horizontal and rotate 270 CW
    6 => { right => 90,  mirror => undef }, # Rotate 90 CW
    7 => { right => 90,  mirror => 'h'   }, # Mirror horizontal and rotate 90 CW
    8 => { right => 270, mirror => undef }, # Rotate 270 CW
};

sub _rotate {
    my($img, $orientation) = @_;
    my $map = $rotate_maps->{$orientation};

    if ($map->{mirror}) {
        $img->flip( dir => $map->{mirror} );
    }

    if ($map->{right}) {
        return $img->rotate( right => $map->{right} );
    }

    $img;
}


sub rotate_filepath {
    my($img, $path) = @_;

    my $exif = ImageInfo($path);

    my $orientation = get_orientation_by_exiftool($exif || {});
    return _rotate($img, $orientation);
}

1;
