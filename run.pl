#!/usr/bin/env perl

use v5.12.0;
use Cwd qw/abs_path cwd/;

my $modes = parse_modes();
my $cwd = cwd();

if ($modes->{all} || $modes->{'perl'}) {
    do_perl($cwd);
}
if ($modes->{all} || $modes->{'httpd'}) {
    do_httpd($cwd);
}
if ($modes->{all} || $modes->{'mod_perl'}) {
    do_mod_perl($cwd);
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
}

sub configure_build_install_perl {
    my ($path, $cwd) = @_;
    my @parts = split '/', $path;
    my $perl_path = $parts[1];
    my @v_parts = split '-', $path;
    my $version = $v_parts[1];
    my $install_path = abs_path(qq[perls/$perl_path]);
    say "configuring, building and installing $version to $install_path";

    say qq[$cwd/perl_src/build.sh $path $install_path];
    `$cwd/perl_src/build.sh $path $install_path`;

    return {
        version => $version,
        path => $install_path
    };
}

sub install_cpan_modules {
    my $perl = shift;

    say "installing some cpan things for $perl->{'version'}";

    print `$perl->{'path'}/bin/cpan$perl->{'version'} HTML::HeadParser LWP::UserAgent CGI BSD::Resource Chatbot::Eliza`;
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
    my $install_path = abs_path(qq[httpds/$httpd_path]);
    say "configuring, building and installing $version to $install_path";

    say qq[$cwd/httpd_src/build.sh $path $install_path];
    `$cwd/httpd_src/build.sh $path $install_path`;

    return {
        version => $version,
        path => $install_path
    };
}

sub do_mod_perl {

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




