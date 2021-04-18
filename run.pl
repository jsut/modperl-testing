#!/usr/bin/env perl

use v5.12.0;
use Cwd qw/abs_path cwd/;

my $modes = parse_modes();
my $cwd = cwd();

if ($modes->{all} || $modes->{'perl'}) {
    do_perl($cwd);
}

# find, extract, configure, build and installer perls
sub do_perl {
    my $cwd = shift;
    my @perl_gzs = glob('perl_src/perl-*.tar.gz');
    say "found:\n", join "\n", map { abs_path($_) } @perl_gzs;
    foreach my $path (@perl_gzs) {
        extract_perl($path, $cwd);
    }
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

# extract a perl source archive
sub extract_perl {
    my ($path, $cwd) = @_;
    say "extracting $path";
    `tar zxvf $path -C $cwd/perl_src/`;
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



# parse the modes you want to run off the command line
sub parse_modes {
    my $modes;
    foreach my $arg (@ARGV) {
        $modes->{$arg} = 1;
    }
    return $modes;
}




