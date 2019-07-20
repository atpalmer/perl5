################################################################################
#
#            !!!!!   Do NOT edit this file directly!   !!!!!
#
#            Edit mktests.PL and/or parts/inc/utf8 instead.
#
#  This file was automatically generated from the definition files in the
#  parts/inc/ subdirectory by mktests.PL. To learn more about how all this
#  works, please read the F<HACKERS> file that came with this distribution.
#
################################################################################

BEGIN {
  if ($ENV{'PERL_CORE'}) {
    chdir 't' if -d 't';
    @INC = ('../lib', '../ext/Devel-PPPort/t') if -d '../lib' && -d '../ext';
    require Config; import Config;
    use vars '%Config';
    if (" $Config{'extensions'} " !~ m[ Devel/PPPort ]) {
      print "1..0 # Skip -- Perl configured without Devel::PPPort module\n";
      exit 0;
    }
  }
  else {
    unshift @INC, 't';
  }

  sub load {
    eval "use Test";
    require 'testutil.pl' if $@;
  }

  if (81) {
    load();
    plan(tests => 81);
  }
}

use Devel::PPPort;
use strict;
BEGIN { $^W = 1; }

package Devel::PPPort;
use vars '@ISA';
require DynaLoader;
@ISA = qw(DynaLoader);
bootstrap Devel::PPPort;

package main;

BEGIN { require warnings if "$]" gt '5.006' }

# skip tests on 5.6.0 and earlier
if ("$]" le '5.006') {
    skip 'skip: broken utf8 support', 0 for 1..81;
    exit;
}

ok(&Devel::PPPort::UTF8_SAFE_SKIP("A", 0), 1);
ok(&Devel::PPPort::UTF8_SAFE_SKIP("A", -1), 0);

ok(&Devel::PPPort::isUTF8_CHAR("A", -1), 0);
ok(&Devel::PPPort::isUTF8_CHAR("A",  0), 1);
ok(&Devel::PPPort::isUTF8_CHAR("\x{100}",  -1), 0);
ok(&Devel::PPPort::isUTF8_CHAR("\x{100}",  0), 2);

if ("$]" lt '5.008') {
    ok(1, 1) for 1 ..3
}
else {
    ok(&Devel::PPPort::foldEQ_utf8("A\x{100}", 3, 1, "a\x{101}", 3, 1), 1);
    ok(&Devel::PPPort::foldEQ_utf8("A\x{100}", 3, 1, "a\x{102}", 3, 1), 0);
    ok(&Devel::PPPort::foldEQ_utf8("A\x{100}", 3, 1, "b\x{101}", 3, 1), 0);
}

my $ret = &Devel::PPPort::utf8_to_uvchr("A");
ok($ret->[0], ord("A"));
ok($ret->[1], 1);

$ret = &Devel::PPPort::utf8_to_uvchr("\0");
ok($ret->[0], 0);
ok($ret->[1], 1);

$ret = &Devel::PPPort::utf8_to_uvchr_buf("A", 0);
ok($ret->[0], ord("A"));
ok($ret->[1], 1);

$ret = &Devel::PPPort::utf8_to_uvchr_buf("\0", 0);
ok($ret->[0], 0);
ok($ret->[1], 1);

