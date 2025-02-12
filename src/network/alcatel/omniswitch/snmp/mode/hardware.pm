#
# Copyright 2023 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::alcatel::omniswitch::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);
use network::alcatel::omniswitch::snmp::mode::components::resources qw(%oids);

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        admin => [
            ['^(reset|takeover|resetWithFabric|takeoverWithFabrc)$', 'WARNING'],
            ['^(powerOff)$', 'CRITICAL'],
            ['powerOn', 'OK'],
            ['standby', 'OK']
        ],
        oper => [
            ['^(testing)$', 'WARNING'],
            ['^(unpowered|down|notpresent)$', 'CRITICAL'],
            ['up', 'OK'],
            ['secondary', 'OK'],
            ['master', 'OK'],
            ['idle', 'OK']
        ],
        fan => [
            ['noStatus', 'OK'],
            ['^notRunning$', 'CRITICAL'],
            ['running', 'OK']
        ]
    };
    
    $self->{components_path} = 'network::alcatel::omniswitch::snmp::mode::components';
    $self->{components_module} = ['backplane', 'chassis', 'container', 'fan', 'module', 'other', 'port', 'psu', 'sensor', 'stack', 'unknown'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};

    my $versions = $self->{snmp}->get_leef(
        oids => [ $oids{aos6}->{version}, $oids{aos7}->{version} ]
    );

    $self->{type} = '';
    if (defined($versions->{ $oids{aos6}->{version} })) {
        $self->{type} = 'aos6';
    } elsif (defined($versions->{ $oids{aos7}->{version} })) {
        $self->{type} = 'aos7';
    }

    if ($self->{type} eq 'aos6') {
        $self->{results} = $self->{snmp}->get_multiple_table(
            oids => [
                { oid => $oids{common}->{entPhysicalClass} },
                { oid => $oids{aos6}->{alaChasEntPhysFanStatus} }
            ]
        );

        $self->{results}->{entity} = $self->{snmp}->get_multiple_table(
            oids => [ 
                { oid => $oids{common}->{entPhysicalDescr} },
                { oid => $oids{common}->{entPhysicalName} },
                { oid => $oids{aos6}->{chasPhysBase}, start => $oids{aos6}->{chasEntPhysAdminStatus}, end => $oids{aos6}->{chasEntPhysOperStatus} },
                { oid => $oids{aos6}->{chasEntPhysPower} },
                { oid => $oids{aos6}->{chasChassisEntry} }
            ],
            return_type => 1
        );
    } elsif ($self->{type} eq 'aos7') {
        $self->{results} = $self->{snmp}->get_multiple_table(
            oids => [
                { oid => $oids{common}->{entPhysicalClass} },
                { oid => $oids{aos7}->{alaChasEntPhysFanStatus} }
            ]
        );

        $self->{results}->{entity} = $self->{snmp}->get_multiple_table(
            oids => [ 
                { oid => $oids{common}->{entPhysicalDescr} },
                { oid => $oids{common}->{entPhysicalName} },
                { oid => $oids{aos7}->{chasPhysBase}, start => $oids{aos7}->{chasEntPhysAdminStatus}, end => $oids{aos7}->{chasEntPhysPower} },
                { oid => $oids{aos7}->{chasChassisEntry} }
            ],
            return_type => 1
        );
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check status of alcatel hardware (AlcatelIND1Chassis.mib).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'other', 'unknown', 'chassis', 'backplane', 'container', 'psu', 'fan', 
'sensor', 'module', 'port, 'stack'.
Some not exists ;)

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=fan).
You can also exclude items from specific instances: --filter=fan,1.2

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='psu.oper,CRITICAL,standby'

=back

=cut
