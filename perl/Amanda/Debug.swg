/*
 * Copyright (c) Zmanda, Inc.  All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 2.1
 * as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.
 *
 * Contact information: Zmanda Inc., 505 N Mathlida Ave, Suite 120
 * Sunnyvale, CA 94085, USA, or: http://www.zmanda.com
 */

%module "Amanda::Debug"
%include "amglue/amglue.swg"
%include "exception.i"

%{
#include <glib.h>
#include "debug.h"
%}

%perlcode %{
=head1 NAME

Amanda::Debug - support for debugging Amanda applications

=head1 SYNOPSIS

  use Amanda::Debug qw( :init :logging );

  # (note: dbopen and such are usually handled by 
  #  Amanda::Util::setup_applicaton)
  dbopen("server");

  debug("this is a debug message");

See C<debug.h> for a more in-depth description of the functionality of
this module.

=head1 API STATUS

Stable>

=head1 INITIALIZATION

The functions C<dbopen> and C<dbrename> are used to open a debug file
whose pathname includes all of the relevant information. C<dbclose> and
C<dbreopen> are used to close that debug file before transferring
control to another process.

The variable C<$erroutput_type> can take on any combination
of the flags C<$ERROUTPUT_INTERACTIVE>, C<$ERROUTPUT_SYSLOG>
and C<$ERROUTPUT_AMANDALOG>.  C<$ERROUTPUT_INTERACTIVE>
causes messages from C<error> and C<critical> to be sent
to stderr. C<$ERROUTPUT_SYSLOG> sends it to syslog, and
C<$ERROUTPUT_AMANDALOG> sends it to the current trace log (see
L<Amanda::Logfile>).

C<$error_exit_status> is the exit status with which C<critical> will
exit.

All of the initialization functions and variables are available via the
export tag C<:init>.

=head1 DEBUG LOGGING

Several debug logging messages, each taking a single string, are
available:

=over

=item C<error> - also aborts the program to produce a core dump

=item C<critical> - exits the program with C<$error_exit_status>

=item C<warning>

=item C<message>

=item C<info>

=item C<debug>

=back

ALl of the debug logging functions are available via the export tag
C<:logging>.

=head1 ADVANCED FUNCTIONS

The current debug file's integer file descriptor (I<not> a Perl
filehandle) is available from C<dbfd()>.  Likewise, C<dbfn()> returns
the filename of the current debug file.

C<debug_dup_stderr_to_debug()> redirects, at the file-descriptor level,
C<STDERR> into the debug file.  This is useful when running external
applications which may produce error output.

=cut
%}

/*
 * Initialization
 */

amglue_export_tag(init,
    dbopen dbreopen dbrename dbclose
    $erroutput_type $error_exit_status
);

void	dbopen(char *subdir);
void	dbreopen(char *file, char *notation);
void	dbrename(char *config, char *subdir);
void	dbclose(void);

amglue_add_flag_tag_fns(erroutput_type_t);
amglue_add_constant_short(ERR_INTERACTIVE, INTERACTIVE, erroutput_type_t);
amglue_add_constant_short(ERR_SYSLOG, SYSLOG, erroutput_type_t);
amglue_add_constant_short(ERR_AMANDALOG, AMANDALOG, erroutput_type_t);
amglue_copy_tag_to(erroutput_type_t, init);

erroutput_type_t erroutput_type;
int error_exit_status;

/*
 * Logging
 */

amglue_export_tag(logging,
    error critical warning message info debug
);

%rename(error) error__; /* error() is a macro defined in debug.h .. just avoid that */
%inline %{
void error__(char *msg) { g_error("%s", msg); }
void critical(char *msg) { g_critical("%s", msg); }
void warning(char *msg) { g_warning("%s", msg); }
void message(char *msg) { g_message("%s", msg); }
void info(char *msg) { g_info("%s", msg); }
void debug(char *msg) { g_debug("%s", msg); }
%}

/*
 * Advanced
 */

int	dbfd(void);
char *	dbfn(void);
void debug_dup_stderr_to_debug(void);