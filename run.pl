#!/usr/bin/env perl

use v5.12.0;
use Cwd qw/abs_path cwd/;
use Data::Dumper;

my $modes = parse_modes();
my $cwd = cwd();

my $perls;
my $httpds;

if ($modes->{all} || $modes->{'perl'}) {
    $perls = do_perl($cwd);
}
else {
    my @installed_perls = glob('perls/perl-*');
    foreach my $path (@installed_perls) {
        if (-d $path) {
            my ($install_path, $version) = perl_details_from_path($path);
            push @$perls, {
                version => $version,
                path => abs_path($path)
            };
        }
    }
}

if ($modes->{all} || $modes->{'httpd'}) {
    $httpds = do_httpd($cwd);
}
else {
    my @installed_httpds = glob('httpds/httpd-*');
    foreach my $path (@installed_httpds) {
        if (-d $path) {
           push @$httpds, httpd_details_from_path($path);
        }
    }
}

if ($modes->{all} || $modes->{'mod_perl'}) {
    do_mod_perl($cwd, $perls, $httpds);
}


# find, extract, configure, build and installer perls
sub do_perl {
    my $cwd = shift;
    extract_archives('perl_src/perl-*.tar.gz', $cwd, 'perl_src');
    my @perls = glob('perl_src/perl-*');
    my @installed;
    foreach my $path (@perls) {
        if (-d $path) {
            push @installed, configure_build_install_perl($path, $cwd);
        }
    }

    foreach my $perl (@installed) {
        install_cpan_modules($perl);
    }
    return \@installed;
}

sub configure_build_install_perl {
    my ($path, $cwd) = @_;
    my ($install_path, $version) = perl_details_from_path($path);
    say "configuring, building and installing $version to $install_path";

    say qq[$cwd/perl_src/build.sh $path $install_path];
    `$cwd/perl_src/build.sh $path $install_path`;

    return {
        version => $version,
        path => $install_path
    };
}

sub perl_details_from_path {
    my $path = shift;
    my @parts = split '/', $path;
    my $perl_path = $parts[1];
    my @v_parts = split '-', $path;
    my $install_path = abs_path(qq[perls/$perl_path]);
    return ($install_path, $v_parts[1]);
}

sub install_cpan_modules {
    my $perl = shift;

    say "installing some cpan things for $perl->{'version'}";

    print `PERL_MM_USE_DEFAULT=1 $perl->{'path'}/bin/cpan$perl->{'version'} HTML::HeadParser LWP::UserAgent CGI BSD::Resource Chatbot::Eliza`;
}

sub do_httpd {
    my $cwd = shift;
    say $cwd;
    extract_archives('httpd_src/httpd-*.tar.gz', $cwd, 'httpd_src');
    my @httpds = glob('httpd_src/httpd-*');
    my @installed;
    foreach my $path (@httpds) {
        if (-d $path) {
            put_apr_in_srclib($path, $cwd);
            push @installed, configure_build_install_httpd($path, $cwd);
        }
    }
    return \@installed;
}

sub put_apr_in_srclib {
    my ($path, $cwd) = @_;
    extract_archives('httpd_src/apr-*', $cwd, qq[$path/srclib]);
    my @aprs = glob(qq[$path/srclib/apr-*]);
    say join ' ', @aprs;
    foreach my $apr (@aprs) {
        my $util_pos = index($apr, 'apr-util-');
        my $apr_pos = index($apr, 'apr-');
        my $dest;
        if ($util_pos > -1) {
            $dest = substr($apr, 0, $util_pos + 8);
        }
        else {
            $dest = substr($apr, 0, $apr_pos + 3);
        }
        say qq[moving $apr to $dest];
        `mv $apr $dest`;
    }
}

sub configure_build_install_httpd {
    my ($path, $cwd) = @_;
    my @parts = split '/', $path;
    my $httpd_path = $parts[1];
    my @v_parts = split '-', $path;
    my $version = $v_parts[1];
    my @installed;

    foreach my $mpm (qw/worker event prefork/) {
        say "configuring, building and installing $version with $mpm mpm";
        my $install_path = abs_path(qq[httpds/$httpd_path-$mpm]);
        say qq[$cwd/httpd_src/build.sh $path $install_path $mpm];
        `$cwd/httpd_src/build.sh $path $install_path $mpm`;
        push @installed, {
            version => $version,
            path => $install_path,
            mpm => $mpm
        };
    }

    return @installed;
}

sub httpd_details_from_path {
    my $path = shift;
    my @parts = split '/', $path;
    my $httpd_path = $parts[1];
    my @v_parts = split '-', $path;
    my $version = $v_parts[1];
    my $mpm = $v_parts[2];
    return {
        version => $version,
        path => abs_path($path),
        mpm => $mpm
    };

}

sub do_mod_perl {
    my ($cwd, $perls, $httpds) = @_;
    my $cwd = shift;
    extract_archives('mod_perl_src/mod_perl-*.tar.gz', $cwd, 'mod_perl_src');
    my @modperls = glob('mod_perl_src/mod_perl-*');
    my @installed;

    foreach my $mp_path (@modperls) {
        foreach my $perl_path (@$perls) {
            foreach my $httpd_path (@$httpds) {
                if (-d $mp_path) {
                    push @installed, configure_build_install_mod_perl($mp_path, $perl_path, $httpd_path, $cwd);
                }
            }
        }
    }
}

sub configure_build_install_mod_perl {
    my ($mp_path, $perl_path, $httpd_path, $cwd) = @_;
    my @parts = split '/', $mp_path;
    my $mod_perl_path = $parts[1];
    my @v_parts = split '-', $mp_path;
    my $version = $v_parts[1];
    my @installed;

    say "configuring, building and installing mod_perl $version with perl $perl_path->{'version'} and httpd $httpd_path->{'version'}-$httpd_path->{'mpm'}";
    `$cwd/mod_perl_src/build.sh $mp_path $perl_path->{'path'} $perl_path->{'version'} $httpd_path->{'path'} $httpd_path->{'mpm'}`;

    return {
        version => $version,
        perl => $perl_path,
        httpd => $httpd_path
    };
} 

# find and extract source archives
sub extract_archives {
    my ($glob, $cwd, $dest_path) = @_;
    my @archives = glob($glob);
    foreach my $path (@archives) {
        say "extracting $path to $cwd/$dest_path/";
        `tar zxvf $path -C $cwd/$dest_path/`;
    }
}


# parse the modes you want to run off the command line
sub parse_modes {
    my $modes;
    foreach my $arg (@ARGV) {
        $modes->{$arg} = 1;
    }
    return $modes;
}