if (ord("A") != 65) {   # tests not valid for EBCDIC
    ok(1, 1) for 1 .. (2 + 4 + (7 * 5));
}
else {
    $ret = &Devel::PPPort::utf8_to_uvchr_buf("\xc4\x80", 0);
    ok($ret->[0], 0x100);
    ok($ret->[1], 2);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_; };

    {
        BEGIN { 'warnings'->import('utf8') if "$]" gt '5.006' }
        $ret = &Devel::PPPort::utf8_to_uvchr("\xe0\0\x80");
        ok($ret->[0], 0);
        ok($ret->[1], -1);

        BEGIN { 'warnings'->unimport() if "$]" gt '5.006' }
        $ret = &Devel::PPPort::utf8_to_uvchr("\xe0\0\x80");
        ok($ret->[0], 0xFFFD);
        ok($ret->[1], 1);
    }

    my @buf_tests = (
        {
            input      => "A",
            adjustment => -1,
            warning    => qr/empty/,
            no_warnings_returned_length => 0,
        },
        {
            input      => "\xc4\xc5",
            adjustment => 0,
            warning    => qr/non-continuation/,
            no_warnings_returned_length => 1,
        },
        {
            input      => "\xc4\x80",
            adjustment => -1,
            warning    => qr/short|1 byte, need 2/,
            no_warnings_returned_length => 1,
        },
        {
            input      => "\xc0\x81",
            adjustment => 0,
            warning    => qr/overlong|2 bytes, need 1/,
            no_warnings_returned_length => 2,
        },
        {
            input      => "\xe0\x80\x81",
            adjustment => 0,
            warning    => qr/overlong|3 bytes, need 1/,
            no_warnings_returned_length => 3,
        },
        {
            input      => "\xf0\x80\x80\x81",
            adjustment => 0,
            warning    => qr/overlong|4 bytes, need 1/,
            no_warnings_returned_length => 4,
        },
        {                 # Old algorithm failed to detect this
            input      => "\xff\x80\x90\x90\x90\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf",
            adjustment => 0,
            warning    => qr/overflow/,
            no_warnings_returned_length => 13,
        },
    );

    # An empty input is an assertion failure on debugging builds.  It is
    # deliberately the first test.
    require Config; import Config;
    use vars '%Config';
    if ($Config{ccflags} =~ /-DDEBUGGING/) {
        shift @buf_tests;
        ok(1, 1) for 1..5;
    }

    for my $test (@buf_tests) {
        my $input = $test->{'input'};
        my $adjustment = $test->{'adjustment'};
        my $display = 'utf8_to_uvchr_buf("';
        for (my $i = 0; $i < length($input) + $adjustment; $i++) {
            $display .= sprintf "\\x%02x", ord substr($input, $i, 1);
        }

        $display .= '")';
        my $warning = $test->{'warning'};

        undef @warnings;
        BEGIN { 'warnings'->import('utf8') if "$]" gt '5.006' }
        $ret = &Devel::PPPort::utf8_to_uvchr_buf($input, $adjustment);
        ok($ret->[0], 0,  "returned value $display; warnings enabled");
        ok($ret->[1], -1, "returned length $display; warnings enabled");
        my $all_warnings = join "; ", @warnings;
        my $contains = grep { $_ =~ $warning } $all_warnings;
        ok($contains, 1, $display
                    . "; Got: '$all_warnings', which should contain '$warning'");

        undef @warnings;
        BEGIN { 'warnings'->unimport('utf8') if "$]" gt '5.006' }
        $ret = &Devel::PPPort::utf8_to_uvchr_buf($input, $adjustment);
        ok($ret->[0], 0xFFFD,  "returned value $display; warnings disabled");
        ok($ret->[1], $test->{'no_warnings_returned_length'},
                      "returned length $display; warnings disabled");
    }
}

if ("$]" ge '5.008') {
    BEGIN { if ("$]" ge '5.008') { require utf8; "utf8"->import() } }

    ok(Devel::PPPort::sv_len_utf8("aščť"), 4);
    ok(Devel::PPPort::sv_len_utf8_nomg("aščť"), 4);

    my $str = "áíé";
    utf8::downgrade($str);
    ok(Devel::PPPort::sv_len_utf8($str), 3);
    utf8::downgrade($str);
    ok(Devel::PPPort::sv_len_utf8_nomg($str), 3);
    utf8::upgrade($str);
    ok(Devel::PPPort::sv_len_utf8($str), 3);
    utf8::upgrade($str);
    ok(Devel::PPPort::sv_len_utf8_nomg($str), 3);

    tie my $scalar, 'TieScalarCounter', "é";

    ok(tied($scalar)->{fetch}, 0);
    ok(tied($scalar)->{store}, 0);
    ok(Devel::PPPort::sv_len_utf8($scalar), 2);
    ok(tied($scalar)->{fetch}, 1);
    ok(tied($scalar)->{store}, 0);
    ok(Devel::PPPort::sv_len_utf8($scalar), 3);
    ok(tied($scalar)->{fetch}, 2);
    ok(tied($scalar)->{store}, 0);
    ok(Devel::PPPort::sv_len_utf8($scalar), 4);
    ok(tied($scalar)->{fetch}, 3);
    ok(tied($scalar)->{store}, 0);
    ok(Devel::PPPort::sv_len_utf8_nomg($scalar), 4);
    ok(tied($scalar)->{fetch}, 3);
    ok(tied($scalar)->{store}, 0);
    ok(Devel::PPPort::sv_len_utf8_nomg($scalar), 4);
    ok(tied($scalar)->{fetch}, 3);
    ok(tied($scalar)->{store}, 0);
} else {
    for (1..23) {
        skip 'skip: no SV_NOSTEAL support', 0;
    }
}

package TieScalarCounter;

sub TIESCALAR {
    my ($class, $value) = @_;
    return bless { fetch => 0, store => 0, value => $value }, $class;
}

sub FETCH {
    BEGIN { if ("$]" ge '5.008') { require utf8; "utf8"->import() } }
    my ($self) = @_;
    $self->{fetch}++;
    return $self->{value} .= "é";
}

sub STORE {
    my ($self, $value) = @_;
    $self->{store}++;
    $self->{value} = $value;
}
