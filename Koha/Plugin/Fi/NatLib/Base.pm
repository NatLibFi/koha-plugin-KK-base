package Koha::Plugin::Fi::NatLib::Base;
use Modern::Perl; use utf8; use open qw(:utf8);
use base qw(Koha::Plugins::Base);

use C4::Context;

our $VERSION = "{VERSION}";
our $metadata = {
    name            => 'KK-Base',
    author          => 'Kansalliskirjasto Koha Dev Team / Andrii, Slava, Petro',
    description     => 'BASE PACKAGE for other NatLibFi KK-Dev team plugins. Required.',
    homepage        => 'https://github.com/NatLibFi/koha-plugin-KK-base',
    date_authored   => '2024-04-30',
    date_updated    => '1900-01-01',
    minimum_version => '23.1100000',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new({ %{$args//{}}, metadata => { %$metadata, class => $class } });
    return $self;
}

sub install { return 1; }
sub uninstall {
    # check if any Koha::Plugin::Fi::NatLib subfolders which does `use base qw(Koha::Plugin::Fi::NatLib::Base::App);`
    # and prevent uninstall if there are some:

    my $lib = (__FILE__ =~ s{/Base\.pm$}{}r);
    my $subfolders = [ grep { -d $_ and ! m{/Base$}; } glob $lib.'/*' ];
    if ( @$subfolders ) {
        die "Cannot uninstall this plugin, because there are sub-plugins which depend on it: @$subfolders\n";
    }
    return 1;
}

sub intranet_js {
    my ( $self ) = @_;

    my $userenv = C4::Context->userenv;

    # works both for dev-apache environment and plack one:
    return if $ENV{REQUEST_URI} !~ m{^/(intranet|cgi-bin/koha)/plugins/plugins-home\.pl};

    return q{<script>
        'use strict';
        $(function() {
            if (window.location.pathname.match(/\/plugins-home\.pl$/)) {
                let pluginactions = $('a[id^=pluginactions]');
                let count_dependent_plugins = 0;
                let kk_base_object;
                let plugin = pluginactions.filter(function() {
                    // get from this 'a' followed by 'ul li a.class="uninstall_plugin"' :
                    let rest_of_id = $(this).attr('id').replace('pluginactions', '');
                    // console.log(rest_of_id);
                    if (rest_of_id == 'Koha::Plugin::Fi::NatLib::Base') {
                        kk_base_object = $(this);
                        return false;
                    }
                    else if (rest_of_id.startsWith('Koha::Plugin::Fi::NatLib::')) {
                        count_dependent_plugins++;
                        console.log('Koha::Plugin::Fi::NatLib::Base DEPENDENT PLUGIN:', rest_of_id);
                    }
                    return false;
                });
                if (count_dependent_plugins) {
                    let uninstall = $(kk_base_object).next().find('a.uninstall_plugin');
                    let pluginname = $(uninstall).attr('data-plugin-name');
                    let nouninstall = $(uninstall).after($('<a href="#" class="uninstall_plugin" data-plugin-name="' +
                        pluginname + '"' +
                        ' onclick="alert('+"'"+'Cannot uninstall this plugin: there are depentant Koha::Plugin::Fi::NatLib:: plugins installed, remove them first!'+"'"+'); return false;"' +
                        ' title="There are depentant Koha::Plugin::Fi::NatLib:: plugins installed, remove them first"><i class="fa fa-trash-can-arrow-up fa-fw"></i> Can&apos;t uninstall</a>'));
                    uninstall.remove();
                    // console.log($(nouninstall).get(0));
                    return false;
                }
            }
        });
    </script>};
}

1;
