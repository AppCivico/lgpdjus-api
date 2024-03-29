package Lgpdjus::Types;
use strict;
use warnings;

use MooseX::Types -declare => [
    qw(DateStr DateTimeStr MobileNumber CPF JSON CEP Genero Nome Raca UploadIntention IntList )
];
use MooseX::Types::Moose qw(ArrayRef HashRef CodeRef Str ScalarRef);
use MooseX::Types::Common::String qw(NonEmptySimpleStr NonEmptyStr);
use Business::BR::CEP qw(test_cep);
use Moose::Util::TypeConstraints;
use DateTime::Format::ISO8601;

# ISO_8601
my $parser_datetime_zulu = DateTime::Format::ISO8601->new();

use DateTime::Format::Pg;
use MooseX::Types::JSON;
use Business::BR::CPF qw(test_cpf);

my $is_international_mobile_number = sub {
    my $num = shift;

    # too long
    return 0 if length $num > 100;

    return $num =~ /^\+\d{12,13}$/ ? 1 : 0 if $num =~ /\+55/;

    return $num =~ /^\+\d{10,16}$/ ? 1 : 0;
};

subtype DateStr, as Str, where {
    eval { DateTime::Format::Pg->parse_date($_)->ymd };
    return $@ eq '';
}, message {"invalid date [$_]"};

coerce DateStr, from Str, via {
    DateTime::Format::Pg->parse_date($_)->ymd;
};

subtype DateTimeStr, as Str, where {
    eval { $parser_datetime_zulu->parse_datetime($_)->datetime };
    return $@ eq '';
}, message {"invalid date [$_]"};

coerce DateTimeStr, from Str, via {
    $parser_datetime_zulu->parse_datetime($_)->datetime;
};

subtype MobileNumber, as Str, where {
    return 1 if $_ eq '+5599901010101';

    $is_international_mobile_number->($_);
}, message {
    "$_ mobile number invalido";
};

subtype CPF, as NonEmptyStr, where {
    my $cpf = $_;
    ($cpf !~ /^0+$/) && ($cpf !~ /^(\d)\1+$/) && ($cpf =~ /^\d+$/) && test_cpf($cpf);
};

coerce CPF, from Str, via {
    my $cpf = $_;
    $cpf =~ s/\D+//g;
    $cpf;
};

subtype CEP, as Str, where {
    my $cep = $_;
    $cep =~ s/\D+//g;
    $cep =~ s/^(\d+)(\d{3})$/$1-$2/;
    return test_cep($cep);
}, message {"$_[0] is not a valid CEP"};

coerce CEP, from Str, via {
    s/\D+//g;
    $_;
};

subtype Genero, as Str, where {
    my $str = $_;

    return $str =~ /^(Feminino|Masculino|NaoInformado)$/ ? 1 : 0;
}, message {"$_[0] is not a valid Genero"};

coerce Genero, from Str, via {
    $_;
};

subtype Raca, as Str, where {
    my $str = $_;
    return 0 if length $str > 100;
    return $str =~ /^(branco|pardo|preto|amarelo|indigena|nao_declarado)$/ ? 1 : 0;
}, message {"$_[0] is not a valid Raca"};

coerce Raca, from Str, via {
    $_;
};


subtype UploadIntention, as Str, where {
    my $str = $_;
    return 0 if length $str > 100;
    return $str =~ /^(quiz)$/ ? 1 : 0;
}, message {"$_[0] is not a valid UploadIntention"};

coerce UploadIntention, from Str, via {
    $_;
};

subtype IntList, as Str, where {
    my $str = $_;

    # too long
    return 0 if length $str > 2000;

    # até aprox 332 numeros max
    return $str =~ /^[0-9]{1,6}(?>,[0-9]{1,6})*$/o ? 1 : 0;
}, message {"$_[0] is not a valid IntList"};

coerce IntList, from Str, via {
    $_;
};

subtype Nome, as Str, where {
    my $str = $_;

    # too long
    return 0 if length $str >= 200;

    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    # precisa ter pelo menos um espaço
    if ($str =~ / /) {

        # nao pode ter emoji ou nao latin
        return 1 if $str =~ /^[\p{Latin}\ \']+$/;
    }
    return 0;
}, message {"$_[0] is not a valid Nome"};

coerce Nome, from Str, via {
    $_;
};

1;
