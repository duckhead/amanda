# vim:ft=perl
# Copyright (c) 2005-2008 Zmanda, Inc.  All Rights Reserved.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License version 2.1 as
# published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.
#
# Contact information: Zmanda Inc., 465 S Mathlida Ave, Suite 300
# Sunnyvale, CA 94086, USA, or: http://www.zmanda.com

package Amanda::Script_App;

no warnings;
no strict;
$GOOD  = 0;
$ERROR = 1;

use strict;
use warnings;
use Amanda::Constants;
use Amanda::Config qw( :init :getconf  config_dir_relative );
use Amanda::Debug qw( :logging );
use Amanda::Paths;
use Amanda::Util qw( :constants );

=head1 NAME

Amanda::Script - perl utility functions for Scripts.

=head1 SYNOPSIS

=cut

sub new {
    my $class = shift;
    my $execute_where = shift;
    my $type = shift;

    my $self = {};
    bless ($self, $class);

    # extract the last component of the class name
    my $name = $class;
    $name =~ s/^.*:://;
    $self->{'name'} = $name;

    if(!defined $execute_where) {
	$execute_where = "client";
    }
    Amanda::Util::setup_application($name, $execute_where, $CONTEXT_DAEMON);

    #initialize config client to get values from amanda-client.conf
    config_init($CONFIG_INIT_CLIENT, undef);
    my ($cfgerr_level, @cfgerr_errors) = config_errors();
    if ($cfgerr_level >= $CFGERR_WARNINGS) {
        config_print_errors();
        if ($cfgerr_level >= $CFGERR_ERRORS) {
            die("errors processing config file");
        }
    }

    Amanda::Util::finish_setup($RUNNING_AS_ANY);

    $self->{'suf'} = '';
    if ( $Amanda::Constants::USE_VERSION_SUFFIXES =~ /^yes$/i ) {
        $self->{'suf'} = "-$Amanda::Constants::VERSION";
    }

    $self->{error_status} = $Amanda::Script_App::GOOD;
    $self->{type} = $type;
    $self->{known_commands} = {};

    debug("$type: $name\n");

    return $self;
}


#$_[0] action
#$_[1] message
#$_[2] status: GOOD or ERROR
sub print_to_server {
    my $self = shift;
    my($action,$msg, $status) = @_;
    if ($status != 0) {
        $self->{error_status} = $status;
    }
    if ($action eq "check") {
	if ($status == $Amanda::Script_App::GOOD) {
            print STDOUT "OK $msg\n";
	} else {
            print STDOUT "ERROR $msg\n";
	}
    } elsif ($action eq "estimate") {
	if ($status == $Amanda::Script_App::GOOD) {
            #do nothing
	} else {
            print STDERR "ERROR $msg\n";
	}
    } elsif ($action eq "backup") {
	if ($status == $Amanda::Script_App::GOOD) {
            print STDERR "| $msg\n";
	} else {
            print STDERR "? $msg\n";
	}
    } elsif ($action eq "restore") {
        print STDOUT "$msg\n";
    } else {
        print STDERR "$msg\n";
    }
}

#$_[0] action
#$_[1] message
#$_[2] status: GOOD or ERROR
sub print_to_server_and_die {
    my $self = shift;

    my $action = $_[0];
    $self->print_to_server( @_ );
    if ($self->can("check_for_backup_failure")) {
	$self->check_for_backup_failure($action);
    }
    die();
}


sub do {
    my $self = shift;
    my $command  = shift;

    $command =~ tr/A-Z-/a-z_/;
    debug("command: $command");

    # first make sure this is a valid command.
    if (!exists($self->{known_commands}->{$command})) {
	print STDERR "Unknown command `$command'.\n";
	exit 1;
    }

    # now convert it to a function name and see if it's
    # defined
    my $function_name = "command_$command";

    if (!$self->can($function_name)) {
        print STDERR "command `$command' is not supported by the '" .
                     $self->{name} . "' " . $self->{type} . ".\n";
        exit 1;
    }

    # it exists -- call it
    $self->$function_name();
}

1;