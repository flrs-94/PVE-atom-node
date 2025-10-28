#!/usr/bin/perl

package PVE::API2::Custom::QAT;

use strict;
use warnings;

use PVE::RESTHandler;
use PVE::JSONSchema qw(get_standard_option);
use PVE::Tools;

use base qw(PVE::RESTHandler);

# QAT Status API Endpoint
__PACKAGE__->register_method({
    name => 'qat_status', 
    path => 'qat',
    method => 'GET',
    description => "Get Intel QAT hardware acceleration status",
    parameters => {
        additionalProperties => 0,
        properties => {
            node => get_standard_option('pve-node'),
        },
    },
    returns => {
        type => 'object',
        properties => {
            qat_available => { type => 'boolean', description => 'QAT hardware available' },
            virtual_functions => { type => 'integer', description => 'Number of active VFs' },
            crypto_engines => { type => 'integer', description => 'Available crypto engines' },
            requests_processed => { type => 'integer', description => 'Total requests processed' },
            acceleration_engines => { 
                type => 'array',
                items => {
                    type => 'object',
                    properties => {
                        id => { type => 'integer' },
                        requests => { type => 'integer' },
                        responses => { type => 'integer' },
                        utilization => { type => 'number' }
                    }
                }
            },
            uptime => { type => 'integer', description => 'QAT service uptime in seconds' }
        },
    },
    code => sub {
        my ($param) = @_;

        my $result = {
            qat_available => 0,
            virtual_functions => 0,
            crypto_engines => 0,
            requests_processed => 0,
            acceleration_engines => [],
            uptime => 0
        };

        # Check if QAT is available
        if (-e "/sys/bus/pci/devices/0000:01:00.0/sriov_numvfs") {
            $result->{qat_available} = 1;
            
            # Get VF count
            my $vf_count = PVE::Tools::file_get_contents("/sys/bus/pci/devices/0000:01:00.0/sriov_numvfs");
            chomp $vf_count;
            $result->{virtual_functions} = int($vf_count || 0);
            
            # Get crypto engines count
            my $crypto_output = `grep -c qat /proc/crypto 2>/dev/null || echo 0`;
            chomp $crypto_output;
            $result->{crypto_engines} = int($crypto_output || 0);
            
            # Parse QAT statistics
            if (-e "/proc/qat") {
                my $qat_stats = `cat /proc/qat 2>/dev/null || echo ""`;
                my @engines = ();
                my $total_requests = 0;
                
                my @lines = split /\n/, $qat_stats;
                for my $line (@lines) {
                    if ($line =~ /^\s*(\d+):\s+(\d+)\s+(\d+)/) {
                        my ($id, $req, $resp) = ($1, $2, $3);
                        my $util = $req > 0 ? ($resp / $req) * 100 : 0;
                        
                        push @engines, {
                            id => int($id),
                            requests => int($req),
                            responses => int($resp),
                            utilization => $util
                        };
                        
                        $total_requests += $req;
                    }
                }
                
                $result->{requests_processed} = $total_requests;
                $result->{acceleration_engines} = \@engines;
            }
            
            # Get service uptime
            my $service_status = `systemctl show qat-sriov.service --property=ActiveEnterTimestamp --value 2>/dev/null || echo ""`;
            if ($service_status) {
                chomp $service_status;
                # Convert timestamp to uptime seconds (simplified)
                $result->{uptime} = time() - 1698480242; # Placeholder
            }
        }

        return $result;
    }});

1;