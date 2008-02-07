package VyattaQosMatch;
require VyattaConfig;
use VyattaQosUtil;
use strict;

my %fields = (
	_dev      => undef,
	_vif      => undef,
	_ip	  => undef,
);

sub new {
    my ( $that, $config ) = @_;
    my $self = {%fields};
    my $class = ref($that) || $that;

    bless $self, $class;
    $self->_define($config);

    return $self;
}

sub _define {
    my ( $self, $config ) = @_;
    my $level = $config->setLevel();

    $self->{_vif} = $config->returnValue("vif");
    $self->{_dev} = VyattaQosUtil::getIfIndex($config->returnValue("interface"));

    if ($config->exists("ip")) {
	my %ip;

	$ip{dsfield} = VyattaQosUtil::getDsfield( $config->returnValue("ip dscp"));
	$ip{protocol} = VyattaQosUtil::getProtocol($config->returnValue("ip protocol"));
	$ip{src} = $config->returnValue("ip source address");
	$ip{dst} = $config->returnValue("ip destination address");
	$ip{sport} = $config->returnValue("ip source port");
	$ip{dport} = $config->returnValue("ip destination port");
	$self->{_ip} = \%ip;
    }
}

sub filter {
    my ( $self, $out, $dev, $id ) = @_;

    print {$out} "filter add dev $dev parent 1:0 prio 1";

    if (defined $self->{_ip}) {
	my $ip = $self->{_ip};
	print {$out} " protocol ip u32";
	print {$out} " match ip dsfield $$ip{dsfield} 0xff"	if defined $$ip{dsfield};
	print {$out} " match ip protocol $$ip{protocol} 0xff"   if defined $$ip{protocol};
	print {$out} " match ip src $$ip{src}"			if defined $$ip{src};
	print {$out} " match ip sport $$ip{sport} 0xffff"	if defined $$ip{sport};
	print {$out} " match ip dst $$ip{dst}"			if defined $$ip{dst};
	print {$out} " match ip dport $$ip{dport} 0xffff"	if defined $$ip{dport};
    }

    if (defined $self->{_dev}) {
	print {$out} " basic match meta \(rt_iif eq $self->{_dev}\)";
    }

    if (defined $self->{_vif}) {
	print {$out} " basic match meta \(vlan mask 0xfff eq $self->{_vif}\)";
    }

    print {$out} " classid 1:$id\n";
}
