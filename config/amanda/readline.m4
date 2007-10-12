# SYNOPSIS
#
#   AMANDA_CHECK_READLINE
#
# OVERVIEW
#
#   Check for readline support.  Defines HAVE_READLINE if readline
#   is available, and also checks for a number of readline headers and
#   adds readline libraries to LIBS.
#
#   See common-src/util.{c,h}.
#
AC_DEFUN([AMANDA_CHECK_READLINE], [
    AC_ARG_WITH(readline,
    dnl no initial space here, so the results line up properly
AS_HELP_STRING([--with-readline], [require readline support (for amrecover)])
AS_HELP_STRING([--without-readline], [don't search for readline]),
        [ 
            case "$withval" in
                y | ye | yes | n | no) : ;;
                *) AC_MSG_ERROR([*** --with-readline does not take a value])
            esac
            want_readline="$withval"
        ], [
            want_readline="maybe" # meaning "only if we can find it"
        ])

    # unless the user said "no", look for readline.
    if test x"$want_readline" != x"no"; then
        # we need a tgetent() somewhere..
        proceed="false"
        AC_CHECK_LIB(termcap, tgetent, [
            proceed="true"
        ], [
            AC_CHECK_LIB(curses, tgetent, [
                proceed="true"
            ], [
                AC_CHECK_LIB(ncurses, tgetent, [
                    proceed="true"
                ])
            ])
        ])

        if $proceed; then
            proceed="false"
            AC_CHECK_HEADERS( history.h readline.h readline/history.h readline/readline.h, [
                # found at least one of the headers, so we can proceed.
                proceed="true"
            ])
        fi

        if $proceed; then
            proceed="false"
            AC_CHECK_LIB(readline,readline, [
                LIBS="-lreadline $LIBS"
                proceed="true"
            ])
        fi

        if $proceed; then
            # we have readline!
            AC_DEFINE(HAVE_READLINE, 1, [System has readline support (headers and libraries)])
        else
            # no readline.  if the user *really* wanted it, bail out.
            if test x"$want_readline" = x"yes"; then
                AC_MSG_ERROR([*** No readline implementation found.  Try using --with-libraries and --with-includes])
            fi
        fi
    fi
])