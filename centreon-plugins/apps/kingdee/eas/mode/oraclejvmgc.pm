#
# Copyright 2016 Centreon (http://www.centreon.com/)
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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::oraclejvmgc;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', },
            "proto:s"           => { name => 'proto' },
            "urlpath:s"         => { name => 'url_path', default => "/easportal/tools/nagios/checkgc_ps.jsp" },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "proxyurl:s"        => { name => 'proxyurl' },
            "timeout:s"         => { name => 'timeout' },
            });
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;
        
    my $webcontent = $self->{http}->request();
    $webcontent =~ s/^\s|\s+$//g;  #trim

	if ( $webcontent !~ /MinorGCCount=\d+/mi ) {
		$self->{output}->output_add(
			severity  => 'UNKNOWN',
			short_msg => "Cannot find jvm gc status."
		);
		$self->{output}->option_exit();
	}
	
    my ($minorgccount, $minorgctime, $fullgccount, $fullgctime) = (0, 0, 0, 0);

    ($minorgccount, $minorgctime, $fullgccount, $fullgctime) = ($1, $2, $3, $4) if ($webcontent =~ /MinorGCCount=(\d+)\sMinorGCTime=(\d+)\sFullGCCount=(\d+)\sFullGCTime=(\d+)/mi);

    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MinorGCCount: %d", $minorgccount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("MinorGCTime: %dms", $minorgctime));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("FullGCCount: %d", $fullgccount));
    $self->{output}->output_add(severity => "ok", short_msg => sprintf("FullGCTime: %dms", $fullgctime));

    $self->{output}->perfdata_add(label => "c[MinorGCCount]", unit => '',
                                  value => sprintf("%d", $minorgccount),
                                  );
    $self->{output}->perfdata_add(label => "c[MinorGCTime]", unit => 'ms',
                                  value => sprintf("%d", $minorgctime),
                                  );
    $self->{output}->perfdata_add(label => "c[FullGCCount]", unit => '',
                                  value => sprintf("%d", $fullgccount),
                                  );
    $self->{output}->perfdata_add(label => "c[FullGCTime]", unit => 'ms',
                                  value => sprintf("%d", $fullgctime),
                                  );

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check EAS application jvm gc status.

=over 8

=item B<--hostname>

IP Addr/FQDN of the EAS application server host

=item B<--port>

Port used by EAS instance.

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkgc_ps.jsp')

=item B<--credentials>

Specify this option if you access page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning>

Warning Threshold for class loaded

=item B<--critical>

Critical Threshold for class unloaded

=back

=cut
